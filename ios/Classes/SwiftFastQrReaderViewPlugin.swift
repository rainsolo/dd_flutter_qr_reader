//
//  FastQrReaderViewPlugin.swift
//  fast_qr_reader_view
//
//  Created by 李亚洲 on 2019/9/25.
//

import Foundation

import Flutter
import AVFoundation

fileprivate extension NSError {
    var flutterError: FlutterError {
        return FlutterError(code: "Error \(code)", message: domain, details: localizedDescription)
    }
}

//fileprivate func makeError(code: String, desc: String) -> [String: String] {
//    return [
//        "event": "error",
//        "errorDescription": desc,
//    ]
//}

fileprivate var accessError: FlutterError {
    return FlutterError(code: "permission", message: "cannot access the camera", details: nil)
}

fileprivate var formatError: FlutterError {
    return FlutterError(code: "format", message: "数据类型错误", details: nil)
}

fileprivate var cameraError: FlutterError {
    return FlutterError(code: "camera", message: "无可用相机", details: nil)
}


class FMCam : NSObject, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate, FlutterStreamHandler, AVCaptureMetadataOutputObjectsDelegate {
    
    //    var textureId: Int64 = 0
    var onFrameAvailable: (() -> Void)?
//    var eventChannel: FlutterEventChannel?
    var eventSink: FlutterEventSink?
    let captureSession: AVCaptureSession
    let captureDevice: AVCaptureDevice
    let captureVideoOutput: AVCaptureVideoDataOutput
    let captureVideoInput: AVCaptureInput
    let captureMetadataOutput: AVCaptureMetadataOutput
    var latestPixelBuffer: Unmanaged<CVPixelBuffer>?
    var previewSize: CGSize
    //    var captureSize: CGSize
    
    //    var videoWriter: AVAssetWriter
    //    var videoWriterInput: AVAssetWriterInput
    //@property(strong, nonatomic) AVAssetWriterInput *audioWriterInput;
    //    var assetWriterPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
    var isScanning: Bool = false
    var codeFormats: [String] = []
    var torchIsOn: Bool = false
    
