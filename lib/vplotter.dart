import 'package:flutter/material.dart';
//import 'package:desktop_multi_window/desktop_multi_window.dart';

class VPlotter extends StatelessWidget {
  final String data;
  const VPlotter({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vector Plotting')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Work in progress...'),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}