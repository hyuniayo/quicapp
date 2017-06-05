//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by Fernflower decompiler)
//

package edu.umich.cse.audioanalysis.Ultraphone.ExpActivity;

import android.app.Activity;
import android.content.Context;
import android.graphics.Point;
import android.hardware.SensorManager;
import android.util.Log;
import edu.umich.cse.audioanalysis.BigMoveDetector;
import edu.umich.cse.audioanalysis.C;
import edu.umich.cse.audioanalysis.D;
import edu.umich.cse.audioanalysis.JniController;
import edu.umich.cse.audioanalysis.LogController;
import edu.umich.cse.audioanalysis.MySensorController;
import edu.umich.cse.audioanalysis.MySensorControllerListener;
import edu.umich.cse.audioanalysis.SpectrumSurvey;
import edu.umich.cse.audioanalysis.SurveyEndListener;
import edu.umich.cse.audioanalysis.Network.NetworkController;
import edu.umich.cse.audioanalysis.Network.NetworkControllerListener;
import edu.umich.cse.audioanalysis.Ultraphone.UltraphoneControllerListener;
import java.io.File;
import java.util.LinkedList;
import java.util.Queue;

public class UltraphoneController2 implements NetworkControllerListener, SurveyEndListener, MySensorControllerListener {
    public static final int ERROR_CODE_PILOT_NOT_FOUND = 1;
    public static final int ERROR_CODE_AUDIO_END = 2;
    Context context;
    UltraphoneControllerListener caller;
    int deviceIdx = -1;
    boolean isSurvying;
    boolean isConnecting;
    boolean needToStartSensingAfterNetworkConnected;
    boolean needToRecordForce;
    boolean needToRecordSqueeze;
    boolean needToStartCheckSqueezeAfterNetworkConnected;
    boolean needToMoveTraceFolderWhenSensingEnded;
    boolean pilotNotSyncedHasBeenFound;
    String traceFolderSuffixToMove;
    int RECORDER_SAMPLERATE = '뮀';
    float volSelected;
    String soundNameSelected;
    String soundSettingSelected;
    SpectrumSurvey ss;
    MySensorController msc;
    LogController lc;
    NetworkController nc;
    JniController jc;
    public BigMoveDetector bmd;
    double anaDelaySum;
    double anaDelayCnt;
    final String SERVER_IP;
    final int SERVER_PORT;
    Queue<Double> estimatedPressures;
    double estimatedPressureSum;
    int bigMoveStatus;
    public long currentAudioTotalRecordedSampleCnt;

    public UltraphoneController2(int detectMode, UltraphoneControllerListener callerIn, Context contextIn) {
        this.volSelected = C.DEFAULT_VOL;
        this.soundNameSelected = "default";
        this.soundSettingSelected = "48000rate-5000repeat-2400period+chirp-18000Hz-24000Hz-1200samples+namereduced";
        this.anaDelaySum = 0.0D;
        this.anaDelayCnt = 0.0D;
        this.SERVER_IP = C.SERVER_ADDR;
        this.SERVER_PORT = C.DETECTER_SERVER_PORT;
        this.currentAudioTotalRecordedSampleCnt = 0L;
        this.context = contextIn;
        this.caller = callerIn;
        D.configBasedOnSetting(detectMode, this.context);
        this.deviceIdx = D.code;
        this.isConnecting = false;
        this.isSurvying = false;
        this.needToStartSensingAfterNetworkConnected = false;
        this.needToRecordForce = false;
        this.needToRecordSqueeze = false;
        this.needToStartCheckSqueezeAfterNetworkConnected = false;
        this.needToMoveTraceFolderWhenSensingEnded = false;
        this.pilotNotSyncedHasBeenFound = false;
        this.estimatedPressureSum = 0.0D;
        this.estimatedPressures = new LinkedList();
        this.nc = new NetworkController(this);
        this.bigMoveStatus = 0;
        this.bmd = new BigMoveDetector();
        this.msc = new MySensorController(this, (SensorManager)this.context.getSystemService("sensor"), "DebugOutput/", 1000);
        this.lc = new LogController(C.appFolderPath + "DebugOutput/", this.nc);
        Log.d("MYYYYM", "ULTRAPHONECONTROLLER");
    }

