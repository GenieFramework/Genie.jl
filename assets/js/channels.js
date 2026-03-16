/*
** channels.js v1.4 // 16th March 2026
** Author: Adrian Salceanu and contributors // @essenciary
** GenieFramework.com // Genie.jl
*/

// Genie.AllWebChannels holds all the channels created by the initWebChannel function
Genie.AllWebChannels = [];
Genie.findWebChannel = function(channel) {
  return this.AllWebChannels.find((app) => app.channel == channel);
}
Genie.findApp = function(channel) {
  const webchannel = this.findWebChannel(channel);
  return (webchannel) ? webchannel.parent : this.AllWebChannels[0].parent;
}
// Genie.WebChannels holds common handlers for all models
Genie.WebChannels = {};
Genie.WebChannels.messageHandlers = [];
Genie.WebChannels.errorHandlers = [];
Genie.WebChannels.openHandlers = [];
Genie.WebChannels.closeHandlers = [];
Genie.WebChannels.subscriptionHandlers = [];
Genie.WebChannels.unsubscriptionHandlers = [];
Genie.WebChannels.processingHandlers = [];
Genie.WebChannels.broadcastMessage = async (message, payload = {}) => {
  for (const WebChannel of Genie.AllWebChannels) {
      WebChannel.sendMessageTo(WebChannel.name, message, payload);
  }
};
Genie.WebChannels.sendMessageTo = async (channel, message, payload = {}) => {
  var WebChannel = Genie.findWebChannel(channel);
  (WebChannel) || (WebChannel = Genie.AllWebChannels[0]);
  WebChannel.sendMessageTo(channel, message, payload);
}

