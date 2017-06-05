package com.samsung.swcdsi.quic;

import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.media.MediaPlayer;
import android.os.IBinder;
import android.os.Vibrator;
import android.util.Log;

import edu.umich.cse.audioanalysis.C;
import edu.umich.cse.audioanalysis.D;
import edu.umich.cse.audioanalysis.Ultraphone.ExpActivity.UltraphoneController2;
import edu.umich.cse.audioanalysis.Ultraphone.UltraphoneControllerListener;

/**
 * Created by ywsung on 17. 5. 30.
 */

public class QuicService extends Service implements UltraphoneControllerListener, SensorEventListener {

    UltraphoneController2 uc;
    String LOG_TAG = "ForcePhoneService";
    Boolean ultraphoneHasStarted;
    Boolean pressureSensingIsReady;
    Boolean userHasPressed;

    boolean useRemoteMatlabModeInsteadOfStandaloneMode;
    boolean checkPressureInsteadOfSqueeze;

    private SensorManager mSensorManager;
    private Sensor mGyroscope;
    private Sensor accSensor;
    private Vibrator vibrator;

    int acXValue;
    int acYValue;
    int acZValue;

    int gyroX;
    int gyroY;
    int gyroZ;

    boolean once;
    double avrg;
    double[] refArray;
    int refIdx, sqCnt;
    static final int MAX_REF_IDX = 32;

//    boolean vibFeedbackOn;
//    boolean soundFeedbackOn;
//    int interval;

    static boolean isOn = false;
    long sqzOnTime;

    MediaPlayer mediaPlayer;


    //Create broadcast object
    BroadcastReceiver mScreenStateReceiver = new BroadcastReceiver() {
        //When Event is published, onReceive method is called
        @Override
        public void onReceive(Context context, Intent intent) {
            // TODO Auto-generated method stub
            Log.d(LOG_TAG, "MyReceiver");

            if (intent.getAction().equals(Intent.ACTION_SCREEN_ON)) {
                Log.d(LOG_TAG, "Screen ON");
                detectionTurnOn();
            }
            else if (intent.getAction().equals(Intent.ACTION_SCREEN_OFF)) {
                Log.d(LOG_TAG, "Screen OFF");
                detectionTurnOff();
            }

        }
    };



    @Override
    public IBinder onBind(Intent intent) {
        // Service 객체와 (화면단 Activity 사이에서)
        // 통신(데이터를 주고받을) 때 사용하는 메서드
        // 데이터를 전달할 필요가 없으면 return null;
        return null;
    }


    @Override
    public void onCreate() {
        super.onCreate();

        Log.d(LOG_TAG, "서비스의 onCreate");

        /* QuicPreference */
        useRemoteMatlabModeInsteadOfStandaloneMode = false; // switch to use different mode of parsing
        checkPressureInsteadOfSqueeze = false; // switch to use different mode of aar lib

        if (useRemoteMatlabModeInsteadOfStandaloneMode) {
            //control global variables to enable the remote mode
            C.SERVER_ADDR = "192.168.11.3";
            // NOTE: the following two flags must be mutual exclusive
            C.TRACE_REALTIME_PROCESSING = false;
            C.TRACE_SEND_TO_NETWORK = true;
        }

        if (checkPressureInsteadOfSqueeze) {
            uc = new UltraphoneController2(D.DETECT_PSE, this, getApplicationContext());
        } else {
            uc = new UltraphoneController2(D.DETECT_SSE, this, getApplicationContext());
            uc.startCheckSqueezeWhenPossible(); // e.g., when the server is connected
        }

        ultraphoneHasStarted = false;
        pressureSensingIsReady = false;
        userHasPressed = false;

        vibrator = (Vibrator) getSystemService(getApplicationContext().VIBRATOR_SERVICE); // (Context.VIBRATE_SERVICE)

        //센서 매니저 얻기
        mSensorManager = (SensorManager) getSystemService(getApplicationContext().SENSOR_SERVICE);
        //자이로스코프 센서(회전)
        mGyroscope = mSensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
        //엑셀러로미터 센서(가속)
        accSensor = mSensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);

        refArray = new double[MAX_REF_IDX];

        avrg = 0;
        sqCnt = 0;
        refIdx = 0;
        once = false;

        acXValue = 0;
        acYValue = 0;
        acZValue = 0;

        gyroX = 0;
        gyroY = 0;
        gyroZ = 0;

        mediaPlayer = MediaPlayer.create(getApplicationContext(), com.samsung.swcdsi.quic.R.raw.squeezetoy4);

