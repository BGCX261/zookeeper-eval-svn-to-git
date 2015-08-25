import java.util.List;
import java.util.Iterator;
import java.util.concurrent.CountDownLatch;
import java.io.File;
import java.util.Properties;
//import java.nio.file.Path;
//import java.io.InputStream;
import org.apache.log4j.PropertyConfigurator;
import org.apache.zookeeper.CreateMode;
import org.apache.zookeeper.KeeperException;
import org.apache.zookeeper.WatchedEvent;
import org.apache.zookeeper.Watcher;
import org.apache.zookeeper.Watcher.Event.KeeperState;
import org.apache.zookeeper.ZooDefs.Ids;
import org.apache.zookeeper.ZooKeeper;
import org.apache.zookeeper.data.Stat;
 
/**
 * simple zookeeper test program.
 * <p><br>
 * @author Rong Shi
 * @version 0.1
 * @param hosts Server List, separated by coma
 * @param rootPath the root directory of znode for zkTest program
 * @param numofznodes Number of znodes to be created
 * @param metasize Size of single znode
 * @param runs number of iterations
 * @param threads number of setter/getter threads
 */
public class zkTest{
    protected static String hosts;
    private final int SESSION_TIMEOUT = 5000;   //in us granularity
    private CountDownLatch connectedSignal = new CountDownLatch(1);
    protected static ZooKeeper zk;
    protected static String rootPath;
 
    static int threads = 1;    // default value 10
    static int runs = 10;      // default value 10
    static int start = 0;
 
    static int metasize = 512; // default value 512 Bytes
    static byte[] testdata;    // znode data
    static String znodename; 
    static int numofznodes = 10;
    static List<String> childlist;
 
