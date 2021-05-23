var Gpio = require("onoff").Gpio;

var led = new Gpio(5, 'out');

// Turn on
led.writeSync(1);

// Turn off after 5 seconds
setTimeout(() => led.writeSync(0), 3000);
