window.Channels = {};
window.Channels.load_channels = function() {
  var socket = new WebSocket('ws://localhost:8000');
  var channels = window.Channels;

  channels.channel = socket;
  channels.sendMessageTo = sendMessageTo;

  channels.messageHandlers = [];
  channels.errorHandlers = [];
  channels.openHandlers = [];
  channels.closeHandlers = [];

  socket.addEventListener('open', function(event) {
    for (var i = 0; i < channels.openHandlers.length; i++) {
      var f = channels.openHandlers[i];
      if (typeof f === "function") {
        f(event);
      }
    }
  });

  socket.addEventListener('message', function(event) {
    for (var i = 0; i < channels.messageHandlers.length; i++) {
      var f = channels.messageHandlers[i];
      if (typeof f === "function") {
        f(event);
      }
    }
  });

  socket.addEventListener('error', function(event) {
    for (var i = 0; i < channels.errorHandlers.length; i++) {
      var f = channels.errorHandlers[i];
      if (typeof f === "function") {
        f(event);
      }
    }
  });

  socket.addEventListener('close', function(event) {
    for (var i = 0; i < channels.closeHandlers.length; i++) {
      var f = channels.closeHandlers[i];
      if (typeof f === "function") {
        f(event);
      }
    }
  });

  // A message maps to a channel route so that channel + message = /action/controller
  // The payload is the data made exposed in the Channel Controller
  function sendMessageTo(channel = "/", message = "", payload = {}) {
    if (socket.readyState === 1) {

      socket.send(JSON.stringify({
        "channel": channel,
        "message": message,
        "payload": payload
      }));
    }
  }
};
