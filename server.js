require('shelljs/global');

var fs      = require('fs');
var express = require('express');
var app     = express();
var docker  = "curl --unix-socket /tmp/docker.sock -X GET http:";

app.get('/containers', function (req, res) {
  var data = exec( docker + '/containers/json', {silent:true} ).stdout;
  var dojo = JSON.parse(data);
  res.send(data);
});

app.get('/saraiva/*', function (req, res) {
  var data = fs.readFileSync(__dirname + '/data/saraiva.json', "utf8");
  var callback = req.query.callback;
  var response = callback + '(' + data + ')';
  res.set('Content-Type', 'application/json');
  res.send(response);
});

fs.unlink("/tmp/app.sock", function(err) {
  app.listen("/tmp/app.sock");
  return setTimeout(function() {
    return fs.chmod("/tmp/app.sock", 0x777, function(callback) {});
  }, 2000);
});
