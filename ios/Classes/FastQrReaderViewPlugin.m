#import "FastQrReaderViewPlugin.h"
#import <dd_flutter_qr_reader/dd_flutter_qr_reader-Swift.h>

@implementation FastQrReaderViewPlugin

+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    [SwiftFastQrReaderViewPlugin registerWithRegistrar:registrar];
}

@end
