import 'package:flutter/material.dart';
//import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'ngspice.dart';

class VPlotter extends StatelessWidget {
  final List<VecValuesAllDart> vecData;
  const VPlotter({super.key, required this.vecData});


  void _plotVectors()
  {
    for(VecValuesAllDart vec in vecData) {
      String name = vec.vecArray[0].vecName;
      double value = vec.vecArray[0].cReal;
      //debugPrint('Vec: $name Value: $value');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vector Plotting')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Work in progress...'),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.of(context).pop();
            //   },
            //   child: const Text('Close'),
            // ),
              ElevatedButton(
              onPressed: () {
                _plotVectors();
              },
              child: const Text('Plot'),
            ),
          ],
        ),
      ),
    );
  }
}
