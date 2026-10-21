import 'dart:io';
import 'package:flutter/material.dart';
import '../screens/ai/ai_personas.dart';
import '../theme/app_theme.dart';

/// Reusable circular avatar for AI personas supporting default assets, custom user images,
/// and fallback robot/person icons.
class PersonaAvatar extends StatelessWidget {
  final AiPersona? persona;
  final double radius;
  final Color? backgroundColor;
  final Color fallbackIconColor;

  const PersonaAvatar({
    super.key,
    required this.persona,
    this.radius = 20,
    this.backgroundColor,
    this.fallbackIconColor = AppColors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surface;

    if (persona == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Icon(
          Icons.smart_toy_outlined,
          color: fallbackIconColor,
          size: radius * 1.0,
        ),
      );
    }

    // 1. If custom persona with user-selected image file
    if (persona!.isCustom && persona!.imagePath != null && persona!.imagePath!.isNotEmpty) {
      final file = File(persona!.imagePath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          backgroundImage: FileImage(file),
        );
      }
    }

    // 2. If persona has assetPath
    if (persona!.assetPath.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        backgroundImage: AssetImage(persona!.assetPath),
      );
    }

    // 3. Fallback for custom persona without picture
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Icon(
        Icons.person,
        color: fallbackIconColor,
        size: radius * 1.1,
      ),
    );
  }
}
