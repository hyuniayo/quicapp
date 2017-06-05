package com.samsung.swcdsi.quic;

import android.app.ActivityManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.telephony.PhoneStateListener;
import android.telephony.TelephonyManager;
import android.util.Log;
import java.util.List;

public class QuicBroadcastReceiver extends BroadcastReceiver {
    private Context mContext;
    private TelephonyManager telephonyManager;
//    private static String SQUEEZE = "android.intent.action.ACTION_SQUEEZE_DETECTED";
    private String mPackageName = "com.samsung.swcdsi.quic";
    private String mActivityName = "com.samsung.swcdsi.quic.MainActivity";
    public String CALL_STATE = "IDLE";
    private ActivityManager activityManager;

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        mContext = context;

        telephonyManager = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
        telephonyManager.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE);
        activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);

        if (action.equals(QuicPreference.SQUEEZE)) {
            Log.d("BroadcastReceiver", "onReceive: SQUEEZE intent");
            try {
                readSharedPreference();
            } catch (Exception e1) {
                e1.printStackTrace();
            }
            List<ActivityManager.RunningTaskInfo> taskInfos = activityManager.getRunningTasks(1);
            Log.d("BroadcastReceiver", "Current activity:" + taskInfos.get(0).topActivity.getClassName());
            List<ActivityManager.RunningServiceInfo> serviceInfos = activityManager.getRunningServices(1);
            Log.d("BroadcastReceiver", "Current service:" + serviceInfos.get(0).service);


            if (CALL_STATE != null) {
                Log.d("BroadcastReceiver", "CALL STATE:" + CALL_STATE);
                Intent send_intent = new Intent(Intent.ACTION_MAIN);
                send_intent.setPackage(mPackageName);
                send_intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
                mContext.startActivity(send_intent);
            }
        }
    }

    PhoneStateListener phoneStateListener = new PhoneStateListener() {
        @Override
        public void onCallStateChanged(int state, String incomingNumber) {
            Log.d("onCallStateChanged", "state :" + state + ", incomingNumber :" + incomingNumber);
            switch (state) {
                case TelephonyManager.CALL_STATE_IDLE:
                    Log.d("onCallStateChanged", "CALL_STATE_IDLE");
                    CALL_STATE = "IDLE";
                    Log.d("onCallStateChanged", "CALL_STATE_IDLE - " + CALL_STATE);
                    break;
                case TelephonyManager.CALL_STATE_RINGING:
                    Log.d("onCallStateChanged", "CALL_STATE_RINGING");
                    CALL_STATE = "RINGING";
                    Log.d("onCallStateChanged", "CALL_STATE_RINGING - " + CALL_STATE);
                    break;
                case TelephonyManager.CALL_STATE_OFFHOOK:
                    Log.d("onCallStateChanged", "CALL_STATE_OFFHOOK");
                    CALL_STATE = "OFFHOOK";
                    Log.d("onCallStateChanged", "CALL_STATE_OFFHOOK - " + CALL_STATE);
                    break;
            }
        }
    };

    public void readSharedPreference() throws Exception {
        SharedPreferences pref = null;
        try {
            pref = mContext.getSharedPreferences("QUIC_PREFERENCE", Context.MODE_PRIVATE);
        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        }
        mPackageName = pref.getString("QUIC_PKG_KEY", "NOT SET");
        Log.d("readSharedPreference", "mPackageName = " + mPackageName);
        mActivityName = pref.getString("QUIC_ACT_KEY", "NOT SET");
        Log.d("readSharedPreference", "mActivityName = " + mActivityName);
    }
}
