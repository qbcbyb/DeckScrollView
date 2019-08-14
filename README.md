# deck_scrollview

A scrollview like recent task view of system in Android

## Getting Started

### example

```
import 'package:flutter/material.dart';
import 'package:deck_scrollview/deck_scroll_view.dart';

void main() => runApp(MyApp());
const List<String> IMAGES = [
  "https://img.xjh.me/desktop/bg/acg/62519151_p0.jpg",
  "https://img.xjh.me/desktop/bg/acg/63788867_p0.jpg",
  "https://img.xjh.me/desktop/bg/acg/60752300_p0.jpg",
  "https://img.xjh.me/desktop/bg/acg/57970506_p0.jpg",
  "https://img.xjh.me/desktop/bg/nature/64639895_p0.jpg",
  "https://img.xjh.me/desktop/bg/nature/57817236_p0.jpg",
  "https://img.xjh.me/desktop/bg/nature/63958512_p0.jpg",
  "https://img.xjh.me/desktop/bg/nature/61516978_p0.jpg",
  "https://img.xjh.me/desktop/bg/nature/63597353_p0.jpg",
];

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> imageList = List.generate(20, (int index) => IMAGES[index % IMAGES.length]);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: DeckScrollView.useDelegate(
          layoutPow: 5.0,
          itemExtent: 250,
          childDelegate: DeckChildBuilderDelegate(
              builder: (context, index) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(blurRadius: 3, color: Color(0x44000000))],
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        child: Image.network(
                          imageList[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              childCount: imageList.length),
        ),
      ),
    );
  }
}
```

![example](./demo.gif)
