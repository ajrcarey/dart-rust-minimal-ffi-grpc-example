part of app;

class NativeFFIRPCClientChannel extends ClientChannelBase
    implements ClientChannel {
  final _connection = new NativeFFIRPCClientConnection();

  @override
  ClientConnection createConnection() {
    return _connection;
  }

  @override
  final String host = "localhost";

  @override
  final ChannelOptions options =
      new ChannelOptions(credentials: ChannelCredentials.insecure());

  @override
  final int port = 0;
}

class NativeFFIRPCClientConnection implements ClientConnection {
  @override
  final String authority = "localhost";

  @override
  void dispatchCall(ClientCall call) {
    call.onConnectionReady(this);
  }

  @override
  GrpcTransportStream makeRequest(String path, Duration timeout,
      Map<String, String> metadata, ErrorHandler onRequestFailure) {
    return new NativeFFIRPCTransportStream(path);
  }

  @override
  final String scheme = "ffi";

  @override
  Future<void> shutdown() {
    return Future<void>.value(null);
  }

  @override
  Future<void> terminate() {
    return Future<void>.value(null);
  }
}

class NativeFFIRPCTransportStream implements GrpcTransportStream {
  final StreamController<GrpcMessage> _incomingMessages = StreamController();

  Stream<GrpcMessage> get incomingMessages => _incomingMessages.stream;

  final StreamController<Uint8List> _outgoingMessages = StreamController();

  StreamSink<Uint8List> get outgoingMessages => _outgoingMessages.sink;

  final String _path;

  bool _areHeadersSent = false;

  NativeFFIRPCTransportStream(this._path) {
    final requestMessageType = NativeFFIBridge._serviceIndex
        .getRequestMessageTypeForService(_path)
        .flatMap(NativeFFIBridge._serviceIndex.getIntValueFromMessageType);

    final responseMessageType = NativeFFIBridge._serviceIndex
        .getResponseMessageTypeForService(_path)
        .flatMap(NativeFFIBridge._serviceIndex.getIntValueFromMessageType);

    if (requestMessageType.isNotEmpty && responseMessageType.isNotEmpty) {
      final requestType = requestMessageType.orElsePanic();

      final expectedResponseType = responseMessageType.orElsePanic();

      final int id = NativeFFIBridge._getNextMessageId();

      int sequence = 0;

      _outgoingMessages.stream.listen((requestPayload) {
        NativeFFIBridge._send(
            requestType, id, sequence++, requestPayload, expectedResponseType,
            (messageType, inReplyToId, responsePayload,
                isResponseStreamComplete) {
          if (!_areHeadersSent) {
            _areHeadersSent = true;
            _incomingMessages.add(new GrpcMetadata({}));
          }

          // We need to clone the response payload buffer before adding it
          // to the incoming messages stream. The buffer was allocated in
          // native code, and it will be deallocated at the end of this
          // function callback, i.e. _before_ the incoming messages stream
          // is flushed in the next microtask. Failing to clone the payload
          // buffer results in failed deserialization of the payload.

          _incomingMessages
              .add(new GrpcData(responsePayload.toList(), isCompressed: false));

          if (isResponseStreamComplete) {
            _incomingMessages.add(new GrpcMetadata({}));
            _incomingMessages.close();
          }
        });
      });
    }
  }

  @override
  Future<void> terminate() async {
    _outgoingMessages.close();
    _incomingMessages.close();
    return Future<void>.value(null);
  }
}
