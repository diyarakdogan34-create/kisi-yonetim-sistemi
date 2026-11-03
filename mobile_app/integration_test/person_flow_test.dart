import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kisi_yonetim/main.dart';
import 'package:kisi_yonetim/services/person_api_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gerçek API ile ekle, düzenle, vazgeç ve sil', (tester) async {
    final api = PersonApiService();
    final name = 'Test ${DateTime.now().millisecondsSinceEpoch}';
    final changedName = '$name Güncel';
    int? createdId;
    final formScroll = find.byType(Scrollable).first;

    Future<void> fill(String label, String value) async {
      final field = find.byKey(ValueKey(label));
      await tester.scrollUntilVisible(field, 180, scrollable: formScroll);
      await tester.enterText(field, value);
      await tester.pumpAndSettle();
    }

    try {
      await tester.pumpWidget(PersonApp(api: api));
      await tester.pumpAndSettle();
      expect(find.text('Kişi Listesi'), findsOneWidget);
      await tester.tap(find.text('Yeni Kişi'));
      await tester.pumpAndSettle();
      await fill('Ad-Soyad', name);
      await fill('Departman', 'Test Departmanı');
      await fill('Doğum Yeri', 'Ankara');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('Doğum Tarihi')),
        180,
        scrollable: formScroll,
      );
      await tester.tap(find.byKey(const ValueKey('Doğum Tarihi')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();
      await fill('E-posta', 'integration@example.com');
      await fill('Telefon', '+905551234567');
      await tester.scrollUntilVisible(
        find.text('Kaydet'),
        180,
        scrollable: formScroll,
      );
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      final created = (await api.getPersons()).singleWhere(
        (p) => p.fullName == name,
      );
      createdId = created.id;
      await tester.scrollUntilVisible(
        find.text(name),
        180,
        scrollable: formScroll,
      );
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      expect(find.text('Kişi Detayı'), findsOneWidget);
      expect(find.text('Test Departmanı'), findsOneWidget);
      await tester.tap(find.text('DÜZENLE'));
      await tester.pumpAndSettle();
      await fill('Ad-Soyad', changedName);
      await tester.scrollUntilVisible(
        find.text('Kaydet'),
        250,
        scrollable: formScroll,
      );
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      expect(find.text(changedName), findsOneWidget);
      expect((await api.getPersonById(createdId!)).fullName, changedName);
      await tester.tap(find.text('KİŞİYİ SİL'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect((await api.getPersonById(createdId)).fullName, changedName);
      await tester.tap(find.text('KİŞİYİ SİL'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
      expect(find.text('Kişi Listesi'), findsOneWidget);
      expect((await api.getPersons()).where((p) => p.id == createdId), isEmpty);
      createdId = null;
    } finally {
      // Yalnızca bu testin kendi oluşturduğu kaydı temizle.
      final remaining = await api.getPersons();
      for (final p in remaining.where(
        (p) => p.fullName == name || p.fullName == changedName,
      )) {
        await api.deletePerson(p.id!);
      }
      api.close();
    }
  });
}
