import '../../data/models/models.dart';
import 'api_client.dart';

/// Administrative panel operations. Only reachable for accounts with
/// is_admin = true (enforced server-side as well).
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  Future<List<Account>> accounts({int limit = 50}) async {
    final data = await ApiClient.getList('/admin/accounts',
        {'limit': limit.toString()});
    return data.map(Account.fromJson).toList();
  }

  Future<List<Transaction>> transactions({int limit = 100}) async {
    final data = await ApiClient.getList('/admin/transactions',
        {'limit': limit.toString()});
    return data.map(Transaction.fromJson).toList();
  }

  Future<List<SuspiciousEvent>> suspicious({int limit = 100}) async {
    final data = await ApiClient.getList('/admin/suspicious',
        {'limit': limit.toString()});
    return data.map(SuspiciousEvent.fromJson).toList();
  }

  Future<void> resolveSuspicious(String id) async =>
      ApiClient.post('/admin/suspicious/$id/resolve', {});

  Future<List<AuditLog>> auditLogs({int limit = 100}) async {
    final data = await ApiClient.getList('/admin/audit-logs',
        {'limit': limit.toString()});
    return data.map(AuditLog.fromJson).toList();
  }

  Future<void> blockAccount(String id) async =>
      ApiClient.post('/admin/accounts/$id/block', {});

  Future<void> unblockAccount(String id) async =>
      ApiClient.post('/admin/accounts/$id/unblock', {});

  Future<void> adjust({
    required String accountId,
    required String direction,
    required double amount,
    required String reason,
    required String idempotencyKey,
  }) async =>
      ApiClient.post(
        '/admin/accounts/$accountId/adjustment',
        {},
        {
          'direction': direction,
          'amount': amount.toString(),
          'reason': reason,
          'idempotency_key': idempotencyKey,
        },
      );
}
