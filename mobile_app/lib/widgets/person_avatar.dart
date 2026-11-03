import 'package:flutter/material.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    required this.photoUrl,
    this.radius = 28,
  });
  final String name;
  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final initials = parts
        .take(2)
        .map((s) => s.characters.first)
        .join()
        .toUpperCase();
    final colors = Theme.of(context).colorScheme;
    final fallback = Container(
      width: radius * 2,
      height: radius * 2,
      color: colors.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: radius * .65,
          fontWeight: FontWeight.w700,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
    final uri = Uri.tryParse(photoUrl);
    final valid =
        uri != null &&
        ['http', 'https'].contains(uri.scheme) &&
        uri.host.isNotEmpty;
    return Semantics(
      label: '$name profil fotoğrafı',
      image: true,
      child: ExcludeSemantics(
        child: ClipOval(
          child: valid
              ? Image.network(
                  photoUrl,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => fallback,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : fallback,
                )
              : fallback,
        ),
      ),
    );
  }
}
