# Kişi Yönetim Sistemi

Mobil Programlama vize projesi: Türkçe Flutter Android uygulaması, bağımsız FastAPI REST sunucusu ve SQLite veritabanı. Listeleme, ID ile detay, ekleme, tüm alanlarla düzenleme ve onaylı silme içerir. E-posta ve telefon satırları cihazdaki ilgili uygulamayı açar.

## Mimari

`Flutter ekranı → PersonApiService → HTTP/JSON → FastAPI → SQLModel Session → SQLite`

Yanıt aynı yolun tersinden `Person.fromJson` ile modele çevrilir ve `setState` ile ekrana yansır. Kullanıcı bilgileri mobilde sabit bir listeye yazılmaz. `setState`, `Navigator`, `http` ve `url_launcher` kullanılır; ek durum yönetimi veya kimlik doğrulama katmanı yoktur.

## Gereken araçlar

- Python 3.11+ (bu bilgisayarda 3.14 ile test edildi).
- Flutter 3.47.9 / Dart 3.13.7 veya uyumlu yeni sürüm; projenin Dart alt sınırı 3.13.7.
- Android Studio, Android SDK ve bir emülatör veya USB hata ayıklaması açık Android telefon.
- Git yalnızca sürüm kontrolü/GitHub aşamasında gerekir.

`flutter --version`, `flutter doctor` ve `flutter devices` ile ortamı kontrol edin. Flutter `bin` klasörü PATH üzerinde olmalıdır. Gerekirse SDK yolunuzu açık terminale ekleyin:

```powershell
$flutterSdk = Read-Host 'Flutter SDK klasörünün tam yolu (bin klasörü hariç)'
$env:Path = "$flutterSdk\bin;$env:Path"
```

Bu ayar yalnızca açık terminali etkiler.

## 1. Sunucuyu çalıştırın — Windows PowerShell

Proje kökünden:

```powershell
cd backend_api
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m app.seed
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Aktivasyon engellenirse sistem politikasını değiştirmeniz gerekmez; doğrudan sanal ortam Python'unu kullanın:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m app.seed
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Sonraki açılışlarda kurulum gerekmez. Proje kökündeki yardımcı komut da aynı işlemi yapar:

```powershell
.\sunucu-baslat.ps1
```

Sunucu terminalini açık bırakın; `Ctrl+C` ile durdurulur. Port zaten kullanılıyorsa ikinci sunucu açmayın; önce mevcut sunucuyu kontrol edin.

- [Swagger /docs](http://127.0.0.1:8000/docs): beş API işlemini **Try it out** ile deneyin.
- [Kişi listesi](http://127.0.0.1:8000/api/persons): doğrudan `[...]` JSON dizisi.

`python -m app.seed` tabloları oluşturur ve üç örnek kişi ekler. Tekrar çalıştırıldığında aynı e-posta adresine sahip örnek kişileri çoğaltmaz. Varsayılan veritabanı `backend_api/persons.db` dosyasıdır; sunucuyu hangi dizinden başlattığınıza bağlı değişmez. İsteğe bağlı `DATABASE_URL` başka bir SQLite dosyasını seçebilir. Örnek: `$env:DATABASE_URL = 'sqlite:///C:/temp/persons-demo.db'` (üst klasör mevcut olmalı). Varsayılan ayara dönüş: `Remove-Item Env:DATABASE_URL`.

Linux/macOS farkı: `python3 -m venv .venv`, ardından `source .venv/bin/activate`. Diğer Python komutları aynıdır.

## 2. Mobil uygulamayı çalıştırın — ikinci terminal

Android Studio > Device Manager üzerinden bir emülatör başlatın. Alternatif: `flutter emulators`, ardından `flutter emulators --launch EMULATOR_ID`.

Proje kökünden:

```powershell
cd mobile_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Birden fazla cihaz varsa `flutter devices` listesinden Android kimliğini alıp `-d emulator-5554` gibi bir seçenek ekleyin. Bu proje Android için hazırlanmıştır; tarayıcı hedefi seçmeyin.

Android emülatöründe `10.0.2.2` ana bilgisayarı gösterir. Telefonun veya emülatörün `127.0.0.1` adresi kendi cihazıdır, bilgisayar değildir.

### Fiziksel Android telefon

Bilgisayar ve telefon aynı Wi-Fi ağında olsun. `ipconfig` ile etkin Wi-Fi adaptörünün gerçek IPv4 adresini bulun. Aşağıdaki komut adresi sizden alır:

```powershell
$bilgisayarIp = Read-Host 'Bilgisayarın Wi-Fi IPv4 adresi'
flutter run --dart-define=API_BASE_URL=http://${bilgisayarIp}:8000
```

