
import java.net.SocketException;
import java.util.List;

import artnet4j.ArtNet;
import artnet4j.ArtNetException;
import artnet4j.ArtNetNode;
import artnet4j.events.ArtNetDiscoveryListener;
import artnet4j.packets.ArtDmxPacket;

import processing.video.*;
Movie myMovie;

int videoWidth = 720;
int videoHeight = 1280;

int screenWidth = 1100;
int screenHeight = 1000;

int projectWidth = 100;
int projectHeight = 300;

void setup() {
  size( 800, 250);
  new PollTest().test();

  //frameRate(5);
  size(screenWidth, screenHeight);
  myMovie = new Movie(this, "/Users/Micael/Desktop/Processing/bigboss/test.mov");
  //myMovie.frameRate(15);
  myMovie.loop();
}

void draw() {
  background(0);
  //tint(255, 255);
  image(myMovie, 0, 0);
  frame.setTitle("FPS: " + frameRate);
}

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}


class PollTest implements ArtNetDiscoveryListener {

    private ArtNetNode netLynx;

    private int sequenceID;

    @Override
    public void discoveredNewNode(ArtNetNode node) {
        if (netLynx == null) {
            netLynx = node;
            System.out.println("found net lynx");
        }
    }

    @Override
    public void discoveredNodeDisconnected(ArtNetNode node) {
        System.out.println("node disconnected: " + node);
        if (node == netLynx) {
            netLynx = null;
        }
    }

    @Override
    public void discoveryCompleted(List<ArtNetNode> nodes) {
        System.out.println(nodes.size() + " nodes found:");
        for (ArtNetNode n : nodes) {
            System.out.println(n);
        }
    }

    @Override
    public void discoveryFailed(Throwable t) {
        System.out.println("discovery failed");
    }

    private void test() {

        ArtNet artnet = new ArtNet();
        //artnet.setReceivePort(6453);
        //artnet.setSendPort(6454);
        int index = 0;
        
        int MATRIX_COUNT = 8; 

        try {
            artnet.start();
            artnet.getNodeDiscovery().addListener(this);
            artnet.startNodeDiscovery();
            while (true) {
              
              ArtDmxPacket dmxTest = new ArtDmxPacket();
              byte[] bufferTest = new byte[512];
              
              for (int i = 0; i < 512; i++) {
                
                // White                
//                bufferTest[i] = 255;
                  
                  // Normal Sin Sequence
//                  byte value = (byte) (Math.sin(sequenceID * 0.05 + i * 0.8) * 127 + 128);
//                  bufferTest[i] = value;
                  
                  // Add Tan Sequence
//                  byte value = (byte) (Math.tan(sequenceID * 0.05 + i * 0.8));
//                  bufferTest[i] = value;
                  
                  // Noise Sequence
//                  byte value = (byte) (Math.sin(sequenceID * 0.65 + i * 0.8) * 127 * 128);
//                  bufferTest[i] = value;

                  // Noise Sequence
                  byte value = (byte) (Math.sin(sequenceID * 80 + i * 0.8) * 256);
                  bufferTest[i] = value;

                  // Dot test
//                  index = (int) sequenceID % 512; // dot
//                  bufferTest[i] = (byte) (i == index ? 255 : 0);
              }
              
              // Tessel and local send data
              int un_count = ceil((float)(MATRIX_COUNT * 256 * 3) / 512);
              //println(un_count);
              for (int jj = 0; jj < un_count; jj++) {
                dmxTest.setUniverse(0, jj);
                dmxTest.setDMX(bufferTest, bufferTest.length);
                artnet.unicastPacket(dmxTest, "192.168.1.66");
                artnet.unicastPacket(dmxTest, "192.168.1.68");
                artnet.unicastPacket(dmxTest, "192.168.1.69"); 
                artnet.unicastPacket(dmxTest, "10.211.55.5");
                delay(2);
//                delay(75);
              }
              
              // Local send data
//              dmxTest.setUniverse(0, 0);
//              dmxTest.setDMX(bufferTest, bufferTest.length);
//              artnet.unicastPacket(dmxTest, "10.211.55.5");

              sequenceID++;
              
                if (netLynx != null) {
                    ArtDmxPacket dmx = new ArtDmxPacket();
                    dmx.setUniverse(netLynx.getSubNet(), netLynx.getDmxOuts()[0]);
                    dmx.setSequenceID(sequenceID % 255);
                    byte[] buffer = new byte[510];
                    buffer[0] = (byte) 55;
                    for (int i = 0; i < buffer.length; i++) {
                        buffer[i] = (byte) (Math.sin(sequenceID * 0.05 + i * 0.8) * 127 + 128);
                    }
                    dmx.setDMX(buffer, buffer.length);
                    artnet.unicastPacket(dmx, netLynx.getIPAddress());
                    dmx.setUniverse(netLynx.getSubNet(), netLynx.getDmxOuts()[1]);
                    artnet.unicastPacket(dmx, netLynx.getIPAddress());
                    sequenceID++;
                }
                Thread.sleep(30);
            }
        } catch (SocketException e) {
            e.printStackTrace();
        } catch (ArtNetException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}

