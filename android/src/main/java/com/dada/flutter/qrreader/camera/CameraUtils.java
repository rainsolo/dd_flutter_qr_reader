package com.dada.flutter.qrreader.camera;

import android.app.Activity;
import android.content.Context;
import android.hardware.Camera;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CameraUtils {

    public static List<Map<String, Object>> getAvailableCameras(Activity activity) throws CameraAccessException {
        List<Map<String, Object>> cameras = new ArrayList<>();

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
            CameraManager cameraManager = (CameraManager) activity.getSystemService(Context.CAMERA_SERVICE);
            String[] cameraNames = cameraManager.getCameraIdList();

            for (String cameraName : cameraNames) {
                HashMap<String, Object> details = new HashMap<>();

                CameraCharacteristics characteristics = cameraManager.getCameraCharacteristics(cameraName);
                details.put("name", cameraName);

                int sensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
                details.put("sensorOrientation", sensorOrientation);

                int lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING);
                switch (lensFacing) {
                    case CameraMetadata.LENS_FACING_FRONT:
                        details.put("lensFacing", "front");
                        break;
                    case CameraMetadata.LENS_FACING_BACK:
                        details.put("lensFacing", "back");
                        break;
                    case CameraMetadata.LENS_FACING_EXTERNAL:
                        details.put("lensFacing", "external");
                        break;
                }
                cameras.add(details);
            }

        } else {
            int size = Camera.getNumberOfCameras();
            Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
            for (int i = 0; i < size; ++i) {
                HashMap<String, Object> details = new HashMap<>();
                Camera.getCameraInfo(i, cameraInfo);
                details.put("sensorOrientation", cameraInfo.orientation);
                switch (cameraInfo.facing) {
                    case Camera.CameraInfo.CAMERA_FACING_BACK:
                        details.put("name", "back");
                        details.put("lensFacing", "back");
                        break;
                    case Camera.CameraInfo.CAMERA_FACING_FRONT:
                        details.put("name", "font");
                        details.put("lensFacing", "front");
                        break;
                }
                cameras.add(details);
            }
        }

        return cameras;
    }


}
