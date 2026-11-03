# Canlı kod savunması ve sunum notları

Bu notlar bu depodaki Flutter + FastAPI + SQLModel koduna aittir. Sunum: **4 Kasım 2026 Çarşamba 13.00**. Amaç yalnızca ekran göstermek değil, verinin hangi satırlardan geçtiğini açıklayabilmektir.

## 1. Liste verisi nereden geliyor?

1. `mobile_app/lib/main.dart` içindeki `main()` → `PersonApp` uygulamayı açar. Türkçe Material bileşenleri ve mavi tema burada kurulur.
2. `PersonListScreen` oluşturulunca `_PersonListScreenState.initState()` bir kez çalışır ve `_loadPersons()` çağırır.
3. `_loadPersons()` yüklenme durumunu açar. `await widget.api.getPersons()` bitene kadar ekranın ana akışı kilitlenmez; progress görünür.
4. `person_api_service.dart` içindeki `getPersons()`, `_request('GET', '/api/persons', 200)` çağırır. `http.Client` sunucuya HTTP isteği gönderir.
5. `backend_api/app/main.py` içindeki `@app.get('/api/persons')` bu isteği `get_persons()` fonksiyonuna yönlendirir.
6. `Depends(get_session)` bu istek için bir SQLModel `Session` sağlar. `select(Person).order_by(Person.id)` sorgusu SQLite verilerini alır.
7. FastAPI `response_model=list[PersonRead]` sayesinde kayıtları JSON dizisi olarak yollar. İçinde `results` gibi bir sarmalayıcı yoktur.
8. Mobilde `utf8.decode` Türkçe karakterleri korur; `jsonDecode` JSON metnini Dart listesine çevirir. Her öğe `Person.fromJson` ile kişi nesnesi olur.
9. `_loadPersons()` sonucu `_persons` alanına atar. `mounted` kontrolü ekranın hâlâ açık olduğunu doğrular. `setState` ekranı günceller.
10. `ListView.builder` görünür satırları üretir; `PersonAvatar`, ad-soyad ve departman ekranda yer alır.

Bir kişiye dokunulunca `_openPerson()` yalnızca ID'yi detay ekranına taşır. Detaydaki `initState → _loadPerson → getPersonById(id)` zinciri yeni bir **GET /api/persons/{id}** yapar. Eski liste nesnesine güvenilmez.

## 2. Ekleme, düzenleme ve silme akışı

**Ekleme:** FAB → `_openForm()` → `PersonFormScreen` → `Form.validate()` → `_save()` → `createPerson()` → POST. `Person.toJson()` ID içermez. Backend `PersonCreate` ile doğrular, `Person` kaydını oluşturur, `session.add`, `commit`, `refresh` yapar. **201** ve üretilen ID döner. Form `Navigator.pop(context, true)` ile başarı bildirir; liste yeniden GET yapar.

**Düzenleme:** Detay `_editPerson()` ile aynı formu mevcut `Person` ile açar. Formun `initState` fonksiyonu alanları doldurur. `_save()` bu kez `updatePerson()` ile **PUT** yapar. Backend bütün zorunlu alanları doğrular, mevcut kaydı bulur, alanları değiştirir, commit eder. **200** döner. Form kapanınca detay yeniden GET yapar. Detaydan listeye dönünce liste de yeniden GET yapar.

**Silme:** Detay `_deletePerson()` önce `showDialog` gösterir. `Vazgeç` false döndürür ve hiçbir DELETE yapılmaz. `Sil` true döndürür; `deletePerson(id)` çalışır. Backend kaydı bulup `session.delete` ve `commit` yapar; **204 ve boş gövde** döndürür. Mobil boş gövdeyi JSON olarak çözmeye çalışmaz. Detay kapanır, liste GET ile yenilenir.

**Hata:** Ağ/timeout/404/422/500 servis katmanında `ApiException` olur. Ekranlar `try/catch` ile Türkçe mesaj gösterir. Form başarısız işlemde kapanmaz, controller değerleri korunur. `_saving` peş peşe kaydı ve kayıt sürerken geri çıkmayı engeller. Silme sırasında da eylemler kilitlidir.

## 3. Kavramlar ve projedeki karşılıkları

