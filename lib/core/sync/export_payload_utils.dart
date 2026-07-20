const String clientRequestIdField = 'client_request_id';

String? buildClientRequestId(dynamic localId) {
  if (localId == null) return null;
  return localId.toString();
}

Map<String, dynamic> preparePayloadForSend(Map<String, dynamic> item) {
  final copy = Map<String, dynamic>.from(item);
  copy.remove('local_id');
  return copy;
}
