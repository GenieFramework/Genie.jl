/*
** channels.js v1.3 // 7th July 2023
** Author: Adrian Salceanu and contributors // @essenciary
** GenieFramework.com // Genie.jl
*/

Genie.initWebChannel = function(channel = Genie.Settings.webchannels_default_route) {
  // A message maps to a channel route so that channel + message = /action/controller
  // The payload is the data exposed in the Channel Controller
  var WebChannel = {};
  WebChannel.sendMessageTo = async (channel, message, payload = {}) => {
    let msg = JSON.stringify({
      'channel': channel,
      'message': message,
      'payload': payload
    });
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

  Genie.AllWebChannels = Genie.AllWebChannels || [];
  Genie.AllWebChannels.push(WebChannel);
  Genie.WebChannels = WebChannel; // for compatibility with older code

  return WebChannel
}

let wsconnectionalert_elemid = 'wsconnectionalert';

function displayAlert(WebChannel, content = 'Can not reach the server. Trying to reconnect...') {
  if (document.getElementById(wsconnectionalert_elemid) || WebChannel.wsconnectionalert_triggered) return;

  let alreadyAlerted = false;
  for (let i = 0; i < Genie.AllWebChannels.length; i++) {
    if (Genie.AllWebChannels[i].wsconnectionalert_triggered) {
      alreadyAlerted = true;
      break;
    }
  }
  
  let elem = document.createElement('div');
  elem.id = wsconnectionalert_elemid;
  elem.style.cssText = 'position:fixed;top:0;width:100%;z-index:100;background:#e63946;color:#f1faee;text-align:center;';
  elem.style.height = '1.8em';
  elem.innerHTML = content;

  let elemspacer = document.createElement('div');
  elemspacer.id = wsconnectionalert_elemid + 'spacer';
  elemspacer.style.height = (Genie.Settings.webchannels_alert_overlay) ? 0 : elem.style.height;

  WebChannel.wsconnectionalert_triggered = true;

  WebChannel.alertTimeout = setTimeout(() => {
    if (Genie.Settings.webchannels_show_alert && !alreadyAlerted) {
      document.body.prepend(elem);
      document.body.prepend(elemspacer);
    }
    if (WebChannel.parent) WebChannel.parent.ws_disconnected = true;
  }, Genie.Settings.webchannels_server_gone_alert_timeout);
}

function deleteAlert(WebChannel) {
  WebChannel.wsconnectionalert_triggered = false;
  clearInterval(WebChannel.alertTimeout);
  if (WebChannel.parent) WebChannel.parent.ws_disconnected = false;

  // if all WebChannels are connected, remove the alert
  setTimeout(() => {
    for (let i = 0; i < Genie.AllWebChannels.length; i++) {
      if (Genie.AllWebChannels[i].wsconnectionalert_triggered) {
        return
      }
    }

    document.getElementById(wsconnectionalert_elemid)?.remove();
    document.getElementById(wsconnectionalert_elemid + 'spacer')?.remove();
  }, 0);
}

function newSocketConnection(WebChannel, host = Genie.Settings.websockets_exposed_host) {
  let ws = new WebSocket(Genie.Settings.websockets_protocol + '//' + host
    + (Genie.Settings.websockets_exposed_port > 0 ? (':' + Genie.Settings.websockets_exposed_port) : '')
    + ( ((Genie.Settings.base_path.trim() === '' || Genie.Settings.base_path.startsWith('/')) ? '' : '/') + Genie.Settings.base_path)
    + ( ((Genie.Settings.websockets_base_path.trim() === '' || Genie.Settings.websockets_base_path.startsWith('/')) ? '' : '/') + Genie.Settings.websockets_base_path));

    ws.addEventListener('open', event => {
      for (let i = 0; i < WebChannel.openHandlers.length; i++) {
        let f = WebChannel.openHandlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
    });

    ws.addEventListener('message', event => {
      for (let i = 0; i < WebChannel.messageHandlers.length; i++) {
        let f = WebChannel.messageHandlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
      WebChannel.lastMessageAt = Date.now();
    });

    ws.addEventListener('error', event => {
      for (let i = 0; i < WebChannel.errorHandlers.length; i++) {
        let f = WebChannel.errorHandlers[i];
        if (typeof f === 'function') {
          f(event);
        }
      }
    });

    ws.addEventListener('close', event => {
      for (let i = 0; i < WebChannel.closeHandlers.length; i++) {
        let f = WebChannel.closeHandlers[i];
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

Genie.Revivers.revive_undefined = function(key, value) {
  if (value == '__undefined__') {
    return undefined;
  } else {
    return value;
  }
}

Genie.Revivers.revivers = [Genie.Revivers.revive_undefined]
Genie.Revivers.rebuildReviver()

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
