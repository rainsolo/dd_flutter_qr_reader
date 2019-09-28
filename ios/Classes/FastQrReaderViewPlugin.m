#import "FastQrReaderViewPlugin.h"
#import <fast_qr_reader_view/fast_qr_reader_view-Swift.h>

//#import "fast_qr_reader_view-Swift.h"

@implementation FastQrReaderViewPlugin

+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    [SwiftFastQrReaderViewPlugin registerWithRegistrar:registrar];
}

@end
