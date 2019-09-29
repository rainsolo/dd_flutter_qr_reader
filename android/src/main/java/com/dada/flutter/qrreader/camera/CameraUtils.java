package com.dada.flutter.qrreader.camera;

import android.app.Activity;
import android.content.Context;
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

        return cameras;
    }

}
