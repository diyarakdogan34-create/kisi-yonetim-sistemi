import 'package:flutter/material.dart';

import '../models/person.dart';
import '../services/person_api_service.dart';

class PersonFormScreen extends StatefulWidget {
  const PersonFormScreen({super.key, required this.api, this.person});
  final PersonApiService api;
  final Person? person;
  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _department = TextEditingController();
  final _photoUrl = TextEditingController();
  final _birthPlace = TextEditingController();
  final _birthDate = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  DateTime? _date;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    if (p != null) {
      _fullName.text = p.fullName;
      _department.text = p.department;
      _photoUrl.text = p.photoUrl;
      _birthPlace.text = p.birthPlace;
      _date = DateTime.tryParse(p.birthDate);
      _birthDate.text = p.displayBirthDate;
      _email.text = p.email;
      _phone.text = p.phone;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _department,
      _photoUrl,
      _birthPlace,
      _birthDate,
      _email,
      _phone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bu alan zorunludur.' : null;

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final initial =
        _date != null &&
            !_date!.isAfter(today) &&
            !_date!.isBefore(DateTime(1900))
        ? _date!
        : DateTime(2000);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Doğum tarihini seçin',
    );
    if (selected != null && mounted) {
      setState(() {
        _date = selected;
        _birthDate.text =
            '${selected.day.toString().padLeft(2, '0')}.${selected.month.toString().padLeft(2, '0')}.${selected.year}';
      });
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final person = Person(
      fullName: _fullName.text.trim(),
      department: _department.text.trim(),
      photoUrl: _photoUrl.text.trim(),
      birthPlace: _birthPlace.text.trim(),
      birthDate:
          '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
      email: _email.text.trim(),
      phone: _phone.text.trim(),
    );
    try {
      if (widget.person == null) {
        await widget.api.createPerson(person);
      } else {
        await widget.api.updatePerson(widget.person!.id!, person);
      }
      if (mounted) {
        // PopScope'un kilidini kaldırıp önce ekranı yeniden oluştur.
        setState(() => _saving = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _saving = false;
        });
      }
    }
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboard,
    int maxLength = 100,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(label),
      controller: controller,
      enabled: !_saving,
      keyboardType: keyboard,
      textInputAction: TextInputAction.next,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        counterText: '',
      ),
      validator: validator ?? _required,
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.person == null ? 'Yeni Kişi Ekle' : 'Kişiyi Düzenle',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.person == null
                      ? 'Yeni bir bağlantı ekleyin.'
                      : 'Kişi bilgilerini güncelleyin.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Fotoğraf dışındaki tüm alanlar zorunludur.'),
                const SizedBox(height: 24),
                _field(
                  'Ad-Soyad',
                  _fullName,
                  Icons.person_outline_rounded,
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Ad-soyad en az 2 karakter olmalıdır.'
                      : null,
                ),
                _field('Departman', _department, Icons.work_outline_rounded),
                _field(
                  'Fotoğraf URL’si (isteğe bağlı)',
                  _photoUrl,
                  Icons.image_outlined,
                  keyboard: TextInputType.url,
                  maxLength: 2048,
                  validator: (_) => null,
                ),
                _field('Doğum Yeri', _birthPlace, Icons.location_on_outlined),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    key: const ValueKey('Doğum Tarihi'),
                    controller: _birthDate,
                    readOnly: true,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Doğum Tarihi',
                      prefixIcon: Icon(Icons.cake_outlined),
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    onTap: _pickDate,
                    validator: (_) =>
                        _date == null ? 'Doğum tarihi seçin.' : null,
                  ),
                ),
                _field(
                  'E-posta',
                  _email,
                  Icons.mail_outline_rounded,
                  keyboard: TextInputType.emailAddress,
                  maxLength: 254,
                  validator: (v) =>
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Geçerli bir e-posta adresi girin.',
                ),
                _field(
                  'Telefon',
                  _phone,
                  Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  maxLength: 30,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    return RegExp(r'^\+?[0-9 ()-]+$').hasMatch(value) &&
                            digits.length >= 7 &&
                            digits.length <= 15
                        ? null
                        : 'Telefon 7–15 rakam içermelidir.';
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
