import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.CountDownLatch;
import java.io.File;
import java.io.IOException;
import java.util.ConcurrentModificationException;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.util.Properties;
import java.util.concurrent.atomic.AtomicLong;
import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;
import org.apache.zookeeper.CreateMode;
import org.apache.zookeeper.KeeperException;
import org.apache.zookeeper.WatchedEvent;
import org.apache.zookeeper.Watcher;
import org.apache.zookeeper.Watcher.Event.KeeperState;
import org.apache.zookeeper.ZooDefs.Ids;
import org.apache.zookeeper.ZooKeeper;
import org.apache.zookeeper.data.Stat;
import org.apache.zookeeper.AsyncCallback.StatCallback;
 
/**
 * simple zookeeper test program.
 * <p><br>
 * @author Rong Shi
 * @version 0.1
 * @param hosts Server List, separated by coma
 * @param rootPath the root directory of znode for zksimpleTestAsync program
 * @param numofznodes Number of znodes to be created
 * @param metasize Size of single znode
 * @param runs number of iterations
 * @param rectime time span to record results
 * @param alltime time span to run experiment
 * @param outfile output file
 */
public class zksimpleTestAsync{
    private final int SESSION_TIMEOUT = 5000;   //in us granularity
    private CountDownLatch connectedSignal = new CountDownLatch(1);
    protected static ZooKeeper zk;
    static Logger logger = Logger.getLogger(zksimpleTestAsync.class);

    protected String hosts;
    protected String rootPath;
    int numofznodes = 100;        // def: 100 znodes
    int metasize = 512;           // def: 512 Bytes
    static int runs = 1000;       // def: 1000 runs
    long rectime = 10*60*1000;    // def: 10 min (milliseconds)
    long alltime = 20*60*1000;    // def: 20 min (milliseconds)
    long warmuptime;
    static byte[] testdata;      // znode data
    static int rec_iter = 1;
    static int iter;
    static int opcnt;
    static AtomicLong async_finished = new AtomicLong();
    static int async_window = 100;
    static int async_avail = async_window;
    static boolean async_done = false;

    static long last_finished;
    static long last_time;
    static long current_time;
    static BufferedWriter outfs;
    static String znodename; 
    static List<String> znodelist = new ArrayList<String>();
    static long t_begin;
    static String outfile;
    Timer timer;

    public void setLog() {
        // Enable log4j services 
        String log4jConfPath = "/proj/EMS/rsproj/zookeeper-3.4.6/conf/log4j.properties";
        PropertyConfigurator.configure(log4jConfPath);

    }

    public void getParm(String[] args) {
        //Get input parameters
        hosts = args[0];
        rootPath = args[1];
        numofznodes = Integer.parseInt(args[2]);
        metasize = Integer.parseInt(args[3]);
        runs = Integer.parseInt(args[4]);
        rectime = Long.parseLong(args[5], 10);
        alltime = Long.parseLong(args[6], 10);
        outfile = args[7];

        //Generating znode data
        testdata = new byte[metasize];
        for(int i=0;i< metasize;i++){
            testdata[i] = 'A';
        }

        logger.info("hosts: "+hosts+", root: "+rootPath);
        logger.info("numznodes: "+numofznodes 
                + ", znode size: "+metasize+" bytes, runs: "+runs + ", outfile: " + outfile);

        try{
            outfs = new BufferedWriter(new FileWriter(outfile));
            outfs.write("## record-iter\t\t runs(WRITE)\t\t SetOps\t\t time(s)\t TPS\n");
            outfs.flush();
        }catch(IOException e){
            logger.error("Error Open BufferedWriter", e);
        }
    }

    public void initRecord() {
        long interval;
        //last_finished = 0;
        last_finished = async_finished.get();
        current_time = 0;
        interval = rectime/4;        //def: half of rectime
        warmuptime = (alltime - rectime)/2;

        timer = new Timer();
        last_time = System.currentTimeMillis() - t_begin;
        timer.scheduleAtFixedRate(new RecordTimer(), warmuptime - last_time, interval);
        logger.info("### schedule timetask ");
    }

    public static void main(String[] args) throws InterruptedException, KeeperException, IOException, Exception {
        // Initialize a zookeeper test case
        zksimpleTestAsync zktest = new zksimpleTestAsync();
        // start time of alltime
        zktest.t_begin = System.currentTimeMillis();
        zktest.setLog();
        zktest.getParm(args);

        // Connect the zookeeper server(s)
        zktest.connect(zktest.hosts);
        logger.info("zksimpleTestAsync connected ...");
        outfs.write("## zksimpleTestAsync connected ... \n");

        if (zk.exists(zktest.rootPath, false) != null) {
            zktest.deleteChildren(zktest.rootPath, true);
            logger.info("clear previous children nodes...");
            zktest.delete(zktest.rootPath);
            logger.info("clear previous nodes...");
        }

        zktest.create(zktest.rootPath, zktest.testdata);
        zktest.createList(zktest.rootPath, zktest.testdata, zktest.numofznodes);

        zktest.initRecord();

        Iterator<String> it = znodelist.iterator();
        while (it.hasNext()){
            zktest.setDataAsync((String) it.next());
        }

        outfs.write("## zksimpleTestAsync launched initial batch of requests ... \n");

        while (System.currentTimeMillis() - zktest.t_begin < zktest.alltime) {
            //wait a while...
            try {
                Thread.sleep(zktest.rectime);
            } catch (InterruptedException ex) {
                Thread.currentThread().interrupt();
            }
        }

        logger.info("zksimpleTestAsync fnishes after (ms) " + (System.currentTimeMillis() - zktest.t_begin));

        zktest.deleteChildren(zktest.rootPath, false);
        zktest.delete(zktest.rootPath);
        logger.info("clear all znodes ...");
        zktest.close();

    } //end of main

