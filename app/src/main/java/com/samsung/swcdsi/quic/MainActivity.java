package com.samsung.swcdsi.quic;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorManager;
import android.os.Vibrator;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.widget.TextView;
import android.widget.Toast;

import edu.umich.cse.audioanalysis.Ultraphone.ExpActivity.UltraphoneController2;

public class MainActivity extends AppCompatActivity /*implements UltraphoneControllerListener, SensorEventListener */{
    UltraphoneController2 uc;
    String LOG_TAG = "ForcePhoneDemo";
    Boolean ultraphoneHasStarted;
    Boolean pressureSensingIsReady;
    Boolean userHasPressed;
    TextView textResult;

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


    boolean vibFeedbackOn;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(com.samsung.swcdsi.quic.R.layout.activity_main);

        textResult = (TextView) findViewById(com.samsung.swcdsi.quic.R.id.textResult);

        requestPermissionsDenial();

/*
        */
/* QuicPreference *//*

        vibFeedbackOn = true;
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
            uc = new UltraphoneController(D.DETECT_PSE, this, getApplicationContext());
        } else {
            uc = new UltraphoneController(D.DETECT_SSE, this, getApplicationContext());
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

*/

        startService(new Intent(getApplicationContext(), QuicService.class)); // 서비스 시작
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();

        if (id == R.id.action_settings) {
            Intent intentSetItem = new Intent(this, SetItemActivity.class);
            startActivity(intentSetItem);
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    private void requestPermissionsDenial() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            if (ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.CALL_PHONE)) {
                Log.d("MainActivity", "requestPermissionDenail - CALL_PHONE");
                ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.CALL_PHONE, Manifest.permission.CALL_PRIVILEGED, Manifest.permission.READ_PHONE_STATE, Manifest.permission.PROCESS_OUTGOING_CALLS}, 0);
            }
        }
    }

    @Override
    protected void onResume (){
        super.onResume();
/*
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

        mSensorManager.registerListener(this, mGyroscope, SensorManager.SENSOR_DELAY_FASTEST);
        mSensorManager.registerListener(this, accSensor, SensorManager.SENSOR_DELAY_FASTEST);
*/
    }


    public void onAccuracyChanged(Sensor sensor, int accuracy) {

    }

    @Override
    protected void onPause (){
        super.onPause();
/*
        uc.stopEverything();
        ultraphoneHasStarted = false;
        pressureSensingIsReady = false;
        userHasPressed = false;

        mSensorManager.unregisterListener(this);
*/
    }

    // NOTE: dispatchTouchEvent can get event even the touch is intercepted by other elements
    @Override
    public boolean dispatchTouchEvent(MotionEvent event){
        super.dispatchTouchEvent(event);
/*
        int x = (int)event.getX();
        int y = (int)event.getY();
        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN: {
                Log.d(C.LOG_TAG, "dispatchTouchEvent: ACTION_DOWN: (x,y) = (" + x + "," + y + ")");

                if(uc!=null && checkPressureInsteadOfSqueeze && ultraphoneHasStarted) {
                    uc.startCheckPressure(new Point(x, y)); // this will trigger the UltraphoneController to start send data to the callback
                    userHasPressed = true;
                }
                break;
            }
            case MotionEvent.ACTION_UP: {
                Log.d(C.LOG_TAG, "dispatchTouchEvent: ACTION_UP: (x,y) = (" + x + "," + y + ")");
                if(uc!=null && checkPressureInsteadOfSqueeze && ultraphoneHasStarted && userHasPressed) {
                    uc.stopCheckPressure();
                }
                break;
            }
        }
*/
        return true;
    }


    /* Ultraphone callbacks */

//    @Override
    public void pressureUpdate(final double v) {
        Log.d(LOG_TAG, "pressure = "+v);
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                textResult.setText(String.format("pressure = %.2f", v));
            }
        });
    }

//    @Override
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
            if(reference < avrg * .82 /*|| avrg * 1.1 < reference*/) {
                if(sqCnt < 3) sqCnt++;
            } else {
                if(sqCnt > 0) {
                    sqCnt--;
                    if (sqCnt == 0) {
                        runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                textResult.setText(String.format("-"));
                            }
                        });
                    }
                }
            }

            if(sqCnt == 3) {
                Log.d(LOG_TAG, "SQUEEZE DETECTED!!!");

                if(vibFeedbackOn)
                    vibrator.vibrate(20);

                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        textResult.setText(String.format("SQUEEZE"));
                    }
                });
            }
        }

/*
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                textResult.setText(String.format("ref = %.2f", reference));
            }
        });
        */
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


//    @Override
    public void updateDebugStatus(final String s) {
        Log.d(LOG_TAG,"Debug: "+s);
    }

//    @Override
    public void showToast(final String s) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(MainActivity.this, s, Toast.LENGTH_LONG).show();
            }
        });
    }

//    @Override
    public void unexpectedEnd(int i, final String s) {
        Log.e(LOG_TAG,"Error: "+s);
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(MainActivity.this, s, Toast.LENGTH_LONG).show();
            }
        });
    }
}