    public static void main(String[] args) throws Exception {
    // Enable log4j services 
    String log4jConfPath = "/proj/EMS/rsproj/zookeeper-3.4.6/conf/log4j.properties";
    PropertyConfigurator.configure(log4jConfPath);

    // Get input parameters
    hosts = args[0];
    rootPath = args[1];
    numofznodes = Integer.parseInt(args[2]);
    metasize = Integer.parseInt(args[3]);
    runs = Integer.parseInt(args[4]);
    threads = Integer.parseInt(args[5]);
    System.out.println("DBG hosts "+hosts+"root "+rootPath+", numznodes "+numofznodes+", meta size "+metasize+", runs "+runs+", threads "+threads);

    // Generating znode data
    testdata = new byte[metasize];
    for(int i=0;i< metasize;i++){
        testdata[i] = 'A';
    }
    
    // Initialize a zookeeper test case
    zkTest zktest = new zkTest();
    // Connect the zookeeper server(s)
    zktest.connect(hosts);
    System.out.println("zkTest connected ...");
    // Delete previous znodes 
    
    if (zk.exists(rootPath, false) != null) {
        zktest.getChild(rootPath, true);
        zktest.delete(rootPath);
        System.out.println("clear previous nodes...");
    }

    zktest.create(rootPath, testdata);
    
    // Create and initialize the znodes
    for ( int i = 0; i < numofznodes; i++) {
    	String nodePath = new File(rootPath, String.valueOf(i)).getPath();
        zktest.create(nodePath, testdata);
    	//System.out.println("zkTest create node " + nodePath);
    }

    System.out.println("zkTest create "+numofznodes+" znodes under path "+rootPath);
    // Fetch the znode list
    zktest.getChild(rootPath, false);
 
    // Enable the multi-thread support
    WorkerStat[] statArray = new WorkerStat[threads];
    Thread[] threadArray = new Thread[threads];
 
    WorkerStat mainStat = new WorkerStat();
    mainStat.runs = runs * threads;
    //System.out.println("DBG mainstat-run: " + mainStat.runs + ", runs: " + runs + ", tids: " + threads);
 
    // Timing the worker threads
    long begin = System.currentTimeMillis();
    for (int i = 0; i<threads; i++) {
        statArray[i] = new WorkerStat();
        statArray[i].start = start + i * runs;
        statArray[i].runs = runs;
        threadArray[i] = new SetterThread(statArray[i]);
        threadArray[i].start();
    }
    for (int i = 0; i<threads; i++) {
        threadArray[i].join();
    }
    mainStat.setterTime = System.currentTimeMillis() - begin;
 
    begin = System.currentTimeMillis();
    for (int i = 0; i<threads; i++) {
        threadArray[i] = new GetterThread(statArray[i]);
        threadArray[i].start();
    }
    for (int i = 0; i<threads; i++) {
        threadArray[i].join();
    }
    mainStat.getterTime = System.currentTimeMillis() - begin;
 
    WorkerStat totalStat = new WorkerStat();
 
    System.out.println("zkTest finishes ...");
    System.out.println("Thread("+threads+")\t\truns\tset time(ms)\tget time(ms)");
 
    for (int i = 0; i<threads; i++) {
        totalStat.runs = totalStat.runs + statArray[i].runs;
        totalStat.setterTime = totalStat.setterTime + statArray[i].setterTime;
        totalStat.getterTime = totalStat.getterTime + statArray[i].getterTime;
    }

    // Output accumulated Statistics
    System.out.println("Total (metasz "+metasize+")\t" + totalStat.runs + "\t"+ totalStat.setterTime + "\t\t" + totalStat.getterTime);
    System.out.println("Avg\t\t" + runs + "\t" + totalStat.setterTime/ threads + "\t\t" + totalStat.getterTime / threads);      
    System.out.println("TPS\t\t\t"+1000*numofznodes * totalStat.runs/totalStat.setterTime+"\t\t"+1000*numofznodes* totalStat.runs/totalStat.getterTime);
    System.out.println("Main\t\t" + mainStat.runs + "\t"+ mainStat.setterTime + "\t\t" + mainStat.getterTime);
    System.out.println("TPS\t\t\t"+1000*numofznodes* mainStat.runs/mainStat.setterTime+"\t\t"+1000*numofznodes* mainStat.runs/mainStat.getterTime);
    
    zktest.getChild(rootPath, true);
    System.out.println("clear all znodes ...");
    zktest.getChild(rootPath, false);
    // Close the ZooKeeper Client
    zktest.close();
    } //end of main
 
    private static class WorkerStat {
    public int start, runs;
    public long setterTime, getterTime;
 
    public WorkerStat() {
        start = runs = 0;
        setterTime = getterTime = 0;
    }
    }
 
    /**
     * SetterThread used to handle setData operations
     * <p>Measure the WRITE operations<br>
     * @see <a href="http://zookeeper.apache.org/doc/r3.4.6/api/index.html">ZooKeeper API</a>
     */
    private static class SetterThread extends Thread {
    private WorkerStat stat;
    static String setpath;
 
    SetterThread(WorkerStat stat) {
        this.stat = stat;
    }
 
    public void run() {
        long begin = System.currentTimeMillis();
        for (int i = stat.start; i<(stat.start + stat.runs); i++) {
            Iterator<String> it = childlist.iterator();
            if(!childlist.isEmpty()){
            while (it.hasNext()){
	            String child = it.next();
    	        setpath = new File(rootPath, child).getPath();
              //System.out.println("DBG PRINT SET znodes " + setpath);
              try {
              zk.setData(setpath, testdata, -1);
              } catch (Exception e) {
              e.printStackTrace();
              }
            }
           }
        }

        long end = System.currentTimeMillis();
        stat.setterTime = end - begin;
    } //end of run()
    }
 
