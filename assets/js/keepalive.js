/*
** keepalive.js // v2.0.0 // 8 June 2026
** Part of Genie.jl WebChannels
** Keeps alive the websocket connection by sending a ping every x seconds
** where x = Genie.config.webchannels_keepalive_frequency
** Includes pong verification to detect backend channel failures
*/

function keepalive(WebChannel) {
  if (WebChannel.lastMessageAt !== undefined) {
    dt = Date.now() - WebChannel.lastMessageAt;
    // allow for a 200ms buffer
    if (dt + 200 < Genie.Settings.webchannels_keepalive_frequency) {
      keepaliveTimer(WebChannel, Genie.Settings.webchannels_keepalive_frequency - dt);
      return;
    }
  }

  // Don't send keepalive if websocket is disconnected or in wrong state
  if (WebChannel.ws_disconnected || !WebChannel.socket || WebChannel.socket.readyState !== 1) {
    // Reset pending state since we can't expect a pong anyway
    WebChannel._keepalive_pending = false;
    return;
  }

  // Check if previous keepalive is still pending (no pong received)
  if (WebChannel._keepalive_pending) {
    const timeoutMs = Genie.Settings.webchannels_keepalive_timeout || 5000;
    const timeSincePing = Date.now() - WebChannel._keepalive_ping_sent;

    if (timeSincePing > timeoutMs) {
      if (Genie.Settings.env == 'dev') {
        console.warn('[Genie.WebChannels] Keepalive pong not received - backend channel may be unresponsive', {
          channel: WebChannel.channel,
          timeSincePing: timeSincePing + 'ms',
          socketState: WebChannel.socket?.readyState,
          wsDisconnected: WebChannel.ws_disconnected
        });
      }

      // Mark channel as not alive
      WebChannel.channel_alive = false;

      // Only trigger alert and close if socket is still open
      // (avoid double-alert if network disconnect already triggered it)
      if (WebChannel.socket.readyState === 1 && !WebChannel.ws_disconnected) {
        // Trigger reconnection
        if (typeof displayAlert === 'function') {
          displayAlert(WebChannel, 'Backend channel is not responding. Attempting to reconnect...');
        }

        // Force reconnection by closing the socket
        WebChannel.socket.close(1000, 'Keepalive timeout');
      }

      // Reset pending state
      WebChannel._keepalive_pending = false;
      return;
    }
  }

  // Send keepalive ping
  if (Genie.Settings.env == 'dev') {
    console.info('[Genie.WebChannels] Sending keepalive ping', { channel: WebChannel.channel });
  }

  WebChannel._keepalive_pending = true;
  WebChannel._keepalive_ping_sent = Date.now();

  WebChannel.sendMessageTo(WebChannel.channel, 'keepalive', {
    'payload': { timestamp: Date.now() }
  });
}

function keepaliveTimer(WebChannel, startDelay = Genie.Settings.webchannels_keepalive_frequency) {
  clearInterval(WebChannel.keepalive_interval);
  clearTimeout(WebChannel._keepaliveTimeout);
  WebChannel._keepaliveTimeout = setTimeout(() => {
    keepalive(WebChannel);
    WebChannel.keepalive_interval = setInterval(() => keepalive(WebChannel), Genie.Settings.webchannels_keepalive_frequency);
  }, startDelay);
}

function stopKeepalive(WebChannel) {
  clearInterval(WebChannel.keepalive_interval);
  clearTimeout(WebChannel._keepaliveTimeout);
  WebChannel._keepalive_pending = false;
  WebChannel.keepalive_interval = null;
  WebChannel._keepaliveTimeout = null;
}

// Initialize keepalive state on WebChannel creation
function initKeepalive(WebChannel) {
  WebChannel._keepalive_pending = false;
  WebChannel._keepalive_ping_sent = null;
  WebChannel.channel_alive = true;

  // Public API to check if backend channel is alive
  WebChannel.isChannelAlive = function() {
    return WebChannel.socket &&
           WebChannel.socket.readyState === 1 &&
           WebChannel.channel_alive &&
           !WebChannel.ws_disconnected;
  };

  // Backwards compatibility alias for Stipple
  WebChannel.isModelAlive = WebChannel.isChannelAlive;

  // Register pong handler
  WebChannel.messageHandlers.unshift(function(event) {
    try {
      let ed = event.data.trim();

      // Handle base64 encoded payloads
      if (ed.startsWith(Genie.Settings.webchannels_base64_marker)) {
        ed = atob(ed.substring(Genie.Settings.webchannels_base64_marker.length).trim());
      }

      if (ed.startsWith('{') && ed.endsWith('}')) {
        const payload = JSON.parse(ed, Genie.Revivers.reviver);

        // Check for keepalive pong response
        if (payload.message === 'keepalive') {
          WebChannel._keepalive_pending = false;
          WebChannel.channel_alive = true;

          if (Genie.Settings.env == 'dev') {
            const latency = Date.now() - WebChannel._keepalive_ping_sent;
            console.info('[Genie.WebChannels] Keepalive pong received', {
              channel: WebChannel.channel,
              latency: latency + 'ms'
            });
          }

          // Mark this message as handled so it doesn't propagate further
          return true;
        }
      }
    } catch (ex) {
      // Ignore parsing errors, let other handlers deal with it
    }

    return false; // Not handled, continue to other handlers
  });

  // Reset keepalive state on reconnection
  WebChannel.openHandlers.push(function() {
    WebChannel._keepalive_pending = false;
    WebChannel.channel_alive = true;
    if (Genie.Settings.env == 'dev') {
      console.info('[Genie.WebChannels] Keepalive state reset on connection', { channel: WebChannel.channel });
    }
  });

  // Clear keepalive state on close
  WebChannel.closeHandlers.push(function() {
    if (Genie.Settings.env == 'dev') {
      console.info('[Genie.WebChannels] Stopping keepalive on close', { channel: WebChannel.channel });
    }
    stopKeepalive(WebChannel);
    WebChannel.channel_alive = false;
  });
}
