part of app;

typedef T Supplier<T>();

class ProtobufServiceIndex {
  Map<int, MessageType> _messageTypesByIntValue = new Map<int, MessageType>();

  Map<MessageType, int> _intValuesByMessageType = new Map<MessageType, int>();

  Map<String, MessageType> _messageTypesByQualifiedMessageName =
      new Map<String, MessageType>();

  Map<MessageType, Supplier<GeneratedMessage>> _buildersByMessageType =
      new Map<MessageType, Supplier<GeneratedMessage>>();

  Map<String, MessageType> _messageTypesByClassName =
      new Map<String, MessageType>();

  Map<MessageType, String> _classNamesByMessageType =
      new Map<MessageType, String>();

  Map<String, MessageType> _requestMessageTypesByQualifiedServiceName =
      new Map<String, MessageType>();

  Map<String, MessageType> _responseMessageTypesByQualifiedServiceName =
      new Map<String, MessageType>();

  Map<String, bool> _requestIsStreamByQualifiedServiceName =
      new Map<String, bool>();

  Map<String, bool> _responseIsStreamByQualifiedServiceName =
      new Map<String, bool>();

  ProtobufServiceIndex() {
    createServiceIndexEntries(this._createServiceIndexEntriesForOnePackage);
  }

  void _createServiceIndexEntriesForOnePackage(
      final String packageName,
      final String messageNamesInPackage,
      final List<MessageType> messageTypesInPackage,
      final List<Supplier<GeneratedMessage>> messageBuildersInPackage,
      final String rpcServicesInPackage) {
    int index = 0;

    messageTypesInPackage.forEach((MessageType type) {
      final int sequence = _messageTypesByIntValue.length;

      _messageTypesByIntValue[sequence] = type;
      _intValuesByMessageType[type] = sequence;

      Maybe(messageBuildersInPackage[index])
          .ifPresent((Supplier<GeneratedMessage> builder) {
        _buildersByMessageType[type] = builder;

        final built = builder();

        _messageTypesByClassName[built.runtimeType.toString()] = type;
        _classNamesByMessageType[type] = built.runtimeType.toString();
      });

      index++;
    });

    index = 0;

    messageNamesInPackage.trim().split(" ").forEach((String messageName) {
      Maybe(messageTypesInPackage[index]).ifPresent((MessageType type) =>
          _messageTypesByQualifiedMessageName[
              packageName + '.' + messageName.trim()] = type);

      index++;
    });

    rpcServicesInPackage.split('//:service ').forEach((service) {
      if (service.trim().isNotEmpty) {
        final String serviceName = service.split(' {')[0].trim();

        index = 0;

        service.split('//:rpc ').forEach((String rpc) {
          if (index > 0) {
            final List<String> fields = rpc.split('(');

            final rpcName = fields[0].trim();

            final qualifiedServiceName =
                '/' + packageName + '.' + serviceName + '/' + rpcName;

            String requestMessageName =
                fields[1].substring(0, fields[1].lastIndexOf(')')).trim();

            if (requestMessageName.startsWith('stream ')) {
              requestMessageName =
                  requestMessageName.substring('stream '.length);

              _requestIsStreamByQualifiedServiceName[qualifiedServiceName] =
                  true;
            } else {
              _requestIsStreamByQualifiedServiceName[qualifiedServiceName] =
                  false;
            }

            Maybe(_messageTypesByQualifiedMessageName[
                    packageName + '.' + requestMessageName])
                .ifPresent((type) => _requestMessageTypesByQualifiedServiceName[
                    qualifiedServiceName] = type);

            String responseMessageName =
                fields[2].substring(0, fields[2].lastIndexOf(')')).trim();

            if (responseMessageName.startsWith('stream ')) {
              responseMessageName =
                  responseMessageName.substring('stream '.length);

              _responseIsStreamByQualifiedServiceName[qualifiedServiceName] =
                  true;
            } else {
              _responseIsStreamByQualifiedServiceName[qualifiedServiceName] =
                  false;
            }

            Maybe(_messageTypesByQualifiedMessageName[
                    packageName + '.' + responseMessageName])
                .ifPresent((type) =>
                    _responseMessageTypesByQualifiedServiceName[
                        qualifiedServiceName] = type);
          }

          index++;
        });
      }
    });
  }

  Option<int> getIntValueFromMessageType(MessageType type) =>
      Maybe(_intValuesByMessageType[type]);

  Option<MessageType> getMessageTypeFromIntValue(int value) =>
      Maybe(_messageTypesByIntValue[value]);

  Option<GeneratedMessage> getEmptyMessageFromMessageType(MessageType type) =>
      Maybe(_buildersByMessageType[type]).map((builder) => builder());

  Option<GeneratedMessage> getDecodedPayloadFromMessageType(
          MessageType type, Uint8List buffer) =>
      getEmptyMessageFromMessageType(type)
          .map((message) => message..mergeFromBuffer(buffer));

  Option<MessageType> getMessageTypeForMessage<T extends GeneratedMessage>(
          T message) =>
      Maybe(_messageTypesByQualifiedMessageName[
          message.info_.qualifiedMessageName]);

  Option<MessageType>
      getMessageTypeForMessageClass<T extends GeneratedMessage>() =>
          Maybe(_messageTypesByClassName[T.toString()]);

  Option<MessageType> getRequestMessageTypeForService(String path) =>
      Maybe(_requestMessageTypesByQualifiedServiceName[path]);

  Option<MessageType> getResponseMessageTypeForService(String path) =>
      Maybe(_responseMessageTypesByQualifiedServiceName[path]);

  bool getRequestIsStreamForService(String path) =>
      Maybe(_requestIsStreamByQualifiedServiceName[path]).orElse(false);

  bool getResponseIsStreamForService(String path) =>
      Maybe(_responseIsStreamByQualifiedServiceName[path]).orElse(false);
}
