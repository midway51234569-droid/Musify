import 'dart:ui';
import 'package:flutter/material.dart';

class MordanFab extends StatelessWidget {
  final VoidCallback? onPressed;
  const MordanFab({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF9C4DFF), Color(0xFF6A5CFF)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: Color(0xFF9C4DFF).withOpacity(0.5), blurRadius: 20, offset: Offset(0, 8)),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        ),
        child: Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36)),
      ),
    );
  }
}
