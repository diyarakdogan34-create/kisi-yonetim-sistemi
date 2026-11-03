import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/person.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PersonApiService {
  PersonApiService({
    http.Client? client,
    this.baseUrl = defaultBaseUrl,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client();

  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  Future<dynamic> _request(
    String method,
    String path,
    int expected, [
    Person? person,
  ]) async {
    try {
      final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');
      final headers = {'Content-Type': 'application/json; charset=utf-8'};
      final body = person == null ? null : jsonEncode(person.toJson());
      // Her işlem kendi HTTP metodu ve beklenen durum koduyla çalışır.
      final response = await (switch (method) {
        'POST' => _client.post(uri, headers: headers, body: body),
        'PUT' => _client.put(uri, headers: headers, body: body),
        'DELETE' => _client.delete(uri),
        _ => _client.get(uri),
      }).timeout(timeout);
      if (response.statusCode != expected) {
        if (response.statusCode == 404) {
          throw const ApiException(
            'Kişi bulunamadı. Silinmiş olabilir. Listeye dönüp yenileyin.',
          );
        }
        if (response.statusCode == 422) {
          throw const ApiException(
            'Bilgiler doğrulanamadı. Zorunlu alanları, e-postayı, telefonu ve doğum tarihini kontrol edin.',
          );
        }
        throw ApiException(
          response.statusCode >= 500
              ? 'Sunucuda bir sorun oluştu. Lütfen yeniden deneyin.'
              : 'İşlem tamamlanamadı (HTTP ${response.statusCode}).',
        );
      }
      if (expected == 204) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const ApiException(
        'Sunucu zamanında yanıt vermedi. Bağlantınızı kontrol edip yeniden deneyin.',
      );
    } on SocketException {
      throw const ApiException(
        'Sunucuya ulaşılamıyor. Sunucunun açık olduğunu ve ağ bağlantısını kontrol edin.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Sunucuya bağlanılamadı. Ağ bağlantısını ve sunucu adresini kontrol edin.',
      );
    } on FormatException {
      throw const ApiException('Sunucudan beklenmeyen bir yanıt alındı.');
    }
  }

  Person _person(dynamic data) {
    try {
      return Person.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      throw const ApiException('Sunucudan gelen kişi bilgileri okunamadı.');
    }
  }

  Future<List<Person>> getPersons() async {
    final data = await _request('GET', '/api/persons', 200);
    if (data is! List) {
      throw const ApiException('Sunucudan gelen kişi listesi okunamadı.');
    }
    return data.map(_person).toList();
  }

  Future<Person> getPersonById(int id) async =>
      _person(await _request('GET', '/api/persons/$id', 200));
  Future<Person> createPerson(Person person) async =>
      _person(await _request('POST', '/api/persons', 201, person));
  Future<Person> updatePerson(int id, Person person) async =>
      _person(await _request('PUT', '/api/persons/$id', 200, person));
  Future<void> deletePerson(int id) async {
    await _request('DELETE', '/api/persons/$id', 204);
  }

  void close() => _client.close();
}
