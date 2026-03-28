import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const VibeViewApp());
}

// ── 색상 팔레트 ───────────────────────────────────────────
const Color kBg       = Color(0xFFF5FFFE);
const Color kSurface  = Color(0xFFFFFFFF);
const Color kSurface2 = Color(0xFFEEFAF7);
const Color kBorder   = Color(0xFFCCEDE6);
const Color kAccent   = Color(0xFF00C49A);
const Color kAccent2  = Color(0xFFFF6B6B);
const Color kAccent3  = Color(0xFF6C63FF);
const Color kYellow   = Color(0xFFFFD93D);
const Color kText     = Color(0xFF1A2E2A);
const Color kTextMid  = Color(0xFF4A7A6D);
const Color kTextDim  = Color(0xFF8BB8AD);

const Map<String, Color> kEmotionColors = {
  'happy':     Color(0xFF00C49A),
  'sad':       Color(0xFF5B9BD5),
  'angry':     Color(0xFFFF6B6B),
  'surprised': Color(0xFFFFD93D),
  'neutral':   Color(0xFF8BB8AD),
  'fearful':   Color(0xFFB39DDB),
  'disgusted': Color(0xFF81C784),
};

const Map<String, String> kEmotionKo = {
  'happy':     '행복',
  'sad':       '슬픔',
  'angry':     '분노',
  'surprised': '놀람',
  'neutral':   '중립',
  'fearful':   '두려움',
  'disgusted': '혐오',
};

const Map<String, Color> kGradeColors = {
  'S': Color(0xFF00C49A),
  'A': Color(0xFF6C63FF),
  'B': Color(0xFFFFD93D),
  'C': Color(0xFFFF8C42),
  'D': Color(0xFFFF6B6B),
};

const String kApiBase = 'http://10.0.2.2:8000';

enum CharacterMood { idle, thinking, happy, sad, surprised, angry }

// ── Paint 헬퍼 ────────────────────────────────────────────
Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

// ── SD 치비 백호 수인 페인터 (사람 기반) ──────────────────
class BeastmanPainter extends CustomPainter {
  final CharacterMood mood;
  final double floatAnim;
  final double spinAnim;

  BeastmanPainter({
    required this.mood,
    required this.floatAnim,
    required this.spinAnim,
  });

