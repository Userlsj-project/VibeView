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

  // ── 색상 (static const) ──────────────────────────────────
  static const Color cSkin     = Color(0xFFFFE0C4);  // 피부
  static const Color cSkinDark = Color(0xFFFFCA9E);  // 피부 음영
  static const Color cHair     = Color(0xFFF5F0E8);  // 흰 머리카락
  static const Color cHairDim  = Color(0xFFE8E2D5);  // 머리카락 음영
  static const Color cStripe   = Color(0xFF8B9DB5);  // 회청색 줄무늬
  static const Color cOutline  = Color(0xFF3D3530);  // 외곽선 (따뜻한 어두운 색)
  static const Color cEyeL     = Color(0xFF5BB8FF);  // 백호 파란 눈
  static const Color cPupil    = Color(0xFF1A1A2E);  // 동공
  static const Color cBlush    = Color(0xFFFFB3C8);  // 볼터치
  static const Color cEarIn    = Color(0xFFFFCCDD);  // 귀 안쪽
  static const Color cTeeth    = Color(0xFFFFFBF0);  // 이빨
  static const Color cTongue   = Color(0xFFFF8FAB);  // 혀
  static const Color cNose     = Color(0xFFE8967A);  // 코
  static const Color cLip      = Color(0xFFD4786A);  // 입술
  static const Color cCloth    = Color(0xFF4A90D9);  // 옷 (파란색)
  static const Color cCloth2   = Color(0xFF2E6DB4);  // 옷 어두운 부분

  // 전역 색상 참조
  static const Color cAccent2  = kAccent2;
  static const Color cAccent3  = kAccent3;
  static const Color cYellow   = kYellow;
  static const Color cTextDim  = kTextDim;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.38;
    final r  = size.width * 0.33;

    // 그리기 순서: 귀 → 머리카락(뒤) → 몸 → 얼굴 → 머리카락(앞) → 장식
    _drawTigerEars(canvas, cx, cy, r);
    _drawHairBack(canvas, cx, cy, r);
    _drawBody(canvas, cx, cy, r);
    _drawFace(canvas, cx, cy, r);
    _drawHairFront(canvas, cx, cy, r);
    _drawDecorations(canvas, cx, cy, r);
  }

  // ── 호랑이 귀 ────────────────────────────────────────────
  void _drawTigerEars(Canvas canvas, double cx, double cy, double r) {
    for (final isLeft in [true, false]) {
      final ex = isLeft ? cx - r * 0.68 : cx + r * 0.68;
      final ey = cy - r * 0.82;

      // 귀 외형 (뾰족한 삼각형)
      final earPath = Path()
        ..moveTo(ex, ey - r * 0.42)           // 꼭대기
        ..lineTo(ex - r * 0.28, ey + r * 0.18) // 왼쪽 아래
        ..lineTo(ex + r * 0.28, ey + r * 0.18) // 오른쪽 아래
        ..close();
      canvas.drawPath(earPath, _fill(cHair));
      canvas.drawPath(earPath, _fill(cStripe.withOpacity(0.15)));
      canvas.drawPath(earPath, _stroke(cOutline, 1.8));

      // 귀 안쪽 핑크
      final innerPath = Path()
        ..moveTo(ex, ey - r * 0.28)
        ..lineTo(ex - r * 0.15, ey + r * 0.08)
        ..lineTo(ex + r * 0.15, ey + r * 0.08)
        ..close();
      canvas.drawPath(innerPath, _fill(cEarIn));

      // 귀 털 줄무늬
      canvas.drawLine(
        Offset(ex - r * 0.06, ey - r * 0.22),
        Offset(ex - r * 0.04, ey + r * 0.06),
        _stroke(cStripe.withOpacity(0.35), 1.5),
      );
      canvas.drawLine(
        Offset(ex + r * 0.06, ey - r * 0.22),
        Offset(ex + r * 0.04, ey + r * 0.06),
        _stroke(cStripe.withOpacity(0.35), 1.5),
      );
    }
  }

  // ── 머리카락 (뒤) ─────────────────────────────────────────
  void _drawHairBack(Canvas canvas, double cx, double cy, double r) {
    // 뒤쪽 머리카락 (얼굴보다 먼저 그려서 뒤에 위치)
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

  // ── 몸 (SD 치비) ─────────────────────────────────────────
  void _drawBody(Canvas canvas, double cx, double cy, double r) {
    final by = cy + r * 1.08;

    // 몸통 (옷)
    final bodyPath = Path()
      ..moveTo(cx - r * 0.58, cy + r * 0.78)
      ..quadraticBezierTo(cx - r * 0.72, by + r * 0.1, cx - r * 0.55, by + r * 0.58)
      ..lineTo(cx + r * 0.55, by + r * 0.58)
      ..quadraticBezierTo(cx + r * 0.72, by + r * 0.1, cx + r * 0.58, cy + r * 0.78)
      ..close();
    canvas.drawPath(bodyPath, _fill(cCloth));
    canvas.drawPath(bodyPath, _stroke(cOutline, 1.8));

    // 옷 깃 (흰색)
    final collarPath = Path()
      ..moveTo(cx - r * 0.22, cy + r * 0.82)
      ..lineTo(cx, cy + r * 1.05)
      ..lineTo(cx + r * 0.22, cy + r * 0.82);
    canvas.drawPath(collarPath, _fill(Colors.white));
    canvas.drawPath(collarPath, _stroke(cOutline, 1.5));

    // 옷 줄무늬 (백호 느낌)
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(cx + i * r * 0.22, cy + r * 0.88),
        Offset(cx + i * r * 0.2, by + r * 0.4),
        _stroke(cCloth2.withOpacity(0.5), 2.0),
      );
    }

    // 팔 (SD 짧은 팔)
    _drawArm(canvas, cx - r * 0.68, by - r * 0.08, r * 0.2, true);
    _drawArm(canvas, cx + r * 0.68, by - r * 0.08, r * 0.2, false);

    // 다리
    for (final dx in [-0.26, 0.26]) {
      // 바지
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + r * dx, by + r * 0.75),
            width: r * 0.38, height: r * 0.44,
          ),
          const Radius.circular(14),
        ),
        _fill(const Color(0xFF2E4A6B)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + r * dx, by + r * 0.75),
            width: r * 0.38, height: r * 0.44,
          ),
          const Radius.circular(14),
        ),
        _stroke(cOutline, 1.5),
      );
      // 신발
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + r * dx + r * 0.04, by + r * 1.0),
          width: r * 0.44, height: r * 0.22,
        ),
        _fill(const Color(0xFF1A2A3A)),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + r * dx + r * 0.04, by + r * 1.0),
          width: r * 0.44, height: r * 0.22,
        ),
        _stroke(cOutline, 1.4),
      );
    }

    // 꼬리 (옷 뒤에서 나오는)
    final tailPath = Path()
      ..moveTo(cx + r * 0.5, by + r * 0.35)
      ..cubicTo(
        cx + r * 1.05, by,
        cx + r * 1.25, by + r * 0.55,
        cx + r * 0.88, by + r * 0.78,
      );
    canvas.drawPath(tailPath, _stroke(cHair, r * 0.24));
    canvas.drawPath(tailPath, _stroke(cOutline, r * 0.24 + 1.8));
    canvas.drawPath(tailPath, _stroke(cHair, r * 0.18));
    // 꼬리 줄무늬
    for (double t = 0.15; t < 0.85; t += 0.25) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + r * (0.5 + t * 0.48), by + r * (0.35 - t * 0.12 + t * t * 0.55)),
          width: r * 0.07, height: r * 0.18,
        ),
        _fill(cStripe.withOpacity(0.5)),
      );
    }
  }

  void _drawArm(Canvas canvas, double ax, double ay, double ar, bool isLeft) {
    canvas.save();
    canvas.translate(ax, ay);
    canvas.rotate(isLeft ? 0.3 : -0.3);
    // 소매
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: ar * 1.2, height: ar * 2.2),
      _fill(cCloth),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: ar * 1.2, height: ar * 2.2),
      _stroke(cOutline, 1.5),
    );
    // 손 (피부)
    canvas.drawCircle(Offset(0, ar * 1.0), ar * 0.55, _fill(cSkin));
    canvas.drawCircle(Offset(0, ar * 1.0), ar * 0.55, _stroke(cOutline, 1.3));
    canvas.restore();
  }

  // ── 얼굴 ─────────────────────────────────────────────────
  void _drawFace(Canvas canvas, double cx, double cy, double r) {
    // 얼굴 그림자
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + r * 0.02, cy + r * 0.04),
        width: r * 2.08, height: r * 2.08),
      _fill(cOutline.withOpacity(0.05)),
    );

    // 얼굴 (사람 얼굴형 - 약간 갸름한 SD)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2.0, height: r * 2.05),
      _fill(cSkin),
    );

    // 볼터치
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - r * 0.58, cy + r * 0.2),
        width: r * 0.5, height: r * 0.28),
      _fill(cBlush.withOpacity(0.6)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + r * 0.58, cy + r * 0.2),
        width: r * 0.5, height: r * 0.28),
      _fill(cBlush.withOpacity(0.6)),
    );

    // 눈
    _drawEyes(canvas, cx, cy, r);

    // 코 (사람 코 - 작고 귀여운)
    _drawNose(canvas, cx, cy, r);

    // 입
    _drawMouth(canvas, cx, cy, r);

    // 얼굴 외곽선
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2.0, height: r * 2.05),
      _stroke(cOutline, 2.0),
    );

    // 이마 줄무늬 (백호 특징 - 얼굴 외곽선 위에)
    _drawForheadStripes(canvas, cx, cy, r);
  }

  // ── 머리카락 (앞) ─────────────────────────────────────────
  void _drawHairFront(Canvas canvas, double cx, double cy, double r) {
    // 앞머리 (얼굴 앞에 겹치도록)
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

    // 앞머리 가닥 (삐쭉삐쭉)
    _drawHairStrands(canvas, cx, cy, r);

    // 머리카락 줄무늬 (백호 느낌)
    _drawHairStripes(canvas, cx, cy, r);
  }

  void _drawHairStrands(Canvas canvas, double cx, double cy, double r) {
    // 앞머리 가닥들
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
    // 머리카락에 미세한 줄무늬
    final sw = _stroke(cStripe.withOpacity(0.2), r * 0.055);
    final p1 = Path()
      ..moveTo(cx - r * 0.25, cy - r * 1.08)
      ..quadraticBezierTo(cx - r * 0.18, cy - r * 0.82, cx - r * 0.14, cy - r * 0.62);
    canvas.drawPath(p1, sw);
    final p2 = Path()
      ..moveTo(cx + r * 0.12, cy - r * 1.1)
      ..quadraticBezierTo(cx + r * 0.08, cy - r * 0.85, cx + r * 0.06, cy - r * 0.65);
    canvas.drawPath(p2, sw);
    final p3 = Path()
      ..moveTo(cx + r * 0.45, cy - r * 1.0)
      ..quadraticBezierTo(cx + r * 0.38, cy - r * 0.8, cx + r * 0.32, cy - r * 0.62);
    canvas.drawPath(p3, _stroke(cStripe.withOpacity(0.15), r * 0.045));
  }

  void _drawForheadStripes(Canvas canvas, double cx, double cy, double r) {
    // 이마 줄무늬 (백호 특징)
    final sw = _stroke(cStripe.withOpacity(0.32), r * 0.07);
    // 중앙 줄무늬
    final p1 = Path()
      ..moveTo(cx, cy - r * 0.6)
      ..quadraticBezierTo(cx + r * 0.02, cy - r * 0.45, cx, cy - r * 0.32);
    canvas.drawPath(p1, sw);
    // 왼쪽
    final p2 = Path()
      ..moveTo(cx - r * 0.22, cy - r * 0.55)
      ..quadraticBezierTo(cx - r * 0.18, cy - r * 0.42, cx - r * 0.15, cy - r * 0.3);
    canvas.drawPath(p2, _stroke(cStripe.withOpacity(0.22), r * 0.055));
    // 오른쪽
    final p3 = Path()
      ..moveTo(cx + r * 0.22, cy - r * 0.55)
      ..quadraticBezierTo(cx + r * 0.18, cy - r * 0.42, cx + r * 0.15, cy - r * 0.3);
    canvas.drawPath(p3, _stroke(cStripe.withOpacity(0.22), r * 0.055));
  }

  // ── 눈 (사람 눈 기반) ─────────────────────────────────────
  void _drawEyes(Canvas canvas, double cx, double cy, double r) {
    final lx = cx - r * 0.34;
    final rx = cx + r * 0.34;
    final ey = cy - r * 0.06;
    final ew = r * 0.32;  // 눈 너비
    final eh = r * 0.22;  // 눈 높이

    switch (mood) {
      case CharacterMood.happy:
        // ^_^ 초승달 눈
        for (final ex in [lx, rx]) {
          final p = Path()
            ..moveTo(ex - ew * 0.9, ey + eh * 0.2)
            ..quadraticBezierTo(ex, ey - eh * 1.4, ex + ew * 0.9, ey + eh * 0.2);
          canvas.drawPath(p, _stroke(cOutline, 2.8));
          // 눈 아래 반짝임
          canvas.drawOval(
            Rect.fromCenter(center: Offset(ex, ey + eh * 0.6),
              width: ew * 1.2, height: eh * 0.5),
            _fill(cEyeL.withOpacity(0.18)),
          );
        }
        // 웃는 눈썹
        _drawEyebrows(canvas, lx, rx, ey, ew, r, mood);
        break;

      case CharacterMood.sad:
        _drawBaseEyes(canvas, lx, rx, ey, ew, eh, r, offsetY: eh * 0.15);
        _drawEyebrows(canvas, lx, rx, ey, ew, r, mood);
        // 눈물
        _drawTear(canvas, lx + ew * 0.1, ey + eh * 1.5, r * 0.12);
        break;

      case CharacterMood.surprised:
        _drawBaseEyes(canvas, lx, rx, ey - eh * 0.1, ew * 1.2, eh * 1.35, r);
        _drawEyebrows(canvas, lx, rx, ey, ew, r, mood);
        break;

      case CharacterMood.thinking:
        _drawBaseEyes(canvas, lx, rx, ey, ew, eh, r);
        // 오른쪽 눈 반쯤 감기
        canvas.drawRect(
          Rect.fromLTWH(rx - ew, ey - eh * 0.1, ew * 2.0, eh * 0.6),
          _fill(cSkin),
        );
        canvas.drawLine(
          Offset(rx - ew * 0.9, ey),
          Offset(rx + ew * 0.9, ey),
          _stroke(cOutline, 2.5),
        );
        _drawEyebrows(canvas, lx, rx, ey, ew, r, mood);
        break;

      case CharacterMood.angry:
        _drawBaseEyes(canvas, lx, rx, ey + eh * 0.1, ew * 0.92, eh * 0.85, r);
        _drawEyebrows(canvas, lx, rx, ey, ew, r, mood);
        break;

      default: // idle
        _drawBaseEyes(canvas, lx, rx, ey, ew, eh, r);
        _drawEyebrows(canvas, lx, rx, ey, ew, r, mood);
    }
  }

  void _drawBaseEyes(Canvas canvas, double lx, double rx, double ey,
      double ew, double eh, double r, {double offsetY = 0}) {
    for (final ex in [lx, rx]) {
      // 흰자 (눈 모양)
      final eyePath = Path()
        ..moveTo(ex - ew, ey + offsetY)
        ..quadraticBezierTo(ex, ey - eh + offsetY, ex + ew, ey + offsetY)
        ..quadraticBezierTo(ex, ey + eh + offsetY, ex - ew, ey + offsetY)
        ..close();
      canvas.drawPath(eyePath, _fill(Colors.white));

      // 홍채 (파란색 - 백호)
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, ey + offsetY + eh * 0.05),
          width: ew * 1.0, height: eh * 1.5),
        _fill(cEyeL),
      );

      // 동공
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex + ew * 0.08, ey + offsetY + eh * 0.1),
          width: ew * 0.5, height: eh * 0.85),
        _fill(cPupil),
      );

      // 하이라이트
      canvas.drawCircle(
        Offset(ex + ew * 0.28, ey - eh * 0.15 + offsetY),
        r * 0.055,
        _fill(Colors.white),
      );
      canvas.drawCircle(
        Offset(ex - ew * 0.1, ey + eh * 0.25 + offsetY),
        r * 0.028,
        _fill(Colors.white.withOpacity(0.7)),
      );

      // 눈 테두리
      canvas.drawPath(
        Path()
          ..moveTo(ex - ew, ey + offsetY)
          ..quadraticBezierTo(ex, ey - eh + offsetY, ex + ew, ey + offsetY)
          ..quadraticBezierTo(ex, ey + eh + offsetY, ex - ew, ey + offsetY)
          ..close(),
        _stroke(cOutline, 1.8),
      );

      // 속눈썹 (위쪽)
      for (int i = -2; i <= 2; i++) {
        final lashX = ex + i * ew * 0.38;
        final lashY = ey - eh * 0.85 + offsetY;
        canvas.drawLine(
          Offset(lashX, lashY),
          Offset(lashX + i * r * 0.015, lashY - r * 0.045),
          _stroke(cOutline, 1.4),
        );
      }
    }
  }

  void _drawEyebrows(Canvas canvas, double lx, double rx,
      double ey, double ew, double r, CharacterMood mood) {
    final by = ey - r * 0.28;

    switch (mood) {
      case CharacterMood.happy:
        for (final ex in [lx, rx]) {
          final p = Path()
            ..moveTo(ex - ew * 0.85, by + r * 0.04)
            ..quadraticBezierTo(ex, by - r * 0.06, ex + ew * 0.85, by + r * 0.04);
          canvas.drawPath(p, _stroke(cOutline, 2.2));
        }
        break;
      case CharacterMood.sad:
        canvas.drawLine(Offset(lx - ew, by - r * 0.04), Offset(lx + ew, by + r * 0.04),
          _stroke(cOutline, 2.2));
        canvas.drawLine(Offset(rx - ew, by + r * 0.04), Offset(rx + ew, by - r * 0.04),
          _stroke(cOutline, 2.2));
        break;
      case CharacterMood.surprised:
        for (final ex in [lx, rx]) {
          final p = Path()
            ..moveTo(ex - ew * 0.85, by - r * 0.06)
            ..quadraticBezierTo(ex, by - r * 0.16, ex + ew * 0.85, by - r * 0.06);
          canvas.drawPath(p, _stroke(cOutline, 2.5));
        }
        break;
      case CharacterMood.thinking:
        canvas.drawLine(Offset(lx - ew * 0.8, by), Offset(lx + ew * 0.8, by),
          _stroke(cOutline, 2.0));
        final tp = Path()
          ..moveTo(rx - ew * 0.8, by + r * 0.02)
          ..quadraticBezierTo(rx, by - r * 0.1, rx + ew * 0.8, by + r * 0.02);
        canvas.drawPath(tp, _stroke(cOutline, 2.0));
        break;
      case CharacterMood.angry:
        canvas.drawLine(Offset(lx - ew, by - r * 0.02), Offset(lx + ew, by + r * 0.08),
          _stroke(cAccent2, 2.8));
        canvas.drawLine(Offset(rx - ew, by + r * 0.08), Offset(rx + ew, by - r * 0.02),
          _stroke(cAccent2, 2.8));
        break;
      default:
        for (final ex in [lx, rx]) {
          final p = Path()
            ..moveTo(ex - ew * 0.85, by + r * 0.02)
            ..quadraticBezierTo(ex, by - r * 0.04, ex + ew * 0.85, by + r * 0.02);
          canvas.drawPath(p, _stroke(cOutline.withOpacity(0.7), 2.0));
        }
    }
  }

  void _drawTear(Canvas canvas, double tx, double ty, double tr) {
    final path = Path()
      ..moveTo(tx, ty - tr * 0.4)
      ..quadraticBezierTo(tx + tr * 0.5, ty + tr * 0.1, tx, ty + tr * 0.7)
      ..quadraticBezierTo(tx - tr * 0.5, ty + tr * 0.1, tx, ty - tr * 0.4);
    canvas.drawPath(path, _fill(const Color(0xFF93C5FD).withOpacity(0.85)));
  }

  // ── 코 (사람 코) ──────────────────────────────────────────
  void _drawNose(Canvas canvas, double cx, double cy, double r) {
    // 작고 귀여운 사람 코
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.18),
        width: r * 0.22, height: r * 0.14),
      _fill(cSkinDark),
    );
    // 콧구멍 (작은 점 2개)
    canvas.drawCircle(Offset(cx - r * 0.07, cy + r * 0.19), r * 0.04,
      _fill(cNose.withOpacity(0.6)));
    canvas.drawCircle(Offset(cx + r * 0.07, cy + r * 0.19), r * 0.04,
      _fill(cNose.withOpacity(0.6)));
  }

  // ── 입 ────────────────────────────────────────────────────
  void _drawMouth(Canvas canvas, double cx, double cy, double r) {
    final my = cy + r * 0.4;

    switch (mood) {
      case CharacterMood.happy:
        // 활짝 웃는 입
        final mouthPath = Path()
          ..moveTo(cx - r * 0.35, my - r * 0.04)
          ..quadraticBezierTo(cx, my + r * 0.32, cx + r * 0.35, my - r * 0.04);
        canvas.drawPath(mouthPath, _stroke(cOutline, 2.5));
        // 이빨
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, my + r * 0.1),
              width: r * 0.42, height: r * 0.16),
            const Radius.circular(5),
          ),
          _fill(cTeeth),
        );
        canvas.drawLine(Offset(cx, my + r * 0.02), Offset(cx, my + r * 0.18),
          _stroke(const Color(0xFFDDD8C8), 1.4));
        // 혀
        final tonguePath = Path()
          ..moveTo(cx - r * 0.15, my + r * 0.18)
          ..quadraticBezierTo(cx, my + r * 0.38, cx + r * 0.15, my + r * 0.18);
        canvas.drawPath(tonguePath, _fill(cTongue));
        break;

      case CharacterMood.sad:
        final path = Path()
          ..moveTo(cx - r * 0.28, my + r * 0.1)
          ..quadraticBezierTo(cx, my - r * 0.15, cx + r * 0.28, my + r * 0.1);
        canvas.drawPath(path, _stroke(const Color(0xFF5B9BD5), 2.4));
        break;

      case CharacterMood.surprised:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, my + r * 0.05),
            width: r * 0.26, height: r * 0.34),
          _fill(const Color(0xFF3D3530)),
        );
        break;

      case CharacterMood.thinking:
        final path = Path()
          ..moveTo(cx - r * 0.1, my + r * 0.02)
          ..quadraticBezierTo(cx + r * 0.06, my - r * 0.1, cx + r * 0.24, my + r * 0.05);
        canvas.drawPath(path, _stroke(cTextDim, 2.2));
        break;

      case CharacterMood.angry:
        final path = Path()
          ..moveTo(cx - r * 0.28, my + r * 0.06)
          ..quadraticBezierTo(cx, my - r * 0.1, cx + r * 0.28, my + r * 0.06);
        canvas.drawPath(path, _stroke(cAccent2, 2.6));
        canvas.drawLine(
          Offset(cx - r * 0.18, my + r * 0.03),
          Offset(cx + r * 0.18, my + r * 0.03),
          _stroke(cOutline.withOpacity(0.3), 1.4),
        );
        break;

      default:
        final path = Path()
          ..moveTo(cx - r * 0.24, my)
          ..quadraticBezierTo(cx, my + r * 0.2, cx + r * 0.24, my);
        canvas.drawPath(path, _stroke(cLip, 2.3));
        break;
    }
  }

  // ── 장식 (말풍선, 반짝이 등) ──────────────────────────────
  void _drawDecorations(Canvas canvas, double cx, double cy, double r) {
    if (mood == CharacterMood.thinking) {
      _drawThinkBubble(canvas, cx + r * 0.88, cy - r * 0.82, r * 0.38);
    }
    if (mood == CharacterMood.happy || mood == CharacterMood.surprised) {
      _drawSparkles(canvas, cx, cy, r);
    }
  }

  void _drawThinkBubble(Canvas canvas, double bx, double by, double br) {
    canvas.drawCircle(Offset(bx - br * 0.65, by + br * 0.8), br * 0.13,
      _fill(cAccent3.withOpacity(0.8)));
    canvas.drawCircle(Offset(bx - br * 0.4, by + br * 0.52), br * 0.18,
      _fill(cAccent3.withOpacity(0.85)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(bx, by), width: br * 2.1, height: br * 1.15),
        const Radius.circular(18),
      ),
      _fill(cAccent3.withOpacity(0.88)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(bx, by), width: br * 2.1, height: br * 1.15),
        const Radius.circular(18),
      ),
      _stroke(Colors.white.withOpacity(0.35), 1.5),
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: '.....',
        style: TextStyle(color: Colors.white, fontSize: 16,
          fontWeight: FontWeight.w800, letterSpacing: 1.5),
      ),
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
    _floatCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _spinCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100),
    );
    _floatAnim = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);
    _spinAnim  = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _spinCtrl, curve: Curves.linear),
    );
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
        colorScheme: const ColorScheme.light(
          primary: kAccent,
          surface: kSurface,
        ),
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
    if (url.isEmpty) {
      setState(() => _error = 'YouTube URL을 입력해주세요.');
      return;
    }
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
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => ResultPage(result: data, url: url)));
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
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [kAccent, Color(0xFF00A882)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      boxShadow: [BoxShadow(color: kAccent.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Center(child: Text('🎬', style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('VibeView', style: TextStyle(color: kText,
                        fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      Text('감정이 조회수를 만든다',
                        style: TextStyle(color: kTextMid, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: BeastmanCharacter(
                  mood: _loading ? CharacterMood.thinking : CharacterMood.idle,
                  size: 130,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Container(
                    key: ValueKey(_loading),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: _loading ? kAccent3.withOpacity(0.1) : kAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _loading ? kAccent3.withOpacity(0.28) : kAccent.withOpacity(0.28),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _loading ? '영상 분석 중이에요~ 잠깐만요! 🤔' : '안녕! YouTube URL을 입력해줘 👋',
                      style: TextStyle(
                        color: _loading ? kAccent3 : kAccent,
                        fontSize: 13, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
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
                  color: kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder, width: 1.5),
                  boxShadow: [BoxShadow(color: kAccent.withOpacity(0.07),
                    blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(color: kText, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'https://youtube.com/shorts/...',
                    hintStyle: TextStyle(color: kTextDim, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Icon(Icons.link_rounded, color: kTextDim, size: 20),
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
                    gradient: _loading ? null
                        : const LinearGradient(colors: [kAccent, Color(0xFF00A882)]),
                    color: _loading ? kBorder : null,
                    boxShadow: _loading ? [] : [BoxShadow(color: kAccent.withOpacity(0.38),
                      blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                      ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                          const SizedBox(width: 10),
                          Text('분석 중...', style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 15, fontWeight: FontWeight.w700)),
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
                  decoration: BoxDecoration(
                    color: kAccent2.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kAccent2.withOpacity(0.28)),
                  ),
                  child: Row(children: [
                    const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                    Expanded(child: Text(_error,
                      style: const TextStyle(color: kAccent2, fontSize: 13))),
                  ]),
                ),
              ],
              if (_loading) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kAccent3.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kAccent3.withOpacity(0.18)),
                  ),
                  child: const Row(children: [
                    Text('🎬', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('영상 다운로드 → 얼굴 분석 → 음성 분석',
                          style: TextStyle(color: kTextMid, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('1~3분 정도 소요될 수 있어요',
                          style: TextStyle(color: kTextDim, fontSize: 11)),
                      ],
                    )),
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

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder, width: 1.5),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
        blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: child,
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: kTextDim, fontSize: 10,
      letterSpacing: 1.5, fontWeight: FontWeight.w600)),
  );

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
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value, backgroundColor: kBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 7,
          ),
        ),
      ]),
    );
  }

  Widget _statCell(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: kSurface2,
        borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: kTextDim, fontSize: 9,
          letterSpacing: 1, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: kText, fontSize: 13,
          fontWeight: FontWeight.w700)),
      ]),
    ),
  );

  Widget _infoCard(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: kTextDim, fontSize: 9, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: kText, fontSize: 15,
          fontWeight: FontWeight.w800)),
      ]),
    ),
  );

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: kTextDim, fontSize: 10)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final videoInfo    = (widget.result['video_info']    as Map<String, dynamic>?) ?? {};
    final faceSummary  = (widget.result['face_summary']  as Map<String, dynamic>?) ?? {};
    final audioSummary = (widget.result['audio_summary'] as Map<String, dynamic>?) ?? {};
    final timeline     = (widget.result['emotion_timeline'] as List<dynamic>?) ?? [];
    final emotionDist  = (faceSummary['emotion_distribution'] as Map<String, dynamic>?) ?? {};
    final peakEmotion  = faceSummary['peak_emotion'] as Map<String, dynamic>?;
    final dominantEmotion = peakEmotion?['emotion'] as String? ?? '';
    final dominantColor   = kEmotionColors[dominantEmotion] ?? kAccent;
    final sortedEmotions  = emotionDist.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    final mood = _getMood();

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
          Text('VibeView', style: TextStyle(color: kText, fontSize: 18,
            fontWeight: FontWeight.w800)),
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
            _card(child: Column(children: [
              Center(child: BeastmanCharacter(mood: mood, size: 110)),
              const SizedBox(height: 8),
              Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: dominantColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dominantColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${kEmotionKo[dominantEmotion] ?? dominantEmotion} 감정이 가장 강해요! ✨',
                  style: TextStyle(color: dominantColor, fontSize: 13,
                    fontWeight: FontWeight.w700),
                ),
              )),
            ])),
            _label('VIDEO INFO'),
            Container(margin: const EdgeInsets.only(bottom: 16),
              child: Column(children: [
                Row(children: [
                  _infoCard('DURATION', '${(videoInfo['duration'] as num?)?.toStringAsFixed(1)}s'),
                  const SizedBox(width: 8),
                  _infoCard('FPS', '${(videoInfo['fps'] as num?)?.toStringAsFixed(0)}'),
                  const SizedBox(width: 8),
                  _infoCard('FRAMES', '${videoInfo['total_frames']}'),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _infoCard('RESOLUTION', '${videoInfo['width']}×${videoInfo['height']}'),
                ]),
              ]),
            ),
            _label('FACE ANALYSIS'),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('얼굴 감정 분석', style: TextStyle(color: kText,
                  fontSize: 15, fontWeight: FontWeight.w700)),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('VALENCE', style: TextStyle(color: kTextDim, fontSize: 10)),
                  Text((faceSummary['avg_valence'] as num?)?.toStringAsFixed(2) ?? '-',
                    style: const TextStyle(color: kAccent, fontSize: 18,
                      fontWeight: FontWeight.w800)),
                ]),
              ]),
              const SizedBox(height: 14),
              for (final e in sortedEmotions)
                _emotionBar(e.key, (e.value as num).toDouble()),
              if (peakEmotion != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: dominantColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: dominantColor.withOpacity(0.22)),
                  ),
                  child: Row(children: [
                    const Text('🏆 PEAK  ',
                      style: TextStyle(color: kTextDim, fontSize: 11)),
                    Text(kEmotionKo[dominantEmotion] ?? dominantEmotion,
                      style: TextStyle(color: dominantColor, fontSize: 14,
                        fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('@ ${(peakEmotion['timestamp'] as num?)?.toStringAsFixed(1)}s',
                      style: const TextStyle(color: kTextMid, fontSize: 12)),
                  ]),
                ),
            ])),
            _label('AUDIO ANALYSIS'),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('음성 감정 분석', style: TextStyle(color: kText,
                  fontSize: 15, fontWeight: FontWeight.w700)),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('VALENCE', style: TextStyle(color: kTextDim, fontSize: 10)),
                  Text((audioSummary['avg_valence'] as num?)?.toStringAsFixed(2) ?? '-',
                    style: const TextStyle(color: kAccent3, fontSize: 18,
                      fontWeight: FontWeight.w800)),
                ]),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _statCell('DOMINANT',
                  kEmotionKo[audioSummary['dominant_emotion']] ??
                  audioSummary['dominant_emotion']?.toString() ?? '-'),
                const SizedBox(width: 8),
                _statCell('TEMPO',
                  '${(audioSummary['tempo'] as num?)?.toStringAsFixed(0) ?? '-'} BPM'),
                const SizedBox(width: 8),
                _statCell('LANGUAGE',
                  (audioSummary['language'] as String?)?.toUpperCase() ?? '-'),
              ]),
              if ((audioSummary['full_text'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kSurface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBorder)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('💬 TRANSCRIPT', style: TextStyle(color: kTextDim,
                      fontSize: 10, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(audioSummary['full_text'] as String,
                      style: const TextStyle(color: kTextMid, fontSize: 13, height: 1.5)),
                  ]),
                ),
              ],
            ])),
            if (timeline.isNotEmpty) ...[
              _label('EMOTION TIMELINE'),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📊 총 ${timeline.length}개 구간 분석됨',
                  style: const TextStyle(color: kTextMid, fontSize: 13,
                    fontWeight: FontWeight.w600)),
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
                              color: c.withOpacity(0.82),
                              borderRadius: BorderRadius.circular(3),
                            ),
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
            _label('GEMINI AI COACH'),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('AI 감정 코치 피드백', style: TextStyle(color: kText,
                  fontSize: 15, fontWeight: FontWeight.w700)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _coachLoading ? null
                        : const LinearGradient(colors: [kAccent3, kAccent2]),
                    color: _coachLoading ? kBorder : null,
                    boxShadow: _coachLoading ? [] : [BoxShadow(
                      color: kAccent3.withOpacity(0.32),
                      blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: ElevatedButton(
                    onPressed: _coachLoading ? null : _getCoach,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _coachLoading
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                      : const Text('🤖 AI 코치', style: TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (_coachFeedback.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kAccent3.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kAccent3.withOpacity(0.18)),
                  ),
                  child: Text(_coachFeedback, style: const TextStyle(
                    color: kTextMid, fontSize: 13, height: 1.7)),
                )
              else
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: kSurface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder)),
                  child: const Text(
                    'AI 코치 버튼을 눌러\nGemini의 피드백을 받아보세요 🎯',
                    style: TextStyle(color: kTextDim, fontSize: 13, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                ),
            ])),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