    init?(cameraName: String, resolutionPreset: String, codeFormats:[String]) {
        self.captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        
        guard let captureDevice = AVCaptureDevice(uniqueID: cameraName) else {
            return nil
        }
        self.captureDevice = captureDevice
        guard let captureVideoInput = try? AVCaptureDeviceInput(device: self.captureDevice) else {
            return nil
        }
        self.captureVideoInput = captureVideoInput
        
        let dimensions = CMVideoFormatDescriptionGetDimensions(self.captureDevice.activeFormat.formatDescription);
        self.previewSize = CGSize(width: Double(dimensions.width), height: Double(dimensions.height))
        
        self.captureVideoOutput = AVCaptureVideoDataOutput()
        self.captureVideoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        self.captureVideoOutput.alwaysDiscardsLateVideoFrames = true
        
        let connection = AVCaptureConnection(inputPorts: self.captureVideoInput.ports, output: self.captureVideoOutput)
        if (self.captureDevice.position == AVCaptureDevice.Position.front) {
            connection.isVideoMirrored = true
        }
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        self.captureSession.addInputWithNoConnections(self.captureVideoInput)
        self.captureSession.addOutputWithNoConnections(self.captureVideoOutput)
        self.captureSession.add(connection)
        
        //    _capturePhotoOutput = [AVCapturePhotoOutput new];
        //    [_captureSession addOutput:_capturePhotoOutput];
//        self.scanChannel = scanChannel
        self.codeFormats = codeFormats
        let dispatchQueue = DispatchQueue(label: "qrDetectorQueue")
        self.captureMetadataOutput = AVCaptureMetadataOutput()
        self.captureSession.addOutput(self.captureMetadataOutput)
        
        //    NSLog(@"QR Code: %@", [_captureMetadataOutput availableMetadataObjectTypes]);
        
        let availableFormats: [String: AVMetadataObject.ObjectType] = [
            "code39": AVMetadataObject.ObjectType.code39,
            "code93": AVMetadataObject.ObjectType.code93,
            "code128": AVMetadataObject.ObjectType.code128,
            "ean8": AVMetadataObject.ObjectType.ean8,
            "ean13": AVMetadataObject.ObjectType.ean13,
            "itf": AVMetadataObject.ObjectType.ean13,
            "upce": AVMetadataObject.ObjectType.upce,
            "aztec": AVMetadataObject.ObjectType.aztec,
            "datamatrix": AVMetadataObject.ObjectType.dataMatrix,
            "pdf417": AVMetadataObject.ObjectType.pdf417,
            "qr": AVMetadataObject.ObjectType.qr,
            ]
        
        let reqFormats = availableFormats.filter({ codeFormats.contains($0.key) }).map( {$0.value} )
        self.captureMetadataOutput.metadataObjectTypes = reqFormats
        
        super.init()
        self.captureVideoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        self.captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatchQueue)
    }
    
    public func start() {
        captureSession.startRunning()
        isScanning = true
    }
    
    public func stop() {
        captureSession.stopRunning()
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.isScanning = false
//        }
    }
    
    fileprivate func dispose() {
        stop()
        captureSession.inputs.forEach( { [weak self] in self?.captureSession.removeInput($0)} )
        captureSession.outputs.forEach( { [weak self] in self?.captureSession.removeOutput($0)} )
    }
    
    fileprivate func successScanningWithResult(result: String?) {
        guard let qr = result else {
            return
        }
        
        guard !qr.isEmpty else {
            return
        }
        
        guard isScanning else {
            return
        }
        
        stop()
        eventSink?(qr)
        //        channel.invokeMethod("updateCode", arguments: qr)
    }
    
    // MARK: camera delegate
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject else {
            return
        }
        
        if (metadataObj.type == AVMetadataObject.ObjectType.qr) {
            if (isScanning) {
                DispatchQueue.main.async {
                    self.successScanningWithResult(result: metadataObj.stringValue)
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard output == captureVideoOutput else {
            return
        }
        guard let newBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        //        swap(newBuffer: newBuffer)
        
        latestPixelBuffer = Unmanaged.passRetained(newBuffer)
        
        onFrameAvailable?()
        if !CMSampleBufferDataIsReady(sampleBuffer) {
            eventSink?([
                "event": "error",
                "errorDescription" : "sample buffer is not ready. Skipping sample",
                ]
            )
        }
    }
    
    // MARK: texture delegate
    
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        return latestPixelBuffer
        
        //        let pointer : UnsafeMutablePointer<UnsafeMutableRawPointer?> = UnsafeMutablePointer.allocate(capacity: 1)
        //        pointer.pointee = latestPixelBuffer?.toOpaque()
        //        var pixelBuffer: UnsafeMutableRawPointer? = pointer.pointee
        //        while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, pointer)) {
        //            latestPixelBuffer = pointer.pointee != nil ? Unmanaged.fromOpaque(pointer.pointee!) : nil
        //            pixelBuffer = latestPixelBuffer?.toOpaque()
        //        }
        //
        //        return pixelBuffer == nil ? nil : Unmanaged.fromOpaque(pixelBuffer!)
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil;
    }
    
    
    //    private func swap(newBuffer: CVImageBuffer) {
    //        let pointer : UnsafeMutablePointer<UnsafeMutableRawPointer?> = UnsafeMutablePointer.allocate(capacity: 1)
    //        pointer.pointee = latestPixelBuffer?.toOpaque()
    //        var oldValuePointer: UnsafeMutableRawPointer? = pointer.pointee;
    //        let newValuePointer = Unmanaged.passUnretained(newBuffer).toOpaque()
    //
    //        func loopBuffer() {
    //            if OSAtomicCompareAndSwapPtrBarrier(oldValuePointer, newValuePointer, pointer) {
    //                if let pointee = pointer.pointee {
    //                    self.latestPixelBuffer = Unmanaged.fromOpaque(pointee)
    //                } else {
    //                    self.latestPixelBuffer = nil
    //                }
    //                return
    //            } else {
    //                oldValuePointer = latestPixelBuffer?.toOpaque();
    //                loopBuffer()
    //            }
    //        }
    //
    //        loopBuffer()
    //    }
}

public class SwiftFastQrReaderViewPlugin: NSObject, FlutterPlugin {
    
