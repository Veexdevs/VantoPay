import '../../data/models/models.dart';
import 'api_client.dart';

/// Account, balance, statement and session operations.
class AccountService {
  AccountService._();
  static final AccountService instance = AccountService._();

  Future<User> fetchMe() async => User.fromJson(await ApiClient.get('/auth/me'));

  Future<Account> register({
    required String holderName,
    required String document,
    double transactionLimit = 0,
    double dailyLimit = 0,
  }) async {
    final data = await ApiClient.post('/auth/accounts', {
      'holder_name': holderName,
      'document': document,
      'transaction_limit': transactionLimit,
      'daily_limit': dailyLimit,
    });
    final account = (data['account'] as Map).cast<String, dynamic>();
    return Account.fromJson(account);
  }

  Future<Account> fetchAccount() async =>
      Account.fromJson(await ApiClient.get('/accounts'));

  Future<Balance> fetchBalance() async =>
      Balance.fromJson(await ApiClient.get('/accounts/balance'));

  Future<List<StatementEntry>> statement({int limit = 100}) async {
    final data = await ApiClient.getList('/accounts/statement',
        {'limit': limit.toString()});
    return data.map(StatementEntry.fromJson).toList();
  }

  Future<List<Transaction>> transactions({int limit = 50}) async {
    final data = await ApiClient.getList('/accounts/transactions',
        {'limit': limit.toString()});
    return data.map(Transaction.fromJson).toList();
  }

  Future<Account> updateLimits({
    required double transactionLimit,
    required double dailyLimit,
  }) async =>
      Account.fromJson(await ApiClient.patch('/accounts/limits', {
        'transaction_limit': transactionLimit,
        'daily_limit': dailyLimit,
      }));

  Future<void> block() async => ApiClient.post('/accounts/block', {});

  Future<void> close() async => ApiClient.post('/accounts/close', {});

  Future<List<SessionInfo>> sessions() async {
    final data = await ApiClient.getList('/sessions');
    return data.map((m) => SessionInfo(
          id: m['id']?.toString() ?? '',
          deviceLabel: m['device_label']?.toString() ?? '',
          createdAt:
              DateTime.tryParse(m['created_at']?.toString() ?? '') ??
                  DateTime.now(),
          lastSeenAt:
              DateTime.tryParse(m['last_seen_at']?.toString() ?? '') ??
                  DateTime.now(),
          revoked: m['revoked'] ?? false,
        )).toList();
  }

  Future<void> revokeSession(String id) async => ApiClient.delete('/sessions/$id');

  Future<List<IntegrationStatus>> integrations() async {
    final data = await ApiClient.getList('/integrations/status');
    return data.map(IntegrationStatus.fromJson).toList();
  }
}
