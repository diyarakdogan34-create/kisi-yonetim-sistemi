import 'package:flutter/material.dart';

import '../models/person.dart';
import '../services/person_api_service.dart';
import '../widgets/person_avatar.dart';
import 'person_detail_screen.dart';
import 'person_form_screen.dart';

class PersonListScreen extends StatefulWidget {
  const PersonListScreen({super.key, required this.api});
  final PersonApiService api;
  @override
  State<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends State<PersonListScreen> {
  List<Person> _persons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final persons = await widget.api.getPersons();
      if (mounted) setState(() => _persons = persons);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PersonFormScreen(api: widget.api)),
    );
    if (saved == true && mounted) await _loadPersons();
  }

  Future<void> _openPerson(Person person) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonDetailScreen(id: person.id!, api: widget.api),
      ),
    );
    // Düzenleme veya silme sonrasında sunucudan güncel liste alınır.
    if (mounted) await _loadPersons();
  }

  Widget _message(
    IconData icon,
    String title,
    String message,
    String action,
    VoidCallback onPressed,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kişi Listesi'),
        actions: [
          IconButton(
            tooltip: 'Listeyi yenile',
            onPressed: _loading ? null : _loadPersons,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _message(
                Icons.cloud_off_rounded,
                'Bağlantı kurulamadı',
                _error!,
                'Yeniden Dene',
                _loadPersons,
              )
            : _persons.isEmpty
            ? _message(
                Icons.people_outline_rounded,
                'Rehberiniz sizi bekliyor',
                'İlk kişinizi ekleyerek başlayın. Tüm iletişim bilgileri tek yerde.',
                'İlk Kişiyi Ekle',
                _openForm,
              )
            : RefreshIndicator(
                onRefresh: _loadPersons,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
                  itemCount: _persons.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bağlantılarınız, bir arada.',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_persons.length} kişi · İletişim bilgileri ve daha fazlası',
                            ),
                          ],
                        ),
                      );
                    }
                    final person = _persons[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: PersonAvatar(
                            name: person.fullName,
                            photoUrl: person.photoUrl,
                          ),
                          title: Text(
                            person.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(person.department),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _openPerson(person),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        tooltip: 'Yeni kişi ekle',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Kişi'),
      ),
    );
  }
}
