import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class InGame extends StatefulWidget {
  InGame({Key key, this.nickname}) : super(key: key);
  final String nickname;
  @override
  _InGameState createState() => _InGameState();
}

class RemaPlayersItem {
  int id;
  String playerone, playertwo;
  RemaPlayersItem(this.id, this.playerone, this.playertwo);
}

class GameStatus {
  final int timetostart;
  final String message;
  final int status;
  GameStatus({this.timetostart, this.status, this.message});
  GameStatus.fromJson(dynamic data)
      : timetostart = json.decode(data)['timetostart'],
        status = json.decode(data)['status'],
        message = json.decode(data)['message'];
}

class _InGameState extends State<InGame> {
  List<String> playersList = [];

  IO.Socket rpsio;
  int onlineusers = 0;
  bool areyouConnected = false;
  bool disposedDis = false;

  int gameStatus = 0;
  String gameStMessage = "";

  _connectSocket() {
    rpsio = IO.io('http://192.168.0.100:80', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    rpsio.connect();
    rpsio.onConnect(_onCon);
    rpsio.on('onlineusers', _onOu);
    rpsio.on('game_status', _onGameStatus);
    rpsio.onDisconnect(_onDis);
  }

  _onCon(_) {
    if (mounted) {
      rpsio.emit("gjoin", widget.nickname);
      setState(() {
        areyouConnected = true;
      });
    }
  }

  _onDis(_) {
    if (!mounted || disposedDis) {
      disposedDis = false;
      return false;
    }
    setState(() {
      areyouConnected = false;
    });
  }

  _onOu(dynamic data) {
    print("Num of online users: " + data.toString());
    if (mounted) {
      setState(() {
        onlineusers = data;
      });
    }
  }

  _onGameStatus(dynamic data) {
    var status = GameStatus.fromJson(data);
    if (mounted) {
      setState(() {
        gameStMessage = status.message;
        gameStatus = status.status;
        playersList = List<String>.from(json.decode(data)['players']);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  @override
  void dispose() {
    super.dispose();
    disposedDis = true;
    rpsio.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Column(
        children: <Widget>[
          Hero(
            tag: "welcome",
            child: Container(
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
                      text: 'You\'re ', // default text style
                      children: <TextSpan>[
                        TextSpan(
                          text: areyouConnected ? 'connected.' : 'disconnected',
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color:
                                  areyouConnected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                        if (areyouConnected)
                          TextSpan(
                            text: ' ' + onlineusers.toString(),
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        if (areyouConnected) TextSpan(text: ' online!'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
                margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                child: Column(
                  children: gameStatus == 2
                      ? [
                          Text(
                            "MATCHES (Real-time)",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                              child: ListView.builder(
                            itemCount: playersList.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: EdgeInsets.all(5),
                                padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 1,
                                          blurRadius: 5),
                                    ]),
                                child: Row(children: [
                                  Expanded(child: Text(playersList[index])),
                                  Image.asset(
                                    "assets/images/rps.png",
                                    width: 64,
                                  ),
                                  Expanded(
                                      child: Text(
                                    playersList[index],
                                    textAlign: TextAlign.right,
                                  )),
                                ]),
                              );
                            },
                          ))
                        ]
                      : gameStatus == 1
                          ? [
                              Text(
                                gameStMessage,
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "CONNECTED PLAYERS",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                  child: GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 200,
                                  childAspectRatio: 6 / 2,
                                ),
                                itemCount: playersList.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: EdgeInsets.all(5),
                                    padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 1,
                                              blurRadius: 5),
                                        ]),
                                    child: Text(playersList[index]),
                                  );
                                },
                              ))
                            ]
                          : [
                              Text(
                                "Connecting...",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                )),
          ),
          Expanded(
            flex: 5,
            child: Container(
                margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "GAME",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 5),
                                  ]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Player 1: ",
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  Text(
                                    "THORAKNA",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 5),
                                  ]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Player 2: ",
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  Text(
                                    "YOU",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Image.asset(
                              "assets/images/scissors.png",
                            ),
                          ),
                          Expanded(
                            child: Image.asset(
                              "assets/images/paper.png",
                            ),
                          ),
                        ]),
                  ],
                )),
          ),
        ],
      ),
    ));
  }
}
