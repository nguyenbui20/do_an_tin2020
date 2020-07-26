
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image_pub;
import 'package:path_provider/path_provider.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'loadBackground.dart';

import 'bmp_header.dart';


class RemoveBackground extends StatefulWidget {

  final String imagePath;
  final String url;

  const RemoveBackground({Key key, this.imagePath, @required this.url}) : super(key: key);


  @override
  _RemoveBackgroundState createState() => _RemoveBackgroundState();
}

class _RemoveBackgroundState extends State<RemoveBackground> {


  String imagePath;
  String url;
  File _image;
  bool _busy = false;
  List _recognitions;
  Uint8List masked_image;
  Uint8List mask_image;
  Uint8List original_image;
  Uint8List background_image_decoded;
  double _imageHeight;
  double _imageWidth;

  Uint8List bmp;
  BMP332Header header;


  //init state to load model
  @override
  void initState() {
    imagePath = widget.imagePath;
    url=widget.url;
    super.initState();
    _busy = true;
    _image = File(imagePath);
    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
    loadBackgroundImage();
  }

  loadModel() async {
    String res;
    res = await Tflite.loadModel(
      model: "assets/deeplabv3_257_mv_gpu.tflite",
      labels: "assets/deeplabv3_257_mv_gpu.txt",
    );
  }

  loadBackgroundImage() async {
   // if (url == null){ url ='assets/images/cloud.png';} else {return url =url;}
    ByteData backgroundData = await rootBundle.load(url);
    Uint8List backgroundBytes = Uint8List.view(backgroundData.buffer);
    image_pub.Image background_image = image_pub.decodeImage(backgroundBytes);
    background_image_decoded = background_image.getBytes();
  }

  //main function to get segmentation here
  Future runSegmentationProcess() async {
    await loadModel();
    masked_image = Uint8List(3686400);

    var recognitions = await Tflite.runSegmentationOnImage(
      path: imagePath,
      imageMean: 0,
      imageStd: 255.0,
      outputType: "png",
      asynch: true,
    );

    //resize va lay thong tin pixel cua mask image
    image_pub.Image image_recogn = image_pub.decodeImage(recognitions);
    image_pub.Image image_recogn_resize = image_pub.copyResize(
        image_recogn, width: 720, height: 1280);

    mask_image = image_recogn_resize.getBytes();

    image_pub.Image _image_orgiginal = image_pub.decodeImage(
        _image.readAsBytesSync());
    original_image = _image_orgiginal.getBytes();


    for (int k = 0; k < 1280; k++)
    {
      for (int t=0; t < 2880; t++)
      {
        if (mask_image[2880*(1279-k)+t] == 0)
        {
          masked_image[2880 * k + t] = background_image_decoded[2880 * (1279 - k) + t];
        }
        else
        {
          masked_image[2880 * k + t] = original_image[2880 * (1279 - k) + t];
        }
      }
    }

    header = BMP332Header(720, 1280);
    bmp = header.appendBitmap(masked_image);

    setState(() {
      _recognitions = recognitions;
    });

    // get the width and height of selected image
    FileImage(_image).resolve(ImageConfiguration()).addListener(
        (ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        })));
    setState(() {
      _busy = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    // get the width and height of current screen the app is running on
    Size size = MediaQuery
        .of(context)
        .size;

    // initialize two variables that will represent final width and height of the segmentation
    // and image preview on screen
    double finalW;
    double finalH;

    // when the app is first launch usually image width and height will be null
    // therefore for default value screen width and height is given
    if (_imageWidth == null && _imageHeight == null) {
      finalW = size.width;
      finalH = size.height;
    } else {
      // ratio width and ratio height will given ratio to
      // scale up or down the preview image and segmentation
      double ratioW = size.width / _imageWidth;
      double ratioH = size.height / _imageHeight;

      // final width and height after the ratio scaling is applied
      finalW = _imageWidth * ratioW;
      finalH = _imageHeight * ratioH;
    }

    List<Widget> stackChildren = [];

    // when busy load a circular progress indicator
    if (_busy) {
      stackChildren.add(Positioned(
        top: 0,
        left: 0,
        child: Center(child: CircularProgressIndicator(),),
      ));
    }

//    // widget to show image preview, when preview not available default text is shown
    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: finalW,
      height: finalH,
      //child: Image.memory(masked_image),
      child:Opacity(
        opacity : 1,
        child:_image == null ? Center(
          child: Text('Please Select an Image From Camera or Gallery'),) : Image.file(_image, fit: BoxFit.fill,),
    )));


    // widget to show segmentation preview, when segmentation not available default blank text is shown
    stackChildren.add(Positioned(
        top: 0,
        left: 0,
        width: finalW,
        height: finalH,
        child: Opacity(
          opacity: 1,
          child: _recognitions == null ? Center(child: Text(''),): Image.memory(bmp, fit: BoxFit.fill),)
    ),
    );


    return Scaffold(
        appBar: AppBar(title: Text('Chen Background'),
          actions: [
            FloatingActionButton.extended(
                label : Text('BackGround'),
                heroTag: "btn3",
                onPressed: ()  {
                  print(imagePath);
                  print(url);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BackGround(path: imagePath)),
                  );
                }
            )
          ],
        ),
        body: Stack(
          children: stackChildren,
        ),
        floatingActionButton: FloatingActionButton.extended(
          label: Text('Apply'),
          onPressed:
          //  if (url == null){ print('please select background');} else {
          runSegmentationProcess,
        ),
        bottomNavigationBar: BottomAppBar(
          child: Container(
            height: 56.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () => _shareFile(),
                ),
                IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () => _showMyDialog(),
                ),
              ],
            ),
          ),
        )
    );
  }

  _shareFile() async {
    await Share.file(
      'image',
      'image.png',
      bmp,
      'image/jpeg',
    );
  }

  _saveImage() async {
    Uint8List bytes = bmp;
    String dir = (await getApplicationDocumentsDirectory()).path;
    String fullPath = '$dir/${DateTime.now()}.png';
    File file = File(fullPath);
    await file.writeAsBytes(bytes);
    final pathh= file.path;
    GallerySaver.saveImage(pathh);
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Saving image'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you want to save this image?'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Yes'),
              onPressed: () {
                _saveImage();
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}