Sunucu `--host 0.0.0.0` ile dinlemelidir. Windows Güvenlik Duvarı bağlantıyı engellerse Python/8000 erişimini yalnızca güvenilir özel ağ için etkinleştirin; güvenlik duvarını tamamen kapatmayın. VPN, misafir Wi-Fi ve istemci izolasyonu da bağlantıyı kesebilir. Önce telefon tarayıcısından `http://GERCEK_IP:8000/api/persons` adresini deneyin. IP değişirse mobil uygulamayı yeni `--dart-define` ile yeniden başlatın/derleyin.

### Android HTTP geliştirme ayarı

`android/app/src/main/AndroidManifest.xml` internet iznini taşır. `src/debug/AndroidManifest.xml` içinde `usesCleartextTraffic="true"` yalnızca **debug** derlemesinde yerel HTTP'ye izin verir. Release için bu izin verilmez; dağıtımda HTTPS gerekir. `0.0.0.0` sunucuyu LAN'da erişilebilir yapar; geliştirme sunucusunu internete yönlendirmeyin. Native Flutter için CORS eklenmemiştir.

## API sözleşmesi

| Metot | Yol | Sonuç |
|---|---|---|
| GET | `/api/persons` | 200, doğrudan kişi dizisi |
| GET | `/api/persons/{id}` | 200, kişi |
| POST | `/api/persons` | 201, oluşturulan kişi |
| PUT | `/api/persons/{id}` | 200, güncellenen kişi |
| DELETE | `/api/persons/{id}` | 204, boş gövde |

Yolların sonunda `/` yoktur. Bulunmayan kayıt `404`; geçersiz veya eksik giriş `422` döndürür. `422` yanıtındaki `detail` listesi Türkçe mesaj içerir. `PUT` kısmi güncelleme değildir; formun tüm zorunlu alanlarını ister. Ad-soyad 2–100, departman/doğum yeri 1–100 karakter, telefon 7–15 rakam olmalıdır. Doğum tarihi 1900–bugün aralığında geçerli bir ISO tarihtir. E-posta Pydantic `EmailStr` ile doğrulanır. Fotoğraf isteğe bağlıdır; bozuk bağlantıda baş harf avatarı görünür.

POST/PUT gövdesi (`id` gönderilmez):

```json
{
  "fullName": "Ayşe Kaya",
  "department": "İnsan Kaynakları",
  "photoUrl": "",
  "birthPlace": "İstanbul",
  "birthDate": "1998-07-21",
  "email": "ayse.kaya@sirket.com",
  "phone": "+905551112233"
}
```

GET kişi, POST ve PUT yanıtı aynı alanlara backend'in ürettiği `"id": 1` gibi bir tamsayı ekler. GET liste örneği:

```json
[{"id":1,"fullName":"Ayşe Kaya","department":"İnsan Kaynakları","photoUrl":"","birthPlace":"İstanbul","birthDate":"1998-07-21","email":"ayse.kaya@sirket.com","phone":"+905551112233"}]
```

### PowerShell ile gerçek CRUD denemesi

Sunucu açıkken ayrı terminalde çalıştırın. Bu akış yalnızca kendi oluşturduğu deneme kaydını siler:

```powershell
$api = 'http://127.0.0.1:8000/api/persons'
Invoke-RestMethod $api
$kisi = @{
  fullName = 'Deneme Kişisi'; department = 'Yazılım'; photoUrl = ''
  birthPlace = 'Ankara'; birthDate = '2000-05-10'
  email = 'deneme@example.com'; phone = '+905551234567'
}
$body = [Text.Encoding]::UTF8.GetBytes(($kisi | ConvertTo-Json))
$kayit = Invoke-RestMethod $api -Method Post -ContentType 'application/json; charset=utf-8' -Body $body
Invoke-RestMethod "$api/$($kayit.id)"
$kisi.department = 'Ürün Tasarımı'
$body = [Text.Encoding]::UTF8.GetBytes(($kisi | ConvertTo-Json))
Invoke-RestMethod "$api/$($kayit.id)" -Method Put -ContentType 'application/json; charset=utf-8' -Body $body
Invoke-RestMethod "$api/$($kayit.id)" -Method Delete
# Aşağıdaki istek artık beklenen 404 hatasını verir:
Invoke-RestMethod "$api/$($kayit.id)"
```

## Test ve APK

Backend klasöründe, sanal ortam etkin durumdayken:

```powershell
python -m pytest -q
python -m compileall app
```

