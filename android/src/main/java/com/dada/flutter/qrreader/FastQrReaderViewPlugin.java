package com.dada.flutter.qrreader;

import android.hardware.camera2.CameraAccessException;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.util.Size;

import com.dada.flutter.qrreader.camera.CameraPermissions;
import com.dada.flutter.qrreader.camera.CameraSource;
import com.dada.flutter.qrreader.camera.CameraUtils;
import com.dada.flutter.qrreader.processor.QrProcessor;

import java.util.HashMap;
import java.util.Map;

import androidx.annotation.NonNull;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FastQrReaderViewPlugin
 */
public class FastQrReaderViewPlugin implements MethodCallHandler {
    private static final String TAG = "FastQrReaderViewPlugin";
    private final CameraPermissions cameraPermissions;
    private final Registrar registrar;
    private final EventChannel scanChannel;
    private CameraSource cameraSource;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "fast_qr_reader_view");
        channel.setMethodCallHandler(new FastQrReaderViewPlugin(registrar));
    }

    private FastQrReaderViewPlugin(Registrar registrar) {
        this.registrar = registrar;
        this.cameraPermissions = new CameraPermissions();
        this.scanChannel = new EventChannel(registrar.messenger(), "fast_qr_reader_view/scan");
    }

    @Override
    public void onMethodCall(MethodCall call, final MethodChannel.Result result) {
        switch (call.method) {
            case "availableCameras":
                try {
                    result.success(CameraUtils.getAvailableCameras(registrar.activity()));
                } catch (Exception e) {
                    handleException(e, result);
                }
                break;
            case "initialize":
                if (cameraSource != null) {
                    cameraSource.stopPreview();
                }

                cameraPermissions.requestPermissions(registrar, new CameraPermissions.ResultCallback() {
                    @Override
                    public void onError(String errorCode, String errorDescription) {
                        result.error(errorCode, errorDescription, null);
                    }

                    @Override
                    public void onSuccess() {
                        instantiateCamera(call, result);
                    }
                });
                break;
            case "startScan":
                startScan(result);
                break;
            case "stopScan":
                stopScan(result);
                break;
            case "dispose":
                dispose(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void instantiateCamera(MethodCall call, Result result) {
        Size size;
        try {
            int w = call.argument("previewWidth");
            int h = call.argument("previewHeight");
            size = new Size(w, h);
        } catch (NullPointerException | ClassCastException e) {
            Log.e(TAG, "instantiateCamera no previewWidth or previewHeight");
            size = new Size(1280, 720);
        }
        try {
            cameraSource = new CameraSource(registrar.activity(), size);
            cameraSource.startPreview(registrar.view());
            Map<String, Object> reply = new HashMap<>();
            reply.put("textureId", cameraSource.getTextureId());
            reply.put("previewWidth", cameraSource.getPreviewSize().getWidth());
            reply.put("previewHeight", cameraSource.getPreviewSize().getHeight());
            result.success(reply);
        } catch (Exception e) {
            handleException(e, result);
        }
    }

    private void startScan(@NonNull Result result) {
        scanChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                if (null == cameraSource)
                    return;

                cameraSource.startScan(new QrProcessor(barcode -> {
                    if (cameraSource != null)
                        cameraSource.stopScan();

                    if (registrar.activity() != null) {
                        registrar.activity().runOnUiThread(() -> eventSink.success(barcode));
                    }
                }));
            }

            @Override
            public void onCancel(Object o) {
            }
        });
        result.success(null);
    }

    private void stopScan(@NonNull Result result) {
        if (cameraSource != null) {
            cameraSource.stopScan();
        }
        result.success(null);
    }

    private void dispose(Result result) {
        if (cameraSource != null) {
            cameraSource.release();
            cameraSource = null;
        }
        result.success(null);
    }

    private void handleException(Exception exception, Result result) {
        if (exception instanceof CameraAccessException) {
            result.error("CameraAccess", exception.getMessage(), null);
        } else {
            result.error("RuntimeException", exception.getMessage(), null);
        }
    }

    // MethodChannel.Result wrapper that responds on the platform thread.
    private static class MethodResultWrapper implements MethodChannel.Result {
        private MethodChannel.Result methodResult;
        private Handler handler;

        MethodResultWrapper(MethodChannel.Result result) {
            methodResult = result;
            handler = new Handler(Looper.getMainLooper());
        }

        @Override
        public void success(final Object result) {
            handler.post(
                    () -> methodResult.success(result));
        }

        @Override
        public void error(
                final String errorCode, final String errorMessage, final Object errorDetails) {
            handler.post(
                    () -> methodResult.error(errorCode, errorMessage, errorDetails));
        }

        @Override
        public void notImplemented() {
            handler.post(
                    () -> methodResult.notImplemented());
        }
    }
}


