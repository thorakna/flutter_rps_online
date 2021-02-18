import 'package:flutter/material.dart';

class InGame extends StatefulWidget {
  InGame({Key key, this.nickname}) : super(key: key);
  final String nickname;
  @override
  _InGameState createState() => _InGameState();
}

class _InGameState extends State<InGame> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
            padding: EdgeInsets.all(15),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 10),
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, " + widget.nickname,
                  style: TextStyle(fontSize: 22),
                ),
                Text.rich(
                  TextSpan(
                    text: 'by ', // default text style
                    children: <TextSpan>[
                      TextSpan(
                          text: 'Onur YAŞAR',
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
              margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
              padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 10),
                  ]),
              child: Text("Buraya oyun gelecek!")),
        ],
      ),
    ));
  }
}
