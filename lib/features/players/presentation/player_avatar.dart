import 'dart:typed_data';

import 'package:flutter/material.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    required this.displayName,
    this.photoUrl,
    this.photoBytes,
    this.radius = 22,
    super.key,
  });

  final String displayName;
  final String? photoUrl;
  final Uint8List? photoBytes;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = photoBytes != null
        ? Image.memory(
            photoBytes!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(context),
          )
        : photoUrl == null || photoUrl!.isEmpty
        ? _fallback(context)
        : Image.network(
            photoUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(context),
          );
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      child: ClipOval(child: image),
    );
  }

  Widget _fallback(BuildContext context) {
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().substring(0, 1).toUpperCase();
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
