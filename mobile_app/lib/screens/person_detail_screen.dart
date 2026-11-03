import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/person.dart';
import '../services/person_api_service.dart';
import '../widgets/person_avatar.dart';
import 'person_form_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  const PersonDetailScreen({super.key, required this.id, required this.api});
  final int id;
  final PersonApiService api;
  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  Person? _person;
  String? _error;
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadPerson();
  }

  Future<void> _loadPerson() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final person = await widget.api.getPersonById(widget.id);
      if (mounted) setState(() => _person = person);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editPerson() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonFormScreen(api: widget.api, person: _person),
      ),
    );
    if (saved == true && mounted) await _loadPerson();
  }

  Future<void> _deletePerson() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kişi silinsin mi?'),
        content: Text(
          '${_person!.fullName} rehberden kalıcı olarak silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.api.deletePerson(widget.id);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _launchContact(String scheme, String value) async {
    try {
      final address = scheme == 'tel'
          ? value.replaceAll(RegExp(r'[^0-9+]'), '')
          : value;
      final opened = await launchUrl(
        Uri(scheme: scheme, path: address),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw Exception('Uygulama bulunamadı');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              scheme == 'tel'
                  ? 'Telefon uygulaması açılamadı. Cihazda uygun bir uygulama olduğundan emin olun.'
                  : 'E-posta uygulaması açılamadı. Cihazda bir e-posta uygulaması kurulu olmalı.',
            ),
          ),
        );
      }
    }
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(label, style: Theme.of(context).textTheme.labelLarge),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    ),
    trailing: onTap == null
        ? null
        : const Icon(Icons.open_in_new_rounded, size: 18),
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    final person = _person;
    return PopScope(
      canPop: !_deleting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Kişi Detayı')),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _loadPerson,
                          child: const Text('Yeniden Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : person == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            PersonAvatar(
                              name: person.fullName,
                              photoUrl: person.photoUrl,
                              radius: 56,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              person.fullName,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              person.department,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'KİŞİ BİLGİLERİ',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [
                          _infoRow(
                            Icons.location_on_outlined,
                            'Doğum Yeri',
                            person.birthPlace,
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _infoRow(
                            Icons.cake_outlined,
                            'Doğum Tarihi',
                            person.displayBirthDate,
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _infoRow(
                            Icons.mail_outline_rounded,
                            'E-posta',
                            person.email,
                            onTap: () => _launchContact('mailto', person.email),
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _infoRow(
                            Icons.phone_outlined,
                            'Telefon',
                            person.phone,
                            onTap: () => _launchContact('tel', person.phone),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        bottomNavigationBar: person == null || _loading || _error != null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: _deleting ? null : _editPerson,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('DÜZENLE'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _deleting ? null : _deletePerson,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        icon: _deleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                        label: Text(_deleting ? 'Siliniyor…' : 'KİŞİYİ SİL'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
