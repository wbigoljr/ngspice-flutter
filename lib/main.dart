// Author: Wilfredo Bigol Jr.
// Description: This is a Flutter app demonstrating the usage of NGSpice shared library using Dart FFI.

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:menu_bar/menu_bar.dart';
import 'dart:isolate';
import 'package:provider/provider.dart';
// import 'package:desktop_multi_window/desktop_multi_window.dart';
// import 'dart:convert';

// import 'package:flutter_quill/flutter_quill.dart';
import 'ngspice.dart' as ngspice;
import 'userprefs.dart';
import 'vplotter.dart';

String titleText = 'NGSpice ';
String initialOutput = '';
 
 String themeButtonName = 'Dark'; //Default is light

ngspice.NgSpiceInterface ngspiceInit = ngspice.NgSpiceInterface();

void main() async {

  _initalizeNgspice();

  ThemePreferences themePrefs = ThemePreferences();
  final bool isDark = await themePrefs.getTheme();
  if(isDark) {themeButtonName = 'Light';}
  
  //runApp(const MyApp());
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(isDark ? darkTheme : lightTheme),
      child: const MyApp(),
    ),
  );
}

void _initalizeNgspice()
{
  ngspiceInit.ngInit();
  titleText = 'ngspiceInit ';
  titleText += ngspiceInit.getVersion();
  initialOutput = ngspiceInit.initOuput;

  //Modify the text in window title bar.
  WidgetsFlutterBinding.ensureInitialized();
  windowManager.ensureInitialized();
  windowManager.setTitleBarStyle(TitleBarStyle.normal);
  windowManager.setTitle(titleText);
  windowManager.setSize(const Size(800, 800));
  windowManager.setMinimumSize(const Size(800, 800));
  //windowManager.setPosition(position)

  windowManager.show();

}

ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey),
  useMaterial3: true,
);

ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark, background: Colors.blueGrey),
  useMaterial3: true,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return 
      MaterialApp(
      title: 'Flutter NGSpice',
      theme: Provider.of<ThemeNotifier>(context).themeData,
      home: MyHomePage(title: titleText),
      );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final TextEditingController _commandStrCtrl = TextEditingController(text: 'source InverterTESTy.cir');
  final TextEditingController _outputStrCtrl = TextEditingController(text: initialOutput);
  final FocusNode _commandTextfocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  double monoFontSize = 13;
 

  String ngspiceOutString = '';
  String ngspiceStatusString = ">>> status <<<";
  bool isRunning = false;

  void _runNGSpiceCommand() async {

    if(isRunning) return;
    isRunning = true;

    setState(() {
        ngspiceStatusString = 'running command';
    });

    ReceivePort receivePortStats = ReceivePort();
    receivePortStats.listen((dynamic data) {
      setState(() {
        ngspiceStatusString = data;
      });
    });

    ReceivePort receivePortOut = ReceivePort();
    receivePortOut.listen((dynamic data) {
      setState(() {
        ngspiceOutString += '$data\n';

        _outputStrCtrl.text = ngspiceOutString;
        _scrollController.animateTo(
          _scrollController.position.extentTotal,
          duration: const Duration(seconds: 1),
          curve: Curves.easeOutSine,
        );

        _commandTextfocusNode.requestFocus();

        isRunning = false;
        ngspiceStatusString = 'ready';
      });

    });

    ReceivePort receivePortVectors = ReceivePort();
    receivePortVectors.listen((dynamic data) {
      setState(() {
        ngspice.vecAllArray = data;
      });
    });

    ngspice.vecAllArray.clear(); //Clear current vectors

    await Isolate.spawn(ngspice.ngCommandPort, {
      'value': _commandStrCtrl.text,
      'sendPortStat':receivePortStats.sendPort,
      'sendPortOut':receivePortOut.sendPort,
      'sendPortVectors':receivePortVectors.sendPort,
    });

  } 
  
  void _switchTheme()
  {

    bool isDark = false;
    if(themeButtonName == 'Dark') {isDark = true;}

    Provider.of<ThemeNotifier>(context, listen: false)
        .setTheme(
      Provider.of<ThemeNotifier>(context, listen: false).themeData ==
              lightTheme
          ? darkTheme
          : lightTheme, isDark
    );

    Provider.of<ThemeNotifier>(context, listen: false).themeData ==
            lightTheme
        ? themeButtonName = 'Dark'
        : themeButtonName = 'Light';
    
  }

  void _openVPlotter()
  {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => VPlotter(vecData: ngspice.vecAllArray)),);
  }

  @override
  Widget build(BuildContext context) {

    const double gFontSize = 13;
    return MenuBarWidget(

      barButtons: [
        BarButton(
          text: const Text('File', style: TextStyle(fontSize: gFontSize)),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                text: const Text('Save', style: TextStyle(fontSize: gFontSize)),
                onTap: () {},
                icon: const Icon(Icons.save, size: 19,),
                shortcutText: 'Ctrl+S',
              ),
              const MenuDivider(),
                MenuButton(
                text: const Text('Reload Library', style: TextStyle(fontSize: gFontSize)),
                onTap: () {
                    _initalizeNgspice();
                    setState(() {
                      _outputStrCtrl.text = initialOutput;
                    });
                  },
                //icon: const Icon(Icons.save, size: 19,),
                shortcutText: 'Ctrl+R',
              ),
              const MenuDivider(),
              MenuButton(
                text: const Text('Exit', style: TextStyle(fontSize: gFontSize)),
                onTap: () {},
                icon: const Icon(Icons.exit_to_app, size: 19,),
                shortcutText: 'Ctrl+Q',
              ),
            ],
          ),
        ),
        BarButton(
          text: const Text('View', style: TextStyle(fontSize: gFontSize)),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                text: const Text('Show Graph', style: TextStyle(fontSize: gFontSize)),
                onTap: () {_openVPlotter();},
                //icon: const Icon(Icons.save, size: 19,),
                //shortcutText: 'Ctrl+S',
              ),
              const MenuDivider(),
              MenuButton(
                text: const Text('Show Editor', style: TextStyle(fontSize: gFontSize)),
                onTap: () {},
                //icon: const Icon(Icons.exit_to_app, size: 19,),
                //shortcutText: 'Ctrl+Q',
              ),
              const MenuDivider(),
              MenuButton(
                text: const Text('Show Sidebar', style: TextStyle(fontSize: gFontSize)),
                onTap: () {},
                //icon: const Icon(Icons.exit_to_app, size: 19,),
                //shortcutText: 'Ctrl+Q',
              ),
              const MenuDivider(),
              MenuButton(
                text: const Text('Set Theme', style: TextStyle(fontSize: gFontSize)),
                onTap: () {
                  _switchTheme();
                },
                //icon: const Icon(Icons.exit_to_app, size: 19,),
                shortcutText: themeButtonName,
                shortcutStyle: const TextStyle(fontWeight: FontWeight.normal, color: Colors.grey)
              ),
            ],
          ),
        ),
        BarButton(
          text: const Text('Help', style: TextStyle(fontSize: gFontSize)),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                text: const Text('Manual', style: TextStyle(fontSize: gFontSize)),
                onTap: () {},
              ),
              MenuButton(
                text: const Text('About', style: TextStyle(fontSize: gFontSize)),
                onTap: () {},
                //icon: const Icon(Icons.info, size: 19,),
              ),
            ],
          ),
        ),
      ],
      child: Scaffold(
        //extendBody: true,
        body: 
         Padding(
          padding: const EdgeInsets.all(17.0),
          child:
          Column(

            children: [
              Expanded(child:
                TextField(
                  controller: _outputStrCtrl,
                  scrollController: _scrollController,
                  autofocus: false,
                  readOnly: true,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(fontFamily: 'RobotoMono', fontSize: monoFontSize),
                  maxLines: null,
                  minLines: null,
                  expands: true,
                  autocorrect: false,
                  //onChanged: (s) => {},
                  decoration: const InputDecoration(
                    labelText: 'Output',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                ngspiceStatusString,
                style: TextStyle(fontFamily: 'RobotoMono', fontSize: monoFontSize),
              ),
              
              const SizedBox(height: 8),
              
              TextField (
                controller: _commandStrCtrl,
                focusNode: _commandTextfocusNode,
                style: TextStyle(fontFamily: 'RobotoMono', fontSize: monoFontSize),
                onSubmitted: (String value) {
                  _runNGSpiceCommand();
                },
                decoration: const InputDecoration(
                  labelText: 'Command', // Placeholder text
                  border: OutlineInputBorder(), // Border outline
                ),
              ),
              
              const SizedBox(height: 1),
            ]

          ),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _runNGSpiceCommand();
          },
          tooltip: 'Run Command',
          child: const Icon(Icons.keyboard_return),
        ),



      ),
      
    );
    
  }
}
