import 'package:flutter/material.dart';

/// A vector-rendered friendly CAREMATE companion robot illustration
/// with glowing cyan smiling eyes and clean clinical white-and-teal accents.
class CaremateRobotAvatar extends StatelessWidget {
  final double width;
  final double height;
  final bool isSmiling;

  const CaremateRobotAvatar({
    super.key,
    this.width = 110,
    this.height = 100,
    this.isSmiling = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'CAREMATE Robot Companion: Friendly assistive medical robot with smiling LED eyes',
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          size: Size(width, height),
          painter: _RobotCompanionPainter(isSmiling: isSmiling),
        ),
      ),
    );
  }
}

class _RobotCompanionPainter extends CustomPainter {
  final bool isSmiling;

  _RobotCompanionPainter({required this.isSmiling});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Center coordinates
    final cx = w * 0.5;

    // --- 1. Soft Shadow Under Robot ---
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.94), width: w * 0.65, height: h * 0.12),
      shadowPaint,
    );

    // --- 2. Robot Body (Lower Torso) ---
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx, h * 0.76), width: w * 0.56, height: h * 0.36),
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: const Radius.circular(28),
      bottomRight: const Radius.circular(28),
    );

    const bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFF1F5F9),
        Color(0xFFE2E8F0),
      ],
    );

    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(bodyRect.outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bodyRect, bodyPaint);

    // Body trim outline
    final bodyBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(bodyRect, bodyBorderPaint);

    // Lower Teal Accent Band
    final bandPaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final bandPath = Path();
    bandPath.moveTo(cx - w * 0.22, h * 0.88);
    bandPath.quadraticBezierTo(cx, h * 0.91, cx + w * 0.22, h * 0.88);
    canvas.drawPath(bandPath, bandPaint);

    // Chest Logo (Caremate Teal Monogram Badge)
    final chestLogoPaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, h * 0.74), 6.5, chestLogoPaint);

    final crossPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    // Cross horizontal & vertical
    canvas.drawLine(Offset(cx - 3.2, h * 0.74), Offset(cx + 3.2, h * 0.74), crossPaint);
    canvas.drawLine(Offset(cx, h * 0.74 - 3.2), Offset(cx, h * 0.74 + 3.2), crossPaint);

    // --- 3. Ears / Audio Sensors ---
    final earPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final earBorder = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Left ear
    final leftEarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - w * 0.38, h * 0.38), width: w * 0.08, height: h * 0.22),
      const Radius.circular(6),
    );
    canvas.drawRRect(leftEarRect, earPaint);
    canvas.drawRRect(leftEarRect, earBorder);

    // Right ear
    final rightEarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + w * 0.38, h * 0.38), width: w * 0.08, height: h * 0.22),
      const Radius.circular(6),
    );
    canvas.drawRRect(rightEarRect, earPaint);
    canvas.drawRRect(rightEarRect, earBorder);

    // --- 4. Robot Head ---
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.38), width: w * 0.72, height: h * 0.52),
      const Radius.circular(30),
    );

    const headGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Color(0xFFF8FAFC),
        Color(0xFFE2E8F0),
      ],
      stops: [0.0, 0.6, 1.0],
    );

    final headPaint = Paint()
      ..shader = headGradient.createShader(headRect.outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(headRect, headPaint);

    final headBorder = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(headRect, headBorder);

    // Head Top Highlight (glossy shine)
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.17), width: w * 0.34, height: h * 0.05),
      shinePaint,
    );

    // --- 5. Dark Glossy Visor Screen ---
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.38), width: w * 0.56, height: h * 0.36),
      const Radius.circular(20),
    );

    final visorPaint = Paint()
      ..color = const Color(0xFF0F172A) // Deep Obsidian
      ..style = PaintingStyle.fill;
    canvas.drawRRect(visorRect, visorPaint);

    final visorBorder = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(visorRect, visorBorder);

    // Visor subtle glossy reflection
    final visorGlossPath = Path();
    visorGlossPath.moveTo(cx - w * 0.24, h * 0.24);
    visorGlossPath.lineTo(cx + w * 0.24, h * 0.24);
    visorGlossPath.quadraticBezierTo(cx, h * 0.30, cx - w * 0.24, h * 0.27);
    visorGlossPath.close();

    final visorGlossPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(visorGlossPath, visorGlossPaint);

    // --- 6. Glowing Smiling Cyan Eyes (LED) ---
    final eyeGlowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final eyeCorePaint = Paint()
      ..color = const Color(0xFF22D3EE) // Vibrant Cyan LED
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    final leftEyeCx = cx - w * 0.13;
    final rightEyeCx = cx + w * 0.13;
    final eyeY = h * 0.38;

    if (isSmiling) {
      // Upward curving smiling crescent eyes (^_^)
      final leftEyePath = Path();
      leftEyePath.moveTo(leftEyeCx - 9, eyeY + 2);
      leftEyePath.quadraticBezierTo(leftEyeCx, eyeY - 8, leftEyeCx + 9, eyeY + 2);

      final rightEyePath = Path();
      rightEyePath.moveTo(rightEyeCx - 9, eyeY + 2);
      rightEyePath.quadraticBezierTo(rightEyeCx, eyeY - 8, rightEyeCx + 9, eyeY + 2);

      // Draw Glow
      canvas.drawPath(leftEyePath, eyeGlowPaint);
      canvas.drawPath(rightEyePath, eyeGlowPaint);
      // Draw Core LED
      canvas.drawPath(leftEyePath, eyeCorePaint);
      canvas.drawPath(rightEyePath, eyeCorePaint);

      // Cute little blush dots
      final blushPaint = Paint()
        ..color = const Color(0xFF0D9488).withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(leftEyeCx - 2, eyeY + 11), 3.5, blushPaint);
      canvas.drawCircle(Offset(rightEyeCx + 2, eyeY + 11), 3.5, blushPaint);
    } else {
      // Normal friendly oval LED eyes
      canvas.drawOval(Rect.fromCenter(center: Offset(leftEyeCx, eyeY), width: 12, height: 16), eyeGlowPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(leftEyeCx, eyeY), width: 12, height: 16), eyeCorePaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(rightEyeCx, eyeY), width: 12, height: 16), eyeGlowPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(rightEyeCx, eyeY), width: 12, height: 16), eyeCorePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RobotCompanionPainter oldDelegate) {
    return oldDelegate.isSmiling != isSmiling;
  }
}
