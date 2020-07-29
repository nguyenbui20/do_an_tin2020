import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:gallery_saver/gallery_saver.dart';

import 'RemoveBackground.dart';
import 'RemoveBackground2.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: CameraScreen(
      ),
    ),
  );
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key key}) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen>
    with AutomaticKeepAliveClientMixin {
  CameraController _controller;
  List<CameraDescription> _cameras;
  int turns;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  void initState() {
    _initCamera();
    super.initState();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.high);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_controller != null) {
      if (!_controller.value.isInitialized) {
        return Container();
      }
    } else {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        key: _scaffoldKey,
        extendBody: true,
        appBar:  AppBar(
          title: Text('INFORMATION PROJECT 2020',style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.orangeAccent,
          centerTitle: true,     ),
        body:NativeDeviceOrientationReader(builder: (context) {
          NativeDeviceOrientation orientation = NativeDeviceOrientationReader.orientation(context);
         // int turns;
          switch (orientation) {
            case NativeDeviceOrientation.landscapeLeft:
              turns = -1;
              break;
            case NativeDeviceOrientation.landscapeRight:
              turns = 1;
              break;
            case NativeDeviceOrientation.portraitDown:
              turns = 2;
              break;
            default:
              turns = 0;
              break;
          }
          return Stack(
              children: <Widget>[
                RotatedBox(
                  quarterTurns: turns,
                  child: _buildCameraPreview(),
                ),
              ]
          );
        }
        )
    );
  }


  Widget _buildCameraPreview() {
    return Scaffold(
        body: body(context)
    );
  }

  Widget body(BuildContext context) {
    if(MediaQuery.of(context).orientation == Orientation.portrait)
    {
      return portrait();
    }
    else {
      return landscape();
    }
  }


  Widget portrait() {
    return Stack(
      children: <Widget>[
        Center(
                child: CameraPreview(_controller),),
//            ),
//          ),
//        ),
        Container(
          height: 600,
          width: 360,
          alignment: Alignment.bottomCenter,
          child: Container(
              width: 60.0,
              height: 60.0,
              child: new FloatingActionButton(
                shape: new CircleBorder(),
                elevation: 0.0,
                child: Icon(Icons.camera_alt,
                size: 40,),
                onPressed: () async {
                  try {
                    final path = join(
                      (await getTemporaryDirectory()).path, '${DateTime.now()}.png',);
                    await _controller.takePicture(path);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) =>
                          DisplayPictureScreen(imagePath: path,turns: turns,),),
                    );
                  } catch (e) {
                    print(e);
                  }
                },
              )
          ),
        ),
        Container(
          width: 350,
          alignment: Alignment.topRight,
          child:IconButton(
            icon: Icon(
              Icons.switch_camera,
              size: 40,
              color: Colors.tealAccent,
            ),
            onPressed: () {
              _onCameraSwitch();
            },
          ),
        ),
      ],
    );
  }

  Widget landscape() {
    return Stack(
      children: <Widget>[
        Center(
          child: Transform.scale(
            scale: 0.81/_controller.value.aspectRatio ,
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: CameraPreview(_controller),),
            ),
          ),
        ),
        Container(

          color: Colors.transparent,
          height: 665,
          width: 360,
          alignment: Alignment.bottomCenter,
          child: Container(
              width: 60.0,
              height: 60.0,
              child: new FloatingActionButton(
                backgroundColor: Colors.tealAccent,
                shape: new CircleBorder(),
                elevation: 0.0,
                child: Icon(Icons.camera_alt,
                  size: 40,),
                onPressed: () async {
                  try {
                    final path = join(
                      (await getTemporaryDirectory()).path, '${DateTime.now()}.png',);
                    await _controller.takePicture(path);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) =>
                          DisplayPictureScreen(imagePath: path,turns: turns,),),
                    );
                  } catch (e) {
                    print(e);
                  }
                },
              )
          ),
        ),
        Container(
          alignment: Alignment.bottomRight,
          child:IconButton(
            icon: Icon(
              Icons.switch_camera,
              size: 40,
              color: Colors.tealAccent,
            ),
            onPressed: () {
              _onCameraSwitch();
            },
          ),
        ),
      ],
    );
  }


  Future<void> _onCameraSwitch() async {
    final CameraDescription cameraDescription =
    (_controller.description == _cameras[0]) ? _cameras[1] : _cameras[0];
    if (_controller != null) {
      await _controller.dispose();
    }
    _controller = CameraController(cameraDescription, ResolutionPreset.high);
    _controller.addListener(() {
      if (mounted) setState(() {});
      if (_controller.value.hasError) {
        showInSnackBar('Camera error ${_controller.value.errorDescription}');
      }
    });

    try {
      await _controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void logError(String code, String message) =>
      print('Error: $code\nError Message: $message');

  @override
  bool get wantKeepAlive => true;
}


class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final int turns;
  const DisplayPictureScreen({Key key, this.imagePath,this.turns}) : super(key: key);

  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen>{
  String imagePath;
  int turns;

  @override
  void initState() {
    imagePath = widget.imagePath;
    turns = widget.turns;
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(title: Text('INFORMATION PROJECT',style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,),
          body: Stack(
            children: <Widget>[
              Container(
                child:Center(
                  child:  new Image.file(File(imagePath),
                    ),
                ),
              ),
              Container(
                alignment: Alignment.bottomLeft,
                margin: EdgeInsets.only(
                    left: 30),
                child: IconButton(
                  iconSize: 40,
                  color: Colors.tealAccent,
                  icon: Icon(Icons.share),
                  onPressed: () => _shareFile(),
                ),
              ),
              Container(
                alignment: Alignment.bottomRight,
                margin: EdgeInsets.only(
                right: 30,),
                child: IconButton(
                  color: Colors.tealAccent,
                  iconSize: 40,
                  icon: Icon(Icons.save_alt),
                  onPressed: () => _showMyDialog(),
                ),
              ),
              Container(
                  alignment: Alignment.bottomCenter,
                  margin: EdgeInsets.only(
                    bottom: 5,),
                  child:IconButton(
                      color: Colors.tealAccent,
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: 40,),
                      onPressed: ()
                      {if (turns==-1 ) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                        builder: (context) => BackGround2(path: imagePath)),
                        );
                      }
                      else if (turns== 1 ) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BackGround2(path: imagePath)),
                        );
                      }
                      else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BackGround(path: imagePath)),
                        );
                      }
                      }
                      )
              ),
            ],
          ),
        backgroundColor:Colors.black12 ,
      );
  }

  _shareFile() async {
    await Share.file(
      'image',
      'image.png',
      File(imagePath).readAsBytesSync(),
      'image/jpeg',
    );
  }

  _saveImage() async {
    GallerySaver.saveImage(imagePath);
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.orangeAccent,
          title: Text(
            'Saving image',
            style: TextStyle(color: Colors.black),),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Do you want to save this image?',
                  style: TextStyle(color: Colors.black),),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(
                  'No',
                style: TextStyle(color: Colors.black),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(
                  'Yes',
                style: TextStyle(color: Colors.black),),
              onPressed: () {
                _saveImage();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
