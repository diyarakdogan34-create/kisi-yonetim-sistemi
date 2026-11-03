import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kisi_yonetim/main.dart';
import 'package:kisi_yonetim/models/person.dart';
import 'package:kisi_yonetim/screens/person_form_screen.dart';
import 'package:kisi_yonetim/services/person_api_service.dart';

const sample = Person(
  id: 1,
  fullName: 'Ayşe Kaya',
  department: 'Tasarım',
  photoUrl: '',
  birthPlace: 'İzmir',
  birthDate: '1998-07-21',
  email: 'ayse@example.com',
  phone: '+905551112233',
);

void main() {
  testWidgets('Boş liste ve form doğrulaması', (tester) async {
    final api = PersonApiService(
      client: MockClient((_) async => http.Response('[]', 200)),
    );
    addTearDown(api.close);
    await tester.pumpWidget(PersonApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('Rehberiniz sizi bekliyor'), findsOneWidget);
    await tester.tap(find.text('İlk Kişiyi Ekle'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Kaydet'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Telefon 7–15 rakam içermelidir.'), findsOneWidget);
    expect(find.text('Doğum tarihi seçin.'), findsOneWidget);
  });

  testWidgets('Ağ hatası ve yeniden deneme', (tester) async {
    var calls = 0;
    final api = PersonApiService(
      client: MockClient((_) async {
        if (++calls == 1) throw http.ClientException('offline');
        return http.Response('[]', 200);
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(PersonApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('Bağlantı kurulamadı'), findsOneWidget);
    await tester.tap(find.text('Yeniden Dene'));
    await tester.pumpAndSettle();
    expect(find.text('Rehberiniz sizi bekliyor'), findsOneWidget);
  });

  testWidgets(
    'ID ile detay, silmeden vazgeçme ve silme sonrası liste yenileme',
    (tester) async {
      var deleted = false;
      var details = 0;
      final api = PersonApiService(
        client: MockClient((request) async {
          if (request.method == 'DELETE') {
            deleted = true;
            return http.Response('', 204);
          }
          if (request.url.path.endsWith('/1')) {
            details++;
            return http.Response(
              jsonEncode({...sample.toJson(), 'id': 1}),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response(
            jsonEncode(
              deleted
                  ? []
                  : [
                      {...sample.toJson(), 'id': 1},
                    ],
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(PersonApp(api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ayşe Kaya'));
      await tester.pumpAndSettle();
      expect(details, 1);
      expect(find.text('21.07.1998'), findsOneWidget);
      await tester.tap(find.text('KİŞİYİ SİL'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(deleted, false);
      await tester.tap(find.text('KİŞİYİ SİL'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
      expect(deleted, true);
      expect(find.text('Rehberiniz sizi bekliyor'), findsOneWidget);
    },
  );

  testWidgets('Kaydet kilitlenir ve hata sonrasında bilgiler korunur', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    var requests = 0;
    final api = PersonApiService(
      client: MockClient((request) {
        requests++;
        return response.future;
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: PersonFormScreen(api: api, person: sample),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Kaydet'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    expect(find.text('Kaydediliyor…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(requests, 1);
    response.complete(http.Response('server error', 500));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sunucuda bir sorun'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('Ad-Soyad')),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('Ad-Soyad')))
          .controller!
          .text,
      'Ayşe Kaya',
    );
  });

  for (final size in [const Size(375, 667), const Size(667, 375)]) {
    testWidgets('Küçük ekran ve büyük yazı: $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = PersonApiService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode([
              {...sample.toJson(), 'id': 1},
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: const TextScaler.linear(1.5),
          ),
          child: PersonApp(api: api),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Ayşe Kaya'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
