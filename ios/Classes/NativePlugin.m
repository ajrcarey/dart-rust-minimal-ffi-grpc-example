#import "NativePlugin.h"
#if __has_include(<native/native-Swift.h>)
#import <native/native-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "native-Swift.h"
#endif

@implementation NativePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNativePlugin registerWithRegistrar:registrar];
}
@end