    let registry: FlutterTextureRegistry
    let messenger: FlutterBinaryMessenger
    let scanChannel: FlutterEventChannel
    var camera: FMCam?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fast_qr_reader_view", binaryMessenger: registrar.messenger())
        let instance = SwiftFastQrReaderViewPlugin(registry: registrar.textures(), messager: registrar.messenger());
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private init(registry: FlutterTextureRegistry, messager: FlutterBinaryMessenger) {
        self.registry = registry
        self.messenger = messager
        self.scanChannel = FlutterEventChannel(name: "fast_qr_reader_view/scan", binaryMessenger: messager)
        super.init()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if ("availableCameras" == call.method) {
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
            
            let devices = discoverySession.devices;
            let reply = devices.map { (device) -> [String : String] in
                switch (device.position) {
                case AVCaptureDevice.Position.back:
                    return ["name": device.uniqueID,
                            "lensFacing": "back"
                    ];
                    
                case AVCaptureDevice.Position.front:
                    return ["name": device.uniqueID,
                            "lensFacing": "front"
                    ];
                    
                default:
                    return ["name": device.uniqueID,
                            "lensFacing": "external"
                    ];
                }
            }
            result(reply);
        } else if ("initialize" == call.method) {
            
            SwiftFastQrReaderViewPlugin.requestAccess { (granted) in
                guard granted else {
                    result(accessError)
                    return
                }
                
                guard let arguments = call.arguments as? [String: Any] else {
                    result(formatError);
                    return
                }
                
                let cameraName: String = arguments["cameraName"] as! String
                let resolutionPreset: String = arguments["resolutionPreset"] as! String
                let formats: [String] = arguments["codeFormats"] as! [String]
                self.camera?.dispose()
                
                guard let camera = FMCam(cameraName: cameraName, resolutionPreset: resolutionPreset, codeFormats: formats) else {
                    // TODO: 报错
                    result(cameraError);
                    return
                }
                
                self.camera = camera
                
                let textureId = self.registry.register(camera)
                self.camera?.onFrameAvailable = { [weak self] in
                    self?.registry.textureFrameAvailable(textureId);
                }
                
                //            let eventChannel = FlutterEventChannel(name: "fast_qr_reader_view/cameraEvents\(textureId)", binaryMessenger: messenger)
                //            eventChannel.setStreamHandler(camera)
                //            camera.eventChannel = eventChannel
                result([
                    "textureId": textureId,
                    "previewWidth": camera.previewSize.width,
                    "previewHeight": camera.previewSize.height,
                    //                    "captureWidth": camera.captureSize.width,
                    //                    "captureHeight": camera.captureSize.height,
                    ] as [String : Any]);
                //            self.camera?.start()
            }
        } else if ("startScan" == call.method) {
            self.scanChannel.setStreamHandler(self.camera)
            self.camera?.start()
            result(true)
        }
        else if ("stopScan" == call.method) {
            self.scanChannel.setStreamHandler(nil)
            self.camera?.stop()
            result(true)
        }
//        else if ("checkPermission" == call.method) {
//            let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
//            if (authStatus == AVAuthorizationStatus.authorized) {
//                result("granted");
//            } else if (authStatus == AVAuthorizationStatus.denied) {
//                result("denied");
//            } else if (authStatus == AVAuthorizationStatus.restricted) {
//                result("restricted");
//            } else if (authStatus == AVAuthorizationStatus.notDetermined) {
//                result("unknown");
//            }
//        } else if ("settings" == call.method) {
//            UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!)
//            result(nil);
//        } else if ("requestPermission" == call.method) {
//            SwiftFastQrReaderViewPlugin.requestAccess { (granted) in
//                granted ? result("granted") : result("denied");
//            }
//        }
        else {
            if ("dispose" == call.method) {
                let argsMap: [String: Any]? = call.arguments as? [String : Any]
                if let textureId = argsMap?["textureId"] as? Int64 {
                    self.registry.unregisterTexture(textureId)
                    self.camera?.dispose()
                    result(nil);
                } else {
                    result(formatError)
                }
            } else {
                result(FlutterMethodNotImplemented);
            }
        }
    }
    
    
    static public func requestAccess(_ callBack: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
        case .authorized:
            callBack(true)
        case .denied, .restricted:
            callBack(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted) in
                callBack(granted)
            }
        }
    }
    
}
