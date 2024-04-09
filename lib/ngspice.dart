import 'package:flutter/material.dart';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'dart:io' show Platform, Directory, File;
import 'package:path/path.dart' as path;
import 'package:compute/compute.dart';

String _ngspiceLibVer = '00';
String _output = '';
String _ngStatus = 'ready';
String _simResults = '';

class NgSpiceInterface {
  
  bool _isInitialized = false;
  String initOuput = '';

  late ffi.DynamicLibrary ngspice;
  
  //Dart Functions of NGSpice
  late NgSpiceCommandD ngspiceCommand;

  String getOutput()
  {
     return _output;
  }

  String getVersion()
  {
    return _ngspiceLibVer;
  }

  void ngInit()
  {
    if(_isInitialized) return; //Already Initialized

    String libraryPath = path.join(Directory.current.path, 'NgSpice', 'bin', 'ngspice.dll');
    
    if (Platform.isMacOS) { 
      libraryPath = path.join(Directory.current.path, 'NgSpice', 'bin', 'ngspice.dylib');
    } else if (Platform.isLinux) { 
      libraryPath = path.join(Directory.current.path, 'NgSpice', 'bin', 'ngspice.so');
    }

    if(File(libraryPath).existsSync() == false)
    {
      _ngspiceLibVer = '(Library not found)';
      return;
    } 

    ngspice =  ffi.DynamicLibrary.open(libraryPath);
    
    // Look up the functions
    final NgSpiceInitD ngspiceInit = ngspice
      .lookup<ffi.NativeFunction<NgSpiceInit>>('ngSpice_Init')
      .asFunction();
    ngspiceCommand = ngspice
      .lookup<ffi.NativeFunction<NgSpiceCommand>>('ngSpice_Command')
      .asFunction();  

    //NgSpice Init Call
    int init = ngspiceInit(
      getCharPointer,         // Use the function pointer for GetChar
      getStatPointer,         // Use the function pointer for GetStat
      controlledExitPointer,  // Use the function pointer for ControlledExit
      ngDataPointer,        // Use the function pointer for SendData
      sendInitDataPointer,    // Use the function pointer for SendInitData
      bGThreadRunningPointer, // Use the function pointer for BGThreadRunning
      userDataPtr,            // Not used at the moment
    );

    if(init == 0){_isInitialized = true;}
    
    //setOutputFormat('ascii');
    initOuput = _output;

    _output = ''; //Clear output string
  }

  void ngCommand(String command)
  {
    if(!_isInitialized) {
      _output += '\nERROR: NGSpice not loaded\n';
      return;
    }
    _output += '\n> $command\n';
    ngspiceCommand(command.toNativeUtf8());

  }

  ///Output Format: ascii, binary(default).
  void setOutputFormat(String type)
  {
    ngCommand('set filetype=$type');
  }

  Future<bool> ngIsReady() async
  {
    await Future.doWhile(() => (!_ngStatus.contains('ready')));
    return true;
  }

  String getStatus()
  {
    return _ngStatus;
  }
  
}

//Isolate functions
Future<String> ngCommandAsync(String command) async
{
   return await compute(_ngCommandCompute, command);
}

Future<String> _ngCommandCompute(String command) async
{
  NgSpiceInterface ngspiceLo = NgSpiceInterface();
  ngspiceLo.ngInit();
  ngspiceLo.ngCommand(command);

  await ngspiceLo.ngIsReady();
  String output = ngspiceLo.getOutput();

  return output;
}


//C functions
typedef NgSpiceInit = ffi.Int32 Function(
  ffi.Pointer ptrchar,
  ffi.Pointer ptrstat,
  ffi.Pointer ptrexit,
  ffi.Pointer ptrdata,
  ffi.Pointer ptrinitdata,
  ffi.Pointer ptrnoruns,
  ffi.Pointer userData,
);
typedef NgSpiceCommand = ffi.Int32 Function(ffi.Pointer<Utf8> ms);

