import 'package:flutter/material.dart';

class CardItem extends StatelessWidget {
  final String title;
  final IconData icon;

  const CardItem({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(16),
      color: const Color(0xff1E2E3D),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon,
              size: 48,
              color: const Color.fromRGBO(255, 255, 98, 0.98),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
