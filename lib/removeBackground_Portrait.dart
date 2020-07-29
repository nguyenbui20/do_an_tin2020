import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image_pub;
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

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
  bool visible = true;

  //init state to load model
  @override
  void initState() {
    imagePath = widget.imagePath;
    url = widget.url;
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
  //load and decode background image
  loadBackgroundImage() async {
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
        image_recogn, width: 720, height: 1280); // portrait only
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

    header = BMP332Header(720, 1280); //portrait
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
    stackChildren.add(Center(
        child:Opacity(
          opacity : 1,
          child:_image == null ? Center(
            child: Text('Please Select an Image From Camera or Gallery'),) : Image.file(_image, fit: BoxFit.fill,),
        )));


    // widget to show segmentation preview, when segmentation not available default blank text is shown
    stackChildren.add(Center(
        child: Opacity(
          opacity: 1,
          child: _recognitions == null ? Center(child: Text(''),): Image.memory(bmp, fit: BoxFit.fill),)
    ),
    );

    return Scaffold(
        appBar:  AppBar(title: Text('10 ĐIỂM NHA CÔ :)',style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.orangeAccent,
          centerTitle: true,),
        body: Stack(
          children: <Widget>[
            Stack(
              children: stackChildren,
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
                  bottom: 20,
                  right: 10),
                child:IconButton(
                    icon: Icon(
                      Icons.check,
                      size: 60,
                      color: Colors.tealAccent,),
                    onPressed: runSegmentationProcess,
                )
            ),
          ],
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


class BMP332Header {
  int _width; // NOTE: width must be multiple of 4 as no account is made for bitmap padding
  int _height;

  Uint8List _bmp;
  int _totalHeaderSize;

  BMP332Header(this._width, this._height) : assert(_width & 3 == 0) {
    int baseHeaderSize = 118;
    _totalHeaderSize = baseHeaderSize + 1024; // base + color map
    int fileLength = _totalHeaderSize + _width * _height*4 ; // header + bitmap
    _bmp = new Uint8List(fileLength);
    ByteData bd = _bmp.buffer.asByteData();
    bd.setUint8(0, 0x42);
    bd.setUint8(1, 0x4d);
    bd.setUint32(2, fileLength, Endian.little); // file length
    bd.setUint32(10, _totalHeaderSize, Endian.little); // start of the bitmap
    bd.setUint32(14, 40, Endian.little); // info header size
    bd.setUint32(18, _width, Endian.little);
    bd.setUint32(22, _height, Endian.little);
    bd.setUint16(26, 1, Endian.little); // planes
    bd.setUint32(28, 32, Endian.little); // bpp
    bd.setUint32(30, 3, Endian.little); // compression
    bd.setUint32(34, _width * _height*4, Endian.little); // bitmap size
    bd.setUint8(54, 0xff);
    bd.setUint8(59, 0xff);
    bd.setUint8(64, 0xff);
    bd.setUint8(69, 0xff);
  }
  /// Insert the provided bitmap after the header and return the whole BMP
  Uint8List appendBitmap(Uint8List bitmap) {
    int size = _width * _height*4 ;
    // assert(bitmap.length == size);
    _bmp.setRange(_totalHeaderSize, _totalHeaderSize + size, bitmap);
    return _bmp;
  }
}


class BackGround extends StatelessWidget {
  final String path;

  const BackGround({Key key, this.path}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List choices = const [
      const Choice(
          title: 'Hinh 1',
          imglink: 'assets/images/cloud.png'
      ),
      const Choice(
          title: 'Hinh 2',
          imglink: 'assets/images/forest.png'
      ),
      const Choice(
          title: 'Hinh 4',
          imglink: 'assets/images/mountain.png'
      ),
      const Choice(
          title: 'Hinh 5',
          imglink: 'assets/images/road.png'
      ),
    ];

    return Scaffold(
      appBar:  AppBar(title: Text('CHOOSE BACKGROUND',style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,),
      body: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(5),
        children: List.generate(choices.length, (index) {
          return Center(
            child: ChoiceCard(
              choice: choices[index],
              item: choices[index],
              onTap: () async {
                print(choices[index].imglink);
                print(path);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) {
                      return RemoveBackground(imagePath: path, url: choices[index].imglink,);
                    }
                ));
              },
            ),
          );
        },
        ),
        scrollDirection: Axis.vertical,
      ),
      backgroundColor: Colors.white,
    );
  }
}


class Choice {
  final String title;
  final String imglink;

  const Choice({this.title, this.imglink});
}


class ChoiceCard extends StatelessWidget {
  const ChoiceCard(
      {Key key,
        this.choice,
        this.onTap,
        @required this.item,
        this.selected: false})
      : super(key: key);

  final Choice choice; // Lay tu class Choice 1 bien la choice co 2 thuoc tinh la title va imglink
  final VoidCallback onTap;
  final Choice item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.headline1;

    if (selected)
      textStyle = textStyle.copyWith(color: Colors.lightGreenAccent[400]);

    return InkWell(
        onTap: onTap,
        child: Card(
            color: Colors.white,
            child: Column(
              children: [
                new Container(
                  height: 600 ,
                  width:  650,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    image: DecorationImage(
                      image: AssetImage(choice.imglink),
                    ),
                  ),
                ),
              ],
            )
        )
    );
  }
}