Genie.initWebChannel = function(channel = Genie.Settings.webchannels_default_route) {
  // A message maps to a channel route so that channel + message = /action/controller
  // The payload is the data exposed in the Channel Controller

  // Avoid creating duplicate channels
  if (Genie.AllWebChannels.map(w => w.channel).includes(channel)) {
    console.warn("Channel '" + channel + "' already exists, please use a different name.");
    return;
  }

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
  WebChannel.unsubscriptionHandlers = [];
  WebChannel.processingHandlers = [];

  const waitForOpenConnection = (WebChannel) => {
    // Reuse a single shared promise while a reconnection is in progress to
    // avoid spawning one interval per queued message (memory leak).
    if (WebChannel._openConnectionPromise) {
      return WebChannel._openConnectionPromise;
    }
    WebChannel._openConnectionPromise = new Promise((resolve, reject) => {
        const maxNumberOfAttempts = Genie.Settings.webchannels_connection_attempts;
        const delay = Genie.Settings.webchannels_reconnect_delay;

        let currentAttempt = 0;
        const interval = setInterval(() => {
            if (currentAttempt > maxNumberOfAttempts - 1) {
                clearInterval(interval);
                WebChannel._openConnectionPromise = null;
                reject(new Error('Maximum number of attempts exceeded: Message not sent.'));
            } else if (WebChannel.socket.readyState === 1) {
                clearInterval(interval);
                WebChannel._openConnectionPromise = null;
                resolve();
            };
            currentAttempt++;
        }, delay)
    });
    return WebChannel._openConnectionPromise;
  }

  WebChannel.socket = newSocketConnection(WebChannel);

  WebChannel.processingHandlers.push(event => {
    // backward compatibility with Genie < v5.32
    window.parse_payload.length == 2 ? window.parse_payload(WebChannel, event.data) : window.parse_payload(event.data);
  });
  
  WebChannel.messageHandlers.push(event => {
    try {
      let ed = event.data.trim();
  
      // if payload is marked as base64 encoded, remove the marker and decode
      if (ed.startsWith(Genie.Settings.webchannels_base64_marker)) {
        ed = atob(ed.substring(Genie.Settings.webchannels_base64_marker.length).trim());
      }
  
      if (ed.startsWith('{') && ed.endsWith('}')) {
        const payload = JSON.parse(ed, Genie.Revivers.reviver);
        // backward compatibility with Genie < v5.32
        window.parse_payload.length == 2 ? window.parse_payload(WebChannel, payload) : window.parse_payload(payload);
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
      clearTimeout(WebChannel._reconnectTimer);
      WebChannel._reconnectTimer = setTimeout(function() {
        WebChannel._openConnectionPromise = null;
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
  clearTimeout(WebChannel.alertTimeout);
  if (WebChannel.parent) WebChannel.parent.ws_disconnected = false;

  if (Genie.allConnected()) {
    document.getElementById(Genie.wsconnectionalert_elemid)?.remove();
    document.getElementById(Genie.wsconnectionalert_elemid + 'spacer')?.remove();
  }
}

function newSocketConnection(WebChannel, host = Genie.Settings.websockets_exposed_host) {
  // Remove listeners from the previous socket before creating a new one so
  // the old WebSocket object can be garbage-collected.
  if (WebChannel._socketListeners) {
    const prev = WebChannel._socketListeners.socket;
    if (prev) {
      prev.removeEventListener('open',    WebChannel._socketListeners.open);
      prev.removeEventListener('message', WebChannel._socketListeners.message);
      prev.removeEventListener('error',   WebChannel._socketListeners.error);
      prev.removeEventListener('close',   WebChannel._socketListeners.close);
    }
    WebChannel._socketListeners = null;
  }

  let ws = new WebSocket(Genie.Settings.websockets_protocol + '//' + host
    + (Genie.Settings.websockets_exposed_port > 0 ? (':' + Genie.Settings.websockets_exposed_port) : '')
    + ( ((Genie.Settings.base_path.trim() === '' || Genie.Settings.base_path.startsWith('/')) ? '' : '/') + Genie.Settings.base_path)
    + ( ((Genie.Settings.websockets_base_path.trim() === '' || Genie.Settings.websockets_base_path.startsWith('/')) ? '' : '/') + Genie.Settings.websockets_base_path));

    const onOpen = event => {
      const handlers = WebChannel.openHandlers.concat(Genie.WebChannels.openHandlers)
      for (let i = 0; i < handlers.length; i++) {
        let f = handlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
    };

    const onMessage = event => {
      const handlers = WebChannel.messageHandlers.concat(Genie.WebChannels.messageHandlers)
      for (let i = 0; i < handlers.length; i++) {
        let f = handlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
      WebChannel.lastMessageAt = Date.now();
    };

    const onError = event => {
      const handlers = WebChannel.errorHandlers.concat(Genie.WebChannels.errorHandlers)
      for (let i = 0; i < handlers.length; i++) {
        let f = handlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
    };

    const onClose = event => {
      const handlers = WebChannel.closeHandlers.concat(Genie.WebChannels.closeHandlers)
      for (let i = 0; i < handlers.length; i++) {
        let f = handlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
    };

    ws.addEventListener('open',    onOpen);
    ws.addEventListener('message', onMessage);
    ws.addEventListener('error',   onError);
    ws.addEventListener('close',   onClose);

    // Store named listener refs so they can be removed on the next reconnect.
    WebChannel._socketListeners = { socket: ws, open: onOpen, message: onMessage, error: onError, close: onClose };

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

// prevent overwriting of `parse_payload()` if it already exists
window.parse_payload = window.parse_payload || function(WebChannel, json_data) {
  if (isDev()) {
    console.info('Overwrite window.parse_payload to handle messages from the server');
    console.info(json_data);
  }
};

function process_payload(WebChannel, event) {
  const handlers = WebChannel.processingHandlers.concat(Genie.WebChannels.processingHandlers);
  for (let i = 0; i < handlers.length; i++) {
    let f = handlers[i];
    if (typeof f === 'function') {
      f(event);
    }
  }
};

function subscription_ready(WebChannel) {
  const handlers = WebChannel.subscriptionHandlers.concat(Genie.WebChannels.subscriptionHandlers);
  for (let i = 0; i < handlers.length; i++) {
    let f = handlers[i];
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
    clearTimeout(WebChannel._subscribeTimer);
    WebChannel._subscribeTimer = setTimeout(subscribe.bind(this, WebChannel, trial + 1), Genie.Settings.webchannels_timeout);
  } else {
    displayAlert(WebChannel);
  }
};

async function unsubscribe(WebChannel) {
  const handlers = WebChannel.unsubscriptionHandlers.concat(Genie.WebChannels.unsubscriptionHandlers);
  
  // Wrap all handlers to ensure they are converted to Promises
  const handlerPromises = handlers.map(f => {
    if (typeof f === 'function') {
      try {
        const result = f();
        if (result instanceof Promise) return result;
      } catch (err) {
        console.error('Error in unsubscription handler:', err);
      }
    }
    return Promise.resolve();
  });

  // Wait for all handlers to complete
  await Promise.all(handlerPromises);

  // Now unsubscribe
  WebChannel.sendMessageTo(WebChannel.channel, window.Genie.Settings.webchannels_unsubscribe_channel);
  if (isDev()) console.info('Unsubscription completed');
};

function isDev() {
  return Genie.Settings.env === 'dev';
}

// --------------- Initialize WebChannel ---------------
// compatibilty with earlier versions
if (window.CHANNEL === undefined) {
  Genie.initWebChannel(Genie.Settings.webchannels_default_route || '____');
} else if (typeof window.CHANNEL === 'string') {
  Genie.initWebChannel(window.CHANNEL);
}
