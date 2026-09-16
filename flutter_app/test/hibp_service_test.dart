import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexpass/services/hibp_service.dart';

/// P1-7c: HIBP k-anonymity client. Network is fully mocked — no live calls.
void main() {
  // SHA-1('password') = 5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8
  const kPrefix = '5BAA6';
  const kSuffix = '1E4C9B93F3F0682250B6CF8331B7EE68FD8';

  MockClient clientReturning(String body, {int status = 200}) {
    return MockClient((request) async {
      expect(request.url.toString(),
          'https://api.pwnedpasswords.com/range/$kPrefix');
      expect(request.headers['Add-Padding'], 'true');
      return http.Response(body, status);
    });
  }

  group('breach lookup', () {
    test('returns count when suffix matches (case-insensitive)', () async {
      final service = HibpService(
        client: clientReturning('${kSuffix.toLowerCase()}:2454662\n'
            'A1B2C3D4E5F60718293A4B5C6D7E8F90123:7\n'),
      );
      expect(await service.breachCount('password'), 2454662);
    });

    test('returns 0 when suffix is absent', () async {
      final service = HibpService(
        client: clientReturning('A1B2C3D4E5F60718293A4B5C6D7E8F90123:7\n'),
      );
      expect(await service.breachCount('password'), 0);
    });

    test('returns null on non-200 status', () async {
      final service = HibpService(
        client: clientReturning('error', status: 503),
      );
      expect(await service.breachCount('password'), isNull);
    });

    test('returns null on transport failure', () async {
      final service = HibpService(
        client: MockClient((_) async => throw const SocketExceptionShim()),
      );
      expect(await service.breachCount('password'), isNull);
    });

    test('empty password short-circuits without a request', () async {
      var calls = 0;
      final service = HibpService(
        client: MockClient((_) async {
          calls++;
          return http.Response('', 200);
        }),
      );
      expect(await service.breachCount(''), isNull);
      expect(calls, 0);
    });
  });
}

/// Stand-in for SocketException (dart:io unavailable in some test runners).
class SocketExceptionShim implements Exception {
  const SocketExceptionShim();
}