    public void startEverything() {
        if(C.TRACE_SEND_TO_NETWORK) {
            this.startNetwork();
            this.needToStartSensingAfterNetworkConnected = true;
        } else {
            this.startSensing();
        }

    }

    public void stopEverything() {
        this.stopSensing();
        this.stopNetwork();
    }

    public void startSensing() {
        this.ss = new SpectrumSurvey(this.RECORDER_SAMPLERATE, this.soundSettingSelected, this.context);
        boolean initSuccess = this.ss.initSurvey(this, 1);
        if(!initSuccess) {
            this.caller.showToast("Please wait the previos sensing ends");
        } else {
            if(C.TRACE_REALTIME_PROCESSING) {
                this.jc = new JniController(C.appFolderPath + "DebugOutput/" + "log/");
            }

            this.lc = new LogController(C.appFolderPath + "DebugOutput/", this.nc);
            this.msc.startRecord(C.appFolderPath + "DebugOutput/");
            this.isSurvying = true;
            this.caller.updateDebugStatus("Wait survey ends");
            this.ss.startSurvey();
            if(this.needToStartCheckSqueezeAfterNetworkConnected) {
                this.startCheckSqueezeRightNow();
                this.needToStartCheckSqueezeAfterNetworkConnected = false;
            }
        }

    }

    public void stopSensing() {
        if(this.isSurvying) {
            this.ss.stopSurvey();
        }

    }

    public void startNetwork() {
        this.caller.updateDebugStatus("Wait connection to server...");
        this.nc.connectServer(this.SERVER_IP, this.SERVER_PORT);
    }

    public void stopNetwork() {
        if(this.isConnecting) {
            this.nc.closeServerIfServerIsAlive();
            this.isConnecting = false;
        }

    }

    public void startCheckPressure(Point p) {
        this.needToRecordForce = true;
        this.resetSmoothedPressure();
        this.lc.addLogAndOutputDirectly(this.ss.audioTotalRecordedSampleCnt, "pse", 1, (float)p.x, (float)p.y);
        if(!this.isConnecting && C.TRACE_REALTIME_PROCESSING && this.jc != null) {
            this.jc.enablePseReply();
        }

        this.caller.pressureUpdate(0.0D);
    }

    public void stopCheckPressure() {
        this.needToRecordForce = false;
        this.lc.addLogAndOutputDirectly(this.ss.audioTotalRecordedSampleCnt, "pse", 2, 0.0F, 0.0F);
        if(!this.isConnecting && C.TRACE_REALTIME_PROCESSING && this.jc != null) {
            this.jc.disableReply();
        }

        this.caller.pressureUpdate(0.0D);
    }

    public void startCheckSqueezeWhenPossible() {
        this.needToStartCheckSqueezeAfterNetworkConnected = true;
    }

    public void startCheckSqueezeRightNow() {
        if(this.needToRecordSqueeze) {
            Log.d("AudioAnalysis", "[ERROR]: somehting wrong, actionSqueezeTestStart is triggered when needToRecordSqueeze = YES (remote server?)");
            this.caller.updateDebugStatus("Squeeze is ERROR");
        } else {
            this.needToRecordSqueeze = true;
            this.lc.addLogAndOutputDirectly(this.ss.audioTotalRecordedSampleCnt, "sse", 1, 0.0F, 0.0F);
            if(!this.isConnecting && C.TRACE_REALTIME_PROCESSING && this.jc != null) {
                this.jc.enableSseReply();
            }

            this.caller.updateDebugStatus("Squeeze is ON");
            Log.d("AudioAnalysis", "Squeeze is ON");
        }

    }

