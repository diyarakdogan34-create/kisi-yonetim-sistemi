# Doğrulama sonuçları

Kontrol tarihi: 3 Kasım 2026. Python 3.14, Flutter 3.47.9, Dart 3.13.7, Android emülatörü `Medium_Phone_5` (Android 14 / API 34).

| Kontrol | Gerçek sonuç |
|---|---|
| `python -m pytest -q` | **18 geçti**. CRUD, camelCase sözleşmesi, JSON dizi, 201/204/404/422, geçersiz girişler, idempotent seed, geçici dosyada kalıcılık ve Swagger. |
| `python -m compileall app` | Başarılı. |
| `python -m pip check` | Bağımlılık çakışması yok. |
| `python -m app.seed` | İlk çalıştırmada 3 kayıt; tekrarında 0 yeni kayıt. |
| Canlı `GET /api/persons` | 200, üç örnek kişi içeren doğrudan JSON dizisi. |
| Canlı `/docs` | HTTP 200; OpenAPI şemasında beş REST işlemi. |
| `flutter pub get` | Başarılı. |
| `dart format lib test integration_test` | Başarılı, 10 Dart dosyası biçimlendirildi. |
| `flutter analyze` | **No issues found**. |
| `flutter test` | **14 geçti**. HTTP sözleşmesi, Türkçe karakterler, 404/422/500, bozuk yanıt, timeout, boş liste, yeniden deneme, ID ile detay, onaylı silme, kaydet kilidi, hata sonrası form değerleri, dar/dikey ve yatay ekran. |
| Android gerçek API testi | **1 geçti**. `integration_test/person_flow_test.dart`, mobil formdan POST → liste → ID GET → PUT → detay yenileme → silmeden vazgeç → DELETE → liste yenileme. Test kaydı temizlendi. |
| `flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000` | Başarılı. Son APK entegrasyon testinden sonra normal `lib/main.dart` hedefiyle yeniden üretildi. |
| APK kurulumu ve açılışı | Android emülatörüne kuruldu; canlı kişi listesi ve ağ fotoğrafları görüntülendi. |
| Telefon bağlantısı | Detaydaki telefon satırına dokununca Android Dialer uygulaması açıldı. Arama yapılmadı. |

## APK ve görsel kontrol

APK: `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`.

Yerel ekran görüntüleri: `mobile_app/build/kisi-listesi.png`, `mobile_app/build/kisi-detayi.png`. Build klasörü Git'e eklenmez. Liste görünümü emülatörde incelendi; iki ağ fotoğrafı ve bir baş harf avatarı doğru göründü. Liste/detay için 375×667 ve 667×375 boyutları ayrıca widget testinde kontrol edildi.

## Küçük ortam notları

- Python testlerinde Starlette'in `httpx` test istemcisi için bir kullanım dışı bırakma uyarısı var. 18 test başarılı; görevde istenen `httpx` korunmuştur.
- `dart format .` ilk kaynak oluşturma aşamasında çalıştı. Android derlemesinden sonra Windows'taki üretilmiş uzun `build/integration_test/.transforms/...` yolu nedeniyle bu genel komut dizin okuma hatası verdi. Son kaynak biçimlendirmesi `dart format lib test integration_test` ile başarılıdır; README bu daha dar komutu kullanır.
- İlk APK denemesi Gradle'ın doküman içeren `all` dağıtımını indirirken gecikti. Aynı sürümün derleme için yeterli `bin` dağıtımı seçildi; sonraki derleme başarılı oldu. Gradle sürümü 9.3.1 olarak kaldı.
- Veritabanı kalıcılığı, seed'in iki ayrı Python sürecinde aynı geçici dosyaya çalışması ve yeni engine ile verinin okunmasıyla test edildi. Çalışan demo sunucusunu kapat/aç ile manuel gösterme adımı sunum kontrol listesinde duruyor.

## Cihazda ayrıca denenmesi gerekenler

- Gerçek telefonda LAN IP'si ve Windows Güvenlik Duvarı bağlantısı.
- Gerçek telefonda e-posta hesabı ve telefon uygulamasıyla `mailto:` / `tel:` davranışı. Cihazda uygulama yoksa Türkçe hata gösterilir.
- TalkBack ile tam gezinme ve cihazın en büyük yazı ayarında bütün form alanlarının kontrolü.
- Yerel HTTP yalnızca debug yapılandırmasındadır; release/HTTPS dağıtımı bu ders projesinin kapsamı değildir.

## GitHub hazırlığı

Kaynaklar, README, sunum notları ve bağımlılık kilit dosyaları hazır. `.gitignore` sanal ortamı, veritabanını, build çıktılarını, önbellekleri, `.env` dosyalarını ve imzalama anahtarlarını dışarıda tutar. Henüz uzak depo oluşturulmadı ve GitHub'a yükleme yapılmadı.
