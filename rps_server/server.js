// Author: Onur YAŞAR

var http = require('http');
var app = http.createServer((req, res)=>{
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.end("Working...");
});

var io = require('socket.io')(app);
var users = [];

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

io.sockets.on('connection', function (socket){
    function login(user){
      socket.username = user;
      users.push(socket.username);
      console.log(socket.username+' girdi!');
      io.sockets.emit('onlineusers', users.length);
    }
    socket.on('gjoin', (socd)=>{
        login(socd);
    });
    socket.on('mesaj', (msg)=>{
      io.sockets.emit('msg', {
        mesag:msg,
        user:socket.username
      });
    });
    socket.on('disconnect', ()=>{
      console.log(socket.username+' çıktı!');
      users.remove(socket.username);
      io.sockets.emit('onlineusers', users.length);
    });
  });
  
  app.listen(80);