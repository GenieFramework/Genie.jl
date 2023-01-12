/*
** channels.js v1.1 // 6th January 2022
** Author: Adrian Salceanu // @essenciary
** GenieFramework.com // Genie.jl
*/
Genie.WebChannels = {};

Genie.WebChannels.initialize = function() {
  Genie.WebChannels.sendMessageTo = sendMessageTo;
  Genie.WebChannels.messageHandlers = [];
  Genie.WebChannels.errorHandlers = [];
  Genie.WebChannels.openHandlers = [];
  Genie.WebChannels.closeHandlers = [];
  Genie.WebChannels.subscriptionHandlers = [];
  Genie.WebChannels.processingHandlers = [];

  // A message maps to a channel route so that channel + message = /action/controller
  // The payload is the data exposed in the Channel Controller
  function sendMessageTo(channel, message, payload = {}) {
    var msg = JSON.stringify({
      'channel': channel,
      'message': message,
      'payload': payload
    });
    if (Genie.WebChannels.socket.readyState === 1) {
      Genie.WebChannels.socket.send(msg);
    } else if (Object.keys(payload).length > 0) {
      setTimeout(Genie.WebChannels.socket.send.bind(this, msg), Genie.Settings.webchannels_timeout);
    }
  }
}

function displayAlert(content = 'Can not reach the server - please reload the page') {
  var elemid = 'wsconnectionalert';
  if (document.getElementById(elemid) === null) {
    var elem = document.createElement('div');
    elem.id = elemid;
    elem.style.cssText = 'position:absolute;width:100%;opacity:0.5;z-index:100;background:#e63946;color:#f1faee;text-align:center;';
    elem.innerHTML = content + '<a href="javascript:location.reload();" style="color:#a8dadc;padding: 0 10pt;font-weight:bold;">Reload</a>';
    setTimeout(() => {
      document.body.appendChild(elem);
      document.location.href = '#' + elemid;
    }, Genie.Settings.webchannels_server_gone_alert_timeout);
  }
}

function newSocketConnection(host = Genie.Settings.websockets_exposed_host) {
  var ws = new WebSocket(Genie.Settings.websockets_protocol + '//' + host
    + (Genie.Settings.websockets_exposed_port > 0 ? (':' + Genie.Settings.websockets_exposed_port) : '')
    + ( ((Genie.Settings.base_path.trim() === '' || Genie.Settings.base_path.startsWith('/')) ? '' : '/') + Genie.Settings.base_path)
    + ( ((Genie.Settings.websockets_base_path.trim() === '' || Genie.Settings.websockets_base_path.startsWith('/')) ? '' : '/') + Genie.Settings.websockets_base_path));
    
    ws.addEventListener('open', function(event) {
      for (var i = 0; i < Genie.WebChannels.openHandlers.length; i++) {
        var f = Genie.WebChannels.openHandlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
    });
  
    ws.addEventListener('message', function(event) {
      for (var i = 0; i < Genie.WebChannels.messageHandlers.length; i++) {
        var f = Genie.WebChannels.messageHandlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
    });
  
    ws.addEventListener('error', function(event) {
      for (var i = 0; i < Genie.WebChannels.errorHandlers.length; i++) {
        var f = Genie.WebChannels.errorHandlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
    });
  
    ws.addEventListener('close', function(event) {
      for (var i = 0; i < Genie.WebChannels.closeHandlers.length; i++) {
        var f = Genie.WebChannels.closeHandlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
    });
  
    ws.addEventListener('error', function(_){
      Genie.WebChannels.socket = newSocketConnection();
    });

    return ws
}

Genie.WebChannels.initialize();
Genie.WebChannels.socket = newSocketConnection();

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

Genie.WebChannels.processingHandlers.push(function(event){
  window.parse_payload(event.data);
});

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
    } else if (event.data == 'Subscription: OK') {
      window.subscription_ready();
    } else {
      window.process_payload(event);
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

function process_payload(event) {
  for (var i = 0; i < Genie.WebChannels.processingHandlers.length; i++) {
    var f = Genie.WebChannels.processingHandlers[i];
    if (typeof f === 'function') {
      f(event);
    }
  }
};

function subscription_ready() {
  for (var i = 0; i < Genie.WebChannels.subscriptionHandlers.length; i++) {
    var f = Genie.WebChannels.subscriptionHandlers[i];
    if (typeof f === 'function') {
      f();
    }
  }

  if (Genie.Settings.env == 'dev') {
    console.info('Subscription ready');
  }
};


function subscribe(trial = 1) {
  if (Genie.WebChannels.socket.readyState && (document.readyState === 'complete' || document.readyState === 'interactive')) {
    Genie.WebChannels.sendMessageTo(window.Genie.Settings.webchannels_default_route, window.Genie.Settings.webchannels_subscribe_channel);
  } else if (trial < 4) {
    if (Genie.Settings.env == 'dev') {
      console.warn('Queuing subscription');
    }
    trial++;
    setTimeout(subscribe.bind(this, trial), Genie.Settings.webchannels_timeout);
  } else if (trial == 4) {
    displayAlert();
  }
};

function unsubscribe() {
  Genie.WebChannels.sendMessageTo(window.Genie.Settings.webchannels_default_route, window.Genie.Settings.webchannels_unsubscribe_channel);
  if (Genie.Settings.env == 'dev') {
    console.info('Unsubscription completed');
  }
};