| Kavram | Projede ne anlama gelir? |
|---|---|
| `async` | `_loadPersons`, `_save` gibi beklemeli işlemler içeren fonksiyonu tanımlar. |
| `await` | Ağ yanıtı gelmeden ona bağlı sonraki satıra geçmez; arayüz iş parçacığını bloke etmez. |
| `Future<T>` | Sonradan tamamlanacak değer; `Future<List<Person>>` kişi listesini vaat eder. |
| `try/catch` | `ApiException` yakalanıp ekranda hata mesajına çevrilir. |
| `setState` | State içindeki yüklenme/veri/hata değişikliğinden sonra widget'ın yeniden çizilmesini ister. |
| `initState` | State ilk oluştuğunda çalışır; ilk GET burada başlar, `build` içinde başlamaz. |
| `mounted` | Ağ beklenirken ekran kapanmışsa `setState`/navigasyon yapılmasını önler. |
| `Navigator` | `push` ile ekran açar, `pop` ile geri döner; formun true sonucu yenilemeyi tetikler. |
| `Form` | Alanların doğrulamasını `GlobalKey<FormState>` üzerinden birlikte çalıştırır. |
| `TextFormField` | Controller, etiket, klavye türü ve validator içeren form alanıdır. |
| `ListView.builder` | Kişi satırlarını ihtiyaç oldukça üretir; kaydırılabilir liste sağlar. |
| `jsonDecode/jsonEncode` | JSON metnini Dart yapılarına / Dart map'ini JSON metnine çevirir. |
| `http` | REST çağrılarını yapar; yanıtın gövdesini ve durum kodunu sağlar. |
| `url_launcher` | Detayda `tel:` / `mailto:` URI'sini cihazdaki uygun uygulamaya verir. |
| FastAPI | HTTP rotalarını, giriş doğrulamasını ve JSON yanıtlarını yönetir. |
| Uvicorn | Ağ portunu dinleyip gelen HTTP isteklerini FastAPI uygulamasına ileten ASGI sunucusudur. |
| `@app.get/post/put/delete` | URL ve HTTP metodunu bir Python fonksiyonuna bağlayan dekoratörlerdir. |
| Pydantic | `PersonCreate` üzerinde e-posta, tarih ve diğer giriş doğrulamalarını yürütür. |
| SQLModel | Pydantic + SQLAlchemy üzerine kurulur; hem veri şemalarını hem tablo modelini tanımlar. |
| `Depends` | İstek için `get_session` bağımlılığını çalıştırıp parametreye sonucu verir. |
| `Session` | Veritabanı sorgularını ve değişikliklerini bir işlem bağlamında yürütür. |
| `commit` | Bekleyen değişiklikleri veritabanına kalıcı olarak yazar. |
| `refresh` | Commit sonrası üretilen ID dahil veritabanındaki son değerleri nesneye geri alır. |
| `HTTPException` | Bulunamayan kişi için 404 ve açıklayıcı mesajla isteği sonlandırır. |
| SQLite | Ayrı sunucu kurmadan `.db` dosyasında kalıcı veri tutan ilişkisel veritabanıdır. |
| ORM | `Person` nesnesi ve SQL tablosu arasında eşleme yapar; çoğu işlemde elle SQL yazmayı azaltır. |
| `/docs` | FastAPI'nin OpenAPI şemasından oluşturduğu etkileşimli Swagger arayüzüdür. |
| Lifespan | Sunucu başlangıcında tabloları oluşturur; her istekte tablo kurmaz. |

## 4. Dosya dosya açıklama

### Backend

