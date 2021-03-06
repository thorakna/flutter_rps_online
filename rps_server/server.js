// Author: Onur YAŞAR

Array.prototype.remove = function() {
  var what, a = arguments, L = a.length, ax;
  while (L && this.length) {
      what = a[--L];
      while ((ax = this.indexOf(what)) !== -1) {
          this.splice(ax, 1);
      }
  }
  return this;
};

var http = require('http');
const { start } = require('repl');
var app = http.createServer((req, res)=>{
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.end("Working...");
});

var io = require('socket.io')(app);

var usersonlyname = [];
var players = [];
var matches = [];
var notmatched = [];
var unluckyaga = {};

const ttstart = 10;
var timetostart = ttstart;

var gameStInterval;

function randGet(){
  var randindex = Math.floor(Math.random() * notmatched.length);
  return notmatched[randindex];
}
function spliceUnmatched(z){
  notmatched.splice(notmatched.findIndex(function(i){
      return i.id === z;
  }), 1);
}

function setgameinterval(y){
  if(gameStInterval && !y){
    clearInterval(gameStInterval);
    timetostart = ttstart;
  }
  if(y){
    matches = [];
    notmatched = [];
    unluckyaga = {};

    gameStInterval = setInterval(function (){
      io.sockets.emit('game_status', JSON.stringify({
        timetostart,
        status:1,
        message: "New game will start "+timetostart+" seconds later!",
        players: usersonlyname
      }));
      timetostart--;
      if(timetostart < 1){
        startGame();
        clearInterval(gameStInterval);
        timetostart = ttstart + 1;
      }
    }, 1000);
  }else{
    io.sockets.emit('game_status', JSON.stringify({
      timetostart: 0,
      status:1,
      message: "Waiting for more players!",
      players: usersonlyname
    }));
  }
}

function gameWinner(winner){
  io.sockets.emit('game_status', JSON.stringify({
    status:3,
    message: winner.nick,
    matchlength: matches.length,
    matches
  }));
  players.forEach((e,i) => {
    players[i].eliminated = false;
  });
  setTimeout(()=>{
    setgameinterval(true);
  }, 5000);
}

function matchPlayers(){
  var matchid = 0;
  while(notmatched.length > 0){
      var playerone = randGet();
      spliceUnmatched(playerone.id);
      var playertwo = randGet();
      spliceUnmatched(playertwo.id);
      if(notmatched.length == 1){
          unluckyaga = notmatched[0];
          spliceUnmatched(notmatched[0].id);
      }
      matchid++;
      matches.push({
          matchid,
          playerone: {
            id: playerone.id, 
            playernick: playerone.nick,
            item: 'yok'
          }, 
          playertwo: {
            id: playertwo.id, 
            playernick: playertwo.nick,
            item: 'yok'
          }
      });
  }
}

function startGame(){
  notmatched = [];
  var ctNotEliminated = 0;
  for (var i = 0; i < players.length; i++) {
      if(players[i].eliminated == false){
          notmatched.push(players[i]);
          ctNotEliminated++;
      }
  }
  if(ctNotEliminated == 1){
    gameWinner(notmatched[0]);
  }else{
    matchPlayers();
    io.sockets.emit('game_status', JSON.stringify({
      status:2,
      message: "",
      matchlength: matches.length,
      matches
    }));
  
    for(var i=0; i<matches.length; i++){
      var playerone = matches[i].playerone;
      var playertwo = matches[i].playertwo;
  
      console.log("Game started between "+playerone.playernick+" and "+playertwo.playernick);
  
      io.to(playerone.id).emit('game', JSON.stringify({
        opponent: playertwo.playernick,
        opitem: 'yok'
      }));
  
      io.to(playertwo.id).emit('game', JSON.stringify({
        opponent: playerone.playernick,
        opitem: 'yok'
      }));
    }
  }
}

function eliminatePlayer(playerid){
  players[players.findIndex(function(i){
    return i.id === playerid;
  })].eliminated = true;
  startGame();
}

