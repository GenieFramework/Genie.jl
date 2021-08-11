Genie.WebChannels = {};
var tm = null;

Genie.WebChannels.load_channels = function() {
  let port = window.location.port;
  var socket = new Pollymer.Request();
  var channels = Genie.WebChannels;
  var poll_interval = Genie.Settings.webchannels_timeout;
  var server_uri = window.location.protocol + '//' + window.location.hostname + ':' +  port;

  channels.channel = socket;
  channels.sendMessageTo = sendMessageTo;
  channels.clientId = clientId;
  channels.wtid = clientId();
  channels.poll_interval = poll_interval;
  channels.server_uri = server_uri;

  channels.messageHandlers = [];
  channels.errorHandlers = [];

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
  console.log("Preparing to unload");

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

function subscribe() {
  if (document.readyState === "complete" || document.readyState === "interactive") {
    Genie.WebChannels.channel.start('GET', Genie.WebChannels.server_uri + Genie.Settings.base_path + Genie.Settings.webthreads_default_route + '/' + Genie.Settings.webchannels_subscribe_channel + '?wtclient=' + Genie.WebChannels.wtid, {}, '');
    pull();
  } else {
    tm = setTimeout(subscribe, Genie.WebChannels.poll_interval);
  }
}

function unsubscribe() {
  clearTimeout(tm);
  Genie.WebChannels.channel.abort();

  if (document.readyState === "complete" || document.readyState === "interactive") {
    Genie.WebChannels.channel.start('GET', Genie.WebChannels.server_uri + Genie.Settings.base_path + Genie.Settings.webthreads_default_route + '/' + Genie.Settings.webchannels_unsubscribe_channel + '?wtclient=' + Genie.WebChannels.wtid, {}, '');
  } else {
    tm = setTimeout(unsubscribe, Genie.WebChannels.poll_interval);
  }
}

function pull() {
  if (document.readyState === "complete" || document.readyState === "interactive") {
    Genie.WebChannels.channel.start('POST', Genie.WebChannels.server_uri + Genie.Settings.base_path + Genie.Settings.webthreads_default_route + '/' + Genie.Settings.webthreads_pull_route + '?wtclient=' + Genie.WebChannels.wtid, {}, '');
  }

  tm = setTimeout(pull, Genie.WebChannels.poll_interval);
}

function push(body, headers = {}) {
  clearTimeout(tm);
  Genie.WebChannels.channel.abort();

  if (document.readyState === "complete" || document.readyState === "interactive") {
    Genie.WebChannels.channel.start('POST', Genie.WebChannels.server_uri + Genie.Settings.base_path + Genie.Settings.webthreads_default_route + '/' + Genie.Settings.webthreads_push_route + '?wtclient=' + Genie.WebChannels.wtid, headers, body);
  }

  pull();
}

Genie.WebChannels.messageHandlers.push(function(code, result, headers){
  for ( i=0; i<result.length; i++ ) {
    message = result[i].trim();
    try {
      if (message.startsWith('{') && message.endsWith('}')) {
        window.parse_payload(JSON.parse(message, function (key, value) {
          if (value == "__undefined__") {
            return undefined;
          } else {
            return value;
          }
        }));
      } else if (message.startsWith(Genie.Settings.webchannels_eval_command)) {
        return Function('"use strict";return (' + message.substring(Genie.Settings.webchannels_eval_command.length).trim() + ')')();
      } else {
        window.parse_payload(message);
      }
    } catch (ex) {
      console.log(ex);
    }
  }
});

Genie.WebChannels.errorHandlers.push(function(event) {
  console.log("Error: ", event);
  tm = setTimeout(pull, Genie.WebChannels.poll_interval * 2);
});

function parse_payload(json_data) {
  console.log("Overwrite window.parse_payload to handle messages from the server")
  console.log(json_data);
};