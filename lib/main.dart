import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:menu_bar/menu_bar.dart';


// import 'package:flutter_quill/flutter_quill.dart';
import 'ngspice.dart';


String titleText = 'NGSpice ';
String initialOutput = '';

NgSpiceInterface ngspice = NgSpiceInterface();

void main() async {

  _initalizeNgspice();

  runApp(const MyApp());

}

void _initalizeNgspice()
{
  ngspice.ngInit();
  titleText = 'NGSpice ';
  titleText += ngspice.getVersion();
  initialOutput = ngspice.initOuput;

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter NGSpice',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark, background: Colors.blueGrey),
        useMaterial3: true,
      ),
         
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
  double monoFontSize = 15;
  String ngspiceOutString = '';
  String ngspiceStatusString = "NGSpice status";
  bool isRunning = false;

  void _runNGSpiceCommand() async {

    if(isRunning) return;

    setState(() {
        ngspiceStatusString = 'running command';
    });

    isRunning = true;
    String outputStr = await ngCommandAsync(_commandStrCtrl.text);
    ngspiceOutString += '$outputStr\n';

    isRunning = false;

    setState(() {
      
      ngspiceStatusString = 'ready';

      _outputStrCtrl.text = ngspiceOutString;
      _scrollController.animateTo(
        _scrollController.position.extentTotal,
        duration: const Duration(seconds: 1),
        curve: Curves.easeOutSine,
      );

      _commandTextfocusNode.requestFocus();
      
    });
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
                onTap: () {_initalizeNgspice();},
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
                text: const Text('Show Console', style: TextStyle(fontSize: gFontSize)),
                onTap: () {},
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
                MenuButton(
                text: const Text('Dark Theme', style: TextStyle(fontSize: gFontSize)),
                onTap: () {},
                //icon: const Icon(Icons.exit_to_app, size: 19,),
                //shortcutText: 'Ctrl+Q',
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
                  //textAlignVertical: TextAlignVertical.bottom,
                  autocorrect: false,
                  //onChanged: (s) => {},
                  decoration: const InputDecoration(
                    labelText: 'Output', // Placeholder text
                    border: OutlineInputBorder(), // Border outline
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
