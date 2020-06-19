part of app;

typedef void ResponseHandler(int responseMessageTypeValue, int inReplyToId,
    Uint8List payload, bool isResponseStreamComplete);

typedef InitializeFFI = void Function();

typedef InitializeFFINativeReceiver = Void Function();

typedef ReceiveProtobufFromFFI = Void Function(
    Int32 requestMessageType,
    Int32 inReplyToId,
    Pointer<Uint8> payloadBuffer,
    IntPtr payloadBufferLength,
    Uint8 isPayloadStreamComplete);

typedef SendProtobufToFFI = void Function(
    int requestMessageType,
    int requestMessageId,
    Pointer<Uint8> payloadBuffer,
    int payloadBufferLength,
    int expectedResponseMessageType,
    Pointer<NativeFunction<ReceiveProtobufFromFFI>>);

typedef SendProtobufToFFINativeReceiver = Void Function(
    Int32 request_message_type,
    Int32 request_message_id,
    Pointer<Uint8> payload_buffer,
    IntPtr payload_buffer_length,
    Int32 expected_response_message_type,
    Pointer<NativeFunction<ReceiveProtobufFromFFI>>);

class NativeFFIBridge {
  static final NativeFFIBridge _singleton = new NativeFFIBridge._();

  static final DynamicLibrary _nativeLibrary = Platform.isAndroid
      ? DynamicLibrary.open("libnative.so")
      : DynamicLibrary.process();

  static final InitializeFFI _initializeFFI = _nativeLibrary
      .lookup<NativeFunction<InitializeFFINativeReceiver>>("initialize_ffi")
      .asFunction();

  static final SendProtobufToFFI _sendToFFI = _nativeLibrary
      .lookup<NativeFunction<SendProtobufToFFINativeReceiver>>(
          "receive_from_ffi")
      .asFunction();

  NativeFFIBridge._() {
    final start = DateTime.now();

    print("Initializing NativeFFIBridge.");

    if (_nativeLibrary == null) {
      print("Error: Native library not available, check build and packaging.");
    } else {
      _initializeFFI();

      print("Native library ${_nativeLibrary.toString()} loaded and ready.");

      // Dart does not initialize static finals until their first access.
      // Force initialization now.

      _serviceIndex;
      _rpcClientChannel;

      final startup = DateTime.now().difference(start).inMilliseconds;

      print("NativeFFIBridge initialized in ${startup}ms.");
    }
  }

  factory NativeFFIBridge() => _singleton;

  static int _id = 0;

  static int _getNextMessageId() => _id++;

  static final NativeFFIRPCClientChannel _rpcClientChannel =
      new NativeFFIRPCClientChannel();

  static final ProtobufServiceIndex _serviceIndex = new ProtobufServiceIndex();

  NativeFFIRPCClientChannel get rpcClientChannel => _rpcClientChannel;

  static final _unrecognized = new UnrecognizedMessageException();

  void announce<T extends GeneratedMessage>(T message) => _announceRaw(
      _serviceIndex
          .getMessageTypeForMessage(message)
          .flatMap(_serviceIndex.getIntValueFromMessageType)
          .orElse(-1),
      message.writeToBuffer());

  void _announceRaw(int requestType, List<int> payload) => _send(
      requestType, _getNextMessageId(), 0, payload, -1, (_, __, ___, ____) {});

  void streamAnnounce<T extends GeneratedMessage>(Stream<T> messages) =>
      messages.listen(announce);

  Future<R> request<S extends GeneratedMessage, R extends GeneratedMessage>(
          S request) =>
      _serviceIndex.getMessageTypeForMessageClass<R>().cond(
          (expectedResponseType) => _requestRaw(
                  _serviceIndex
                      .getMessageTypeForMessage(request)
                      .flatMap(_serviceIndex.getIntValueFromMessageType)
                      .orElse(-1),
                  Stream<Uint8List>.value(request.writeToBuffer()),
                  _serviceIndex
                      .getIntValueFromMessageType(expectedResponseType)
                      .orElse(-1))
              .last
              .then((message) => message as R),
          () => Future.error(_unrecognized));

  Stream<GeneratedMessage> _requestRaw(
      int requestType, Stream<Uint8List> payload, int expectedResponseType) {
    final StreamController<GeneratedMessage> controller =
        new StreamController<GeneratedMessage>();

    final int id = _getNextMessageId();

    int sequence = 0;

    payload.listen((requestPayload) =>
        _send(requestType, id, sequence++, requestPayload, expectedResponseType,
            (messageType, inReplyToId, responsePayload,
                isResponseStreamComplete) {
          _serviceIndex
              .getMessageTypeFromIntValue(expectedResponseType)
              .flatMap((type) => _serviceIndex.getDecodedPayloadFromMessageType(
                  type, responsePayload))
              .ifPresent(controller.add);

          if (isResponseStreamComplete) {
            controller.close();
          }
        }));

    return controller.stream;
  }

