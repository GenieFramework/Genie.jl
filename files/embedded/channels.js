Genie.WebChannels = {};
Genie.WebChannels.load_channels = function() {
  let port = Genie.Settings.websockets_port == Genie.Settings.server_port ? window.location.port : Genie.Settings.websockets_port;
  var socket = new WebSocket(window.location.protocol.replace("http", "ws") + '//' + window.location.hostname + ':' +  port);
  var channels = Genie.WebChannels;

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
  // The payload is the data exposed in the Channel Controller
  function sendMessageTo(channel, message, payload = {}) {
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
  console.log("Preparing to unload");

  if ( Genie.Settings.webchannels_autosubscribe ) {
    unsubscribe();
  }

  if (Genie.WebChannels.channel.readyState === 1) {
    Genie.WebChannels.channel.close();
  }
});

Genie.WebChannels.load_channels();

Genie.WebChannels.messageHandlers.push(function(event){
  try {
    if (event.data.startsWith('{') && event.data.endsWith('}')) {
      window.parse_payload(JSON.parse(event.data, function (key, value) {
        if (value == "__undefined__") {
          return undefined;
        } else {
          return value;
        }
      }));
    } else {
      window.parse_payload(event.data);
    }
  } catch (ex) {
    console.log(ex);
  }
});

Genie.WebChannels.errorHandlers.push(function(event) {
  console.log(event.data);
});

Genie.WebChannels.closeHandlers.push(function(event) {
  console.log("Server closed WebSocket connection");
});

Genie.WebChannels.openHandlers.push(function(event) {
  if ( Genie.Settings.webchannels_autosubscribe ) {
    subscribe();
  }
});

function parse_payload(json_data) {
  console.log("Overwrite window.parse_payload to handle messages from the server")
  console.log(json_data);
};

function subscribe() {
  if (document.readyState === "complete" || document.readyState === "interactive") {
    Genie.WebChannels.sendMessageTo(window.Genie.Settings.webchannels_default_route, window.Genie.Settings.webchannels_subscribe_channel);
    console.log("Subscription ready");
  } else {
    console.log("Queuing subscription");
    setTimeout(subscribe, 1000);
  }
};

function unsubscribe() {
  Genie.WebChannels.sendMessageTo(window.Genie.Settings.webchannels_default_route, window.Genie.Settings.webchannels_unsubscribe_channel);
  console.log("Unsubscription completed");
};