import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

//Combine image from camera with background image in assets
class AddBackground extends StatelessWidget {
  final String imagePath;

  const AddBackground({Key key, this.imagePath}) : super(key: key);

  loadModel() async {
    String res;
    res = await Tflite.loadModel(
      model: "assets/deeplabv3_257_mv_gpu.tflite",
      labels: "assets/deeplabv3_257_mv_gpu.txt",
    );
    print(res);
  }

  dlv(File image) async {
    var recognitions = await Tflite.runSegmentationOnImage(
      path: image.path,
      imageMean: 0.0,
      imageStd: 255.0,
      outputType: "png",
      asynch: true,
    );


  }

  @override
  Widget build(BuildContext context) {

    var img = Image.file(File(imagePath));



    return Scaffold(
      body: Stack(
        children: <Widget>[
          Image.file(File(imagePath)),
          Image.asset('assets/images/flower01.png'),
        ],
      ),
    );
  }
}

/*
class AddBackground extends StatefulWidget {
  final String imagePath;

  AddBackground(this.imagePath);

  @override
  _AddBackgroundState createState() => _AddBackgroundState();
}


class _AddBackgroundState extends State<AddBackground> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Image.file(File(imagePath)),
          Image.asset('images/flower01.png')
        ],
      ),
    );
  }
}

 */






