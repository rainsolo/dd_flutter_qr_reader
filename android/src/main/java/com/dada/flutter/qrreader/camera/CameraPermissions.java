package com.dada.flutter.qrreader.camera;

import android.Manifest.permission;
import android.app.Activity;
import android.content.pm.PackageManager;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.plugin.common.PluginRegistry;

public class CameraPermissions implements PluginRegistry.RequestPermissionsResultListener {
    private static final int CAMERA_REQUEST_ID = 9976;
    private boolean ongoing = false;
    private ResultCallback callback;

    public void requestPermissions(@NonNull PluginRegistry.Registrar registrar, @NonNull ResultCallback callback) {
        this.callback = callback;

        if (ongoing) {
            callback.onError("permission_ongoing", "Camera permission request ongoing");
        }

        Activity activity = registrar.activity();
        if (hasCameraPermission(activity)) {
            callback.onSuccess();
        } else {
            ongoing = true;
            registrar.addRequestPermissionsResultListener(this);
            ActivityCompat.requestPermissions(
                    activity,
                    new String[]{permission.CAMERA},
                    CAMERA_REQUEST_ID);
        }
    }

    private boolean hasCameraPermission(Activity activity) {
        return ContextCompat.checkSelfPermission(activity, permission.CAMERA) == PackageManager.PERMISSION_GRANTED;
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] strings, int[] grantResults) {
        if (requestCode != CAMERA_REQUEST_ID)
            return false;

        ongoing = false;
        if (grantResults[0] != PackageManager.PERMISSION_GRANTED) {
            callback.onError("permission", "MediaRecorderCamera permission not granted");
        } else {
            callback.onSuccess();
        }

        return true;
    }

    public interface ResultCallback {
        void onError(String errorCode, String errorDescription);

        void onSuccess();
    }
}
