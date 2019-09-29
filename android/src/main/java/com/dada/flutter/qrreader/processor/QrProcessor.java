// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package com.dada.flutter.qrreader.processor;

import android.util.Log;

import com.dada.flutter.qrreader.camera.FrameMetadata;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.PlanarYUVLuminanceSource;
import com.google.zxing.Result;
import com.google.zxing.common.HybridBinarizer;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumMap;
import java.util.Map;


/**
 * Qr Code Processor.
 */
public class QrProcessor implements VisionImageProcessor {

    private static final String TAG = "QrProcessor";

    private final MultiFormatReader reader;

    private final OnCodeScanned callback;

    private boolean hasStopped;

    public QrProcessor(OnCodeScanned callback) {
        this.callback = callback;
        reader = new MultiFormatReader();
        Map<DecodeHintType, Object> hints = new EnumMap<>(DecodeHintType.class);
        Collection<BarcodeFormat> barcodeFormats = new ArrayList<>();
        barcodeFormats.add(BarcodeFormat.QR_CODE);
        hints.put(DecodeHintType.POSSIBLE_FORMATS, barcodeFormats);
        reader.setHints(hints);
    }

    @Override
    public void stop() {
        hasStopped = true;
        Log.i(TAG, "Qr Processor Stopped");
    }

    //    private PlanarYUVLuminanceSource buildPlanarYUVLuminanceSource(byte[] data, int width, int height, boolean isRotate) {
    //        PlanarYUVLuminanceSource source;
    //        if (isRotate) {
    //            byte[] rotatedData = new byte[data.length];
    //            for (int y = 0; y < height; y++) {
    //                for (int x = 0; x < width; x++)
    //                    rotatedData[x * height + height - y - 1] = data[x + y * width];
    //            }
    //            final int rotatedWidth = height;
    //            final int rotatedHeight = width;
    //            source = buildLuminanceSource(rotatedData, rotatedWidth, rotatedHeight);
    //        } else {
    //            source = buildLuminanceSource(data, width, height);
    //        }
    //        return source;
    //    }

    private PlanarYUVLuminanceSource buildLuminanceSource(byte[] data, int width, int height) {
        return new PlanarYUVLuminanceSource(data, width, height, 0, 0, width, height, false);
    }

    @Override
    public void process(ByteBuffer data, FrameMetadata frameMetadata) {
                Log.d("zf", "w = " + frameMetadata.getWidth() + " h = " + frameMetadata.getHeight()
                        + " r = " + frameMetadata.getRotation());

        if (hasStopped)
            return;

        PlanarYUVLuminanceSource source = buildLuminanceSource(
                data.array(),
                frameMetadata.getWidth(),
                frameMetadata.getHeight());

        BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));
        Result result = null;
        try {
            result = reader.decodeWithState(bitmap);
        } catch (Exception e) {
//            e.printStackTrace();
        }
        if (null != result) {
            Log.i(TAG, result.getText());
            callback.onCodeScanned(result.getText());
        }

    }
}