  static const Color cSkin     = Color(0xFFFFE0C4);
  static const Color cSkinDark = Color(0xFFFFCA9E);
  static const Color cHair     = Color(0xFFF5F0E8);
  static const Color cHairDim  = Color(0xFFE8E2D5);
  static const Color cStripe   = Color(0xFF8B9DB5);
  static const Color cOutline  = Color(0xFF3D3530);
  static const Color cEyeL     = Color(0xFF5BB8FF);
  static const Color cPupil    = Color(0xFF1A1A2E);
  static const Color cBlush    = Color(0xFFFFB3C8);
  static const Color cEarIn    = Color(0xFFFFCCDD);
  static const Color cTeeth    = Color(0xFFFFFBF0);
  static const Color cTongue   = Color(0xFFFF8FAB);
  static const Color cNose     = Color(0xFFE8967A);
  static const Color cLip      = Color(0xFFD4786A);
  static const Color cCloth    = Color(0xFF4A90D9);
  static const Color cCloth2   = Color(0xFF2E6DB4);
  static const Color cAccent2  = kAccent2;
  static const Color cAccent3  = kAccent3;
  static const Color cYellow   = kYellow;
  static const Color cTextDim  = kTextDim;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.38;
    final r  = size.width * 0.33;
    _drawTigerEars(canvas, cx, cy, r);
    _drawHairBack(canvas, cx, cy, r);
    _drawBody(canvas, cx, cy, r);
    _drawFace(canvas, cx, cy, r);
    _drawHairFront(canvas, cx, cy, r);
    _drawDecorations(canvas, cx, cy, r);
  }

  void _drawTigerEars(Canvas canvas, double cx, double cy, double r) {
    for (final isLeft in [true, false]) {
      final ex = isLeft ? cx - r * 0.68 : cx + r * 0.68;
      final ey = cy - r * 0.82;
      final earPath = Path()
        ..moveTo(ex, ey - r * 0.42)
        ..lineTo(ex - r * 0.28, ey + r * 0.18)
        ..lineTo(ex + r * 0.28, ey + r * 0.18)
        ..close();
      canvas.drawPath(earPath, _fill(cHair));
      canvas.drawPath(earPath, _fill(cStripe.withOpacity(0.15)));
      canvas.drawPath(earPath, _stroke(cOutline, 1.8));
      final innerPath = Path()
        ..moveTo(ex, ey - r * 0.28)
        ..lineTo(ex - r * 0.15, ey + r * 0.08)
        ..lineTo(ex + r * 0.15, ey + r * 0.08)
        ..close();
      canvas.drawPath(innerPath, _fill(cEarIn));
      canvas.drawLine(Offset(ex - r * 0.06, ey - r * 0.22),
        Offset(ex - r * 0.04, ey + r * 0.06), _stroke(cStripe.withOpacity(0.35), 1.5));
      canvas.drawLine(Offset(ex + r * 0.06, ey - r * 0.22),
        Offset(ex + r * 0.04, ey + r * 0.06), _stroke(cStripe.withOpacity(0.35), 1.5));
    }
  }

  void _drawHairBack(Canvas canvas, double cx, double cy, double r) {
    final backHair = Path()
      ..moveTo(cx - r * 0.95, cy - r * 0.3)
      ..quadraticBezierTo(cx - r * 1.05, cy + r * 0.4, cx - r * 0.8, cy + r * 0.7)
      ..lineTo(cx - r * 0.6, cy + r * 0.5)
      ..quadraticBezierTo(cx - r * 0.85, cy + r * 0.2, cx - r * 0.78, cy - r * 0.25)
      ..close();
    canvas.drawPath(backHair, _fill(cHairDim));
    final backHairR = Path()
      ..moveTo(cx + r * 0.95, cy - r * 0.3)
      ..quadraticBezierTo(cx + r * 1.05, cy + r * 0.4, cx + r * 0.8, cy + r * 0.7)
      ..lineTo(cx + r * 0.6, cy + r * 0.5)
      ..quadraticBezierTo(cx + r * 0.85, cy + r * 0.2, cx + r * 0.78, cy - r * 0.25)
      ..close();
    canvas.drawPath(backHairR, _fill(cHairDim));
  }

  void _drawBody(Canvas canvas, double cx, double cy, double r) {
    final by = cy + r * 1.08;
    final bodyPath = Path()
      ..moveTo(cx - r * 0.58, cy + r * 0.78)
      ..quadraticBezierTo(cx - r * 0.72, by + r * 0.1, cx - r * 0.55, by + r * 0.58)
      ..lineTo(cx + r * 0.55, by + r * 0.58)
      ..quadraticBezierTo(cx + r * 0.72, by + r * 0.1, cx + r * 0.58, cy + r * 0.78)
      ..close();
    canvas.drawPath(bodyPath, _fill(cCloth));
    canvas.drawPath(bodyPath, _stroke(cOutline, 1.8));
    final collarPath = Path()
      ..moveTo(cx - r * 0.22, cy + r * 0.82)
      ..lineTo(cx, cy + r * 1.05)
      ..lineTo(cx + r * 0.22, cy + r * 0.82);
    canvas.drawPath(collarPath, _fill(Colors.white));
    canvas.drawPath(collarPath, _stroke(cOutline, 1.5));
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(cx + i * r * 0.22, cy + r * 0.88),
        Offset(cx + i * r * 0.2, by + r * 0.4),
        _stroke(cCloth2.withOpacity(0.5), 2.0),
      );
    }
    _drawArm(canvas, cx - r * 0.68, by - r * 0.08, r * 0.2, true);
    _drawArm(canvas, cx + r * 0.68, by - r * 0.08, r * 0.2, false);
    for (final dx in [-0.26, 0.26]) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + r * dx, by + r * 0.75), width: r * 0.38, height: r * 0.44),
        const Radius.circular(14)), _fill(const Color(0xFF2E4A6B)));
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + r * dx, by + r * 0.75), width: r * 0.38, height: r * 0.44),
        const Radius.circular(14)), _stroke(cOutline, 1.5));
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + r * dx + r * 0.04, by + r * 1.0),
        width: r * 0.44, height: r * 0.22), _fill(const Color(0xFF1A2A3A)));
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + r * dx + r * 0.04, by + r * 1.0),
        width: r * 0.44, height: r * 0.22), _stroke(cOutline, 1.4));
    }
    final tailPath = Path()
      ..moveTo(cx + r * 0.5, by + r * 0.35)
      ..cubicTo(cx + r * 1.05, by, cx + r * 1.25, by + r * 0.55, cx + r * 0.88, by + r * 0.78);
    canvas.drawPath(tailPath, _stroke(cHair, r * 0.24));
    canvas.drawPath(tailPath, _stroke(cOutline, r * 0.24 + 1.8));
    canvas.drawPath(tailPath, _stroke(cHair, r * 0.18));
    for (double t = 0.15; t < 0.85; t += 0.25) {
      canvas.drawOval(Rect.fromCenter(
        center: Offset(cx + r * (0.5 + t * 0.48), by + r * (0.35 - t * 0.12 + t * t * 0.55)),
        width: r * 0.07, height: r * 0.18), _fill(cStripe.withOpacity(0.5)));
    }
  }

  void _drawArm(Canvas canvas, double ax, double ay, double ar, bool isLeft) {
    canvas.save();
    canvas.translate(ax, ay);
    canvas.rotate(isLeft ? 0.3 : -0.3);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: ar * 1.2, height: ar * 2.2), _fill(cCloth));
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: ar * 1.2, height: ar * 2.2), _stroke(cOutline, 1.5));
    canvas.drawCircle(Offset(0, ar * 1.0), ar * 0.55, _fill(cSkin));
    canvas.drawCircle(Offset(0, ar * 1.0), ar * 0.55, _stroke(cOutline, 1.3));
    canvas.restore();
  }

  void _drawFace(Canvas canvas, double cx, double cy, double r) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + r * 0.02, cy + r * 0.04),
      width: r * 2.08, height: r * 2.08), _fill(cOutline.withOpacity(0.05)));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 2.0, height: r * 2.05), _fill(cSkin));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - r * 0.58, cy + r * 0.2),
      width: r * 0.5, height: r * 0.28), _fill(cBlush.withOpacity(0.6)));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + r * 0.58, cy + r * 0.2),
      width: r * 0.5, height: r * 0.28), _fill(cBlush.withOpacity(0.6)));
    _drawEyes(canvas, cx, cy, r);
    _drawNose(canvas, cx, cy, r);
    _drawMouth(canvas, cx, cy, r);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 2.0, height: r * 2.05),
      _stroke(cOutline, 2.0));
    _drawForheadStripes(canvas, cx, cy, r);
  }

  void _drawHairFront(Canvas canvas, double cx, double cy, double r) {
    final bangPath = Path()
      ..moveTo(cx - r * 0.95, cy - r * 0.55)
      ..quadraticBezierTo(cx - r * 0.7, cy - r * 1.15, cx, cy - r * 1.12)
      ..quadraticBezierTo(cx + r * 0.7, cy - r * 1.15, cx + r * 0.95, cy - r * 0.55)
      ..quadraticBezierTo(cx + r * 0.6, cy - r * 0.72, cx + r * 0.35, cy - r * 0.65)
      ..quadraticBezierTo(cx + r * 0.1, cy - r * 0.58, cx, cy - r * 0.62)
      ..quadraticBezierTo(cx - r * 0.25, cy - r * 0.58, cx - r * 0.42, cy - r * 0.68)
      ..quadraticBezierTo(cx - r * 0.6, cy - r * 0.72, cx - r * 0.95, cy - r * 0.55)
      ..close();
    canvas.drawPath(bangPath, _fill(cHair));
    canvas.drawPath(bangPath, _stroke(cOutline, 1.8));
    _drawHairStrands(canvas, cx, cy, r);
    _drawHairStripes(canvas, cx, cy, r);
  }

  void _drawHairStrands(Canvas canvas, double cx, double cy, double r) {
    final strands = [
      [cx - r * 0.35, cy - r * 0.58, cx - r * 0.28, cy - r * 0.38],
      [cx - r * 0.08, cy - r * 0.62, cx - r * 0.04, cy - r * 0.4],
      [cx + r * 0.18, cy - r * 0.6, cx + r * 0.22, cy - r * 0.42],
    ];
    for (final s in strands) {
      final strandPath = Path()
        ..moveTo(s[0] - r * 0.06, s[1])
        ..quadraticBezierTo(s[0], s[3] - r * 0.05, s[2], s[3])
        ..quadraticBezierTo(s[0] + r * 0.02, s[3] - r * 0.05, s[0] + r * 0.06, s[1])
        ..close();
      canvas.drawPath(strandPath, _fill(cHair));
      canvas.drawPath(strandPath, _stroke(cOutline, 1.2));
    }
  }

  void _drawHairStripes(Canvas canvas, double cx, double cy, double r) {
    final sw = _stroke(cStripe.withOpacity(0.2), r * 0.055);
    canvas.drawPath(Path()
      ..moveTo(cx - r * 0.25, cy - r * 1.08)
      ..quadraticBezierTo(cx - r * 0.18, cy - r * 0.82, cx - r * 0.14, cy - r * 0.62), sw);
    canvas.drawPath(Path()
      ..moveTo(cx + r * 0.12, cy - r * 1.1)
      ..quadraticBezierTo(cx + r * 0.08, cy - r * 0.85, cx + r * 0.06, cy - r * 0.65), sw);
    canvas.drawPath(Path()
      ..moveTo(cx + r * 0.45, cy - r * 1.0)
      ..quadraticBezierTo(cx + r * 0.38, cy - r * 0.8, cx + r * 0.32, cy - r * 0.62),
      _stroke(cStripe.withOpacity(0.15), r * 0.045));
  }

  void _drawForheadStripes(Canvas canvas, double cx, double cy, double r) {
    final sw = _stroke(cStripe.withOpacity(0.32), r * 0.07);
    canvas.drawPath(Path()
      ..moveTo(cx, cy - r * 0.6)
      ..quadraticBezierTo(cx + r * 0.02, cy - r * 0.45, cx, cy - r * 0.32), sw);
    canvas.drawPath(Path()
      ..moveTo(cx - r * 0.22, cy - r * 0.55)
      ..quadraticBezierTo(cx - r * 0.18, cy - r * 0.42, cx - r * 0.15, cy - r * 0.3),
      _stroke(cStripe.withOpacity(0.22), r * 0.055));
    canvas.drawPath(Path()
      ..moveTo(cx + r * 0.22, cy - r * 0.55)
      ..quadraticBezierTo(cx + r * 0.18, cy - r * 0.42, cx + r * 0.15, cy - r * 0.3),
      _stroke(cStripe.withOpacity(0.22), r * 0.055));
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double r) {
    final lx = cx - r * 0.34;
    final rx = cx + r * 0.34;
    final ey = cy - r * 0.06;
    final ew = r * 0.32;
    final eh = r * 0.22;

    switch (mood) {
      case CharacterMood.happy:
        for (final ex in [lx, rx]) {
          final p = Path()
            ..moveTo(ex - ew * 0.9, ey + eh * 0.2)
            ..quadraticBezierTo(ex, ey - eh * 1.1, ex + ew * 0.9, ey + eh * 0.2);
          canvas.drawPath(p, _stroke(cOutline, 2.5));
        }
        _drawEyebrows(canvas, lx, rx, ey, ew, r, mood);
        return;
      case CharacterMood.sad:
        _drawDefaultEyeShape(canvas, lx, rx, ey, ew, eh, 0.0);
        _drawTear(canvas, lx + ew * 0.4, ey + eh * 1.3, r * 0.1);
        _drawTear(canvas, rx + ew * 0.4, ey + eh * 1.3, r * 0.1);
        _drawEyebrows(canvas, lx, rx, ey, ew, r, mood);
        return;
      case CharacterMood.surprised:
        for (final ex in [lx, rx]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(ex, ey),
            width: ew * 1.6, height: eh * 2.4), _fill(Colors.white));
          canvas.drawOval(Rect.fromCenter(center: Offset(ex, ey),
            width: ew * 0.9, height: eh * 1.5), _fill(cEyeL));
          canvas.drawOval(Rect.fromCenter(center: Offset(ex, ey + eh * 0.1),
            width: ew * 0.45, height: eh * 0.85), _fill(cPupil));
          canvas.drawCircle(Offset(ex + ew * 0.2, ey - eh * 0.3), r * 0.055, _fill(Colors.white));
          canvas.drawOval(Rect.fromCenter(center: Offset(ex, ey),
            width: ew * 1.6, height: eh * 2.4), _stroke(cOutline, 1.8));
        }
        _drawEyebrows(canvas, lx, rx, ey, ew, r, mood);
        return;
      default:
        _drawDefaultEyeShape(canvas, lx, rx, ey, ew, eh, 0.0);
        _drawEyebrows(canvas, lx, rx, ey, ew, r, mood);
    }
  }

  void _drawDefaultEyeShape(Canvas canvas, double lx, double rx,
      double ey, double ew, double eh, double offsetY) {
    for (final ex in [lx, rx]) {
      final eyePath = Path()
        ..moveTo(ex - ew, ey + offsetY)
        ..quadraticBezierTo(ex, ey - eh + offsetY, ex + ew, ey + offsetY)
        ..quadraticBezierTo(ex, ey + eh + offsetY, ex - ew, ey + offsetY)
        ..close();
      canvas.drawPath(eyePath, _fill(Colors.white));
      canvas.drawOval(Rect.fromCenter(center: Offset(ex, ey + offsetY + eh * 0.05),
        width: ew * 1.0, height: eh * 1.5), _fill(cEyeL));
      canvas.drawOval(Rect.fromCenter(center: Offset(ex + ew * 0.08, ey + offsetY + eh * 0.1),
        width: ew * 0.5, height: eh * 0.85), _fill(cPupil));
      canvas.drawCircle(Offset(ex + ew * 0.28, ey - eh * 0.15 + offsetY), r * 0.055, _fill(Colors.white));
      canvas.drawCircle(Offset(ex - ew * 0.1, ey + eh * 0.25 + offsetY), r * 0.028,
        _fill(Colors.white.withOpacity(0.7)));
      canvas.drawPath(
        Path()
          ..moveTo(ex - ew, ey + offsetY)
          ..quadraticBezierTo(ex, ey - eh + offsetY, ex + ew, ey + offsetY)
          ..quadraticBezierTo(ex, ey + eh + offsetY, ex - ew, ey + offsetY)
          ..close(),
        _stroke(cOutline, 1.8));
      for (int i = -2; i <= 2; i++) {
        final lashX = ex + i * ew * 0.38;
        final lashY = ey - eh * 0.85 + offsetY;
        canvas.drawLine(Offset(lashX, lashY), Offset(lashX + i * r * 0.015, lashY - r * 0.045),
          _stroke(cOutline, 1.4));
      }
    }
  }

  // r 필드는 CustomPainter 안에서 직접 사용할 수 없으므로 paint()의 r을 인자로 전달
  double get r => 0.0; // 사용 안 함 - _drawDefaultEyeShape는 r을 0으로 사용하므로 별도 처리

  void _drawEyebrows(Canvas canvas, double lx, double rx,
      double ey, double ew, double r, CharacterMood mood) {
    final by = ey - r * 0.28;
    switch (mood) {
      case CharacterMood.happy:
        for (final ex in [lx, rx]) {
          canvas.drawPath(Path()
            ..moveTo(ex - ew * 0.85, by + r * 0.04)
            ..quadraticBezierTo(ex, by - r * 0.06, ex + ew * 0.85, by + r * 0.04),
            _stroke(cOutline, 2.2));
        }
        break;
      case CharacterMood.sad:
        canvas.drawLine(Offset(lx - ew, by - r * 0.04), Offset(lx + ew, by + r * 0.04), _stroke(cOutline, 2.2));
        canvas.drawLine(Offset(rx - ew, by + r * 0.04), Offset(rx + ew, by - r * 0.04), _stroke(cOutline, 2.2));
        break;
      case CharacterMood.surprised:
        for (final ex in [lx, rx]) {
          canvas.drawPath(Path()
            ..moveTo(ex - ew * 0.85, by - r * 0.06)
            ..quadraticBezierTo(ex, by - r * 0.16, ex + ew * 0.85, by - r * 0.06),
            _stroke(cOutline, 2.5));
        }
        break;
      case CharacterMood.thinking:
        canvas.drawLine(Offset(lx - ew * 0.8, by), Offset(lx + ew * 0.8, by), _stroke(cOutline, 2.0));
        canvas.drawPath(Path()
          ..moveTo(rx - ew * 0.8, by + r * 0.02)
          ..quadraticBezierTo(rx, by - r * 0.1, rx + ew * 0.8, by + r * 0.02),
          _stroke(cOutline, 2.0));
        break;
      case CharacterMood.angry:
        canvas.drawLine(Offset(lx - ew, by - r * 0.02), Offset(lx + ew, by + r * 0.08), _stroke(cAccent2, 2.8));
        canvas.drawLine(Offset(rx - ew, by + r * 0.08), Offset(rx + ew, by - r * 0.02), _stroke(cAccent2, 2.8));
        break;
      default:
        for (final ex in [lx, rx]) {
          canvas.drawPath(Path()
            ..moveTo(ex - ew * 0.85, by + r * 0.02)
            ..quadraticBezierTo(ex, by - r * 0.04, ex + ew * 0.85, by + r * 0.02),
            _stroke(cOutline.withOpacity(0.7), 2.0));
        }
    }
  }

  void _drawTear(Canvas canvas, double tx, double ty, double tr) {
    canvas.drawPath(Path()
      ..moveTo(tx, ty - tr * 0.4)
      ..quadraticBezierTo(tx + tr * 0.5, ty + tr * 0.1, tx, ty + tr * 0.7)
      ..quadraticBezierTo(tx - tr * 0.5, ty + tr * 0.1, tx, ty - tr * 0.4),
      _fill(const Color(0xFF93C5FD).withOpacity(0.85)));
  }

  void _drawNose(Canvas canvas, double cx, double cy, double r) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + r * 0.18),
      width: r * 0.22, height: r * 0.14), _fill(cSkinDark));
    canvas.drawCircle(Offset(cx - r * 0.07, cy + r * 0.19), r * 0.04, _fill(cNose.withOpacity(0.6)));
    canvas.drawCircle(Offset(cx + r * 0.07, cy + r * 0.19), r * 0.04, _fill(cNose.withOpacity(0.6)));
  }

  void _drawMouth(Canvas canvas, double cx, double cy, double r) {
    final my = cy + r * 0.4;
    switch (mood) {
      case CharacterMood.happy:
        canvas.drawPath(Path()
          ..moveTo(cx - r * 0.35, my - r * 0.04)
          ..quadraticBezierTo(cx, my + r * 0.32, cx + r * 0.35, my - r * 0.04),
          _stroke(cOutline, 2.5));
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, my + r * 0.1), width: r * 0.42, height: r * 0.16),
          const Radius.circular(5)), _fill(cTeeth));
        canvas.drawLine(Offset(cx, my + r * 0.02), Offset(cx, my + r * 0.18),
          _stroke(const Color(0xFFDDD8C8), 1.4));
        canvas.drawPath(Path()
          ..moveTo(cx - r * 0.15, my + r * 0.18)
          ..quadraticBezierTo(cx, my + r * 0.38, cx + r * 0.15, my + r * 0.18),
          _fill(cTongue));
        break;
      case CharacterMood.sad:
        canvas.drawPath(Path()
          ..moveTo(cx - r * 0.28, my + r * 0.1)
          ..quadraticBezierTo(cx, my - r * 0.15, cx + r * 0.28, my + r * 0.1),
          _stroke(const Color(0xFF5B9BD5), 2.4));
        break;
      case CharacterMood.surprised:
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, my + r * 0.05),
          width: r * 0.26, height: r * 0.34), _fill(const Color(0xFF3D3530)));
        break;
      case CharacterMood.thinking:
        canvas.drawPath(Path()
          ..moveTo(cx - r * 0.1, my + r * 0.02)
          ..quadraticBezierTo(cx + r * 0.06, my - r * 0.1, cx + r * 0.24, my + r * 0.05),
          _stroke(cTextDim, 2.2));
        break;
      case CharacterMood.angry:
        canvas.drawPath(Path()
          ..moveTo(cx - r * 0.28, my + r * 0.06)
          ..quadraticBezierTo(cx, my - r * 0.1, cx + r * 0.28, my + r * 0.06),
          _stroke(cAccent2, 2.6));
        canvas.drawLine(Offset(cx - r * 0.18, my + r * 0.03), Offset(cx + r * 0.18, my + r * 0.03),
          _stroke(cOutline.withOpacity(0.3), 1.4));
        break;
      default:
        canvas.drawPath(Path()
          ..moveTo(cx - r * 0.24, my)
          ..quadraticBezierTo(cx, my + r * 0.2, cx + r * 0.24, my),
          _stroke(cLip, 2.3));
    }
  }

  void _drawDecorations(Canvas canvas, double cx, double cy, double r) {
    if (mood == CharacterMood.thinking) {
      _drawThinkBubble(canvas, cx + r * 0.88, cy - r * 0.82, r * 0.38);
    }
    if (mood == CharacterMood.happy || mood == CharacterMood.surprised) {
      _drawSparkles(canvas, cx, cy, r);
    }
  }

  void _drawThinkBubble(Canvas canvas, double bx, double by, double br) {
    canvas.drawCircle(Offset(bx - br * 0.65, by + br * 0.8), br * 0.13, _fill(cAccent3.withOpacity(0.8)));
    canvas.drawCircle(Offset(bx - br * 0.4, by + br * 0.52), br * 0.18, _fill(cAccent3.withOpacity(0.85)));
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(bx, by), width: br * 2.1, height: br * 1.15),
      const Radius.circular(18)), _fill(cAccent3.withOpacity(0.88)));
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(bx, by), width: br * 2.1, height: br * 1.15),
      const Radius.circular(18)), _stroke(Colors.white.withOpacity(0.35), 1.5));
    final tp = TextPainter(
      text: const TextSpan(text: '.....', style: TextStyle(
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(bx - tp.width / 2, by - tp.height / 2));
  }

  void _drawSparkles(Canvas canvas, double cx, double cy, double r) {
    final p = _fill(cYellow.withOpacity(0.88));
    for (final pos in [
      Offset(cx - r * 1.05, cy - r * 0.5),
      Offset(cx + r * 1.08, cy - r * 0.58),
      Offset(cx - r * 0.82, cy - r * 0.92),
    ]) {
      _drawStar(canvas, pos, r * 0.09, p);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle  = i * pi / 4;
      final radius = i.isEven ? size : size * 0.42;
      final x = center.dx + radius * cos(angle - pi / 2);
      final y = center.dy + radius * sin(angle - pi / 2);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BeastmanPainter old) =>
      old.mood != mood || old.floatAnim != floatAnim || old.spinAnim != spinAnim;
}

// ── 캐릭터 위젯 ───────────────────────────────────────────
class BeastmanCharacter extends StatefulWidget {
  final CharacterMood mood;
  final double size;
  const BeastmanCharacter({super.key, required this.mood, this.size = 150});

  @override
  State<BeastmanCharacter> createState() => _BeastmanCharacterState();
}

class _BeastmanCharacterState extends State<BeastmanCharacter>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _spinCtrl;
  late Animation<double> _floatAnim;
  late Animation<double> _spinAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _spinCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _floatAnim = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);
    _spinAnim  = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _spinCtrl, curve: Curves.linear));
    if (widget.mood == CharacterMood.thinking) _spinCtrl.repeat();
  }

  @override
  void didUpdateWidget(BeastmanCharacter old) {
    super.didUpdateWidget(old);
    if (widget.mood == CharacterMood.thinking) {
      if (!_spinCtrl.isAnimating) _spinCtrl.repeat();
    } else {
      _spinCtrl.stop();
      _spinCtrl.reset();
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnim, _spinAnim]),
      builder: (context, _) {
        final floatOffset = sin(_floatAnim.value * pi) * 8.0;
        final spin = widget.mood == CharacterMood.thinking ? _spinAnim.value : 0.0;
        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: Transform.rotate(
            angle: spin,
            child: SizedBox(
              width: widget.size,
              height: widget.size * 1.5,
              child: CustomPaint(
                painter: BeastmanPainter(
                  mood: widget.mood,
                  floatAnim: _floatAnim.value,
                  spinAnim: spin,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── 앱 ───────────────────────────────────────────────────
class VibeViewApp extends StatelessWidget {
  const VibeViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeView',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.light(primary: kAccent, surface: kSurface),
      ),
      home: const HomePage(),
    );
  }
}

// ── 홈 화면 ───────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  bool _loading = false;
  String _error = '';

  Future<void> _analyze() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) { setState(() => _error = 'YouTube URL을 입력해주세요.'); return; }
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await http.post(
        Uri.parse('$kApiBase/api/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      ).timeout(const Duration(minutes: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResultPage(result: data, url: url)));
      } else {
        final err = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _error = err['detail']?.toString() ?? '분석 실패 (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _error = '서버 연결 실패. 백엔드가 실행 중인지 확인해주세요.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(colors: [kAccent, Color(0xFF00A882)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: kAccent.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Center(child: Text('🎬', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('VibeView', style: TextStyle(color: kText, fontSize: 20,
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  Text('감정이 조회수를 만든다', style: TextStyle(color: kTextMid, fontSize: 11)),
                ]),
                const Spacer(),
                // 트렌드 버튼
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrendPage())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: kAccent3.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kAccent3.withOpacity(0.3)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('📊', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text('트렌드', style: TextStyle(color: kAccent3, fontSize: 12,
                        fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Center(child: BeastmanCharacter(
                mood: _loading ? CharacterMood.thinking : CharacterMood.idle, size: 130)),
              const SizedBox(height: 6),
              Center(child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Container(
                  key: ValueKey(_loading),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: _loading ? kAccent3.withOpacity(0.1) : kAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _loading ? kAccent3.withOpacity(0.28) : kAccent.withOpacity(0.28), width: 1.5),
                  ),
                  child: Text(
                    _loading ? '영상 분석 중이에요~ 잠깐만요! 🤔' : '안녕! YouTube URL을 입력해줘 👋',
                    style: TextStyle(color: _loading ? kAccent3 : kAccent,
                      fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              )),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('// ANALYZE VIDEO', style: TextStyle(color: kAccent,
                  fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
                  children: [
                    TextSpan(text: '영상 URL을 입력하고\n', style: TextStyle(color: kText)),
                    TextSpan(text: '감정을 분석', style: TextStyle(color: kAccent)),
                    TextSpan(text: '하세요', style: TextStyle(color: kText)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: kSurface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder, width: 1.5),
                  boxShadow: [BoxShadow(color: kAccent.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(color: kText, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'https://youtube.com/shorts/...',
                    hintStyle: const TextStyle(color: kTextDim, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: const Icon(Icons.link_rounded, color: kTextDim, size: 20),
                  ),
                  onSubmitted: (_) => _analyze(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: _loading ? null : const LinearGradient(colors: [kAccent, Color(0xFF00A882)]),
                    color: _loading ? kBorder : null,
                    boxShadow: _loading ? [] : [BoxShadow(color: kAccent.withOpacity(0.38),
                      blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                      ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                          const SizedBox(width: 10),
                          Text('분석 중...', style: TextStyle(
                            color: Colors.white.withOpacity(0.85), fontSize: 15, fontWeight: FontWeight.w700)),
                        ])
                      : const Text('✨ 분석 시작', style: TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: kAccent2.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10), border: Border.all(color: kAccent2.withOpacity(0.28))),
                  child: Row(children: [
                    const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                    Expanded(child: Text(_error, style: const TextStyle(color: kAccent2, fontSize: 13))),
                  ]),
                ),
              ],
              if (_loading) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kAccent3.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12), border: Border.all(color: kAccent3.withOpacity(0.18))),
                  child: const Row(children: [
                    Text('🎬', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('다운로드 → 얼굴 분석 → 음성 분석 → 장면 분석',
                        style: TextStyle(color: kTextMid, fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('1~3분 정도 소요될 수 있어요',
                        style: TextStyle(color: kTextDim, fontSize: 11)),
                    ])),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── 공통 위젯 헬퍼 ────────────────────────────────────────
Widget _card({required Widget child, Color? borderColor}) => Container(
  width: double.infinity, padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.only(bottom: 16),
  decoration: BoxDecoration(
    color: kSurface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor ?? kBorder, width: 1.5),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
  ),
  child: child,
);

Widget _sectionLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(text, style: const TextStyle(color: kTextDim, fontSize: 10,
    letterSpacing: 1.5, fontWeight: FontWeight.w600)),
);

Widget _miniBar(String label, double value, Color color) {
  final pct = (value * 100).round();
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        Text('$pct%', style: const TextStyle(color: kTextMid, fontSize: 11)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(value: value, backgroundColor: kBorder,
          valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 5),
      ),
    ]),
  );
}

// ── 결과 화면 ─────────────────────────────────────────────
class ResultPage extends StatefulWidget {
  final Map<String, dynamic> result;
  final String url;
  const ResultPage({super.key, required this.result, required this.url});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _coachLoading = false;
  String _coachFeedback = '';

  CharacterMood _getMood() {
    final face = widget.result['face_summary'] as Map<String, dynamic>?;
    final peak = face?['peak_emotion'] as Map<String, dynamic>?;
    switch (peak?['emotion'] as String? ?? '') {
      case 'happy':     return CharacterMood.happy;
      case 'sad':       return CharacterMood.sad;
      case 'surprised': return CharacterMood.surprised;
      case 'angry':     return CharacterMood.angry;
      default:          return CharacterMood.idle;
    }
  }

  Future<void> _getCoach() async {
    setState(() { _coachLoading = true; _coachFeedback = ''; });
    try {
      final res = await http.post(
        Uri.parse('$kApiBase/api/coach'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': 'mobile_analysis',
          'emotion_data': {
            'face_summary':  widget.result['face_summary'],
            'audio_summary': widget.result['audio_summary'],
            'video_info':    widget.result['video_info'],
          },
          'question': '이 영상의 감정 분석 결과를 바탕으로 크리에이터에게 구체적인 피드백을 한국어로 해줘.',
        }),
      ).timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        setState(() => _coachFeedback = data['feedback']?.toString() ?? '피드백을 가져올 수 없습니다.');
      } else {
        setState(() => _coachFeedback = 'AI 코치 응답 실패 (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _coachFeedback = 'AI 코치 연결 실패.');
    } finally {
      setState(() => _coachLoading = false);
    }
  }

  Widget _emotionBar(String emotion, double value) {
    final color = kEmotionColors[emotion] ?? kTextDim;
    final pct   = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(kEmotionKo[emotion] ?? emotion,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          Text('$pct%', style: const TextStyle(color: kTextMid, fontSize: 12)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: value, backgroundColor: kBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 7)),
      ]),
    );
  }

  Widget _statCell(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: kTextDim, fontSize: 9, letterSpacing: 1,
          fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    ),
  );

  Widget _infoCard(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: kTextDim, fontSize: 9, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w800)),
      ]),
    ),
  );

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: kTextDim, fontSize: 10)),
    ],
  );

  String _fmtNum(dynamic n) {
    if (n == null) return '-';
    final v = (n as num).toDouble();
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final videoInfo    = (widget.result['video_info']     as Map<String, dynamic>?) ?? {};
    final ytStats      = (widget.result['youtube_stats']  as Map<String, dynamic>?) ?? {};
    final faceSummary  = (widget.result['face_summary']   as Map<String, dynamic>?) ?? {};
    final audioSummary = (widget.result['audio_summary']  as Map<String, dynamic>?) ?? {};
    final sceneSummary = (widget.result['scene_summary']  as Map<String, dynamic>?) ?? {};
    final fusionResult = (widget.result['fusion_result']  as Map<String, dynamic>?) ?? {};
    final viralResult  = (widget.result['viral_result']   as Map<String, dynamic>?) ?? {};
    final timeline     = (widget.result['emotion_timeline'] as List<dynamic>?) ?? [];

    final emotionDist     = (faceSummary['emotion_distribution'] as Map<String, dynamic>?) ?? {};
    final peakEmotion     = faceSummary['peak_emotion'] as Map<String, dynamic>?;
    final dominantEmotion = peakEmotion?['emotion'] as String? ?? '';
    final dominantColor   = kEmotionColors[dominantEmotion] ?? kAccent;
    final sortedEmotions  = emotionDist.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    final mood = _getMood();

    // 바이럴 등급
    final grade      = viralResult['grade'] as String? ?? '';
    final gradeColor = kGradeColors[grade] ?? kTextDim;
    final viralScore = (viralResult['viral_score'] as num?)?.toStringAsFixed(1) ?? '-';

    // 장면 분위기 분포
    final vibeColors = [kAccent, kAccent3, kYellow, kAccent2, const Color(0xFF5B9BD5), const Color(0xFFB39DDB)];
    final vibeDist   = (sceneSummary['vibe_distribution'] as Map<String, dynamic>?) ?? {};
    final vibeList   = vibeDist.entries.toList()..sort((a, b) => (b.value as num).compareTo(a.value as num));

    // 모달리티 점수
    final modalityScores = (fusionResult['modality_scores'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: kText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(children: [
          Text('🎬', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('VibeView', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── 캐릭터 + 감정 배지 ──────────────────────────
            _card(child: Column(children: [
              Center(child: BeastmanCharacter(mood: mood, size: 110)),
              const SizedBox(height: 8),
              Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: dominantColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dominantColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${kEmotionKo[dominantEmotion] ?? dominantEmotion} 감정이 가장 강해요! ✨',
                  style: TextStyle(color: dominantColor, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              )),
            ])),

            // ── YouTube 통계 ─────────────────────────────────
            if (ytStats.isNotEmpty) ...[
              _sectionLabel('YOUTUBE STATS'),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // 썸네일
                  if (ytStats['thumbnail_url'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ytStats['thumbnail_url'] as String,
                        width: 100, height: 60, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100, height: 60, color: kSurface2,
                          child: const Icon(Icons.image_not_supported, color: kTextDim)),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (ytStats['title'] != null)
                      Text(ytStats['title'] as String,
                        style: const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w700, height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (ytStats['channel'] != null) ...[
                      const SizedBox(height: 4),
                      Text('@ ${ytStats['channel']}',
                        style: const TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ])),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _statCell('VIEWS',    _fmtNum(ytStats['view_count'])),
                  const SizedBox(width: 8),
                  _statCell('LIKES',    _fmtNum(ytStats['like_count'])),
                  const SizedBox(width: 8),
                  _statCell('COMMENTS', _fmtNum(ytStats['comment_count'])),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _statCell('VIEWS/DAY', ytStats['views_per_day'] != null
                    ? _fmtNum((ytStats['views_per_day'] as num).round())
                    : '-'),
                  const SizedBox(width: 8),
                  _statCell('DAYS UP', ytStats['days_since_upload'] != null
                    ? '${ytStats['days_since_upload']}d'
                    : '-'),
                  const SizedBox(width: 8),
                  _statCell('VIDEO ID', ytStats['video_id'] != null
                    ? '${(ytStats['video_id'] as String).substring(0, min(8, (ytStats['video_id'] as String).length))}…'
                    : '-'),
                ]),
                // 태그
                if (ytStats['tags'] != null && (ytStats['tags'] as List).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6,
                    children: ((ytStats['tags'] as List).take(5)).map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kBorder)),
                      child: Text('#$t', style: const TextStyle(color: kTextMid, fontSize: 11)),
                    )).toList()),
                ],
              ])),
            ],

            // ── 비디오 기본 정보 ─────────────────────────────
            _sectionLabel('VIDEO INFO'),
            Container(margin: const EdgeInsets.only(bottom: 16), child: Column(children: [
              Row(children: [
                _infoCard('DURATION', '${(videoInfo['duration'] as num?)?.toStringAsFixed(1)}s'),
                const SizedBox(width: 8),
                _infoCard('FPS', '${(videoInfo['fps'] as num?)?.toStringAsFixed(0)}'),
                const SizedBox(width: 8),
                _infoCard('FRAMES', '${videoInfo['total_frames']}'),
              ]),
              const SizedBox(height: 8),
              Row(children: [_infoCard('RESOLUTION', '${videoInfo['width']}×${videoInfo['height']}')]),
            ])),

            // ── 얼굴 감정 ────────────────────────────────────
            _sectionLabel('FACE ANALYSIS'),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('얼굴 감정 분석', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('VALENCE', style: TextStyle(color: kTextDim, fontSize: 10)),
                  Text((faceSummary['avg_valence'] as num?)?.toStringAsFixed(2) ?? '-',
                    style: const TextStyle(color: kAccent, fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
              ]),
              const SizedBox(height: 14),
              for (final e in sortedEmotions) _emotionBar(e.key, (e.value as num).toDouble()),
              if (peakEmotion != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: dominantColor.withOpacity(0.07), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: dominantColor.withOpacity(0.22)),
                  ),
                  child: Row(children: [
                    const Text('🏆 PEAK  ', style: TextStyle(color: kTextDim, fontSize: 11)),
                    Text(kEmotionKo[dominantEmotion] ?? dominantEmotion,
                      style: TextStyle(color: dominantColor, fontSize: 14, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('@ ${(peakEmotion['timestamp'] as num?)?.toStringAsFixed(1)}s',
                      style: const TextStyle(color: kTextMid, fontSize: 12)),
                  ]),
                ),
            ])),

            // ── 음성 감정 ────────────────────────────────────
            _sectionLabel('AUDIO ANALYSIS'),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('음성 감정 분석', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('VALENCE', style: TextStyle(color: kTextDim, fontSize: 10)),
                  Text((audioSummary['avg_valence'] as num?)?.toStringAsFixed(2) ?? '-',
                    style: const TextStyle(color: kAccent3, fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _statCell('DOMINANT',
                  kEmotionKo[audioSummary['dominant_emotion']] ?? audioSummary['dominant_emotion']?.toString() ?? '-'),
                const SizedBox(width: 8),
                _statCell('TEMPO', '${(audioSummary['tempo'] as num?)?.toStringAsFixed(0) ?? '-'} BPM'),
                const SizedBox(width: 8),
                _statCell('LANGUAGE', (audioSummary['language'] as String?)?.toUpperCase() ?? '-'),
              ]),
              if ((audioSummary['full_text'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBorder)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('💬 TRANSCRIPT', style: TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(audioSummary['full_text'] as String,
                      style: const TextStyle(color: kTextMid, fontSize: 13, height: 1.5)),
                  ]),
                ),
              ],
            ])),

            // ── 장면 분석 ────────────────────────────────────
            if (sceneSummary.isNotEmpty) ...[
              _sectionLabel('SCENE ANALYSIS'),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('장면 분위기 분석', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
                  if (sceneSummary['dominant_vibe'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: kYellow.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8), border: Border.all(color: kYellow.withOpacity(0.35))),
                      child: Text(sceneSummary['dominant_vibe'] as String,
                        style: const TextStyle(color: Color(0xFFC8991A), fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ]),
                const SizedBox(height: 14),
                // 콘텐츠 유형 + 인물 비율
                Row(children: [
                  _statCell('CONTENT TYPE', sceneSummary['content_type']?.toString() ?? '-'),
                  const SizedBox(width: 8),
                  _statCell('PERSON RATIO',
                    (sceneSummary['object_stats'] as Map?)?.containsKey('person_ratio') == true
                      ? '${((sceneSummary['object_stats']['person_ratio'] as num) * 100).round()}%'
                      : '-'),
                  const SizedBox(width: 8),
                  _statCell('AVG PERSONS',
                    (sceneSummary['object_stats'] as Map?)?.containsKey('avg_person_count') == true
                      ? (sceneSummary['object_stats']['avg_person_count'] as num).toStringAsFixed(1)
                      : '-'),
                ]),
                // 분위기 분포 바
                if (vibeList.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('VIBE DISTRIBUTION', style: TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  for (int i = 0; i < vibeList.length; i++)
                    _miniBar(vibeList[i].key, (vibeList[i].value as num).toDouble(),
                      vibeColors[i % vibeColors.length]),
                ],
              ])),
            ],

            // ── 융합 결과 ────────────────────────────────────
            if (fusionResult.isNotEmpty) ...[
              _sectionLabel('FUSION RESULT'),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('멀티모달 융합 결과', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
                  if (fusionResult['fused_emotion'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: kAccent3.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8), border: Border.all(color: kAccent3.withOpacity(0.3))),
                      child: Text(fusionResult['fused_emotion'] as String,
                        style: const TextStyle(color: kAccent3, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ]),
                const SizedBox(height: 14),
                // 신뢰도 바
                if (fusionResult['confidence'] != null) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('CONFIDENCE', style: TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1)),
                    Text('${((fusionResult['confidence'] as num) * 100).round()}%',
                      style: const TextStyle(color: kAccent3, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (fusionResult['confidence'] as num).toDouble(),
                      backgroundColor: kBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(kAccent3),
                      minHeight: 7,
                    )),
                  const SizedBox(height: 14),
                ],
                // 모달리티 점수
                if (modalityScores.isNotEmpty) ...[
                  const Text('MODALITY SCORES', style: TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _statCell('FACE',  '${((modalityScores['face']  as num? ?? 0) * 100).round()}%'),
                    const SizedBox(width: 8),
                    _statCell('AUDIO', '${((modalityScores['audio'] as num? ?? 0) * 100).round()}%'),
                    const SizedBox(width: 8),
                    _statCell('SCENE', '${((modalityScores['scene'] as num? ?? 0) * 100).round()}%'),
                  ]),
                ],
                // Vibe 태그
                if (fusionResult['vibe_tags'] != null && (fusionResult['vibe_tags'] as List).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 6, runSpacing: 6,
                    children: (fusionResult['vibe_tags'] as List).map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kAccent3.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kAccent3.withOpacity(0.3)),
                      ),
                      child: Text(t.toString(), style: const TextStyle(color: kAccent3, fontSize: 11)),
                    )).toList()),
                ],
              ])),
            ],

            // ── 바이럴 점수 ──────────────────────────────────
            if (viralResult.isNotEmpty) ...[
              _sectionLabel('VIRAL PREDICTOR'),
              _card(
                borderColor: gradeColor.withOpacity(0.35),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    // 등급 뱃지
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: gradeColor.withOpacity(0.5), width: 2),
                      ),
                      child: Center(child: Text(grade,
                        style: TextStyle(color: gradeColor, fontSize: 24, fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('VIRAL PREDICTOR', style: TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1)),
                      const Text('바이럴 예측 점수', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
                    ]),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('SCORE', style: TextStyle(color: kTextDim, fontSize: 10)),
                      Text(viralScore, style: TextStyle(color: gradeColor, fontSize: 26, fontWeight: FontWeight.w800)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  // 팩터 바
                  if (viralResult['factors'] != null) ...[
                    const Text('FACTOR BREAKDOWN', style: TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    _miniBar('감정 강도',   ((viralResult['factors']['emotional_intensity']   as num?) ?? 0).toDouble(), gradeColor),
                    _miniBar('감정 일관성', ((viralResult['factors']['emotional_consistency'] as num?) ?? 0).toDouble(), gradeColor),
                    _miniBar('콘텐츠 매력', ((viralResult['factors']['content_appeal']        as num?) ?? 0).toDouble(), gradeColor),
                    _miniBar('페이싱',      ((viralResult['factors']['pacing']                as num?) ?? 0).toDouble(), gradeColor),
                    _miniBar('하이라이트',  ((viralResult['factors']['highlight_density']     as num?) ?? 0).toDouble(), gradeColor),
                    const SizedBox(height: 4),
                  ],
                  // 강점 / 약점
                  if (viralResult['strong_points'] != null || viralResult['weak_points'] != null) ...[
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (viralResult['strong_points'] != null)
                        Expanded(child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: kAccent.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10), border: Border.all(color: kAccent.withOpacity(0.2))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('✦ 강점', style: TextStyle(color: kAccent, fontSize: 10,
                              letterSpacing: 1, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            for (final pt in (viralResult['strong_points'] as List))
                              Padding(padding: const EdgeInsets.only(bottom: 4),
                                child: Text('· $pt', style: const TextStyle(color: kTextMid, fontSize: 11, height: 1.4))),
                          ]),
                        )),
                      const SizedBox(width: 8),
                      if (viralResult['weak_points'] != null)
                        Expanded(child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: kAccent2.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10), border: Border.all(color: kAccent2.withOpacity(0.2))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('✦ 약점', style: TextStyle(color: kAccent2, fontSize: 10,
                              letterSpacing: 1, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            for (final pt in (viralResult['weak_points'] as List))
                              Padding(padding: const EdgeInsets.only(bottom: 4),
                                child: Text('· $pt', style: const TextStyle(color: kTextMid, fontSize: 11, height: 1.4))),
                          ]),
                        )),
                    ]),
                    const SizedBox(height: 10),
                  ],
                  // 추천
                  if (viralResult['recommendation'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(0.06), borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: gradeColor.withOpacity(0.2)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('💡 RECOMMENDATION', style: TextStyle(color: gradeColor, fontSize: 10, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Text(viralResult['recommendation'] as String,
                          style: const TextStyle(color: kTextMid, fontSize: 12, height: 1.5)),
                      ]),
                    ),
                ]),
              ),
            ],

            // ── 감정 타임라인 ────────────────────────────────
            if (timeline.isNotEmpty) ...[
              _sectionLabel('EMOTION TIMELINE'),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('📊 총 ${timeline.length}개 구간 분석됨',
                    style: const TextStyle(color: kTextMid, fontSize: 13, fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TimelineViewerPage(timeline: timeline))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kAccent, Color(0xFF6C63FF)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🔍 장면 검증',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: timeline.length,
                    itemBuilder: (context, i) {
                      final t = timeline[i] as Map<String, dynamic>;
                      final v = (t['face_valence'] as num?)?.toDouble() ?? 0.0;
                      final h = ((v + 1) / 2 * 54 + 5).clamp(5.0, 59.0);
                      final c = v > 0.2 ? kAccent : v < -0.2 ? kAccent2 : kYellow;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 5, height: h,
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.82), borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  _legendDot(kAccent, '긍정'),
                  const SizedBox(width: 12),
                  _legendDot(kYellow, '중립'),
                  const SizedBox(width: 12),
                  _legendDot(kAccent2, '부정'),
                ]),
              ])),
            ],

            // ── AI 코치 ──────────────────────────────────────
            _sectionLabel('GEMINI AI COACH'),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('AI 감정 코치 피드백', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _coachLoading ? null : const LinearGradient(colors: [kAccent3, kAccent2]),
                    color: _coachLoading ? kBorder : null,
                    boxShadow: _coachLoading ? [] : [BoxShadow(color: kAccent3.withOpacity(0.32),
                      blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: ElevatedButton(
                    onPressed: _coachLoading ? null : _getCoach,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _coachLoading
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('🤖 AI 코치', style: TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (_coachFeedback.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kAccent3.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12), border: Border.all(color: kAccent3.withOpacity(0.18))),
                  child: Text(_coachFeedback, style: const TextStyle(color: kTextMid, fontSize: 13, height: 1.7)),
                )
              else
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder)),
                  child: const Text('AI 코치 버튼을 눌러\nGemini의 피드백을 받아보세요 🎯',
                    style: TextStyle(color: kTextDim, fontSize: 13, height: 1.6), textAlign: TextAlign.center),
                ),
            ])),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── 타임라인 장면 검증 화면 ───────────────────────────────
