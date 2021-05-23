var Gpio = require("onoff").Gpio;

var button = new Gpio(23, 'in', 'both', {debounceTimeout: 10});

button.watch((err, value) => {
  console.log((value===1) ? 'up':'down');
});
