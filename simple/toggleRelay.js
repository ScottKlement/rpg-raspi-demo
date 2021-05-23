var Gpio = require("onoff").Gpio;

var relay = new Gpio(4, 'out');

function toggle() {
  var currentValue = relay.readSync();
  relay.writeSync(currentValue ^ 1);
}

toggle();
setTimeout(toggle, 3000);