Testler geçici SQLite dosyası ve dependency override kullanır; uygulama başlangıcı da test DB'sine yönlendirilir. Geliştirme veritabanına dokunulmaz. `requirements-lock.txt`, doğrulama sırasında çözülen tam Python sürümlerini tutar; aynı ortam için `python -m pip install -r requirements-lock.txt` kullanılabilir. Flutter bağımlılıkları `pubspec.lock` ile sabittir.

Mobil klasöründe:

```powershell
flutter pub get
dart format lib test integration_test
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Sunucu ve Android emülatörü açıkken gerçek uçtan uca test:

```powershell
flutter test integration_test/person_flow_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Bu test mobil formdan geçici bir kişi oluşturur, düzenler, silmeden vazgeçer ve sonra siler; yalnızca kendi oluşturduğu kaydı temizler. Mevcut kişilere dokunmaz. Cihaz ID'sini `flutter devices` çıktısına göre değiştirin. Entegrasyon testi APK çıktısını test uygulamasıyla değiştirebildiği için teslim APK'sını **testten sonra** normal `flutter build apk --debug` komutuyla yeniden üretin.

APK: `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`. Bu APK emülatördeki sunucu adresiyle derlenir. **Gerçek telefon için `10.0.2.2` kullanılamaz**; `--dart-define=API_BASE_URL=http://GERCEK_LAN_IP:8000` ile yeniden derleyin.

## Dosyalar

| Dosya | Görevi |
|---|---|
| `backend_api/app/main.py` | Lifespan, beş REST işlemi, Türkçe 422 ve 404 |
| `backend_api/app/database.py` | Sabit DB yolu, engine, istek başına session |
| `backend_api/app/models.py` | Tablo, giriş/çıkış şemaları ve doğrulamalar |
| `backend_api/app/seed.py` | Üç örnek kaydı tekrar üretmeden ekler |
| `backend_api/tests/test_persons.py` | İzole API, seed ve kalıcılık testleri |
| `mobile_app/lib/main.dart` | Material 3 teması ve Türkçe yerelleştirme |
| `mobile_app/lib/models/person.dart` | JSON dönüşümü, tarih görünümü |
| `mobile_app/lib/services/person_api_service.dart` | HTTP işlemleri, timeout ve Türkçe API hataları |
| `mobile_app/lib/screens/person_list_screen.dart` | Liste, yenileme, boş/hatalı/yükleniyor durumları |
| `mobile_app/lib/screens/person_detail_screen.dart` | ID ile GET, iletişim bağlantıları, onaylı silme |
| `mobile_app/lib/screens/person_form_screen.dart` | Ortak ekleme/düzenleme formu ve doğrulama |
| `mobile_app/lib/widgets/person_avatar.dart` | Ağ fotoğrafı, bozuk/boş fotoğraf için baş harfler |
| `mobile_app/test/` | HTTP sözleşmesi, hata, ekran ve etkileşim testleri |
| `SUNUM_NOTLARI.md` | Kod savunması, sorular, canlı değişiklik alıştırmaları |
| `DOGRULAMA.md` | Gerçek kontrol sonuçları ve kalan manuel kontroller |

## Sunumdan önce

- Sunucu ve emülatörü açın; `/docs` ve liste GET'ini kontrol edin.
- Liste → detay → ekle → düzenle → silme diyaloğunda Vazgeç → Sil akışını deneyin.
- E-posta ve telefon uygulamalarının cihazda mevcut olduğundan emin olun.
- Backend'i kapatıp listede yeniden deneyin; anlaşılır hata görünmeli.
- Sunucuyu yeniden başlatınca önceki kayıtların kaldığını gösterin.
- Uzak avatar sunucusu internet ister; internetsiz durumda baş harf avatarı normaldir.
- `SUNUM_NOTLARI.md` içindeki soruları ve sekiz canlı müdahaleyi çalışın.

GitHub deposu: [diyarakdogan34-create/kisi-yonetim-sistemi](https://github.com/diyarakdogan34-create/kisi-yonetim-sistemi). `.gitignore` veritabanını, sanal ortamı, yerel ayarları, imzalama anahtarlarını ve derleme çıktılarını dışarıda tutar. APK repoya eklenmez; yukarıdaki komutla üretilir.

Teknik kaynaklar: [Flutter kurulum](https://docs.flutter.dev/install/manual), [SQLModel test rehberi](https://sqlmodel.tiangolo.com/tutorial/fastapi/tests/), [FastAPI SQL veritabanı](https://fastapi.tiangolo.com/tutorial/sql-databases/), [url_launcher](https://pub.dev/packages/url_launcher).
