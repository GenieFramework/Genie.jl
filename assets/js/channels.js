/*
** channels.js v1.1 // 6th January 2022
** Author: Adrian Salceanu // @essenciary
** GenieFramework.com // Genie.jl
*/
Genie.WebChannels = {};

Genie.WebChannels.load_channels = function() {
  Genie.WebChannels.sendMessageTo = sendMessageTo;
  Genie.WebChannels.messageHandlers = [];
  Genie.WebChannels.errorHandlers = [];
  Genie.WebChannels.openHandlers = [];
  Genie.WebChannels.closeHandlers = [];

  Genie.WebChannels.socket.addEventListener('open', function(event) {
    for (var i = 0; i < Genie.WebChannels.openHandlers.length; i++) {
      var f = Genie.WebChannels.openHandlers[i];
      if (typeof f === 'function') {
        f(event);
      }
    }
  });

  Genie.WebChannels.socket.addEventListener('message', function(event) {
    for (var i = 0; i < Genie.WebChannels.messageHandlers.length; i++) {
      var f = Genie.WebChannels.messageHandlers[i];
      if (typeof f === 'function') {
        f(event);
      }
    }
  });

  Genie.WebChannels.socket.addEventListener('error', function(event) {
    for (var i = 0; i < Genie.WebChannels.errorHandlers.length; i++) {
      var f = Genie.WebChannels.errorHandlers[i];
      if (typeof f === 'function') {
        f(event);
      }
    }
  });

  Genie.WebChannels.socket.addEventListener('close', function(event) {
    for (var i = 0; i < Genie.WebChannels.closeHandlers.length; i++) {
      var f = Genie.WebChannels.closeHandlers[i];
      if (typeof f === 'function') {
        f(event);
      }
    }
  });

  // A message maps to a channel route so that channel + message = /action/controller
  // The payload is the data exposed in the Channel Controller
  function sendMessageTo(channel, message, payload = {}) {
    if (Genie.WebChannels.socket.readyState === 1) {
      Genie.WebChannels.socket.send(JSON.stringify({
        'channel': channel,
        'message': message,
        'payload': payload
      }));
    }
  }
};

// connecting to 0.0.0.0 (ex in prod) fails
let wshost = Genie.Settings.server_host == "0.0.0.0" ? window.location.hostname : Genie.Settings.server_host;

function newSocketConnection(host = wshost) {
  return new WebSocket(window.location.protocol.replace('http', 'ws') + '//' + host +
      ':' + Genie.Settings.websockets_port + (Genie.Settings.base_path == '' ? '' : '/' + Genie.Settings.base_path));
}

Genie.WebChannels.port = Genie.Settings.websockets_port == Genie.Settings.server_port ? window.location.port : Genie.Settings.websockets_port
Genie.WebChannels.socket = newSocketConnection();
Genie.WebChannels.socket.addEventListener('error', function(_){
  Genie.WebChannels.socket = newSocketConnection();
});

window.addEventListener('beforeunload', function (_) {
  if (Genie.Settings.env == 'dev') {
    console.info('Preparing to unload');
  }

  if (Genie.Settings.webchannels_autosubscribe) {
    unsubscribe();
  }

  if (Genie.WebChannels.socket.readyState === 1) {
    Genie.WebChannels.socket.close();
  }
});

Genie.WebChannels.load_channels();

Genie.WebChannels.messageHandlers.push(function(event){
  try {
    event.data = event.data.trim();

    if (event.data.startsWith('{') && event.data.endsWith('}')) {
      window.parse_payload(JSON.parse(event.data, function (key, value) {
        if (value == '__undefined__') {
          return undefined;
        } else {
          return value;
        }
      }));
    } else if (event.data.startsWith(Genie.Settings.webchannels_eval_command)) {
      return Function('"use strict";return (' + event.data.substring(Genie.Settings.webchannels_eval_command.length).trim() + ')')();
    } else {
      window.parse_payload(event.data);
    }
  } catch (ex) {
    console.error(ex);
    console.error(event.data);
  }
});

Genie.WebChannels.errorHandlers.push(function(event) {
  if (Genie.Settings.env == 'dev') {
    console.error(event.data);
  }
});

Genie.WebChannels.closeHandlers.push(function(event) {
  if (Genie.Settings.env == 'dev') {
    console.warn('Server closed WebSocket connection');
  }
});

Genie.WebChannels.closeHandlers.push(function(event) {
  if (Genie.Settings.webchannels_autosubscribe) {
    if (Genie.Settings.env == 'dev') {
      console.info('Attempting to reconnect');
    }
    Genie.WebChannels.socket = newSocketConnection();
    subscribe();
  }
});

Genie.WebChannels.openHandlers.push(function(event) {
  if (Genie.Settings.webchannels_autosubscribe) {
    subscribe();
  }
});

function parse_payload(json_data) {
  if (Genie.Settings.env == 'dev') {
    console.info('Overwrite window.parse_payload to handle messages from the server');
    console.info(json_data);
  }
};

function subscription_ready() {
  if (Genie.Settings.env == 'dev') {
    console.info('Subscription ready');
  }
};

function subscribe() {
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    Genie.WebChannels.sendMessageTo(window.Genie.Settings.webchannels_default_route, window.Genie.Settings.webchannels_subscribe_channel);
    window.subscription_ready();
  } else {
    if (Genie.Settings.env == 'dev') {
      console.warn('Queuing subscription');
    }
    setTimeout(subscribe, Genie.Settings.webchannels_timeout);
  }
};

function unsubscribe() {
  Genie.WebChannels.sendMessageTo(window.Genie.Settings.webchannels_default_route, window.Genie.Settings.webchannels_unsubscribe_channel);
  if (Genie.Settings.env == 'dev') {
    console.info('Unsubscription completed');
  }
};