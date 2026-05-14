import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialSignInButtons extends StatelessWidget {
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final bool isLoading;

  const SocialSignInButtons({
    super.key,
    required this.onGoogle,
    this.onApple,
    this.isLoading = false,
  });

  bool get _showApple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GoogleSignInButton(onPressed: isLoading ? null : onGoogle),
        if (_showApple) ...[
          const SizedBox(height: 12),
          SignInWithAppleButton(
            onPressed: isLoading ? () {} : (onApple ?? () {}),
            height: 52,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
        ],
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleSignInButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: Color(0xFFDADCE0)),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GoogleLogo(),
          SizedBox(width: 10),
          Text(
            'Continue with Google',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF3C4043),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    // Four-colour Google "G" rendered via a Row of coloured arcs using a
    // custom painter. Replace with an SVG asset when you have one.
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final stroke = size.width * 0.26;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    const pi = 3.14159265;
    const deg = pi / 180;

    // Blue – top-right arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - stroke / 2),
      -90 * deg,
      90 * deg,
      false,
      paint,
    );
    // Red – bottom-right arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - stroke / 2),
      0,
      90 * deg,
      false,
      paint,
    );
    // Yellow – bottom-left arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - stroke / 2),
      90 * deg,
      90 * deg,
      false,
      paint,
    );
    // Green – top-left arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - stroke / 2),
      180 * deg,
      90 * deg,
      false,
      paint,
    );

    // White horizontal bar (the flat right side of the "G")
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - stroke / 2, r - stroke / 2, stroke),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A styled divider with "OR" label used between auth sections.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}
