import 'package:flutter/material.dart';
import '../utils/logo_painter.dart';

class OlamicLogo extends StatelessWidget {
  final double width;
  final double height;

  const OlamicLogo({
    Key? key,
    this.width = 300,
    this.height = 150,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: LogoPainter(),
        size: Size(width, height),
      ),
    );
  }
}
