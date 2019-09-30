import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dd_flutter_qr_reader/fast_qr_reader_view.dart';

List<CameraDescription> cameras;

Future<Null> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    cameras = await availableCameras();
  } on QRReaderException catch (e) {
    logError(e.code, e.description);
  }
  runApp(MaterialApp(
    home: Builder(
      builder: (_) => MyApp(),
    ),
  ));
}

void logError(String code, String message) => print('Error: $code\nError Message: $message');

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  QRReaderController qrController;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  AnimationController animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    animationController = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: 3),
    );

    animationController.addListener(() {
      this.setState(() {});
    });
    animationController.forward();
    verticalPosition = Tween<double>(begin: 0.0, end: 300.0)
        .animate(CurvedAnimation(parent: animationController, curve: Curves.linear))
          ..addStatusListener((state) {
            if (state == AnimationStatus.completed) {
              animationController.reverse();
            } else if (state == AnimationStatus.dismissed) {
              animationController.forward();
            }
          });

    // pick the first available camera
    onNewCameraSelected(cameras[0]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (qrController == null || !qrController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      qrController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (qrController != null) {
        onNewCameraSelected(qrController.description);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Animation<double> verticalPosition;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: const Text('Fast QR reader example'),
        ),
        floatingActionButton: FloatingActionButton(
          child: new Icon(Icons.check),
          onPressed: () {
            showInSnackBar("Just proving you can put anything on top of the scanner");
          },
        ),
        body: Stack(
          children: <Widget>[
            new Container(
              child: new Padding(
                padding: const EdgeInsets.all(0.0),
                child: new Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
            ),
            RepaintBoundary(
              child: Center(
                child: Stack(
                  children: <Widget>[
                    SizedBox(
                      height: 300.0,
                      width: 300.0,
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.red, width: 2.0)),
                      ),
                    ),
                    Positioned(
                      top: verticalPosition.value,
                      child: Container(
                        width: 300.0,
                        height: 2.0,
                        color: Colors.red,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (qrController == null || !qrController.value.isInitialized) {
      return const Text(
        'No camera selected',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return new AspectRatio(
        aspectRatio: qrController.value.aspectRatio,
        child: new QRReaderPreview(qrController),
      );
    }
  }

  void onCodeRead(dynamic value) {
    showInSnackBar(value.toString());
    // ... do something
    // wait 5 seconds then start scanning again.
//    new Future.delayed(const Duration(seconds: 5), qrController.startScanning);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (qrController != null) {
      await qrController.dispose();
    }
    qrController = new QRReaderController(cameraDescription, ResolutionPreset.high, onCodeRead);

    // If the controller is updated then update the UI.
    qrController.addListener(() {
      if (mounted) setState(() {});
      if (qrController.value.hasError) {
        showInSnackBar('Camera error ${qrController.value.errorDescription}');
      }
    });

    try {
      await qrController.initialize();

      if (mounted) {
        setState(() {
          qrController?.startScanning();
        });
      }
    } on QRReaderException catch (e) {
      logError(e.code, e.description);
      showInSnackBar('Error: ${e.code}\n${e.description}');
    }
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(message)));
  }
}
