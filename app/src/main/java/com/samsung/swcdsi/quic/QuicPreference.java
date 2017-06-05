package com.samsung.swcdsi.quic;

/**
 * Created by ywsung on 17. 6. 5.
 */

public class QuicPreference {
    final static String SQUEEZE = "android.intent.action.ACTION_SQUEEZE_DETECTED";

    static boolean vibFeedbackOn = true;
    static boolean soundFeedbackOn = false;
    static int interval = 10000;
    static double sqzConst = .82;

}
