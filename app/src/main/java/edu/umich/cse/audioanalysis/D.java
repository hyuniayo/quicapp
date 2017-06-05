//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by Fernflower decompiler)
//

package edu.umich.cse.audioanalysis;

import android.content.Context;
import android.media.AudioManager;
import android.util.Log;
import edu.umich.cse.audioanalysis.C;

public class D {
    static final int CODE_ANDROID = 1;
    public static final int DETECT_PSE = 1;
    public static final int DETECT_SSE = 2;
    public static final int DETECT_LOC = 3;
    public static final int DETECT_DEFAULT = 1;
    static Context context;
    public static int detectMode = 1;
    public static int code = 1;
    public static String name = null;
    public static String modelName = null;
    public static int FS = -1;
    public static int PSE_DETECT_CH_IDX = -1;
    public static int SSE_DETECT_CH_IDX = -1;
    public static double PLAYER_VOL;
    public static double SYSTEM_VOL;
    public static int RECORD_SOURCE;
    public static double appPressureButtonThres;
    public static double appPressureEngineSoundScaleMax;
    public static int BIG_MOTION_DETECT_IN_RANGE_SAMPLE_SIZE;
    public static double BIG_MOTION_DETECT_IN_ACC_METRIC_THRE;
    public static double BIG_MOTION_DETECT_IN_ACC_MAX_THRE;
    public static double BIG_MOTION_DETECT_IN_GYRO_METRIC_THRE;
    public static double BIG_MOTION_DETECT_IN_GYRO_MAX_THRE;
    public static int BIG_MOTION_DETECT_MAX_RESET_DELAY;

    public D() {
    }

    static void initBasedOnModelName(String modelNameIn) {
        modelName = modelNameIn;
        if(!modelName.equals("SAMSUNG-SM-G925A") && modelName.indexOf("SAMSUNG-SM-G925") < 0) {
            if(!modelName.equals("SAMSUNG-SM-G935A") && modelName.indexOf("SAMSUNG-SM-G935") < 0) {
                if(!modelName.equals("SAMSUNG-SM-G930V") && modelName.indexOf("SAMSUNG-SM-G930") < 0) {
                    if(modelName.equals("SAMSUNG-SM-N920A")) {
                        initSamsungAfterS6();
                    } else if(modelName.equals("HUAWEI-NEXUS6P")) {
                        initNexus6p();
                    } else {
                        initDefault();
                    }
                } else {
                    initSamsungS7();
                }
            } else {
                initSamsungAfterS6();
            }
        } else {
            initSamsungAfterS6();
        }

    }

    static void initDefault() {
        code = getCode(1);
        name = "Default";
        PSE_DETECT_CH_IDX = 2;
        SSE_DETECT_CH_IDX = 1;
    }

    static void initSamsungAfterS6() {
        initDefault();
        code = getCode(2);
        name = "SamsungAfterS6";
        PSE_DETECT_CH_IDX = 1;
        SSE_DETECT_CH_IDX = 2;
        RECORD_SOURCE = 5;
        appPressureButtonThres = 0.4D;
    }

    static void initSamsungS7() {
        initDefault();
        code = getCode(3);
        name = "SamsungS7";
        PSE_DETECT_CH_IDX = 1;
        SSE_DETECT_CH_IDX = 2;
        RECORD_SOURCE = 5;
        appPressureButtonThres = 0.4D;
        appPressureEngineSoundScaleMax = 0.3D;
    }

    static void initS7Edge() {
        initSamsungAfterS6();
        name = "S7";
        appPressureButtonThres = 0.4D;
    }

    static void initNexus6p() {
        initDefault();
        code = getCode(4);
        name = "Nexus6p";
        appPressureButtonThres = 0.6D;
        appPressureEngineSoundScaleMax = 0.3D;
    }

    static int getCode(int codeIn) {
        return C.FORCE_TO_USE_TOP_SPEAKER?codeIn + 100:codeIn;
    }

    public static void configBasedOnSetting(int mode, Context context) {
        Log.d("AudioAnalysis", "HERE I AM!!!!!!!!!!!!!!!!!!");

        detectMode = mode;
        AudioManager audioManager = (AudioManager)context.getSystemService("audio");
        int maxVolValue = audioManager.getStreamMaxVolume(3);
        int targetValue = (int)Math.round((double)maxVolValue * SYSTEM_VOL);
        int currentVolValue = audioManager.getStreamVolume(3);
        if(currentVolValue != targetValue) {
            audioManager.setStreamVolume(3, targetValue, 0);
            int checkVolValue = audioManager.getStreamVolume(3);
            Log.d("AudioAnalysis", "Set the new volume as vol = " + targetValue + ", set reuslt = " + checkVolValue);
        }

    }

    static {
        PLAYER_VOL = (double)C.DEFAULT_VOL;
        SYSTEM_VOL = 0.5D;
        RECORD_SOURCE = 1;
        appPressureButtonThres = 0.9D;
        appPressureEngineSoundScaleMax = 0.4D;
        BIG_MOTION_DETECT_IN_RANGE_SAMPLE_SIZE = '뮀';
        BIG_MOTION_DETECT_IN_ACC_METRIC_THRE = 0.5D;
        BIG_MOTION_DETECT_IN_ACC_MAX_THRE = 1.0D;
        BIG_MOTION_DETECT_IN_GYRO_METRIC_THRE = 1.0D;
        BIG_MOTION_DETECT_IN_GYRO_MAX_THRE = 2.5D;
        BIG_MOTION_DETECT_MAX_RESET_DELAY = 1500;
    }
}
