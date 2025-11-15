import 'package:flutter/material.dart';

class EgoStream extends StatelessWidget {
  const EgoStream({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.red,
      Colors.blueAccent,
      Colors.green,
      Colors.yellow,
      Colors.orange,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        itemBuilder: (context, index) {
          return _EgoStreamItem(color: colors[index]);
        },
      ),
    );
  }
}

class _EgoStreamItem extends StatelessWidget {
  final Color color;

  const _EgoStreamItem({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160.0,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(35),
      ),
    );
  }
}
