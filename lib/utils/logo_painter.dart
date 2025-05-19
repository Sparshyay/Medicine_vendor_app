import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A custom painter that draws the Olamic Healthcare logo
class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Colors from the Olamic logo
    final Paint navyBluePaint = Paint()
      ..color = const Color(0xFF2A3190)
      ..style = PaintingStyle.fill;
    
    final Paint redPaint = Paint()
      ..color = const Color(0xFFEE1C25)
      ..style = PaintingStyle.fill;
    
    final Paint greenPaint = Paint()
      ..color = const Color(0xFF00A651)
      ..style = PaintingStyle.fill;
    
    final Paint limePaint = Paint()
      ..color = const Color(0xFFB7D435)
      ..style = PaintingStyle.fill;
    
    // Draw the globe background (navy blue circles)
    final double globeRadius = size.height * 0.35;
    final Offset globeCenter = Offset(size.width * 0.15, size.height * 0.5);
    
    // Outer circle
    canvas.drawCircle(globeCenter, globeRadius, navyBluePaint);
    
    // Draw the globe lines (white/transparent)
    final Paint globeLinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.02;
    
    // Horizontal lines
    for (int i = -2; i <= 2; i++) {
      final double y = globeCenter.dy + (globeRadius * 0.3 * i);
      final double xOffset = sqrt(pow(globeRadius, 2) - pow(y - globeCenter.dy, 2));
      
      canvas.drawLine(
        Offset(globeCenter.dx - xOffset, y),
        Offset(globeCenter.dx + xOffset, y),
        globeLinePaint,
      );
    }
    
    // Draw the 'H' shape in red
    final Path hPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.3)
      ..lineTo(size.width * 0.15, size.height * 0.3)
      ..lineTo(size.width * 0.15, size.height * 0.45)
      ..lineTo(size.width * 0.2, size.height * 0.45)
      ..lineTo(size.width * 0.2, size.height * 0.3)
      ..lineTo(size.width * 0.25, size.height * 0.3)
      ..lineTo(size.width * 0.25, size.height * 0.7)
      ..lineTo(size.width * 0.2, size.height * 0.7)
      ..lineTo(size.width * 0.2, size.height * 0.55)
      ..lineTo(size.width * 0.15, size.height * 0.55)
      ..lineTo(size.width * 0.15, size.height * 0.7)
      ..lineTo(size.width * 0.1, size.height * 0.7)
      ..close();
    
    canvas.drawPath(hPath, redPaint);
    
    // Draw the lime green accent
    final Path limePath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.6)
      ..lineTo(size.width * 0.25, size.height * 0.6)
      ..lineTo(size.width * 0.2, size.height * 0.7)
      ..close();
    
    canvas.drawPath(limePath, limePaint);
    
    // Draw OLAMIC text
    final olamicStyle = TextStyle(
      color: const Color(0xFF2A3190), // Navy blue
      fontSize: size.height * 0.3,
      fontWeight: FontWeight.bold,
      letterSpacing: size.width * 0.01,
    );
    
    final olamicSpan = TextSpan(
      text: 'OLAMIC',
      style: olamicStyle,
    );
    
    final olamicPainter = TextPainter(
      text: olamicSpan,
      textDirection: TextDirection.ltr,
    );
    
    olamicPainter.layout(
      minWidth: 0,
      maxWidth: size.width * 0.7,
    );
    
    olamicPainter.paint(
      canvas,
      Offset(size.width * 0.32, size.height * 0.2),
    );
    
    // Draw Healthcare text
    final healthcareStyle = TextStyle(
      color: const Color(0xFFEE1C25), // Red
      fontSize: size.height * 0.25,
      fontWeight: FontWeight.bold,
      letterSpacing: size.width * 0.005,
    );
    
    final healthcareSpan = TextSpan(
      text: 'Healthcare',
      style: healthcareStyle,
    );
    
    final healthcarePainter = TextPainter(
      text: healthcareSpan,
      textDirection: TextDirection.ltr,
    );
    
    healthcarePainter.layout(
      minWidth: 0,
      maxWidth: size.width * 0.7,
    );
    
    healthcarePainter.paint(
      canvas,
      Offset(size.width * 0.4, size.height * 0.55),
    );
    
    // Draw red star
    final Path starPath = Path()
      ..moveTo(size.width * 0.78, size.height * 0.15)
      ..lineTo(size.width * 0.8, size.height * 0.25)
      ..lineTo(size.width * 0.9, size.height * 0.25)
      ..lineTo(size.width * 0.82, size.height * 0.32)
      ..lineTo(size.width * 0.85, size.height * 0.42)
      ..lineTo(size.width * 0.78, size.height * 0.35)
      ..lineTo(size.width * 0.71, size.height * 0.42)
      ..lineTo(size.width * 0.74, size.height * 0.32)
      ..lineTo(size.width * 0.66, size.height * 0.25)
      ..lineTo(size.width * 0.76, size.height * 0.25)
      ..close();
    
    canvas.drawPath(starPath, redPaint);
    
    // Draw green shape
    final Path greenPath = Path()
      ..moveTo(size.width * 0.78, size.height * 0.35)
      ..lineTo(size.width * 0.82, size.height * 0.55)
      ..lineTo(size.width * 0.74, size.height * 0.55)
      ..close();
    
    canvas.drawPath(greenPath, greenPaint);
    
    // Draw certification text
    final certStyle = TextStyle(
      color: const Color(0xFF2A3190), // Navy blue
      fontSize: size.height * 0.1,
      fontWeight: FontWeight.bold,
      letterSpacing: size.width * 0.002,
    );
    
    final certSpan = TextSpan(
      text: '(A WHO-GMP & ISO CERTIFIED COMPANY)',
      style: certStyle,
    );
    
    final certPainter = TextPainter(
      text: certSpan,
      textDirection: TextDirection.ltr,
    );
    
    certPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    
    certPainter.paint(
      canvas,
      Offset((size.width - certPainter.width) / 2, size.height * 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  
  // Helper method to calculate square root
  double sqrt(double value) {
    return math.sqrt(value);
  }
  
  // Helper method to calculate power
  double pow(double x, double exponent) {
    return math.pow(x, exponent).toDouble();
  }
}
