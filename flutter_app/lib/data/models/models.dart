/// Domain models for the VantoPay app.
library;

import 'package:decimal/decimal.dart';

class User {
  final String id;
  final String? email;
  final String role;
  User({required this.id, required this.email, required this.role});

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['user_id']?.toString() ?? '',
        email: json['email']?.toString(),
        role: json['role']?.toString() ?? 'user',
      );
}

class Account {
  final String id;
  final String accountNumber;
  final String holderName;
  final String documentMasked;
  final String currency;
  final String status;
  final bool isAdmin;
  final double transactionLimit;
  final double dailyLimit;

  const Account({
    required this.id,
    required this.accountNumber,
    required this.holderName,
    required this.documentMasked,
    required this.currency,
    required this.status,
    required this.isAdmin,
    required this.transactionLimit,
    required this.dailyLimit,
  });

  bool get isActive => status == 'active';

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id']?.toString() ?? '',
        accountNumber: json['account_number']?.toString() ?? '',
        holderName: json['holder_name']?.toString() ?? '',
        documentMasked: json['document_masked']?.toString() ?? '',
        currency: json['currency']?.toString() ?? 'BRL',
        status: json['status']?.toString() ?? 'active',
        isAdmin: json['is_admin'] ?? false,
        transactionLimit: (json['transaction_limit']?.toDouble()) ?? 0,
        dailyLimit: (json['daily_limit']?.toDouble()) ?? 0,
      );
}

class Balance {
  final String accountId;
  final Decimal amount;
  final String currency;
  const Balance({required this.accountId, required this.amount,
      required this.currency});

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
        accountId: json['account_id']?.toString() ?? '',
        amount: Decimal(json['balance']?.toString() ?? '0'),
        currency: json['currency']?.toString() ?? 'BRL',
      );
}

class Transaction {
  final String id;
  final String kind;
  final String direction;
  final Decimal amount;
  final String currency;
  final String status;
  final String? counterpartyName;
  final String? counterpartyInstitution;
  final String? counterpartyDocumentMasked;
  final String? externalReference;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.kind,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.status,
    this.counterpartyName,
    this.counterpartyInstitution,
    this.counterpartyDocumentMasked,
    this.externalReference,
    required this.createdAt,
  });

  bool get isCredit => direction == 'credit';

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id']?.toString() ?? '',
        kind: json['kind']?.toString() ?? '',
        direction: json['direction']?.toString() ?? '',
        amount: Decimal(json['amount']?.toString() ?? '0'),
        currency: json['currency']?.toString() ?? 'BRL',
        status: json['status']?.toString() ?? '',
        counterpartyName: json['counterparty_name']?.toString(),
        counterpartyInstitution: json['counterparty_institution']?.toString(),
        counterpartyDocumentMasked:
            json['counterparty_document_masked']?.toString(),
        externalReference: json['external_reference']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class StatementEntry {
  final String id;
  final String entryType;
  final Decimal amount;
  final String currency;
  final String description;
  final String? reference;
  final Decimal balanceAfter;
  final DateTime createdAt;
  const StatementEntry({
    required this.id,
    required this.entryType,
    required this.amount,
    required this.currency,
    required this.description,
    this.reference,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory StatementEntry.fromJson(Map<String, dynamic> json) => StatementEntry(
        id: json['id']?.toString() ?? '',
        entryType: json['entry_type']?.toString() ?? '',
        amount: Decimal(json['amount']?.toString() ?? '0'),
        currency: json['currency']?.toString() ?? 'BRL',
        description: json['description']?.toString() ?? '',
        reference: json['reference']?.toString(),
        balanceAfter: Decimal(json['balance_after']?.toString() ?? '0'),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class PixKey {
  final String id;
  final String keyType;
  final String keyValue;
  final String status;
  final DateTime createdAt;
  const PixKey({required this.id, required this.keyType, required this.keyValue,
      required this.status, required this.createdAt});

  factory PixKey.fromJson(Map<String, dynamic> json) => PixKey(
        id: json['id']?.toString() ?? '',
        keyType: json['key_type']?.toString() ?? '',
        keyValue: json['key_value']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class PixCharge {
  final String id;
  final String kind;
  final String keyValue;
  final Decimal amount;
  final String status;
  final String? qrCodePayload;
  final DateTime createdAt;

  PixCharge({
    required this.id,
    required this.kind,
    required this.keyValue,
    required this.amount,
    required this.status,
    this.qrCodePayload,
    required this.createdAt,
  });

  factory PixCharge.fromJson(Map<String, dynamic> json) => PixCharge(
        id: json['id']?.toString() ?? '',
        kind: json['kind']?.toString() ?? '',
        keyValue: json['key_value']?.toString() ?? '',
        amount: Decimal(json['amount']?.toString() ?? '0'),
        status: json['status']?.toString() ?? '',
        qrCodePayload: json['qr_code_payload']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class SessionInfo {
  final String id;
  final String deviceLabel;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final bool revoked;
  const SessionInfo({required this.id, required this.deviceLabel,
      required this.createdAt, required this.lastSeenAt, required this.revoked});
}

class IntegrationStatus {
  final String name;
  final bool configured;
  final String description;
  const IntegrationStatus(
      {required this.name, required this.configured,
      required this.description});

  factory IntegrationStatus.fromJson(Map<String, dynamic> json) =>
      IntegrationStatus(
          name: json['name']?.toString() ?? '',
          configured: json['configured'] ?? false,
          description: json['description']?.toString() ?? '');
}

class SuspiciousEvent {
  final String id;
  final String? accountId;
  final int score;
  final String reason;
  final bool resolved;
  final DateTime createdAt;
  const SuspiciousEvent({required this.id, this.accountId, required this.score,
      required this.reason, required this.resolved, required this.createdAt});

  factory SuspiciousEvent.fromJson(Map<String, dynamic> json) =>
      SuspiciousEvent(
        id: json['id']?.toString() ?? '',
        accountId: json['account_id']?.toString(),
        score: json['score']?.toInt() ?? 0,
        reason: json['reason']?.toString() ?? '',
        resolved: json['resolved'] ?? false,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class AuditLog {
  final String id;
  final String actorRole;
  final String action;
  final String? target;
  final String? ipAddress;
  final DateTime createdAt;
  const AuditLog({required this.id, required this.actorRole,
      required this.action, this.target, this.ipAddress,
      required this.createdAt});

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id']?.toString() ?? '',
        actorRole: json['actor_role']?.toString() ?? '',
        action: json['action']?.toString() ?? '',
        target: json['target']?.toString(),
        ipAddress: json['ip_address']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}
