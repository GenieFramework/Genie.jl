/*
** channels.js v1.3 // 7th July 2023
** Author: Adrian Salceanu and contributors // @essenciary
** GenieFramework.com // Genie.jl
*/

// Genie.AllWebChannels holds all the channels created by the initWebChannel function
Genie.AllWebChannels = [];
Genie.findWebchannel = function(channel) {
  return this.AllWebChannels.find((app) => app.channel == channel);
}
Genie.findApp = function(channel) {
  const webchannel = this.findWebchannel(channel);
  return (webchannel) ? webchannel.parent : this.AllWebChannels[0];
}
// Genie.WebChannels holds common handlers for all models
Genie.WebChannels = {};
Genie.WebChannels.messageHandlers = [];
Genie.WebChannels.errorHandlers = [];
Genie.WebChannels.openHandlers = [];
Genie.WebChannels.closeHandlers = [];
Genie.WebChannels.subscriptionHandlers = [];
Genie.WebChannels.processingHandlers = [];
Genie.WebChannels.broadcastMessage = async (message, payload = {}) => {
  for (const WebChannel of Genie.AllWebChannels) {
      WebChannel.sendMessageTo(WebChannel.name, message, payload);
  }
};
Genie.WebChannels.sendMessageTo = async (channel, message, payload = {}) => {
  var WebChannel = Genie.findApp(channel);
  (WebChannel) || (WebChannel = GENIEMODEL.WebChannel);
  WebChannel.sendMessageTo(channel, message, payload);
}

Genie.initWebChannel = function(channel = Genie.Settings.webchannels_default_route) {
  // A message maps to a channel route so that channel + message = /action/controller
  // The payload is the data exposed in the Channel Controller
  var WebChannel = {};
  WebChannel.sendMessageTo = async (channel, message, payload = {}) => {
    let msg = JSON.stringify({
      'channel': channel,
      'message': message,
      'payload': payload
    }, Genie.Serializers.serializer);
    if (WebChannel.socket.readyState === 1) {
      WebChannel.socket.send(msg);
    } else if (Object.keys(payload).length > 0) {
      try {
        await waitForOpenConnection(WebChannel)
        WebChannel.socket.send(msg);
      } catch (err) {
        console.error(err);
        console.warn('Could not send message: ' + msg);
      }
    }
    WebChannel.lastMessageAt = Date.now();
  }

  WebChannel.channel = channel;
  WebChannel.messageHandlers = [];
  WebChannel.errorHandlers = [];
  WebChannel.openHandlers = [];
  WebChannel.closeHandlers = [];
  WebChannel.subscriptionHandlers = [];
  WebChannel.processingHandlers = [];

  const waitForOpenConnection = (WebChannel) => {
    return new Promise((resolve, reject) => {
        const maxNumberOfAttempts = Genie.Settings.webchannels_connection_attempts;
        const delay = Genie.Settings.webchannels_reconnect_delay;

        let currentAttempt = 0;
        const interval = setInterval(() => {
            if (currentAttempt > maxNumberOfAttempts - 1) {
                clearInterval(interval);
                reject(new Error('Maximum number of attempts exceeded: Message not sent.'));
            } else if (WebChannel.socket.readyState === 1) {
                clearInterval(interval);
                resolve();
            };
            currentAttempt++;
        }, delay)
    })
  }

  WebChannel.socket = newSocketConnection(WebChannel);

  WebChannel.processingHandlers.push(event => {
    window.parse_payload(WebChannel, event.data);
  });
  
  WebChannel.messageHandlers.push(event => {
    try {
      let ed = event.data.trim();
  
      // if payload is marked as base64 encoded, remove the marker and decode
      if (ed.startsWith(Genie.Settings.webchannels_base64_marker)) {
        ed = atob(ed.substring(Genie.Settings.webchannels_base64_marker.length).trim());
      }
  
      if (ed.startsWith('{') && ed.endsWith('}')) {
        window.parse_payload(WebChannel, JSON.parse(ed, Genie.Revivers.reviver));
      } else if (ed.startsWith(Genie.Settings.webchannels_eval_command)) {
        return Function('"use strict";return (' + ed.substring(Genie.Settings.webchannels_eval_command.length).trim() + ')')();
      } else if (ed == 'Subscription: OK') {
        window.subscription_ready(WebChannel);
      } else {
        window.process_payload(WebChannel, event);
      }
    } catch (ex) {
      console.error(ex);
      console.error(event.data);
    }
  });
  
  WebChannel.errorHandlers.push(event => {
    if (isDev()) {
      console.error(event.target);
    }
  });
  
  WebChannel.closeHandlers.push(event => {
    if (isDev()) {
      console.warn('WebSocket connection closed: ' + event.code + ' ' + event.reason + ' ' + event.wasClean);
    }
  });
  
  WebChannel.closeHandlers.push(event => {
    displayAlert(WebChannel);
    if (Genie.Settings.webchannels_autosubscribe) {
      if (isDev()) console.info('Attempting to reconnect! ');
      setTimeout(function() {
        WebChannel.socket = newSocketConnection(WebChannel);
      }, Genie.Settings.webchannels_reconnect_delay);
    }
  });
  
  WebChannel.openHandlers.push(event => {
    if (Genie.Settings.webchannels_autosubscribe) {
      subscribe(WebChannel);
    }
  });
  
  window.addEventListener('beforeunload', _ => {
    if (isDev()) {
      console.info('Preparing to unload');
    }
  
    if (Genie.Settings.webchannels_autosubscribe) {
      unsubscribe(WebChannel);
    }
  
    if (WebChannel.socket.readyState === 1) {
      WebChannel.socket.close();
    }
  });

  Genie.AllWebChannels.push(WebChannel);

  return WebChannel
}

