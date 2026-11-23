import 'package:decimal/decimal.dart';

import '../../data/models/models.dart';
import 'api_client.dart';

/// PIX operations: keys, charges (receive), send and history.
class PixService {
  PixService._();
  static final PixService instance = PixService._();

  Future<PixKey> addKey(String keyType, String keyValue) async =>
      PixKey.fromJson(await ApiClient.post('/pix/keys', {
        'key_type': keyType,
        'key_value': keyValue,
      }));

  Future<List<PixKey>> keys() async {
    final data = await ApiClient.getList('/pix/keys');
    return data.map(PixKey.fromJson).toList();
  }

  Future<void> deleteKey(String id) async => ApiClient.delete('/pix/keys/$id');

  Future<PixCharge> createCharge(Decimal amount, String keyValue) async =>
      PixCharge.fromJson(await ApiClient.post('/pix/charges', {
        'amount': amount.toString(),
        'key_value': keyValue,
      }));

  Future<PixCharge> charge(String id) async =>
      PixCharge.fromJson(await ApiClient.get('/pix/charges/$id'));

  /// Send PIX by key. Requires a configured PIX provider.
  Future<Map<String, dynamic>> sendByKey(
          {required String keyValue, required Decimal amount,
          required String idempotencyKey}) async =>
      ApiClient.post('/pix/send/key', {
        'key_value': keyValue,
        'amount': amount.toString(),
        'idempotency_key': idempotencyKey,
      });

  /// Send PIX by copy-and-paste payload (PIX Copia e Cola).
  Future<Map<String, dynamic>> sendByPayload(
          {required String payloadPix, required String idempotencyKey}) async =>
      ApiClient.post('/pix/send/payload', {
        'payload_pix': payloadPix,
        'idempotency_key': idempotencyKey,
      });

  Future<List<Transaction>> history({int limit = 50}) async {
    final data = await ApiClient.getList('/pix/history',
        {'limit': limit.toString()});
    return data.map(Transaction.fromJson).toList();
  }

  Future<Transaction> transaction(String id) async =>
      Transaction.fromJson(await ApiClient.get('/pix/transactions/$id'));
}
