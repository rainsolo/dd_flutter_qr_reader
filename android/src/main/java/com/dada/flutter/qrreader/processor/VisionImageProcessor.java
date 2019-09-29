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

import com.dada.flutter.qrreader.camera.FrameMetadata;

import java.nio.ByteBuffer;


/**
 * An interface to process the images with different detectors and custom image models.
 * ex. ZXing or ML Kit
 */
public interface VisionImageProcessor {

    /**
     * Processes the images with the underlying decode models.
     */
    void process(ByteBuffer data, FrameMetadata frameMetadata);

    /**
     * Stops the underlying decode model and release resources.
     */
    void stop();
}