Genie.wsconnectionalert_elemid = 'wsconnectionalert';
Genie.allConnected = function() {
  for (let i = 0; i < Genie.AllWebChannels.length; i++) {
    if (Genie.AllWebChannels[i].ws_disconnected) {
      return false
    }
  }
  return true
}

function displayAlert(WebChannel, content = 'Can not reach the server. Trying to reconnect...') {
  if (document.getElementById(Genie.wsconnectionalert_elemid) || WebChannel.ws_disconnected) return;

  let allConnected = Genie.allConnected();
  WebChannel.ws_disconnected = true;
  
  WebChannel.alertTimeout = setTimeout(() => {
    if (Genie.Settings.webchannels_show_alert && allConnected) {
      let elem = document.createElement('div');
      elem.id = Genie.wsconnectionalert_elemid;
      elem.style.cssText = 'position:fixed;top:0;width:100%;z-index:100;background:#e63946;color:#f1faee;text-align:center;';
      elem.style.height = '1.8em';
      elem.innerHTML = content;
    
      let elemspacer = document.createElement('div');
      elemspacer.id = Genie.wsconnectionalert_elemid + 'spacer';
      elemspacer.style.height = (Genie.Settings.webchannels_alert_overlay) ? 0 : elem.style.height;

      document.body.prepend(elem);
      document.body.prepend(elemspacer);
    }
    if (WebChannel.parent) WebChannel.parent.ws_disconnected = true;
  }, Genie.Settings.webchannels_server_gone_alert_timeout);
}

function deleteAlert(WebChannel) {
  WebChannel.ws_disconnected = false;
  clearInterval(WebChannel.alertTimeout);
  if (WebChannel.parent) WebChannel.parent.ws_disconnected = false;

  if (Genie.allConnected()) {
    document.getElementById(Genie.wsconnectionalert_elemid)?.remove();
    document.getElementById(Genie.wsconnectionalert_elemid + 'spacer')?.remove();
  }
}