- `app/database.py`: `DB_PATH`, dosyanın konumundan hesaplanır. `engine` bağlantı altyapısıdır. `create_db_and_tables()` yoksa tabloları oluşturur. `get_session()` yield ile oturum verir, blok bitince kapatır.
- `app/models.py`: `PersonBase` ortak alanlardır. `Person(..., table=True)` veritabanı tablosudur; ID primary key'dir. `PersonCreate` giriş doğrulamasını ekler ve fazladan alanları reddeder. `PersonUpdate`, PUT için aynı zorunlu alanları kullanır. `PersonRead` yanıtın ID'sini zorunlu kılar. `trim_text`, `iso_date_only`, `valid_birth_date`, `valid_phone` doğrudan anlaşılır doğrulayıcılardır. JSON sözleşmesi kolay anlatılsın diye camelCase adlar kullanılır.
- `app/main.py`: `lifespan` başlangıcı, `validation_error` Türkçe 422, `find_person` ortak 404 kontrolü ve beş endpoint. `update_person` alanları `model_dump()` ile dolaşır; keyfi istek alanları modele alınmadığı için sadece izin verilen alanlar yazılır.
- `app/seed.py`: `seed_persons(session)` her örneği e-posta üzerinden kontrol eder, yoksa ekler. CLI bloğu tabloları da oluşturduğu için sunucudan önce çalışabilir.
- `tests/test_persons.py`: Geçici dosya engine'i ve `app.dependency_overrides` ile gerçek DB'yi izole eder. Lifespan'ın kullandığı engine de değiştirilir. Seed komutu iki ayrı süreçte çalıştırılarak idempotans ve dosya kalıcılığı doğrulanır.

### Flutter

- `lib/main.dart`: `PersonApp.build` tema, yerelleştirme ve ilk ekranı kurar. Testlerde sahte HTTP istemcisi kullanan servis verilebilir; normal çalışmada gerçek servis kullanılır.
- `lib/models/person.dart`: `fromJson`, `toJson`, `displayBirthDate`. Ekran gösterimi `GG.AA.YYYY`, ağ verisi `YYYY-MM-DD`.
- `lib/services/person_api_service.dart`: `defaultBaseUrl` derleme parametresidir. `_request` metot, URL, gövde, durum kodu ve timeout kontrolünü bir yerde tutar. `_person` bozuk JSON nesnesini kullanıcı dostu hataya dönüştürür. Beş public metot beş API işlemine karşılık gelir.
- `lib/screens/person_list_screen.dart`: `_loadPersons`, `_openForm`, `_openPerson`, `_message` ve `build`. Başarılı dönüşlerden sonra veriyi yeniden istemek eski bilgiyi önler.
- `lib/screens/person_detail_screen.dart`: `_loadPerson` ID bazlı GET, `_infoRow` bilgi satırı, `_launchContact` dış uygulama, `_editPerson` ortak form, `_deletePerson` onay ve DELETE.
- `lib/screens/person_form_screen.dart`: `initState` düzenleme değerlerini doldurur; `_pickDate` gerçek takvim açar; `_field` tekrar eden alan görünümünü azaltır; `_save` ekleme/düzenlemeyi seçer; `dispose` controller kaynaklarını bırakır.
- `lib/widgets/person_avatar.dart`: `build`, geçerli HTTP(S) URL varsa resmi yükler. Boş/bozuk URL veya indirme hatasında baş harfler görünür.
- `test/person_api_service_test.dart` HTTP sözleşmesi ve hata dönüşümünü; `test/widget_test.dart` ekran durumları, silme onayı, kaydet kilidi ve küçük ekranı test eder.

## 5. Muhtemel sözlü soruları

