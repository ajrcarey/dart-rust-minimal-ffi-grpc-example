# dart-rust-minimal-ffi-grpc-example

Building on the excellent starting point provided by truongsinh in
https://github.com/truongsinh/flutter-plugin-protobuf,
this example demonstrates building a protocol buffers-based messaging
system between Dart and a native library (built in Rust in this case)
over FFI.

Once procotol buffers over FFI are implemented, it is then possible to add
support for GRPC, Google's RPC standard. This makes calling into native code
from Dart effortless. 

## Prerequisites

* An existing, up-to-date installation of Dart and Flutter.
* An existing, up-to-date installation of the Android SDK, and the correctly configured environment variables to go with it, in particular `$ANDROID_NDK_HOME`.
* An existing, up-to-date installation of rust, rustup and cargo.
* The standard GNU tools that come with any *nix distribution, including GNU `make` or an equivalent.

Everything below was tested on Arch Linux. It should work without changes on any
up-to-date Linux distribution, and probably on macOS as well (given a few caveats
mentioned below).

## Build

1. Make sure your build environment is set up.

~~~
make init
~~~

2. Build the native library and shared protocol buffers definitions.

~~~
make all
~~~

3. Run the app in Flutter.

~~~
flutter run
~~~

## What's it doing?

There's a lot going on in `make all`. To break it down:

1. `make clean`: The build environment is cleaned of prior artifacts.
2. `make protos`: Source code for both Dart and Rust is generated from the protocol buffer definitions in /protos.
3. `make android-debug`: The Rust code is compiled into three separate binaries, one for each of the three Android architectures. We build debug binaries to keep build times down.
4. `make ios-debug`: The Rust code is compiled into two separate binaries, one for each of the two support iOS architectures. Note that this only takes place if you're running macOS.
5. `make bindings`: A C-style header file is derived from the Rust binaries - this is necessary for library linking when packaging an iOS build with XCode.
6. `make install`: Build artificats are copied into their appropriate positions in the Flutter /android and /ios folders, ready to be packaged with either `flutter run` or `flutter build`. 

That's enough talk about the build environment. Let's look at the implementation.

## What's in the code?

FFI is largely driven from the Dart side. In Rust, we export two functions for
Dart to discover: `initialize_ffi()`, which performs any start-up initialization required
in the native code (in this example, it just sets up logcat logging for Android,
nothing else), and `receive_from_ffi()`, which accepts a protocol buffer from Dart
and dispatches a result. The code is in `/native/lib.rs`.

There are three components to the Dart side. In `lib/bridge.dart`, we define the
FFI interface that calls the two functions exported from Rust. This FFI bridge contains
all the functionality necessary to send requests to, and receive responses from,
the native code, although it's a bit cumbersome to use directly. To make things easier,
we provide `lib/grpc.dart`, an implementation of `GrpcTransportStream` that uses
our FFI bridge. This is the only substantive piece of code required to support GRPC;
stub definitions for everything else are provided as part of `package:grpc`. Finally,
we provide a helper library, `lib/services.dart`, that decodes the service definitions
from the .proto files, since the code generation step doesn't do this for us in Dart.
(It does in Rust.) Without this, it would be difficult for our GRPC implementation
to figure out the messages types associated with the code-generated GRPC services. 

## The example application

This is as simple an example as possible. The standard `greeting.proto` used in Google's
protocol buffers quickstart guide is also used here. The file defines two messages,
`HelloRequest` and `HelloResponse`, and binds those messages together into a
GRPC service (`Greeter`) that provides two functions, `SayHello()` and `SayHelloAgain()`.

In the Dart code in `/lib/main.dart`, we create an instance of the `GreeterClient`,
we bind our FFI channel to it, and we call the `SayHello()` function. Rust returns
a response, which we then display on screen. That's it. 

## TODOs

* Streaming requests from Dart to native are supported, but the message sequence numbers are not actually delivered to the native code yet.
* Streaming responses from native back to Dart are in progress, but not yet completed.
* In a perfect world, response dispatch would be handled using async/await in Rust - everything is sync at the moment.
* The `make protos` section of the makefile does a lot of text processing using awk. There's almost certainly a better way. 

## More reading

* Google protocol buffers and RPC services documentation: https://developers.google.com/protocol-buffers/
* Protocol buffers are usually used over HTTP2, as explained here: https://medium.com/@bettdougie/building-an-end-to-end-system-using-grpc-flutter-part-1-d23b2356ed28

## Notes

* Minimum Android API level is 23 - lower than this, and the libraries created by Rust aren't correctly loaded from within the Flutter app. 
* While this example was built using Linux, in theory everything should work on an appropriately configured Mac as well - but you will likely need to install GNU gawk, as the vendor-supplied version of awk doesn't like the syntax used in the makefile.
* It is absolutely possible to extend this process to include building the equivalent binaries and packages for iOS. An outline is provided in the makefile. 
 
