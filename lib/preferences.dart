import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  Color theme = Colors.red;
  Color sectheme = Colors.white;
  int distanceAlert = 1; // Default value
  final TextEditingController _controller = TextEditingController();

  Future<void> _setDistanceAlert(int distance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('distanceAlert', distance);
      print('Saved distance alert: $distance KM');
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Distance alert saved: $distance KM'),
        ),
      );
    } catch (e) {
      print('Failed to save distance alert: $e');
    }
  }

  Future<int> _getDistanceAlert() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('distanceAlert') ?? 0;
    } catch (e) {
      print('Failed to load distance alert: $e');
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDistanceAlert();
  }

  Future<void> _loadDistanceAlert() async {
    final distance = await _getDistanceAlert();
    setState(() {
      distanceAlert = distance;
      _controller.text = distanceAlert.toString();
    });
  }

  void _updateDistanceAlert() {
    final newDistance = int.tryParse(_controller.text);
    if (newDistance != null) {
      setState(() {
        distanceAlert = newDistance;
      });
      _setDistanceAlert(newDistance);
    } else {
      // Handle invalid input if necessary
      print('Invalid input for distance alert');
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Invalid input: Please input integer only.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F3F2),
      appBar: AppBar(
        backgroundColor: theme,
        title: Text(
          'Preferences',
          style: TextStyle(color: sectheme, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: sectheme),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Distance Alert:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide(color: Colors.black)
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      labelText: 'Enter distance (KM)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _updateDistanceAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme,
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