1. **REST nedir?** Kaynakları URL ile temsil edip standart HTTP metotlarıyla işlem yapan mimari yaklaşımdır; kaynağımız kişidir.
2. **Neden JSON?** Dil bağımsız, okunabilir ve Flutter/Python arasında kolay dönüştürülen veri biçimidir.
3. **GET ve POST farkı?** GET veriyi okur; POST yeni kayıt oluşturur. GET bu projede veritabanını değiştirmez.
4. **PUT ve PATCH farkı?** PUT tüm zorunlu alanlarıyla günceller; PATCH yalnızca değişen alanları kabul edebilir. Projede PUT var.
5. **200 nedir?** Başarılı GET veya PUT yanıtıdır.
6. **201 nedir?** Yeni kaynak oluşturulmuştur; POST'ta kullanılır.
7. **204 nedir?** İşlem başarılıdır, yanıt gövdesi yoktur; DELETE'te kullanılır.
8. **404 nedir?** İstenen ID'ye sahip kişi bulunmamıştır.
9. **422 nedir?** JSON anlaşılmış olsa bile beklenen şemaya/değerlere uymamaktadır.
10. **10.0.2.2 nedir?** Android Studio emülatöründen ana bilgisayarın loopback ağına erişmek için özel adrestir.
11. **Neden async/await?** Ağ yanıtını beklerken arayüzün işlemeye devam etmesini sağlar; bağımlı adımlar sırayla yürür.
12. **Future nedir?** İleride değer veya hata ile tamamlanacak asenkron işlemdir.
13. **Neden setState?** Veri değişince Flutter'ın ekranı yeniden oluşturmasını ister. Küçük uygulamaya yeterlidir.
14. **Neden GET'i build içinde çağırmıyoruz?** Build birçok kez çalışabilir; gereksiz ağ istekleri ve tekrar döngüsü oluşur.
15. **Neden SQLite?** Küçük ders projesinde kurulum gerektirmeden kalıcı ilişkisel veri sağlar.
16. **FastAPI ve Uvicorn aynı şey mi?** Hayır. FastAPI uygulama/route katmanı, Uvicorn bu uygulamayı ağda sunan ASGI sunucusudur.
17. **SQLModel ne yapar?** Python modelleriyle tablo, sorgu ve veri şemalarını ilişkilendirir.
18. **Pydantic doğrulaması neden gerekli?** İstemci doğrulaması atlanabilir; sunucu kendi aldığı veriyi daima denetlemelidir.
19. **Depends nasıl çalışır?** İstek işlenirken bağımlılık fonksiyonunu çağırır ve sonucunu route parametresine sağlar.
20. **Session nedir?** Sorgu ve değişiklikleri yürüten veritabanı çalışma bağlamıdır; istek bitince kapanır.
21. **Commit olmazsa ne olur?** Değişiklik kalıcı kayda geçmez; oturum kapanınca bekleyen işlem geri alınır.
22. **Refresh neden var?** Veritabanının ürettiği ID gibi değerleri bellekteki nesneye alır.
23. **HTTPException ne yapar?** Normal akışı kesip belirtilen HTTP hata kodunu ve mesajı döndürür.
24. **Swagger nasıl oluşur?** FastAPI route, parametre ve model bilgilerinden OpenAPI şemasını çıkarır; `/docs` bunu gösterir.
25. **Kişi ID'si neden gerekli?** Aynı isimde kişiler olabilir; detay, güncelleme ve silme doğru kayda ID ile ulaşır.
26. **ID'yi kullanıcı belirleyebilir mi?** Hayır. `toJson` ID göndermez, giriş şeması fazladan ID'yi reddeder, DB üretir.
27. **Sunucu kapalıysa ne olur?** Servis bağlantı/timeout hatasını Türkçe `ApiException` yapar; ekran yeniden deneme sunar.
28. **Fotoğraf bozuksa?** `Image.network.errorBuilder` baş harf avatarını gösterir.
29. **Silmeden vazgeçilirse?** Dialog false döndürür; `_deletePerson` DELETE çağrısına gelmeden çıkar.
30. **Kaydet'e iki kez basılırsa?** `_saving` hem butonu kapatır hem fonksiyonun yeniden işlem yapmasını engeller.
31. **Veriler sunucu kapanınca silinir mi?** Hayır, `persons.db` dosyasındadır. Testler ayrı geçici dosya kullanır.
32. **Mobil uygulamada CORS neden yok?** Native HTTP istemcisi tarayıcının same-origin kısıtına tabi değildir.
33. **Telefon aramasını uygulama doğrudan başlatır mı?** `tel:` URI'si cihazdaki telefon uygulamasını açar; kullanıcı orada işlem yapar.
34. **Testler gerçek kişileri siler mi?** Backend testleri geçici engine ve dependency override kullanır; gerçek veritabanından ayrıdır.
35. **Seed her açılışta kişi çoğaltır mı?** Hayır, aynı örnek e-posta zaten varsa atlar. Silinmiş örnek kişi seed tekrar çalışırsa yeniden eklenir.
36. **Neden sadece debug için HTTP?** Yerel sunucu HTTPS kullanmıyor. Bu geliştirme istisnası release manifestine konmamıştır.

## 6. Canlı kod müdahalesi alıştırmaları

Değişiklikten sonra `dart format lib` ve `flutter analyze` çalıştırın; `flutter run` açıkken `r` ile hot reload deneyin. API adresi gibi derleme sabitlerini değiştirirken uygulamayı yeniden başlatın.

