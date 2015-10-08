var exec = require('cordova/exec');

_logMessage = function(message){
  return console.log(message);
};

exports.openCamera = function(success, error) {
    success = success || _logMessage;
    error = error || _logMessage;
    exec(success, error, "DBCamera", "openCamera", []);
};

exports.cleanup = function(success, error) {
    success = success || _logMessage;
    error = error || _logMessage;
    exec(success, error, "DBCamera", "cleanup", []);
};