  Future<R> streamRequest<S extends GeneratedMessage,
          R extends GeneratedMessage>(Stream<S> requests) =>
      _serviceIndex.getMessageTypeForMessageClass<S>().cond(
          (requestType) => _serviceIndex
              .getMessageTypeForMessageClass<R>()
              .cond(
                  (expectedResponseType) => _requestRaw(
                          _serviceIndex
                              .getIntValueFromMessageType(requestType)
                              .orElse(-1),
                          requests.map((request) => request.writeToBuffer()),
                          _serviceIndex
                              .getIntValueFromMessageType(expectedResponseType)
                              .orElse(-1))
                      .last
                      .then((message) => message as R),
                  () => Future.error(_unrecognized)),
          () => Future.error(_unrecognized));

  Stream<R> requestStreamResponse<S extends GeneratedMessage,
          R extends GeneratedMessage>(S request) =>
      _serviceIndex.getMessageTypeForMessageClass<R>().cond(
          (expectedResponseType) => _requestRaw(
                  _serviceIndex
                      .getMessageTypeForMessage(request)
                      .flatMap(_serviceIndex.getIntValueFromMessageType)
                      .orElse(-1),
                  Stream<Uint8List>.value(request.writeToBuffer()),
                  _serviceIndex
                      .getIntValueFromMessageType(expectedResponseType)
                      .orElse(-1))
              .map((message) => message as R),
          () => Stream<R>.error(_unrecognized));

  Stream<R> streamRequestStreamResponse<S extends GeneratedMessage,
          R extends GeneratedMessage>(Stream<S> requests) =>
      _serviceIndex.getMessageTypeForMessageClass<S>().cond(
          (requestType) => _serviceIndex
              .getMessageTypeForMessageClass<R>()
              .cond(
                  (expectedResponseType) => _requestRaw(
                          _serviceIndex
                              .getIntValueFromMessageType(requestType)
                              .orElse(-1),
                          requests.map((request) => request.writeToBuffer()),
                          _serviceIndex
                              .getIntValueFromMessageType(expectedResponseType)
                              .orElse(-1))
                      .map((message) => message as R),
                  () => Stream<R>.error(_unrecognized)),
          () => Stream<R>.error(_unrecognized));

  void requestAndHandle<T extends GeneratedMessage>(
      T request, MessageType expectedResponseType, ResponseHandler callback) {
    final int id = _getNextMessageId();

    _send(
        _serviceIndex
            .getMessageTypeForMessage(request)
            .flatMap(_serviceIndex.getIntValueFromMessageType)
            .orElse(-1),
        id,
        0,
        request.writeToBuffer(),
        _serviceIndex
            .getIntValueFromMessageType(expectedResponseType)
            .orElse(-1),
        callback);
  }

  static final Map<int, ResponseHandler> _pendingResponseHandlers =
      new Map<int, ResponseHandler>();

  static void _send(
      int requestMessageType,
      int messageId,
      int sequenceId,
      Uint8List payload,
      int expectedResponseMessageType,
      ResponseHandler handler) {
    _pendingResponseHandlers[messageId] = handler;

    final serializationBuffer = Uint8Array.fromTypedList(payload);

    // TODO: we don't currently deliver sequenceId to native, nor to we indicate
    // to native whether our requests are part of a stream or not (although we
    // do deliver all requests in order with the same messageId)
    // TODO: native always indicates its response is the end of a stream
    // TODO: grpc rpcs with streaming responses not currently implemented - native
    // only ever sends a single response

    _sendToFFI(
      requestMessageType,
      messageId,
      serializationBuffer.rawPtr,
      serializationBuffer.length,
      expectedResponseMessageType,
      Pointer.fromFunction(_receive),
    );

    serializationBuffer.free();
  }

  static void _receive(
      int responseMessageType,
      int inReplyToMessageId,
      Pointer<Uint8> payloadBuffer,
      int payloadBufferLength,
      int isPayloadStreamComplete) {
    final handler = _pendingResponseHandlers[inReplyToMessageId];

    if (handler != null) {
      handler(
          responseMessageType,
          inReplyToMessageId,
          payloadBuffer.asTypedList(payloadBufferLength),
          isPayloadStreamComplete == 1);

      if (isPayloadStreamComplete == 1) {
        _pendingResponseHandlers.remove(inReplyToMessageId);
      }
    }
  }
}

class UnrecognizedMessageException implements Exception {}
