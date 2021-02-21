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

const { time } = require('console');
var http = require('http');
var app = http.createServer((req, res)=>{
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.end("Working...");
});

var io = require('socket.io')(app);
var users = [];
var timetostart = 45;

var gameStInterval;

function setgameinterval(y){
  if(gameStInterval && !y){
    clearInterval(gameStInterval);
  }
  if(y){
    gameStInterval = setInterval(function (){
      if(timetostart < 1){
        timetostart = 45;
      }
      io.sockets.emit('game_status', JSON.stringify({
        timetostart,
        status:1,
        message: "New game will start "+timetostart+" seconds later!",
        players: users
      }));
      timetostart--;
    }, 1000);
  }else{
    io.sockets.emit('game_status', JSON.stringify({
      timetostart: 0,
      status:1,
      message: "Waiting for more players!",
      players: users
    }));
  }
}

io.sockets.on('connection', function (socket){
    function login(user){
      socket.username = user;
      users.push(socket.username);
      console.log(socket.username+' has joined the game!');
      io.sockets.emit('onlineusers', users.length);

      if(users.length >= 2){
        setgameinterval(true);
      }else{
        setgameinterval(false);
      }
    }

    socket.on('gjoin', (socd)=>{
        login(socd);
    });

    socket.on('disconnect', ()=>{
      console.log(socket.username+' çıktı!');
      users.remove(socket.username);
      io.sockets.emit('onlineusers', users.length);

      if(users.length > 2){
        setgameinterval(true);
      }else{
        setgameinterval(false);
      }
    });
  });

  
  app.listen(80);