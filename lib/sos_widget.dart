// sos_widget.dart

import 'package:flutter/material.dart';
import 'package:fypppp/sos.dart';

class SOSWidget extends StatelessWidget {
  const SOSWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the SOSPage when widget is clicked
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SOSPage()),
        );
      },
      child: Container(
        // Your widget UI here
        child: const Icon(Icons.add_alert), // Example: SOS icon
      ),
    );
  }
}
