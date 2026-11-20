import 'package:flutter/material.dart';

/// Pulsing-style dot used for the current user's location.
class CurrentLocationDot extends StatelessWidget {
  static const double size = 16;

  final Color color;

  const CurrentLocationDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Location pin with the friend's name underneath. The pin tip is the bottom
/// center of this widget; the name overflows below it.
class UserPin extends StatelessWidget {
  static const double width = 28;
  static const double height = 36;

  final Color color;
  final String label;

  const UserPin({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Icon(
          Icons.location_on,
          size: height,
          color: color,
          shadows: const [Shadow(color: Color(0x4D000000), blurRadius: 4)],
        ),
        Positioned(
          top: height - 2,
          left: -40,
          right: -40,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
