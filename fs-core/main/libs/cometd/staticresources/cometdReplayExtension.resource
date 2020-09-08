var cometdReplayExtension = function() {
	var REPLAY_FROM_KEY = "replay";
	
	var _cometd;
	var _extensionEnabled;
	var _replay;
	var _channel;

	this.setExtensionEnabled = function(extensionEnabled) {
		_extensionEnabled = extensionEnabled;
	}

	this.setReplay = function (replay) {
		_replay = parseInt(replay, 10);
	}

	this.setChannel = function(channel) {
		_channel = channel;
	}

	this.registered = function(name, cometd) {
		_cometd = cometd;
	};

	this.incoming = function(message) {
		if (message.channel === '/meta/handshake') {
			if (message.ext && message.ext[REPLAY_FROM_KEY] == true) {
				_extensionEnabled = true;
			}
		} else if (message.channel === _channel && message.data && message.data.event && message.data.event.replayId) {
			_replay = message.data.event.replayId;
		}
	}
	
	this.outgoing = function(message) {
		if (message.channel === '/meta/subscribe') {
			if (_extensionEnabled) {
				if (!message.ext) { message.ext = {}; }

				var replayFromMap = {};
				replayFromMap[_channel] = _replay;

				// add "ext : { "replay" : { CHANNEL : REPLAY_VALUE }}" to subscribe message
				message.ext[REPLAY_FROM_KEY] = replayFromMap;
			}
		}
	};
}; 
