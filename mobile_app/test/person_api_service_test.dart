import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kisi_yonetim/models/person.dart';
import 'package:kisi_yonetim/services/person_api_service.dart';

const person = Person(
  id: 42,
  fullName: 'Çağrı Şen',
  department: 'Yazılım',
  photoUrl: '',
  birthPlace: 'İzmir',
  birthDate: '1995-03-24',
  email: 'cagri@example.com',
  phone: '+905550123456',
);

void main() {
  test(
    'JSON alanları, Türkçe karakterler, HTTP metotları ve ID sözleşmesi',
    () async {
      final requests = <String>[];
      final api = PersonApiService(
        baseUrl: 'http://localhost:8000/',
        client: MockClient((request) async {
          requests.add('${request.method} ${request.url.path}');
          expect(request.url.path.endsWith('/'), false);
          if (request.method == 'DELETE') return http.Response('', 204);
          if (['POST', 'PUT'].contains(request.method)) {
            final body = jsonDecode(request.body) as Map;
            expect(body.containsKey('id'), false);
            expect(body.keys.toSet(), person.toJson().keys.toSet());
            expect(body['fullName'], 'Çağrı Şen');
          }
          final data = {...person.toJson(), 'id': 42};
          return http.Response(
            jsonEncode(
              request.method == 'GET' && request.url.path == '/api/persons'
                  ? [data]
                  : data,
            ),
            request.method == 'POST' ? 201 : 200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);
      expect((await api.getPersons()).single.fullName, 'Çağrı Şen');
      expect((await api.getPersonById(42)).displayBirthDate, '24.03.1995');
      expect((await api.createPerson(person)).id, 42);
      expect((await api.updatePerson(42, person)).id, 42);
      await api.deletePerson(42);
      expect(requests, [
        'GET /api/persons',
        'GET /api/persons/42',
        'POST /api/persons',
        'PUT /api/persons/42',
        'DELETE /api/persons/42',
      ]);
    },
  );

  for (final status in [404, 422, 500]) {
    test('HTTP $status Türkçe hataya dönüşür', () async {
      final api = PersonApiService(
        client: MockClient((_) async => http.Response('', status)),
      );
      addTearDown(api.close);
      await expectLater(api.getPersonById(1), throwsA(isA<ApiException>()));
    });
  }

  for (final body in ['not json', '{}', '[{"id":1}]']) {
    test('Bozuk sunucu yanıtı: $body', () async {
      final api = PersonApiService(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(api.close);
      await expectLater(api.getPersons(), throwsA(isA<ApiException>()));
    });
  }

  test('Zaman aşımı', () async {
    final api = PersonApiService(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    addTearDown(api.close);
    await expectLater(
      api.getPersons(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mesaj',
          contains('zamanında'),
        ),
      ),
    );
  });
}
