import 'package:flutter/material.dart';

import 'package:hookra/src/models/report.dart';

class RiskBadge extends StatelessWidget {
  final Risk risk;

  const RiskBadge({super.key, required this.risk});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (risk) {
      case Risk.low:
        color = Colors.green;
        label = 'Bajo';
        break;
      case Risk.mid:
        color = Colors.orange;
        label = 'Medio';
        break;
      case Risk.high:
        color = Colors.red;
        label = 'Alto';
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color),
      shape: StadiumBorder(side: BorderSide(color: color)),
    );
  }
}