    /**
     * GetterThread used to handle getData Operations
     * <p>To be updated<br>
     * @see <a href="http://zookeeper.apache.org/doc/r3.4.6/api/index.html">ZooKeeper API</a>
     */
    private static class GetterThread extends Thread {
    private WorkerStat stat;
    static String getpath;
    GetterThread(WorkerStat stat) {
        this.stat = stat;
    }
    public void run() {
        long begin = System.currentTimeMillis();
        for (int i = stat.start; i<(stat.start + stat.runs); i++) {
            Iterator<String> it = childlist.iterator();
            if(!childlist.isEmpty()){
            while (it.hasNext()){
	          String child = it.next();
                try {
    	          getpath = new File(rootPath, child).getPath();
                zk.getData(getpath, false, null);
                //System.out.println("DBG PRINT GET znodes " + getpath);
                } catch (Exception e) {
                    e.printStackTrace();
                } 
            }
           }
        }
        long end = System.currentTimeMillis();
        stat.getterTime = end - begin;
    } //end of run()
    }
 
    /**
     * Create a ZooKeeper client object
     * <p><br>
     * @param connhost Comma separated host:port pairs e.g. "127.0.0.1:2181,127.0.0.1:2181"
     * @see <a href="http://zookeeper.apache.org/doc/r3.4.6/api/index.html">ZooKeeper API</a>
     */
    public void connect(String connhost) throws Exception {
        System.out.println("try connect "+connhost);
        zk = new ZooKeeper(connhost, SESSION_TIMEOUT, new ConnWatcher());
        // wait for completion
        connectedSignal.await();
    }
    
    public class ConnWatcher implements Watcher{
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
     * @exception org.apache.zookeeper.KeeperException
     * @exception java.lang.InterruptedException
     * @see <a href="http://zookeeper.apache.org/doc/r3.4.6/api/index.html">ZooKeeper API</a>
     */
    public void create(String Path, byte[] data) throws Exception {
        // ACL permission, could use Ids.OPEN_ACL_UNSAFE
        // CreateMode Enum Type
        zk.create(Path, data, Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        //System.out.println("Create Node:"+Path);
    }
      
    /**
     * Create a persistent znode.
     * <p><br>
     * @param path Znode's Path, possibly the root path
     * @param delnodes true for the deletion, false for the simple list
     * @exception org.apache.zookeeper.KeeperException
     * @exception java.lang.InterruptedException
     * @see <a href="http://zookeeper.apache.org/doc/r3.4.6/api/index.html">ZooKeeper API</a>
     */
    public void getChild(String path, boolean delnodes) throws KeeperException, InterruptedException{     
        String delnodepath;
        try{  
            childlist = zk.getChildren(path, false);  
            Iterator<String> it = childlist.iterator();
            if(childlist.isEmpty()){
                System.out.println(path+" has no znode");
            }else{
                System.out.println(path+" has znode");  
                while (it.hasNext()){
	            String child = it.next();
    	            delnodepath = new File(rootPath, child).getPath();
                    if ( delnodes ) {
                      zk.delete(delnodepath, -1);
                      //System.out.println("delete znodes " + delnodepath);
                    } else {
                      //System.out.println("PRINT znodes " + delnodepath);
                    }
                }
            }
        }catch (KeeperException.NoNodeException e) {  
            e.printStackTrace();
        }
    }

    /**
     * Set a single znode
     * <p><br>
     * @param path Znode's Path
     * @param data associated data to be set
     */
    public void setData(String path,String data) throws Exception{
        zk.setData(path, data.getBytes(), -1);
        System.out.println("set Data:"+"testSetData");
    }

    /**
     * Get data of a single znode.
     * <p><br>
     * @param path Znode's Path
     */
    public void getData(String path) throws Exception{
        System.out.println("get Data:");
        zk.getData(path, false, null);
    }

    /**
     * Delete a single znode.
     * <p><br>
     * @param path Znode's Path
     * @see <a href="http://zookeeper.apache.org/doc/r3.4.6/api/index.html">ZooKeeper API</a>
     */
    public void delete(String path) throws Exception{
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
     * @see <a href="http://zookeeper.apache.org/doc/r3.4.6/api/index.html">ZooKeeper API</a>
     */
    public void close() {
        try {
            zk.close();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
