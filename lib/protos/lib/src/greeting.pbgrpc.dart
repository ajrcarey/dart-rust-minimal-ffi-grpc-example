///
//  Generated code. Do not modify.
//  source: greeting.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'greeting.pb.dart' as $0;
export 'greeting.pb.dart';

class GreeterClient extends $grpc.Client {
  static final _$sayHello =
      $grpc.ClientMethod<$0.HelloRequest, $0.HelloResponse>(
          '/com.google.greeting.Greeter/SayHello',
          ($0.HelloRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.HelloResponse.fromBuffer(value));
  static final _$sayHelloAgain =
      $grpc.ClientMethod<$0.HelloRequest, $0.HelloResponse>(
          '/com.google.greeting.Greeter/SayHelloAgain',
          ($0.HelloRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.HelloResponse.fromBuffer(value));

  GreeterClient($grpc.ClientChannel channel, {$grpc.CallOptions options})
      : super(channel, options: options);

  $grpc.ResponseFuture<$0.HelloResponse> sayHello($0.HelloRequest request,
      {$grpc.CallOptions options}) {
    final call = $createCall(_$sayHello, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }

  $grpc.ResponseFuture<$0.HelloResponse> sayHelloAgain($0.HelloRequest request,
      {$grpc.CallOptions options}) {
    final call = $createCall(
        _$sayHelloAgain, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }
}

abstract class GreeterServiceBase extends $grpc.Service {
  $core.String get $name => 'com.google.greeting.Greeter';

  GreeterServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.HelloRequest, $0.HelloResponse>(
        'SayHello',
        sayHello_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HelloRequest.fromBuffer(value),
        ($0.HelloResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.HelloRequest, $0.HelloResponse>(
        'SayHelloAgain',
        sayHelloAgain_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HelloRequest.fromBuffer(value),
        ($0.HelloResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.HelloResponse> sayHello_Pre(
      $grpc.ServiceCall call, $async.Future<$0.HelloRequest> request) async {
    return sayHello(call, await request);
  }

  $async.Future<$0.HelloResponse> sayHelloAgain_Pre(
      $grpc.ServiceCall call, $async.Future<$0.HelloRequest> request) async {
    return sayHelloAgain(call, await request);
  }

  $async.Future<$0.HelloResponse> sayHello(
      $grpc.ServiceCall call, $0.HelloRequest request);
  $async.Future<$0.HelloResponse> sayHelloAgain(
      $grpc.ServiceCall call, $0.HelloRequest request);
}