    public void stopCheckSqueeze() {
        if(!this.needToRecordSqueeze) {
            Log.d("AudioAnalysis", "[ERROR]: somehting wrong, actionSqueezeTestEnd is triggered when needToRecordSqueeze = NO (remote server?)");
            this.caller.updateDebugStatus("Squeeze is ERROR");
        } else {
            this.needToRecordSqueeze = false;
            this.lc.addLogAndOutputDirectly(this.ss.audioTotalRecordedSampleCnt, "sse", 2, 0.0F, 0.0F);
            if(!this.isConnecting && C.TRACE_REALTIME_PROCESSING && this.jc != null) {
                this.jc.disableReply();
            }

            this.caller.updateDebugStatus("Squeeze is OFF");
            Log.d("AudioAnalysis", "Squeeze is OFF");
        }

    }

    public void setTriggerLog(int code, float arg0, float arg1) {
        int stamp = 0;
        if(this.isSurvying) {
            stamp = this.ss.audioTotalRecordedSampleCnt;
        }

        this.lc.addLogAndOutputDirectly(stamp, "trg", code, arg0, arg1);
    }

    public void moveTraceFolderWhenSensingEnded(String suffix) {
        this.needToMoveTraceFolderWhenSensingEnded = true;
        this.traceFolderSuffixToMove = suffix;
    }

    void resetSmoothedPressure() {
        this.estimatedPressures.clear();
        this.estimatedPressureSum = 0.0D;
    }

    double getSmoothedPressure(double dataNow) {
        Double fDouble = new Double(dataNow);
        this.estimatedPressures.add(fDouble);
        this.estimatedPressureSum += fDouble.doubleValue();
        if(this.estimatedPressures.size() > 5) {
            Double smoothedPressure = (Double)this.estimatedPressures.peek();
            this.estimatedPressureSum -= smoothedPressure.doubleValue();
            this.estimatedPressures.poll();
        }

        double smoothedPressure1 = this.estimatedPressureSum / 5.0D;
        return smoothedPressure1;
    }

    public void isConnected(boolean success, String resp) {
        if(success) {
            this.nc.sendSetAction(2, "matlabSourceMatName", ("source_" + this.soundSettingSelected).getBytes());
            this.nc.sendSetAction(5, "traceChannelCnt", "2".getBytes());
            this.nc.sendSetAction(5, "traceVol", "0.5".getBytes());
            this.nc.sendSetAction(5, "deviceIdx", String.format("%d", new Object[]{Integer.valueOf(this.deviceIdx)}).getBytes());
            this.nc.sendInitAction();
            this.isConnecting = true;
            this.caller.updateDebugStatus("Connect successfully");
            if(this.needToStartSensingAfterNetworkConnected) {
                Activity a = (Activity)this.caller;
                a.runOnUiThread(new Runnable() {
                    public void run() {
                        UltraphoneController2.this.startSensing();
                    }
                });
            }
        } else {
            this.caller.showToast("[ERROR]: unable to connect server : " + resp);
        }

    }

    public int consumeReceivedData(double dataReceived) {
        double smoothedData = this.getSmoothedPressure(dataReceived);
        this.caller.updateDebugStatus(String.format("received data= %.3f, smoothed data = %.3f", new Object[]{Double.valueOf(dataReceived), Double.valueOf(smoothedData)}));
        if(this.needToRecordForce) {
            this.caller.pressureUpdate(smoothedData);
        } else if(this.needToRecordSqueeze) {
            int check = (int)Math.round(dataReceived);
            Log.d("AudioAnalysis", String.format("data = %f (%d)", new Object[]{Double.valueOf(dataReceived), Integer.valueOf(check)}));
            this.caller.updateDebugStatus(String.format("data = %f (%d)", new Object[]{Double.valueOf(dataReceived), Integer.valueOf(check)}));
            this.caller.squeezeUpdate((double)check);
        }

        return 0;
    }

