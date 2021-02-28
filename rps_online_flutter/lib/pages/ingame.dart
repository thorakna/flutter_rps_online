// Author: Onur YAŞAR

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:math' as math;

class InGame extends StatefulWidget {
  InGame({Key key, this.nickname}) : super(key: key);
  final String nickname;
  @override
  _InGameState createState() => _InGameState();
}

class Match {
  int matchid;
  PlayerMatched playerone;
  PlayerMatched playertwo;

  Match({this.matchid, this.playerone, this.playertwo});

  Match.fromJson(Map<String, dynamic> json) {
    matchid = json['matchid'];
    playerone = json['playerone'] != null
        ? new PlayerMatched.fromJson(json['playerone'])
        : null;
    playertwo = json['playertwo'] != null
        ? new PlayerMatched.fromJson(json['playertwo'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['matchid'] = this.matchid;
    if (this.playerone != null) {
      data['playerone'] = this.playerone.toJson();
    }
    if (this.playertwo != null) {
      data['playertwo'] = this.playertwo.toJson();
    }
    return data;
  }
}

class PlayerMatched {
  int id;
  String playernick;

  PlayerMatched({this.id, this.playernick});

  PlayerMatched.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    playernick = json['playernick'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['playernick'] = this.playernick;
    return data;
  }
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
  List matchesList = [];
  int matcheslistlength = 0;

  IO.Socket rpsio;
  int onlineusers = 0;
  bool areyouConnected = false;
  bool disposedDis = false;

  int gameStatus = 0;
  String gameStMessage = "";

  String opponentNick = "";
  String opitem = "yok";
  String poneitem = "yok";

  String matchStMessage = "";

  _connectSocket() {
    rpsio = IO.io('http://192.168.0.100:80', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    rpsio.connect();
    rpsio.onConnect(_onCon);
    rpsio.on('onlineusers', _onOu);
    rpsio.on('game_status', _onGameStatus);
    rpsio.on('game', _onGame);
    rpsio.on('matchst', _onMatchSt);
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
      if (status.status == 2) {
        setState(() {
          gameStatus = status.status;
          matchesList = json.decode(data)['matches'];
          matcheslistlength = json.decode(data)['matchlength'];
        });
      } else {
        setState(() {
          gameStMessage = status.message;
          gameStatus = status.status;
          playersList = List<String>.from(json.decode(data)['players']);
        });
      }
    }
  }

  _onGame(dynamic data) {
    if (mounted) {
      setState(() {
        opponentNick = json.decode(data)['opponent'];
        opitem = json.decode(data)['opitem'];
      });
    }
    print("Opponent: " + opponentNick);
  }

  _onMatchSt(dynamic data) {
    if (mounted) {
      setState(() {
        matchStMessage = data;
      });
      Future.delayed(const Duration(milliseconds: 3000), () {
        setState(() {
          poneitem = "yok";
          opitem = "yok";
          matchStMessage = "";
        });
      });
    }
  }

  _pickItem(item) {
    rpsio.emit("gamet", item);
    if (mounted) {
      setState(() {
        poneitem = item;
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
                          text:
                              areyouConnected ? 'connected.' : 'not connected',
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
                        if (areyouConnected)
                          TextSpan(text: ' player(s) online!'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
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
                            itemCount: matcheslistlength,
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
                                  Expanded(
                                      child: Text(matchesList[index]
                                          ["playerone"]["playernick"])),
                                  Image.asset(
                                    "assets/images/rps.png",
                                    width: 64,
                                  ),
                                  Expanded(
                                      child: Text(
                                    matchesList[index]["playertwo"]
                                        ["playernick"],
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
                                    child: Text(
                                      playersList[index],
                                      textAlign: TextAlign.center,
                                    ),
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
          Container(
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (gameStatus == 2)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
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
                                  "YOU",
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
                            margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
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
                                  opponentNick,
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
                if (gameStatus == 2)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: poneitem == "yok"
                          ? Image.asset(
                              "assets/images/rps_wait.gif",
                            )
                          : Image.asset(
                              "assets/images/" + poneitem + ".png",
                            ),
                    ),
                    Expanded(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(math.pi),
                        child: poneitem != "yok" && opitem != "yok"
                            ? Image.asset(
                                "assets/images/" + opitem + ".png",
                              )
                            : Image.asset(
                                "assets/images/rps_wait.gif",
                              ),
                      ),
                    ),
                  ]),
                gameStatus == 2
                    ? Container(
                        height: 80,
                        child: poneitem == "yok"
                            ? ButtonBar(
                                mainAxisSize: MainAxisSize.max,
                                alignment: MainAxisAlignment.center,
                                children: <Widget>[
                                    ElevatedButton(
                                      onPressed: () => _pickItem("rock"),
                                      child: Text(
                                        'Rock',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _pickItem("paper"),
                                      child: Text(
                                        'Paper',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _pickItem("scissors"),
                                      child: Text(
                                        'Scissors',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ])
                            : Center(
                                child: matchStMessage == "draw"
                                    ? Text(
                                        'You tie!',
                                        style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                      )
                                    : matchStMessage == "win"
                                        ? Text(
                                            'You win!',
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          )
                                        : matchStMessage == "lose"
                                            ? Text(
                                                'You lose!',
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),
                                              )
                                            : Text('You picked ' + poneitem)))
                    : Container(
                        height: 80,
                        child: Center(
                            child: Text(
                          'The game has not started yet!',
                          style: TextStyle(fontSize: 18),
                        ))),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
