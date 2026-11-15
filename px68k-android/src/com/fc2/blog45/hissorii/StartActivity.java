package com.fc2.blog45.hissorii;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.Settings;

import java.io.File;

/**
 * Launcher. PX68K keeps its files in (internal storage)/px68k, which needs a
 * storage permission on modern Android. Ask for it once, then start the emulator.
 * If the user refuses, the native side falls back to the app specific folder.
 */
public class StartActivity extends Activity {
    private static final String PREFS = "px68k";
    private static final String KEY_SKIP = "skip_storage_permission";
    private static final int REQ_LEGACY = 1;

    private boolean mWaitingForSettings = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        if (hasStorageAccess() || prefs.getBoolean(KEY_SKIP, false)) {
            launch();
            return;
        }
        askUser();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mWaitingForSettings) {
            // back from the settings screen, whatever the user chose there
            mWaitingForSettings = false;
            launch();
        }
    }

    private boolean hasStorageAccess() {
        if (Build.VERSION.SDK_INT >= 30) {
            return Environment.isExternalStorageManager();
        }
        return checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                == PackageManager.PERMISSION_GRANTED;
    }

    private void askUser() {
        File appDir = getExternalFilesDir(null);
        String appDirStr = (appDir != null) ? appDir.getAbsolutePath() : "";

        new AlertDialog.Builder(this)
            .setTitle(R.string.perm_title)
            .setMessage(getString(R.string.perm_message, appDirStr))
            .setCancelable(false)
            .setPositiveButton(R.string.perm_allow, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    requestAccess();
                }
            })
            .setNegativeButton(R.string.perm_deny, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    getSharedPreferences(PREFS, MODE_PRIVATE).edit()
                        .putBoolean(KEY_SKIP, true).apply();
                    launch();
                }
            })
            .show();
    }

    private void requestAccess() {
        if (Build.VERSION.SDK_INT >= 30) {
            mWaitingForSettings = true;
            try {
                startActivity(new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                                         Uri.parse("package:" + getPackageName())));
            } catch (Exception e) {
                try {
                    startActivity(new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION));
                } catch (Exception e2) {
                    mWaitingForSettings = false;
                    launch();
                }
            }
        } else {
            requestPermissions(new String[] { Manifest.permission.WRITE_EXTERNAL_STORAGE }, REQ_LEGACY);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        launch();
    }

    private void launch() {
        startActivity(new Intent(this, PX68K.class));
        finish();
    }
}