//Dart functions
typedef NgSpiceInitD = int Function(
  ffi.Pointer ptrchar,
  ffi.Pointer ptrstat,
  ffi.Pointer ptrexit,
  ffi.Pointer ptrdata,
  ffi.Pointer ptrinitdata,
  ffi.Pointer ptrnoruns,
  ffi.Pointer userData,
);
typedef NgSpiceCommandD = int Function(ffi.Pointer<Utf8> ms);

typedef GetChar = ffi.Int32 Function(ffi.Pointer<Utf8> callerOut, ffi.Int32 idNum, ffi.IntPtr userData);
typedef GetStat = ffi.Int32 Function(ffi.Pointer<Utf8> simStatus, ffi.Int32 idNum, ffi.IntPtr userData);
typedef ControlledExit = ffi.Int32 Function(ffi.Int32 exitStatus, ffi.Bool unloadStatus, ffi.Bool exitType, ffi.Int32 idNum, ffi.IntPtr userData);
typedef NgData = ffi.Int32 Function(ffi.Pointer<VecValuesAll> pvecvaluesall, ffi.Int32 structNum, ffi.Int32 idNum, ffi.IntPtr userData);
typedef SendInitData = ffi.Int32 Function(ffi.IntPtr pvecinfoall, ffi.Int32 idNum, ffi.IntPtr userData);
typedef BGThreadRunning = ffi.Int32 Function(ffi.Bool backgroundThreadRunning, ffi.Int32 idNum, ffi.IntPtr userData);

ffi.Pointer<ffi.Void> userDataPtr = ffi.Pointer.fromAddress(0); 

//------------------Structures for parsing data from ngDataReceive()-------------------//
//  The following are the equivalent Dart definitions of the
//  C structs defined in sharedspice.h. See sharedspice.h for more information.
var pVectorInfo = VectorInfo;

base class NgComplex extends ffi.Struct {
  @ffi.Double() external double cxreal;
  @ffi.Double() external double cximag;
}

base class VectorInfo extends ffi.Struct {
  external ffi.Pointer<Utf8> vName;
  @ffi.Int32() external int vType;
  @ffi.Int8() external int vFlags;
  external ffi.Pointer<ffi.Double> vRealdata;
  external ffi.Pointer<NgComplex> vCompdata;
  @ffi.Int32() external int vLength;
}

base class VecValue extends ffi.Struct
{
    external ffi.Pointer<Utf8> vecName;     // Name of a specific vector (as char*)
    @ffi.Double() external double cReal;    // actual data value (real)
    @ffi.Double() external double cImag;    // actual data value (imaginary)
    @ffi.Bool() external bool isScale;      // if ’name ’ is the scale vector
    @ffi.Bool() external bool isComplex;    // if the data are complex numbers
}
base class VecValuesAll extends ffi.Struct
{
    @ffi.Int32() external int vecCount;      // Number of vectors in plot
    @ffi.Int32() external int vecIndex;      // Index of actual set of vectors , i.e.	the number of accepted data points
    external ffi.Pointer<ffi.Pointer<VecValue>> vecArray;     //  Pointer to an array of pointers to VecValue
}

base class VecInfo extends ffi.Struct {
  @ffi.Int32() external int number;
  external ffi.Pointer<Utf8> vecName;
  @ffi.Int8() external int isReal;
  external ffi.Pointer pdvec;
  external ffi.Pointer pdvecscale;
}

base class VecInfoAll extends ffi.Struct {
  external ffi.Pointer<Utf8> vname;
  external ffi.Pointer<Utf8> vtitle;
  external ffi.Pointer<Utf8> vdate;
  external ffi.Pointer<Utf8> vtype;
  @ffi.Int32() external int vcount;
  external ffi.Pointer<ffi.Pointer<VecInfo>> vecs; // Pointer to an array of pointers to VecInfo
}

// base class VecValuePtrStruct extends ffi.Struct        // this structure purely makes parsing easier using C# Marshalling
// {
//     @ffi.IntPtr() external int vecValuePtr;
// }