io.sockets.on('connection', function (socket){
    function login(user){
      socket.username = user;
      usersonlyname.push(socket.username);
      players.push({
        id: socket.id,
        nick: socket.username,
        eliminated: false
      });
      console.log(socket.username+' has joined the game!');
      io.sockets.emit('onlineusers', usersonlyname.length);

      if(usersonlyname.length >= 2){
        setgameinterval(true);
      }else{
        setgameinterval(false);
      }
    }

    socket.on('gjoin', (socd)=>{
        login(socd);
    });

    socket.on('gamet', (dt)=>{
      for(var i=0; i<matches.length; i++){
        var playerone = matches[i].playerone;
        var playertwo = matches[i].playertwo;

        if(playerone.id == socket.id){
          io.to(playertwo.id).emit('game', JSON.stringify({
            opponent: playerone.playernick,
            opitem: dt
          }));
          matches[i].playerone.item = dt;
          console.log(playerone.playernick+" picked "+dt);

          if(playertwo.item != "yok"){
            if(matches[i].playerone.item == matches[i].playertwo.item){
              io.to(playerone.id).emit('matchst', "draw");
              io.to(playertwo.id).emit('matchst', "draw");
              matches[i].playerone.item = "yok";
              matches[i].playertwo.item = "yok";
            }else if(matches[i].playerone.item == "rock" && matches[i].playertwo.item == "scissors"){
              io.to(playerone.id).emit('matchst', "win");
              io.to(playertwo.id).emit('matchst', "lose");
              eliminatePlayer(playertwo.id);
              matches.splice(i, 1);
            }else if(matches[i].playerone.item == "scissors" && matches[i].playertwo.item == "rock"){
              io.to(playerone.id).emit('matchst', "lose");
              io.to(playertwo.id).emit('matchst', "win");
              eliminatePlayer(playerone.id);
              matches.splice(i, 1);
            }else if(matches[i].playerone.item == "paper" && matches[i].playertwo.item == "scissors"){
              io.to(playerone.id).emit('matchst', "lose");
              io.to(playertwo.id).emit('matchst', "win");
              eliminatePlayer(playerone.id);
              matches.splice(i, 1);
            }else if(matches[i].playerone.item == "scissors" && matches[i].playertwo.item == "paper"){
              io.to(playerone.id).emit('matchst', "win");
              io.to(playertwo.id).emit('matchst', "lose");
              eliminatePlayer(playertwo.id);
              matches.splice(i, 1);
            }else if(matches[i].playerone.item == "paper" && matches[i].playertwo.item == "rock"){
              io.to(playerone.id).emit('matchst', "win");
              io.to(playertwo.id).emit('matchst', "lose");
              eliminatePlayer(playertwo.id);
              matches.splice(i, 1);
            }else if(matches[i].playerone.item == "rock" && matches[i].playertwo.item == "paper"){
              io.to(playerone.id).emit('matchst', "lose");
              io.to(playertwo.id).emit('matchst', "win");
              eliminatePlayer(playertwo.id);
              matches.splice(i, 1);
            }
          }

          break;
        }else if(playertwo.id == socket.id){
          io.to(playerone.id).emit('game', JSON.stringify({
            opponent: playertwo.playernick,
            opitem: dt
          }));
          matches[i].playertwo.item = dt;
          console.log(playertwo.playernick+" picked "+dt);

          if(playerone.item != "yok"){
            if(matches[i].playerone.item == matches[i].playertwo.item){
              io.to(playerone.id).emit('matchst', "draw");
              io.to(playertwo.id).emit('matchst', "draw");
              matches[i].playerone.item = "yok";
              matches[i].playertwo.item = "yok";
            }else if(matches[i].playerone.item == "rock" && matches[i].playertwo.item == "scissors"){
              io.to(playerone.id).emit('matchst', "win");
              io.to(playertwo.id).emit('matchst', "lose");
              eliminatePlayer(playertwo.id);
              matches.splice(i, 1);
            }else if(matches[i].playerone.item == "scissors" && matches[i].playertwo.item == "rock"){
              io.to(playerone.id).emit('matchst', "lose");
              io.to(playertwo.id).emit('matchst', "win");
              eliminatePlayer(playerone.id);
              matches.splice(i, 1);
            }else if(matches[i].playerone.item == "paper" && matches[i].playertwo.item == "scissors"){
              io.to(playerone.id).emit('matchst', "lose");
              io.to(playertwo.id).emit('matchst', "win");
              eliminatePlayer(playerone.id);
              matches.splice(i, 1);
            }else if(matches[i].playerone.item == "scissors" && matches[i].playertwo.item == "paper"){
              io.to(playerone.id).emit('matchst', "win");
              io.to(playertwo.id).emit('matchst', "lose");
              eliminatePlayer(playertwo.id);
              matches.splice(i, 1);
            }else if(matches[i].playerone.item == "paper" && matches[i].playertwo.item == "rock"){
              io.to(playerone.id).emit('matchst', "win");
              io.to(playertwo.id).emit('matchst', "lose");
              eliminatePlayer(playertwo.id);
              matches.splice(i, 1);
            }else if(matches[i].playerone.item == "rock" && matches[i].playertwo.item == "paper"){
              io.to(playerone.id).emit('matchst', "lose");
              io.to(playertwo.id).emit('matchst', "win");
              eliminatePlayer(playertwo.id);
              matches.splice(i, 1);
            }
          }
          break;
        }
      }
    });

    socket.on('disconnect', ()=>{
      console.log(socket.username+' has left the game!');

      usersonlyname.remove(socket.username);

      players.splice(players.findIndex(function(i){
        return i.id === socket.id;
      }), 1);

      io.sockets.emit('onlineusers', usersonlyname.length);

      if(usersonlyname.length > 2){
        setgameinterval(true);
      }else{
        setgameinterval(false);
      }
    });
  });

  
  app.listen(80);