//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by Fernflower decompiler)
//

package edu.umich.cse.audioanalysis;

public class C {
    public static final String LOG_TAG = "AudioAnalysis";
    public static float DEFAULT_VOL = 1.0F;
    public static final String SETTING_JSON_FILE_NAME = "AudioAnaSetting.json";
    public static boolean USE_REAL_TIME_SURVEY = false;
    public static boolean USE_AUDIO_QUEUE_IN_REAL_TIME_SRUVEY = false;
    public static boolean TRACE_SAVE_TO_FILE = false;
    public static boolean TRACE_REALTIME_PROCESSING = true;
    public static boolean TRACE_SEND_TO_NETWORK = false;
    public static boolean TRIGGERED_BY_NETWORK = false;
    public static boolean TRIGGERED_BY_LOCAL = true;
    public static boolean DISABLE_SQUEEZE_APPS = true;
    public static boolean SHOW_CALIBRATION_LAYOUT = false;
    public static boolean FORCE_TO_USE_TOP_SPEAKER = false;
    public static boolean ANA_NEED_TO_ESTIMATE_JNI_DELAY = false;
    public static final int UI_PRESSURE_SMOOTH_DATA_CNT = 5;
    public static String SERVER_ADDR = "35.2.209.110";
    public static int DETECTER_SERVER_PORT = '썙';
    public static int TRIGGER_SERVER_PORT = '썚';
    public static final String INPUT_FOLDER = "AudioInput/";
    public static final String INPUT_PREFIX = "source_";
    public static final String OUTPUT_FOLDER = "DataOutput/";
    public static final String DEBUG_FOLDER = "DebugOutput/";
    public static final String JNI_LOG_FOLER = "log/";
    public static boolean TERMINATE_AFTER_EACH_LOCATION_SENSING = false;
    public static boolean SURVEY_SEND_DATA_TO_SOCKET = false;
    public static boolean SURVEY_DUMP_RAW_BYTE_DATA_TO_FILE = true;
    public static final int SURVEY_MODE_TRAIN = 1;
    public static final int SURVEY_MODE_PREDICT = 2;
    public static String systemPath;
    public static String appFolderName;
    public static String appFolderPath;

    public C() {
    }

    public static String isValidSetting() {
        return USE_REAL_TIME_SURVEY && TRACE_SEND_TO_NETWORK?"Should not enable networking function when USE_REAL_TIME_SURVEY is on":(TRACE_REALTIME_PROCESSING && TRACE_SEND_TO_NETWORK?"Should not enable both TRACE_REALTIME_PROCESSING and TRACE_SEND_TO_NETWORK":null);
    }
}