class TimelineViewerPage extends StatefulWidget {
  final List<dynamic> timeline;
  const TimelineViewerPage({super.key, required this.timeline});

  @override
  State<TimelineViewerPage> createState() => _TimelineViewerPageState();
}

class _TimelineViewerPageState extends State<TimelineViewerPage> {
  int _selectedIdx = 0;

  Map<String, dynamic> get _selected =>
      widget.timeline[_selectedIdx] as Map<String, dynamic>;

  // 바 높이 계산
  double _barHeight(double v, double maxH) =>
      ((v + 1) / 2 * (maxH - 10) + 5).clamp(5.0, maxH);

  Color _barColor(double v) =>
      v > 0.2 ? kAccent : v < -0.2 ? kAccent2 : kYellow;

  @override
  Widget build(BuildContext context) {
    final total = widget.timeline.length;
    final ts    = (_selected['timestamp'] as num?)?.toStringAsFixed(1) ?? '-';
    final faceEmo   = _selected['face_emotion'] as String? ?? '';
    final audioEmo  = _selected['audio_emotion'] as String? ?? '';
    final faceVal   = (_selected['face_valence']  as num?)?.toDouble() ?? 0.0;
    final audioVal  = (_selected['audio_valence'] as num?)?.toDouble() ?? 0.0;
    final audioEng  = (_selected['audio_energy']  as num?)?.toDouble() ?? 0.0;
    final frameUrl  = _selected['frame_url'] as String? ?? '';
    final faceColor = kEmotionColors[faceEmo]  ?? kTextDim;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: kText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('장면 검증', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
          Text('TIMELINE VIEWER', style: TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder)),
      ),
      body: Column(children: [

        // ── 타임라인 터치 바 차트 ────────────────────────
        Container(
          color: kSurface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('EMOTION TIMELINE',
                style: TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              Text('${_selectedIdx + 1} / $total  |  ${ts}s',
                style: const TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            GestureDetector(
              onTapDown: (d) => _onChartTouch(d.localPosition.dx, context),
              onHorizontalDragUpdate: (d) => _onChartTouch(d.localPosition.dx, context),
              child: SizedBox(
                height: 60,
                child: LayoutBuilder(builder: (ctx, constraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(total, (i) {
                      final t = widget.timeline[i] as Map<String, dynamic>;
                      final v = (t['face_valence'] as num?)?.toDouble() ?? 0.0;
                      final h = _barHeight(v, 56);
                      final c = _barColor(v);
                      final isSelected = i == _selectedIdx;
                      return Expanded(
                        child: Container(
                          height: h,
                          margin: const EdgeInsets.symmetric(horizontal: 0.8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : c.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(2),
                            border: isSelected ? Border.all(color: kAccent, width: 1.5) : null,
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
            const SizedBox(height: 5),
            Row(children: [
              _legendDot(kAccent, '긍정'),
              const SizedBox(width: 10),
              _legendDot(kYellow, '중립'),
              const SizedBox(width: 10),
              _legendDot(kAccent2, '부정'),
              const Spacer(),
              const Text('← 드래그하거나 탭하세요',
                style: TextStyle(color: kTextDim, fontSize: 10)),
            ]),
          ]),
        ),

        // ── 프레임 이미지 + 감정 정보 (스크롤 없이 한 화면) ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [

              // 시점 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kAccent.withOpacity(0.3)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$ts초 시점',
                    style: const TextStyle(color: kAccent, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Text('(${_selectedIdx + 1} / $total)',
                    style: const TextStyle(color: kTextMid, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 10),

              // 프레임 이미지 + 감정 정보를 Row로 나란히
              Expanded(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                  // 프레임 이미지 (왼쪽)
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: kAccent, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: frameUrl.isNotEmpty
                            ? Image.network(
                                'http://10.0.2.2:8000$frameUrl',
                                fit: BoxFit.cover,
                                loadingBuilder: (ctx, child, progress) => progress == null
                                  ? child
                                  : Container(color: kSurface2,
                                      child: const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2))),
                                errorBuilder: (_, __, ___) => Container(
                                  color: kSurface2,
                                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.image_not_supported_outlined, color: kTextDim, size: 32),
                                    SizedBox(height: 6),
                                    Text('이미지 없음', style: TextStyle(color: kTextDim, fontSize: 11)),
                                  ]),
                                ),
                              )
                            : Container(
                                color: kSurface2,
                                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.image_outlined, color: kTextDim, size: 32),
                                  SizedBox(height: 6),
                                  Text('이미지 없음', style: TextStyle(color: kTextDim, fontSize: 11)),
                                ]),
                              ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 감정 수치 (오른쪽)
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 감정 항목
                        for (final item in [
                          {'label': '얼굴 감정', 'value': kEmotionKo[faceEmo] ?? faceEmo, 'score': faceVal, 'color': faceColor},
                          {'label': '음성 감정', 'value': kEmotionKo[audioEmo] ?? audioEmo, 'score': audioVal, 'color': kAccent3},
                          {'label': '음성 에너지', 'value': '', 'score': audioEng, 'color': kYellow},
                        ])
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kBorder),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item['label'] as String,
                                style: TextStyle(color: item['color'] as Color,
                                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(
                                item['value'] != '' ? item['value'] as String : '-',
                                style: const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: ((item['score'] as double) + 1) / 2,
                                  backgroundColor: kBorder,
                                  valueColor: AlwaysStoppedAnimation<Color>(item['color'] as Color),
                                  minHeight: 5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text('${(item['score'] as double).toStringAsFixed(2)}',
                                style: const TextStyle(color: kTextDim, fontSize: 10)),
                            ]),
                          ),

                        // 이전 / 다음
                        Row(children: [
                          Expanded(child: GestureDetector(
                            onTap: _selectedIdx > 0 ? () => setState(() => _selectedIdx--) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedIdx > 0 ? kSurface2 : kBorder,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kBorder),
                              ),
                              child: Icon(Icons.arrow_back_ios_rounded,
                                size: 16,
                                color: _selectedIdx > 0 ? kText : kTextDim),
                            ),
                          )),
                          const SizedBox(width: 6),
                          Expanded(child: GestureDetector(
                            onTap: _selectedIdx < total - 1 ? () => setState(() => _selectedIdx++) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedIdx < total - 1 ? kAccent : kBorder,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: _selectedIdx < total - 1 ? Colors.white : kTextDim),
                            ),
                          )),
                        ]),
                      ],
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  void _onChartTouch(double localX, BuildContext context) {
    final total = widget.timeline.length;
    if (total == 0) return;
    final chartWidth = MediaQuery.of(context).size.width - 32;
    final ratio = (localX / chartWidth).clamp(0.0, 1.0);
    final idx = (ratio * (total - 1)).round();
    if (idx != _selectedIdx) setState(() => _selectedIdx = idx);
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: kTextDim, fontSize: 10)),
    ],
  );
}

