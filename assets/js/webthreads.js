Genie.WebChannels = {};
var tm = null;

Genie.WebChannels.load_channels = function() {
  let port = window.location.port;
  var socket = new Pollymer.Request();
  var channels = Genie.WebChannels;
  var poll_interval = Genie.Settings.webchannels_timeout;
  var server_uri = window.location.protocol + '//' + window.location.hostname + ':' + port;

  channels.channel = socket;
  channels.sendMessageTo = sendMessageTo;
  channels.clientId = clientId;
  channels.wtid = clientId();
  channels.poll_interval = poll_interval;
  channels.server_uri = server_uri;

  channels.messageHandlers = [];
  channels.errorHandlers = [];
  channels.subscriptionHandlers = [];
  channels.processingHandlers = [];

  socket.maxTries = 1;

  socket.on('finished', function(code, result, headers) {
    for (var i = 0; i < channels.messageHandlers.length; i++) {
      var f = channels.messageHandlers[i];
      if (typeof f === 'function') {
        f(code, result, headers);
      }
    }
  });

  socket.on('error', function(event) {
    for (var i = 0; i < channels.errorHandlers.length; i++) {
      var f = channels.errorHandlers[i];
      if (typeof f === 'function') {
        f(event);
      }
    }
  });


  // A message maps to a channel route so that channel + message = /action/controller
  // The payload is the data exposed in the Channel Controller
  function sendMessageTo(channel, message, payload = {}, headers = {}) {
    push(
      JSON.stringify({
      'channel': channel,
      'message': message,
      'payload': payload
    }), headers);
  }

  function clientId() {;
    return window.crypto.getRandomValues(new Uint32Array(1))[0];
  }
};

window.addEventListener('beforeunload', function (event) {
  if ( Genie.Settings.webchannels_autosubscribe ) {
    unsubscribe();
  }

  if (Genie.WebChannels.channel.readyState === 1) {
    Genie.WebChannels.channel.abort();
  }
});

window.addEventListener('load', function (event) {
  if ( Genie.Settings.webchannels_autosubscribe ) {
    subscribe();
  }
});

Genie.WebChannels.load_channels();

function uri_factory(endpoint) {
  return Genie.WebChannels.server_uri + (Genie.Settings.base_path == '' ? '/' : Genie.Settings.base_path) + Genie.Settings.webthreads_default_route + '/' + endpoint + '?wtclient=' + Genie.WebChannels.wtid;
}

function displayAlert(content = 'Can not reach the server - please reload the page') {
  let elemid = 'wsconnectionalert';
  if (document.getElementById(elemid) === null) {
    let elem = document.createElement('div');
    elem.id = elemid;
    elem.style.cssText = 'position:absolute;width:100%;opacity:0.5;z-index:100;background:#e63946;color:#f1faee;text-align:center;';
    elem.innerHTML = content + '<a href="javascript:location.reload();" style="color:#a8dadc;padding: 0 10pt;font-weight:bold;">Reload</a>';
    setTimeout(() => {
      document.body.appendChild(elem);
      document.location.href = '#' + elemid;
    }, Genie.Settings.webchannels_server_gone_alert_timeout);
  }
}

function subscribe(trial = 1) {
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    Genie.WebChannels.channel.start('GET', uri_factory(Genie.Settings.webchannels_subscribe_channel), {}, '');
    pull();
  } else if (trial < Genie.Settings.webchannels_subscription_trails) {
    if (isDev()) console.warn('Queuing subscription');
    trial++;
    setTimeout(subscribe.bind(this, trial), Genie.WebChannels.poll_interval);
  } else {
    displayAlert();
  }
}

function unsubscribe() {
  clearTimeout(tm);
  Genie.WebChannels.channel.abort();

  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    Genie.WebChannels.channel.start('GET', uri_factory(Genie.Settings.webchannels_unsubscribe_channel), {}, '');
  } else {
    tm = setTimeout(unsubscribe, Genie.WebChannels.poll_interval);
  }
}

function pull() {
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    Genie.WebChannels.channel.start('POST', uri_factory(Genie.Settings.webthreads_pull_route), {}, '');
  }

  tm = setTimeout(pull, Genie.WebChannels.poll_interval);
}

function push(body, headers = {}) {
  clearTimeout(tm);
  Genie.WebChannels.channel.abort();

  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    Genie.WebChannels.channel.start('POST', uri_factory(Genie.Settings.webthreads_push_route), headers, body);
  }

  pull();
}


Genie.Revivers = {};
Genie.Revivers.pipeRevivers = (revivers) => (key, value) => revivers.reduce((v, f) => f(key, v), value);

Genie.Revivers.rebuildReviver = function() {
  Genie.Revivers.reviver = Genie.Revivers.pipeRevivers(Genie.Revivers.revivers)
}

Genie.Revivers.addReviver = function(reviver) {
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

Genie.WebChannels.processingHandlers.push(function(json_data){
  window.parse_payload(json_data);
});

Genie.WebChannels.messageHandlers.push(function(code, result, headers){
  if ( typeof result === 'string' ) {
    result = result.trim();
    parts = result.split(',');
    for (let i = 0; i < parts.length; i++) {
      message = parts[i].trim();
      processMessage(message);
    }
  } else if ( typeof result === 'object' && result !== null ) {
    for (let i=0; i<result.length; i++ ) {
      message = result[i].trim();
      processMessage(message);
    }
  }
});

function processMessage(message) {
  if (message.startsWith(Genie.Settings.webchannels_base64_marker)) {
    message = atob(message.substring(Genie.Settings.webchannels_base64_marker.length).trim());
  }

  if (message.startsWith(Genie.Settings.webchannels_eval_command)) {
    return Function('"use strict";return (' + message.substring(Genie.Settings.webchannels_eval_command.length).trim() + ')')();
  } else if (message == 'Subscription: OK') {
    window.subscription_ready();
  } else if (message.startsWith('{') && message.endsWith('}')) {
    window.parse_payload(JSON.parse(message, Genie.Revivers.reviver));
  } else {
    window.process_payload(message);
  }
}

Genie.WebChannels.errorHandlers.push(function(event) {
  if (Genie.Settings.env == 'dev') {
    console.error('Error: ', event);
  }
  tm = setTimeout(pull, Genie.WebChannels.poll_interval * 2);
});

function process_payload(json_data) {
  for (var i = 0; i < Genie.WebChannels.processingHandlers.length; i++) {
    var f = Genie.WebChannels.processingHandlers[i];
    if (typeof f === 'function') {
      f(json_data);
    }
  }
};

function parse_payload(json_data) {
  if (Genie.Settings.env == 'dev') {
    console.info('Overwrite window.parse_payload to handle messages from the server');
    console.info(json_data);
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