| Alıştırma | Gerçek dosya / yer | Kısa çözüm |
|---|---|---|
| Kartta departman yerine telefon | `lib/screens/person_list_screen.dart`, `build`, `ListTile.subtitle` | `Text(person.department)` yerine `Text(person.phone)` yazın. |
| Sil onayının rengini değiştir | `lib/screens/person_detail_screen.dart`, `_deletePerson`, dialog `FilledButton` | `backgroundColor: Theme.of(context).colorScheme.error` kırmızıdır; başka tema rengi seçin. |
| Ekleme ikonunu/rengini değiştir | `lib/screens/person_list_screen.dart`, `build`, `FloatingActionButton.extended` | `Icons.add_rounded` yerine `Icons.person_add_alt_1`; `backgroundColor` ekleyin. |
| Ana başlığı değiştir | Aynı dosya, `build`, `AppBar.title` | `'Kişi Listesi'` metnini `'Şirket Rehberi'` yapın. |
| Ad-soyad yazısını büyüt | Aynı dosya, `ListTile.title` | `fontSize: 17` değerini `20` yapın; küçük ekranda kontrol edin. |
| Detayda doğum yerini kaldır/taşı | `lib/screens/person_detail_screen.dart`, `build`, bilgi `Card` | `'Doğum Yeri'` verilen `_infoRow` satırını ve bitişik Divider'ı kaldırın veya tarih altına taşıyın. |
| Boş liste mesajını değiştir | `lib/screens/person_list_screen.dart`, `build`, `_persons.isEmpty` kolu | `_message` içindeki `'Rehberiniz sizi bekliyor'` ve açıklama metnini değiştirin. |
| Telefon zorunluluğu/hata metni | `lib/screens/person_form_screen.dart`, `build`, `'Telefon'` `_field` validator | Telefon zaten zorunludur. Boş metinde ayrı `'Telefon boş bırakılamaz.'` sonucu döndürün; diğer rakam kontrollerini koruyun. |
| Temayı değiştir | `lib/main.dart`, `PersonApp.build` | `ColorScheme.fromSeed` içindeki `seedColor` değerini değiştirin. |
| API sırasını ters çevir | `backend_api/app/main.py`, `get_persons` | `order_by(Person.id)` yerine `order_by(Person.id.desc())` yapın; listeyi yenileyin. |

## 7. 3–5 dakikalık sunum akışı

- **0:00–0:35:** Backend'i açın. `/docs` üzerinde beş metodu gösterin. GET listeyi çalıştırıp doğrudan JSON dizisini anlatın.
- **0:35–1:05:** Mobil listeyi açın. Avatar, ad ve departmanı gösterin. Bir kişiye girip ID ile ayrı GET yapıldığını belirtin.
- **1:05–1:35:** Doğum yeri/tarihi, e-posta ve telefonu gösterin. Telefon/e-posta satırına dokunun; uygulama yoksa Türkçe hata yönetimini açıklayın.
- **1:35–2:25:** Listeye dönüp yeni kişi ekleyin. Bir zorunlu alanı önce boş bırakarak doğrulamayı gösterin; doldurup POST/201 ile kaydedin.
- **2:25–3:00:** Yeni kişinin departmanını düzenleyin. PUT/200 olduğunu ve detay/liste yenilenmesini gösterin.
- **3:00–3:35:** Sil'e basıp önce Vazgeç deyin. Tekrar onaylayın; DELETE/204 ve kaydın kaybolmasını gösterin.
- **3:35–4:20:** Sunucuyu durdurun, listeyi yenileyin; ağ hatasını gösterin. Yeniden açın, Yeniden Dene'ye basın. Diğer kayıtların kaldığını gösterin.
- **4:20–5:00:** `person_api_service.dart` içindeki GET ve `main.py` içindeki route üzerinden Flutter → JSON → API → Session → SQLite zincirini bir kez açıklayın.

FastAPI seçimi görev dokümanında istenmiştir. Teslim edilecek teknoloji tercihini öğretim elemanına açıklarken bu projede gerçekten kullanılan FastAPI + SQLModel adlarını söyleyin; Django veya ASP.NET kullanıldığını söylemeyin.
