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
import 'RemoveBackground.dart';

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
            title: 'Hinh 3',
            imglink: 'assets/images/mountain.png'
        ),
        const Choice(
            title: 'Hinh 4',
            imglink: 'assets/images/road.png'
        ),
      ];

    return Scaffold(
      appBar: AppBar(
        title: Text('List of background images'),
      ),
      body: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(5),
        children: List.generate(choices.length, (index) {
          return Center(
            child: ChoiceCard(
              choice: choices[index],
              item: choices[index],
              onTap: () {
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
        scrollDirection: Axis.horizontal,
      ),
//      floatingActionButton: FloatingActionButton(
//          heroTag: "btn1",
//          onPressed: () {
//            Navigator.pop(context);
//          },
//          child: Text('Go back')
//      ),
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
            color: Colors.transparent,
            child: Column(
              children: [
                new Container(
                  height: 540 ,
                  width:  350,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
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