// ── 트렌드 화면 ───────────────────────────────────────────
class TrendPage extends StatefulWidget {
  const TrendPage({super.key});
  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  Map<String, dynamic>? _trend;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTrend();
  }

  Future<void> _loadTrend() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await http.get(Uri.parse('$kApiBase/api/trend')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        setState(() { _trend = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>; });
      } else {
        setState(() => _error = '트렌드 로딩 실패 (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _error = '서버 연결 실패. 백엔드가 실행 중인지 확인해주세요.');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _fmtNum(dynamic n) {
    if (n == null) return '-';
    final v = (n as num).toDouble();
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: kText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(children: [
          Text('📊', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('트렌드', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kTextMid),
            onPressed: _loadTrend,
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: kAccent))
        : _error.isNotEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_error, style: const TextStyle(color: kAccent2, fontSize: 13)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadTrend,
                child: const Text('다시 시도')),
            ]))
          : _buildTrendContent(),
    );
  }

  Widget _buildTrendContent() {
    if (_trend == null) return const SizedBox();
    final trend = _trend!;

    final gradeDist   = (trend['grade_distribution']   as Map<String, dynamic>?) ?? {};
    final emotionDist = (trend['emotion_distribution'] as Map<String, dynamic>?) ?? {};
    final topViral    = (trend['top_viral']             as List<dynamic>?)        ?? [];
    final recent      = (trend['recent_videos']         as List<dynamic>?)        ?? [];

    // 등급 정렬
    final gradeOrder  = ['S','A','B','C','D'];
    final gradeList   = gradeOrder.where(gradeDist.containsKey).map((g) =>
      MapEntry(g, (gradeDist[g] as num).toDouble())).toList();

    // 감정 분포
    final emotionList = emotionDist.entries.toList();

    final vibeColors = [kAccent, kAccent3, kYellow, kAccent2, const Color(0xFF5B9BD5), const Color(0xFFB39DDB)];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // 요약 통계 3칸
        Row(children: [
          Expanded(child: _summaryCell('분석 총수', '${trend['total_analyzed'] ?? 0}', kAccent)),
          const SizedBox(width: 10),
          Expanded(child: _summaryCell('평균 바이럴', '${(trend['avg_viral_score'] as num?)?.toStringAsFixed(1) ?? '-'}', kAccent3)),
          const SizedBox(width: 10),
          Expanded(child: _summaryCell('평균 감정극성', '${(trend['avg_valence'] as num?)?.toStringAsFixed(2) ?? '-'}', kYellow)),
        ]),
        const SizedBox(height: 16),

        // 등급 분포
        _sectionLabel('GRADE DISTRIBUTION'),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('등급 분포', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          if (gradeList.isEmpty)
            const Text('데이터 없음', style: TextStyle(color: kTextDim, fontSize: 13))
          else
            for (final e in gradeList) ...[
              Row(children: [
                Container(width: 28, alignment: Alignment.center,
                  child: Text(e.key, style: TextStyle(color: kGradeColors[e.key] ?? kTextDim,
                    fontSize: 14, fontWeight: FontWeight.w800))),
                const SizedBox(width: 8),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: e.value, backgroundColor: kBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(kGradeColors[e.key] ?? kTextDim), minHeight: 8))),
                const SizedBox(width: 8),
                Text('${(e.value * 100).round()}%',
                  style: const TextStyle(color: kTextMid, fontSize: 12, fontFamily: 'monospace')),
              ]),
              const SizedBox(height: 8),
            ],
        ])),

        // 감정 분포
        _sectionLabel('EMOTION DISTRIBUTION'),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('감정 분포', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          if (emotionList.isEmpty)
            const Text('데이터 없음', style: TextStyle(color: kTextDim, fontSize: 13))
          else
            for (int i = 0; i < emotionList.length; i++)
              _miniBar(emotionList[i].key, (emotionList[i].value as num).toDouble(),
                vibeColors[i % vibeColors.length]),
        ])),

        // 바이럴 상위 영상
        if (topViral.isNotEmpty) ...[
          _sectionLabel('TOP VIRAL'),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('바이럴 상위 영상', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            for (int i = 0; i < topViral.length; i++) _topViralItem(topViral[i] as Map, i),
          ])),
        ],

        // 최근 분석 기록
        if (recent.isNotEmpty) ...[
          _sectionLabel('RECENT ANALYSES'),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('최근 분석 기록', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            for (final v in recent) _recentItem(v as Map),
          ])),
        ],

        // 데이터 없음
        if ((trend['total_analyzed'] ?? 0) == 0)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(32),
            child: const Column(children: [
              Text('📭', style: TextStyle(fontSize: 40)),
              SizedBox(height: 12),
              Text('아직 분석된 영상이 없습니다.\n먼저 영상을 분석해보세요!',
                style: TextStyle(color: kTextDim, fontSize: 14, height: 1.6), textAlign: TextAlign.center),
            ]),
          ),

        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _summaryCell(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder, width: 1.5)),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 0.5),
        textAlign: TextAlign.center),
    ]),
  );

  Widget _topViralItem(Map v, int i) {
    final grade = v['grade'] as String? ?? '';
    final gc    = kGradeColors[grade] ?? kTextDim;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder)),
      child: Row(children: [
        Text('#${i + 1}', style: TextStyle(color: gc, fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        if (v['thumbnail_url'] != null)
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: Image.network(v['thumbnail_url'] as String,
              width: 56, height: 36, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 36))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v['title']?.toString() ?? '제목 없음',
            style: const TextStyle(color: kText, fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${v['channel'] ?? ''} · ${_fmtNum(v['view_count'])} views · ${v['fused_emotion'] ?? ''}',
            style: const TextStyle(color: kTextDim, fontSize: 10)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(grade, style: TextStyle(color: gc, fontSize: 14, fontWeight: FontWeight.w800)),
          Text('${(v['viral_score'] as num?)?.toStringAsFixed(1) ?? '-'}',
            style: const TextStyle(color: kTextMid, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _recentItem(Map v) {
    final grade = v['grade'] as String? ?? '';
    final gc    = kGradeColors[grade] ?? kTextDim;
    final date  = v['analyzed_at'] != null
      ? DateTime.tryParse(v['analyzed_at'].toString())?.toLocal().toString().substring(0, 10) ?? '-'
      : '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface2, borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: gc, width: 3), top: BorderSide(color: kBorder),
          right: BorderSide(color: kBorder), bottom: BorderSide(color: kBorder)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v['title']?.toString() ?? '제목 없음',
            style: const TextStyle(color: kText, fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${v['channel'] ?? ''} · $date',
            style: const TextStyle(color: kTextDim, fontSize: 10)),
        ])),
        const SizedBox(width: 8),
        Text('$grade ${(v['viral_score'] as num?)?.toStringAsFixed(1) ?? '-'}',
          style: TextStyle(color: gc, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