    public void onSurveyEnd() {
        Log.d("AudioAnalysis", "onSurveyEnd");
        this.isSurvying = false;
        this.msc.stopRecord();
        if(this.needToMoveTraceFolderWhenSensingEnded) {
            File folderOld = new File(C.appFolderPath + "DebugOutput/");
            File folderNew = new File(C.appFolderPath + "DebugOutput/".substring(0, "DebugOutput/".lastIndexOf("/")) + this.traceFolderSuffixToMove);
            if(folderOld.exists()) {
                if(folderNew.exists()) {
                    Log.w("AudioAnalysis", "[WARN]: new folder path is already existed (forget to clean?)");
                }

                folderOld.renameTo(folderNew);
            } else {
                Log.e("AudioAnalysis", "[ERROR]: no sensing trace folder to move");
            }

            this.needToMoveTraceFolderWhenSensingEnded = false;
        }

        this.ss = null;
        this.caller.unexpectedEnd(2, "[ERROR]: audio play end (might need to use a longer audio?)");
    }

    public void audioRecorded(byte[] data, long audioTotalRecordedSampleCnt) {
        this.currentAudioTotalRecordedSampleCnt = audioTotalRecordedSampleCnt;
        this.msc.outputMotion((int)audioTotalRecordedSampleCnt);
        this.bigMoveStatus = this.bmd.update(this.ss.audioTotalRecordedSampleCnt, (double)this.msc.accMag, (double)this.msc.gyroMag);
        if(this.isConnecting) {
            this.nc.sendDataRequest(data);
        } else if(C.TRACE_REALTIME_PROCESSING) {
            long t1 = 0L;
            long t2 = 0L;
            if(C.ANA_NEED_TO_ESTIMATE_JNI_DELAY) {
                t1 = System.currentTimeMillis();
            }

            int result = this.jc.addAudioSamples(data);
            if(C.ANA_NEED_TO_ESTIMATE_JNI_DELAY) {
                t2 = System.currentTimeMillis();
            }

            if(result == -1) {
                Log.e("AudioAnalysis", "[ERROR]: unable to find pilot (wrong pilot setting?)");
                if(!this.pilotNotSyncedHasBeenFound) {
                    this.pilotNotSyncedHasBeenFound = true;
                    this.caller.showToast("[ERROR] pilot is not synced");
                    this.caller.unexpectedEnd(1, "[ERROR] pilot is not synced");
                }
            }

            if(C.ANA_NEED_TO_ESTIMATE_JNI_DELAY && this.jc.isReplyReadyToFetch() && result > 10) {
                double reply = (double)(t2 - t1) / 1000.0D;
                this.anaDelaySum += reply;
                ++this.anaDelayCnt;
                this.caller.updateDebugStatus(String.format("delayNow = %f, avg = %f", new Object[]{Double.valueOf(reply), Double.valueOf(this.anaDelaySum / this.anaDelayCnt)}));
            }

            while(this.jc.isReplyReadyToFetch()) {
                float reply1 = this.jc.fetchReply();
                if(this.needToRecordForce) {
                    double smoothedReply = this.getSmoothedPressure((double)reply1);
                    if(!C.ANA_NEED_TO_ESTIMATE_JNI_DELAY) {
                        this.caller.updateDebugStatus(String.format("JNI reply = %.3f, smoothed reply = %.3f", new Object[]{Float.valueOf(reply1), Double.valueOf(smoothedReply)}));
                    }

                    this.caller.pressureUpdate(smoothedReply);
                }

                if(this.needToRecordSqueeze) {
                    this.caller.squeezeUpdate((double)reply1);
                }
            }
        }

    }

    public void onTiltChanged(double tiltX, double tiltY, double tiltZ) {
    }

    public void onRecordedEnd() {
    }
}
