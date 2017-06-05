package com.samsung.swcdsi.quic;

import android.content.Intent;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;

import edu.umich.cse.audioanalysis.Ultraphone.ExpActivity.UltraphoneExpMainActivity;


public class GoOldDemoActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(com.samsung.swcdsi.quic.R.layout.activity_go_old_demo);
    }

    @Override
    protected void onResume() {
        super.onResume();

        /* old demo activity class includes:
           ExpPressureEngineSoundActivity
           ExpPressureButtonActivity
           ExpPressureMonitorActivity
           ExpPressureMovingBallActivity
        */
        Intent intent = new Intent(getApplicationContext(), UltraphoneExpMainActivity.class);
        startActivity(intent);

    }
}