        IntentFilter screenStateFilter = new IntentFilter();
        screenStateFilter.addAction(Intent.ACTION_SCREEN_ON);
        screenStateFilter.addAction(Intent.ACTION_SCREEN_OFF);
        registerReceiver(mScreenStateReceiver, screenStateFilter);

    }


    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if(isOn)
            return START_STICKY;

        isOn = true;

        // 서비스가 호출될 때마다 실행
        Log.d(LOG_TAG, "서비스의 onStartCommand");

        uc.startEverything();
        ultraphoneHasStarted = true;

        avrg = 0;
        sqCnt = 0;
        refIdx = 0;
        once = false;

        acXValue = 0;
        acYValue = 0;
        acZValue = 0;

        gyroX = 0;
        gyroY = 0;
        gyroZ = 0;
        sqzOnTime = System.currentTimeMillis();

        mSensorManager.registerListener(this, mGyroscope, SensorManager.SENSOR_DELAY_FASTEST);
        mSensorManager.registerListener(this, accSensor, SensorManager.SENSOR_DELAY_FASTEST);

        return super.onStartCommand(intent, flags, startId);
    }


    public void onAccuracyChanged(Sensor sensor, int accuracy) {

    }


    private void detectionTurnOn() {
        uc.startEverything();
    }

    private void detectionTurnOff() {
        uc.stopEverything();
    }


    @Override
    public void pressureUpdate(final double v) {
        Log.d(LOG_TAG, "pressure = "+v);
    }

    @Override
    public void squeezeUpdate(final double reference) {
        Log.d(LOG_TAG, "reference = "+reference + "    avgr" + avrg);

        if(once)
            avrg -= (refArray[refIdx] / MAX_REF_IDX);

        refArray[refIdx] = reference;
        avrg += (refArray[refIdx] / MAX_REF_IDX);

        refIdx++;

        if(refIdx == MAX_REF_IDX) {
            once = true;
            refIdx = 0;
        }

        if(once) {
            if(reference < avrg * QuicPreference.sqzConst /*|| avrg * 1.1 < reference*/) {
                if(sqCnt < 3) sqCnt++;
            } else {
                if(sqCnt > 0) {
                    sqCnt--;
                }
            }

            if(sqCnt == 3 && sqzOnTime <= System.currentTimeMillis()) {
                Log.d(LOG_TAG, "SQUEEZE DETECTED!!!");

                if(QuicPreference.vibFeedbackOn)
                    vibrator.vibrate(250);

                if(QuicPreference.soundFeedbackOn)
                    mediaPlayer.start();

                sqzOnTime = System.currentTimeMillis() + QuicPreference.interval;

                Intent squeezeIntent = new Intent(this, QuicBroadcastReceiver.class);
                squeezeIntent.setAction(QuicPreference.SQUEEZE);
                sendBroadcast(squeezeIntent);
            }
        }

    }

    public void onSensorChanged(SensorEvent event) {
        Sensor sensor = event.sensor;

        if (sensor.getType() == Sensor.TYPE_GYROSCOPE) {
            int gx, gy, gz;
            gx = Math.round(event.values[0] * 1000);
            gy = Math.round(event.values[1] * 1000);
            gz = Math.round(event.values[2] * 1000);

            if(gx != gyroX || gy != gyroY || gz != gyroZ) {
                gyroX = gx;
                gyroY = gy;
                gyroZ = gz;

                //Log.d(LOG_TAG, "gyro " + gyroX + " " + gyroY + " " + gyroZ);
            }
        }
        if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
            int ax, ay, az;
            ax = (int) event.values[0];
            ay = (int) event.values[1];
            az = (int) event.values[2];

            if(ax != acXValue || ay != acYValue || az != acZValue) {
                acXValue = ax;
                acYValue = ay;
                acZValue = az;

                //Log.d(LOG_TAG, "acXValue " + acXValue + " " + acYValue + " " + acZValue);
            }
        }

    }


    @Override
    public void onDestroy() {
        super.onDestroy();

        uc.stopEverything();
        ultraphoneHasStarted = false;
        pressureSensingIsReady = false;
        userHasPressed = false;

        isOn = false;

        mSensorManager.unregisterListener(this);

        unregisterReceiver(mScreenStateReceiver);

        Log.d(LOG_TAG, "서비스의 onDestroy");
    }

    @Override
    public void updateDebugStatus(final String s) {
        Log.d(LOG_TAG,"Debug: "+s);
    }

    @Override
    public void showToast(final String s) {
    }

    @Override
    public void unexpectedEnd(int i, final String s) {
        Log.e(LOG_TAG, "Error: "+s);
    }

}