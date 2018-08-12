window.WebChannels = {};
window.WebChannels.load_channels = function() {
  const SERVER_HOST = 'localhost';
  const SERVER_PORT = 8001;

  var socket = new WebSocket('ws://' + SERVER_HOST + ':' + SERVER_PORT);
  var channels = window.WebChannels;

  channels.channel = socket;
  channels.sendMessageTo = sendMessageTo;

  channels.messageHandlers = [];
  channels.errorHandlers = [];
  channels.openHandlers = [];
  channels.closeHandlers = [];

  socket.addEventListener('open', function(event) {
    for (var i = 0; i < channels.openHandlers.length; i++) {
      var f = channels.openHandlers[i];
      if (typeof f === 'function') {
        f(event);
      }
    }
  });

  socket.addEventListener('message', function(event) {
    for (var i = 0; i < channels.messageHandlers.length; i++) {
      var f = channels.messageHandlers[i];
      if (typeof f === 'function') {
        f(event);
      }
    }
  });

  socket.addEventListener('error', function(event) {
    for (var i = 0; i < channels.errorHandlers.length; i++) {
      var f = channels.errorHandlers[i];
      if (typeof f === 'function') {
        f(event);
      }
    }
  });

  socket.addEventListener('close', function(event) {
    for (var i = 0; i < channels.closeHandlers.length; i++) {
      var f = channels.closeHandlers[i];
      if (typeof f === 'function') {
        f(event);
      }
    }
  });

  // A message maps to a channel route so that channel + message = /action/controller
  // The payload is the data made exposed in the Channel Controller
  function sendMessageTo(channel, message, payload) {
    if (socket.readyState === 1) {
      socket.send(JSON.stringify({
        'channel': channel,
        'message': message,
        'payload': payload
      }));
    }
  }
};

window.addEventListener('beforeunload', function (event) {
  if (WebChannels.channel.readyState === 1) {
    WebChannels.channel.close();
  }
});