function newSocketConnection(WebChannel, host = Genie.Settings.websockets_exposed_host) {
  let ws = new WebSocket(Genie.Settings.websockets_protocol + '//' + host
    + (Genie.Settings.websockets_exposed_port > 0 ? (':' + Genie.Settings.websockets_exposed_port) : '')
    + ( ((Genie.Settings.base_path.trim() === '' || Genie.Settings.base_path.startsWith('/')) ? '' : '/') + Genie.Settings.base_path)
    + ( ((Genie.Settings.websockets_base_path.trim() === '' || Genie.Settings.websockets_base_path.startsWith('/')) ? '' : '/') + Genie.Settings.websockets_base_path));

    ws.addEventListener('open', event => {
      const handlers = WebChannel.openHandlers.concat(Genie.WebChannels.openHandlers)
      for (let i = 0; i < handlers.length; i++) {
        let f = handlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
    });

    ws.addEventListener('message', event => {
      const handlers = WebChannel.messageHandlers.concat(Genie.WebChannels.messageHandlers)
      for (let i = 0; i < handlers.length; i++) {
        let f = handlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
      WebChannel.lastMessageAt = Date.now();
    });

    ws.addEventListener('error', event => {
      const handlers = WebChannel.errorHandlers.concat(Genie.WebChannels.errorHandlers)
      for (let i = 0; i < handlers.length; i++) {
        let f = handlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
    });

    ws.addEventListener('close', event => {
      const handlers = WebChannel.closeHandlers.concat(Genie.WebChannels.closeHandlers)
      for (let i = 0; i < handlers.length; i++) {
        let f = handlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
      ws.onmessage = null;
      ws.onerror = null;
      ws.onclose = null;
      ws.onopen = null;
      ws = null;
    });

    ws.addEventListener('error', _ => {
      // WebChannel.socket = newSocketConnection();
    });

    return ws
}

// --------------- Revivers ---------------

Genie.Revivers = {};
Genie.Revivers.pipeRevivers = (revivers) => (key, value) => revivers.reduce((v, f) => f(key, v), value);

Genie.Revivers.rebuildReviver = function() {
  Genie.Revivers.reviver = Genie.Revivers.pipeRevivers(Genie.Revivers.revivers)
}

Genie.Revivers.addReviver = function(reviver) {
  if (Genie.Revivers.revivers.includes(reviver)) return
  Genie.Revivers.revivers.push(reviver)
  Genie.Revivers.rebuildReviver()
}

Genie.Revivers.revive_undefined_inf_nan = function(key, value) {
  if (value == '__undefined__') {
    return undefined;
  } else if (value==='__nan__') {
    return NaN
  } else if (value==='__inf__') {
    return Infinity
  } else if (value==='__neginf__') {
    return -Infinity
  } else {
    return value;
  }
}

Genie.Revivers.revivers = [Genie.Revivers.revive_undefined_inf_nan]
Genie.Revivers.rebuildReviver()

// --------------- Serializers ---------------

Genie.Serializers = {};
Genie.Serializers.pipeSerializers = (serializers) => (key, value) => serializers.reduce((v, f) => f(key, v), value);

Genie.Serializers.rebuildSerializer = function() {
  Genie.Serializers.serializer = Genie.Serializers.pipeSerializers(Genie.Serializers.serializers)
}

Genie.Serializers.addSerializer = function(serializer) {
  if (Genie.Serializers.serializers.includes(serializer)) return
  Genie.Serializers.serializers.push(serializer)
  Genie.Serializers.rebuildSerializer()
}

Genie.Serializers.serialize_undefined_inf_nan = function(key, value) {
  if (value === undefined) {
    return '__undefined__'
  } else if (Number.isNaN(value)) {
    return '__nan__'
  } else if (value === Infinity) {
    return '__inf__'
  } else if (value === -Infinity) {
    return '__neginf__'
  } else {
    return value;
  }
}

Genie.Serializers.serializers = [Genie.Serializers.serialize_undefined_inf_nan]
Genie.Serializers.rebuildSerializer()

function parse_payload(WebChannel, json_data) {
  if (isDev()) {
    console.info('Overwrite window.parse_payload to handle messages from the server');
    console.info(json_data);
  }
};

function process_payload(WebChannel, event) {
  for (let i = 0; i < WebChannel.processingHandlers.length; i++) {
    let f = WebChannel.processingHandlers[i];
    if (typeof f === 'function') {
      f(event);
    }
  }
};

function subscription_ready(WebChannel) {
  for (let i = 0; i < WebChannel.subscriptionHandlers.length; i++) {
    let f = WebChannel.subscriptionHandlers[i];
    if (typeof f === 'function') {
      f();
    }
  }
  deleteAlert(WebChannel);
  if (isDev()) console.info('Subscription ready');
};


function subscribe(WebChannel, trial = 1) {
  if (WebChannel.socket.readyState == 1 && (document.readyState === 'complete' || document.readyState === 'interactive')) {
    WebChannel.sendMessageTo(WebChannel.channel, window.Genie.Settings.webchannels_subscribe_channel);
  } else if (trial < Genie.Settings.webchannels_subscription_trials) {
    if (isDev()) console.warn('Queuing subscription');
    trial++;
    setTimeout(subscribe.bind(this, WebChannel, trial), Genie.Settings.webchannels_timeout);
  } else {
    displayAlert(WebChannel);
  }
};

function unsubscribe(WebChannel) {
  WebChannel.sendMessageTo(WebChannel.channel, window.Genie.Settings.webchannels_unsubscribe_channel);
  if (isDev()) console.info('Unsubscription completed');
};

function isDev() {
  return Genie.Settings.env === 'dev';
}

// --------------- Initialize WebChannel ---------------

// Genie.WebChannels = Genie.initWebChannel();