    /**
     * Create a ZooKeeper client object
     * <p><br>
     * @param connhost Comma separated host:port pairs e.g. "127.0.0.1:2181,127.0.0.1:2181"
     * @see ZooKeeper
     */
    public void connect(String connhost) throws Exception {
        logger.info("try connect "+connhost);
        zk = new ZooKeeper(connhost, SESSION_TIMEOUT, new ConnWatcher());
        connectedSignal.await();
    }

    public class ConnWatcher implements Watcher {
        public void process(WatchedEvent event) {
            // establish connection and send callback to process
            // event.getState() should be in KeeperState.SyncConnected
            if (event.getState() == KeeperState.SyncConnected) {
                // Wakeup wait thread on Connect method
                connectedSignal.countDown();
            }
        }
    }

    /**
     * Create a persistent znode.
     * <p><br>
     * @param Path Znode's Path
     * @param data Initialized data associated with znode 
     * @param ACL  permission, could use Ids.OPEN_ACL_UNSAFE
     * @param CreateMode Enum Type
     * @exception org.apache.zookeeper.KeeperException
     * @exception java.lang.InterruptedException
     * @see create
     */
    public void create(String Path, byte[] data) throws Exception {
        zk.create(Path, data, Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
    }

    public void createList(String Path, byte[] data, int count) throws Exception {
        // Create the znodes and znode list
        String nodePath;
        for ( int i = 0; i < count; i++) {
            nodePath = new File(Path, String.valueOf(i)).getPath();
            zk.create(nodePath, data, Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
            znodelist.add(nodePath);
        }
        logger.info("zksimpleTestAsync create "+ count +" znodes under path "+ Path);
    }

    /**
     * Delete znode list.
     * <p><br>
     * @param Path Znode's Path, possibly the root path
     * @exception org.apache.zookeeper.KeeperException
     * @exception java.lang.InterruptedException
     * @see getChildren
     */
    public void deleteChildren(String path, boolean prev) throws KeeperException, InterruptedException {
        try{
            if (prev) {
                List<String> tmplist = zk.getChildren(path, false);
                for (String elem : tmplist) {
                    znodelist.add(new File(path, elem).getPath());
                }
                for (String zelem : znodelist) {
                    System.out.println("### detect path " + zelem);
                }
            }

            if(znodelist.isEmpty()){
                logger.info(path+" has no znode");
            }else{
                Iterator<String> it = znodelist.iterator();
                logger.info(path+" has znode");  
                while (it.hasNext()){
                    zk.delete((String) it.next(), -1);
                }
            }

            // Reset the znodelist to null
            znodelist.clear();

        }catch (KeeperException.NoNodeException e) {  
            logger.error("ERROR delete Children", e);
        }
    }

    /**
     * Set (WRITE) a single znode
     * <p><br>
     * @param Path Znode's Path
     * @param data associated data to be set
     * @see setData
     */
    public void setData(String path,String data) throws Exception {
        zk.setData(path, data.getBytes(), -1);
        System.out.println("set Data:"+"testSetData");
    }

    public void setDataAsync(String path) {
        zk.setData(path, testdata, -1, setAsyncCallback, null);
    }

    StatCallback setAsyncCallback = new StatCallback() {
        public void processResult(int rc, String path, Object ctx, Stat stat) { 
            async_finished.incrementAndGet();
            setDataAsync(path);
        }
    };

    /**
     * Get (READ) data of a single znode.
     * <p><br>
     * @param Path Znode's Path
     * @see getData
     */
    public void getData(String path) throws Exception {
        System.out.println("get Data:");
        zk.getData(path, false, null);
    }

    /**
     * Delete a single znode.
     * <p><br>
     * @param Path Znode's Path
     * @see delete
     */
    public void delete(String path) throws Exception {
        if (zk.exists(path, false) != null) {
            //System.out.println("Delete Znode " + path);
            // cannot delete znode if has different version#，Lock Mechanism
            // Delete without version check if setts it to -1
            zk.delete(path, -1);
        }
    }

    /**
     * Close a Zookeeper Client.
     * <p><br>
     * @see close
     */
    public void close() throws IOException {
        try {
            zk.close();
        } catch (InterruptedException e) {
            logger.error("ERROR close ZooKeeper", e);
        }
    }

    class RecordTimer extends TimerTask {
        double tps;
        long elapsed_time;
        long done_iter;

        @Override
        public void run() {
            long finished = async_finished.get();

            if (outfs != null) {
                try {
                    current_time = System.currentTimeMillis() - t_begin;
                    done_iter = finished - last_finished;
                    elapsed_time = current_time - last_time;
                    tps = (double) 1000 * done_iter / elapsed_time;

                    if (rec_iter > 1) {
                        outfs.write(rec_iter+"\t "+done_iter+"\t "+elapsed_time/1000 +"\t "+ String.format("%.1f",tps) +"\n");
                    } else {
                        outfs.write("##"+rec_iter+"\t "+done_iter+"\t "+elapsed_time/1000 +"\t "+ String.format("%.1f",tps) +"\n");
                    }
                    outfs.flush();

                    if (current_time > rectime + warmuptime /*|| (finished == runs + 1)*/) {
                        outfs.write("## Cancel record timer after " + current_time/1000 + "(s) since test \n");
                        outfs.flush();
                        outfs.close();
                        timer.cancel();
                    } 
                } catch (Exception e) {
                    logger.info("Error while write to output file", e);
                }
            }
            last_finished = finished;
            last_time = current_time;
            rec_iter = rec_iter + 1;
        }
    }

}