final getCharPointer = ffi.Pointer.fromFunction<GetChar>(
  getCharReceive,
  1, // Exceptional return value
);
final getStatPointer = ffi.Pointer.fromFunction<GetStat>(
  getStatReceive,
  1, // Exceptional return value
);
final controlledExitPointer = ffi.Pointer.fromFunction<ControlledExit>(
  controlledExitReceive,
  1, // Exceptional return value
);
final ngDataPointer = ffi.Pointer.fromFunction<NgData>(
  ngDataReceive,
  1, // Exceptional return value
);
final sendInitDataPointer = ffi.Pointer.fromFunction<SendInitData>(
  sendInitDataReceive,
  1, // Exceptional return value
);
final bGThreadRunningPointer = ffi.Pointer.fromFunction<BGThreadRunning>(
  bGThreadRunningReceive,
  1, // Exceptional return value
);


//------------------Callback functions-------------------//
//Wrapper around function within TForm1 class, which cannot be called directly
//Transfers output from printf, fprintf, fputs to caller
int getCharReceive(ffi.Pointer<Utf8> callerOut, int idNum, int userData)
{
    String callerOutString = callerOut.toDartString();
    _saveNgSpiceVersion(callerOutString);
    _saveConsoleOutput(callerOutString);
    debugPrint('<NgSPICE> GetChar: $callerOutString');
    return 0;
}

//Wrapper around function within TForm1 class, which cannot be called directly
//Address sent to ngspice.dll
//Receives progress information (actual task and percent done)
int getStatReceive(ffi.Pointer<Utf8> simStatus, int idNum, int userData)
{
    _ngStatus = simStatus.toDartString();
    debugPrint('<NgSPICE> GetStat: $_ngStatus');
    return 0;
}

// We exit as result of a command, but first have to finish
// the command; so here we can only alert the program to detach,
// detaching is done after the calling fcn has returned
int controlledExitReceive(int exitStatus, bool unloadStatus, bool exitType, int idNum, int userData)
{
    debugPrint('<NgSPICE> ControlledExitReceive: $exitStatus');
    return exitStatus;
}

// get data from all vectors at a every accepted point during simulation
// Here we specially look for vector with number vecgetnumber (found
// in fcn ng_initdata()) and its scale vector
int ngDataReceive(ffi.Pointer<VecValuesAll> pvecvaluesall, int structNum, int idNum, int userData)
{
  //debugPrint('<NgSPICE> SendDataReceive $pvecvaluesall'); ///<<< Getting 5000+ calls on simulation start

  // get allValues struct from unmanaged memory
  VecValuesAll allValues = pvecvaluesall.ref;
  
  final vecValuesPointer = calloc<VecValue>(allValues.vecCount);

  String name = '';
  for (int i = 0; i < allValues.vecCount; i++)
  {
  
    vecValuesPointer[i] = allValues.vecArray[i].ref;

    name += ' ';
    name += allValues.vecArray[i].ref.vecName.toDartString();
    
    //debugPrint('<NgSPICE> VecName: $name');
  }

  //Test, show to output
  //_output += '$name\n'; 
  
  return 0;
}
// Get info on all vectors after they have been set up. Called once
// per access to a new plot in ngspice.
// Put info into a global variable curvinfoall.
// Then here we look for a vector with name 'name'
int sendInitDataReceive(int pvecinfoall, int idNum, int userData)
{
    debugPrint('<NgSPICE> SendInitDataReceive');
    return 0;
}
//show if background thread is running
int bGThreadRunningReceive(bool backgroundThreadRunning, int idNum, int userData)
{
    debugPrint('<NgSPICE> BGThreadRunningReceive');
    return 0;
}

//Other Functions
void _saveNgSpiceVersion(String recieveStr)
{
  //if(!_ngspiceLibVer.contains('00')) return;

  if(recieveStr.contains('shared library'))
  {
      int indexDash = recieveStr.indexOf('-');
      _ngspiceLibVer = recieveStr.substring(indexDash + 1, indexDash + 3);
  }
}
void _saveConsoleOutput(String recieveStr)
{
  if(recieveStr.length < 7){return;}
  
  String subStr = '';
  String outType = recieveStr.substring(0, 6); 
  //Remove 'stdout,stderr' strings.
  //Stings like 'Reference value :  1.53595e-06' are not displayed.
  if(outType.contains('stdout') || outType.contains('stderr'))
  {
    subStr = recieveStr.substring(6, recieveStr.length);
     _output += ' $subStr\n';
  }
  
}