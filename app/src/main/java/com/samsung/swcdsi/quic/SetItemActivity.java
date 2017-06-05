package com.samsung.swcdsi.quic;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.GridView;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.List;

public class SetItemActivity extends AppCompatActivity {
    PackageManager mPackageManager;
    String mtag = "SetItem";
    String mPackageName;
    String mActivityName;
    public Context mContext;

    public class mBaseAdapter extends BaseAdapter {
        private Context myContext;
        private List<ResolveInfo> MyAppList;

        mBaseAdapter(Context c, List<ResolveInfo> l) {
            myContext = c;
            MyAppList = l;
        }

        @Override
        public int getCount(){
            return MyAppList.size();
        }

        @Override
        public Object getItem(int position) {
            return MyAppList.get(position);
        }

        @Override
        public long getItemId(int position) {
            return position;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            ImageView imageView;
            if (convertView == null) {
                imageView = new ImageView(myContext);
                imageView.setLayoutParams(new GridView.LayoutParams(85, 85));
                imageView.setPadding(8, 8, 8, 8);
            } else {
                imageView = (ImageView) convertView;
            }

            ResolveInfo resolveInfo = MyAppList.get(position);
            imageView.setImageDrawable(resolveInfo.loadIcon(mPackageManager));

            return imageView;
        }
    }

    public void writeSharedPreference(View view, ActivityInfo clickedActivityInfo) {
        SharedPreferences sharedPreferences = getSharedPreferences("QUIC_PREFERENCE", Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        mPackageName = clickedActivityInfo.applicationInfo.packageName;
        Log.d(mtag, "writeSharedPreference : mPackageName = " + mPackageName);
        mActivityName = clickedActivityInfo.name;
        Log.d(mtag, "writeSharedPreference : mActivityName = " + mActivityName);
        editor.putString("QUIC_PKG_KEY", mPackageName);
        editor.putString("QUIC_ACT_KEY", mActivityName);
        editor.commit();
    }

    public void readSharedPreference() throws Exception {
        SharedPreferences pref = null;
        try {
            pref = getSharedPreferences("QUIC_PREFERENCE", Context.MODE_PRIVATE);
        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        }
        mPackageName = pref.getString("QUIC_PKG_KEY", "NOT SET");
        Log.d(mtag, "readSharedPreference : mPackageName = " + mPackageName);
        mActivityName = pref.getString("QUIC_ACT_KEY", "NOT SET");
        Log.d(mtag, "readSharedPreference : mActivityName = " + mActivityName);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_set_item);

        mPackageManager = getPackageManager();

        Intent mainIntent = new Intent(Intent.ACTION_MAIN, null);
        mainIntent.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> pkgAppsList = getPackageManager().queryIntentActivities(mainIntent, 0);

        try {
            readSharedPreference();
        } catch (Exception e) {
            e.printStackTrace();
        }

        TextView textView1 = (TextView) findViewById(R.id.set_pkg);
        textView1.setText(mPackageName);
        TextView textView2 = (TextView) findViewById(R.id.set_act);
        textView2.setText(mActivityName);

        GridView gridView = (GridView) findViewById(R.id.list_item);
        gridView.setAdapter(new mBaseAdapter(this, pkgAppsList));

        gridView.setOnItemClickListener(mOnItemClickListener);

        mContext = this;
    }

    AdapterView.OnItemClickListener mOnItemClickListener = new AdapterView.OnItemClickListener() {
        @Override
        public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
            ResolveInfo clickedResolveInfo = (ResolveInfo) parent.getItemAtPosition(position);
            ActivityInfo clickedActivityInfo = clickedResolveInfo.activityInfo;
            Toast.makeText(SetItemActivity.this, "choose "+clickedActivityInfo.applicationInfo.packageName, Toast.LENGTH_SHORT).show();
            writeSharedPreference(view, clickedActivityInfo);
            finish();
        }
    };
}