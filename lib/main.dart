library app;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi_helper/ffi_helper.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';
import 'package:protobuf/protobuf.dart';
import 'package:shared_ffi_protos/protos.dart';

part 'bridge.dart';
part 'grpc.dart';
part 'option.dart';
part 'services.dart';

void main() async {
  final HelloResponse response = await GreeterClient(
          // Normally a GRPC client is constructed using an HTTP2 channel.
          // Here, however, we supply a channel provided by our FFI
          // implementation. The GRPC client is unaware of any difference.
          NativeFFIBridge().rpcClientChannel)
      .sayHello(HelloRequest()..name = "Phred");

  runApp(App(response.message));
}

class App extends StatelessWidget {
  final String title = 'Hello from Rust';

  final String greeting;

  App(this.greeting);

  Widget build(context) => MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(greeting),
        ])),
      ));
}
