import 'package:flutter/material.dart';
import 'package:rebound_dart/BaseSpringSystem.dart';
import 'package:rebound_dart/SimpleSpringListener.dart';
import 'package:rebound_dart/Spring.dart';
import 'package:rebound_dart/SpringConfig.dart';
import 'package:rebound_dart/SpringSystem.dart';
import 'package:rebound_dart/SpringUtil.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  int _counter = 0;
  late SpringSystem springSystem;
  late Spring spring;

  double val = 0;

  @override
  void initState() {
    super.initState();
    this.springSystem = SpringSystem.create(this);
    this.spring = springSystem.createSpring();
    this.spring.setSpringConfig(SpringConfig(180, 10));
    spring.addListener(SimpleSpringListener(updateCallback: (spring) {
      setState(() {
        this.val = spring.getCurrentValue();
        print("$val");
      });
    }));
  }

  @override
  void dispose() {
    super.dispose();
    springSystem.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Stack(
        children: [Positioned(
          top: val,
          left: val,
          child: FlutterLogo(
            size: 100,
          ),
        ),]
      ),
      floatingActionButton: GestureDetector(
        onPanEnd: (details) {
          spring.setEndValue(50);
        },
        onPanDown: (details) {
          spring.setEndValue(350);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}