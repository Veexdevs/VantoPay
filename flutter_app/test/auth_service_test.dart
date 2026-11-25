import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vantopay/auth_service.dart';

void main() {
  SupabaseAuthService makeService(http.Client transport) {
    final client = SupabaseClient('https://example.supabase.co', 'test-public-key');
    final service = SupabaseAuthService(client, url: 'https://example.supabase.co',
      publicKey: 'test-public-key', transport: transport,
      apiUri: Uri.parse('https://vantopay.vercel.app/api/auth'));
    addTearDown(() async { await service.dispose(); await client.dispose(); });
    return service;
  }

  test('signup waits for restore and exposes server pending verification', () async {
    final restore = Completer<http.Response>();
    final actions = <String>[];
    final service = makeService(MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      actions.add(body['action'] as String);
      expect(request.url.path, '/api/auth');
      if (body['action'] == 'status') { return restore.future; }
      expect(body['display_name'], 'Pessoa');
      return http.Response(jsonEncode({'verified': false, 'pending': true, 'email': 'teste@example.com'}), 200);
    }));
    final signup = service.signUp('Pessoa', 'teste@example.com', 'password123');
    await Future<void>.delayed(Duration.zero);
    expect(actions, ['status']);
    restore.complete(http.Response('{"verified":false,"pending":false}', 200));
    expect(await signup, false);
    expect(actions, ['status', 'signup']);
    expect(service.needsVerification, true);
    expect(service.email, 'teste@example.com');
    expect(service.isSignedIn, false);
  });

  test('same device server approval logs in without showing OTP', () async {
    final service = makeService(MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'verified': body['action'] == 'login', 'pending': false, 'email': 'teste@example.com'}), 200);
    }));
    await service.signIn('teste@example.com', 'password123');
    expect(service.isSignedIn, true);
    expect(service.needsVerification, false);
  });

  test('mail failure still exposes pending verification and resend path', () async {
    final service = makeService(MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (body['action'] == 'status') { return http.Response('{"verified":false,"pending":false}', 200); }
      return http.Response('{"code":"email_delivery_failed","pending":true,"email":"teste@example.com"}', 503);
    }));
    await expectLater(service.signUp('Pessoa', 'teste@example.com', 'password123'),
      throwsA(isA<AuthException>().having((e) => e.code, 'code', 'email_delivery_failed')));
    expect(service.needsVerification, true);
    expect(service.isSignedIn, false);
  });

  test('HTML infrastructure errors are reported as service errors, not JSON/network errors', () async {
    final service = makeService(MockClient((_) async => http.Response('<html>Error</html>', 502)));
    await expectLater(service.signIn('teste@example.com', 'password123'),
      throwsA(isA<AuthException>().having((e) => e.code, 'code', 'service_unavailable')));
    expect(service.isSignedIn, false);
  });
}
