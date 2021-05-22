#!/usr/bin/env node
/**********************************************************
 * Node.js code for an RPG & Raspberry Pi Demo
 *                                 Scott Klement, 2021-05-21
 **********************************************************/

var httpServer = require('http');
var Gpio = require("onoff").Gpio;
var needle = require('needle');

/**********************************************************
 * Create global objects for the GPIO pins for the relay,
 * LEDs and switch
 **********************************************************/


global.relay = new Gpio(4, 'out');

global.led = [
  { pin:  5, gpio: null },
  { pin:  6, gpio: null },
  { pin: 13, gpio: null },
  { pin: 19, gpio: null },
  { pin: 26, gpio: null }
];

global.doorSwitch = new Gpio(23, 'in', 'both', {debounceTimeout: 250});

for (var i=0; i<led.length; i++)
  led[i].gpio = new Gpio(led[i].pin, 'out');



/**********************************************************
 * Set up an event -- each time the door switch opens or
 * closes, call a REST API on WatsonJR
 **********************************************************/

doorSwitch.watch(function(err, value) {

  if (err) {
    console.log(err);
    return;
  }

  needle.get(`http://watsonjr:8500/api/doorswitch/${value}`, function(error, response) {
    if (error) console.log(error);
    console.log(`door = ${value}`);
  });

});





/**********************************************************
 * Set up a simple HTTP server to use for a REST API
 * that will toggle the relay and LEDs or flash the LEDs
 **********************************************************/


var server = httpServer.createServer(function (req, resp) {
  
  
    var url = new URL(req.url, `http://${req.headers.host}`);

    resp.writeHead(200, {
      "Content-Type": "text/plain"
    });

    if (url.pathname === "/toggleRelay") {

      var val = relay.readSync();
      relay.writeSync( val ^ 1 );
      var result = String(val ^ 1);
      console.log(`Relay is now ${result}`);
      resp.end(result);

    }
    else if (url.pathname === "/flashLeds") {

      var ledno = 0;
      var val = 1;
        
      var intv = setInterval( function() {
        
        if (ledno >= led.length) {
          ledno = 0;
          val = val ^ 1;
        }

        console.log(`Setting LED ${ledno} to ${val}`);
        led[ledno].gpio.writeSync(val);
        ledno ++;
 
        if (val == 0 && ledno == led.length) {
           clearInterval(intv);
           resp.end("success");
        }

      }, 250);

    }
    else if (url.pathname === "/toggleLed") {

      var ledno = Number(url.search.replace("?",""));
      if (isNaN(ledno) || ledno < 1 || ledno > led.length) led = null;

      if (ledno) {
        var val = led[ledno-1].gpio.readSync();
        led[ledno-1].gpio.writeSync( val ^ 1 );
        var newval = String(val ^ 1);
        console.log(`led ${ledno} is now ${newval}`);
        resp.end(newval);
      }
      else {
        resp.end("ERROR: bad led: " + url.search.replace("?",""));
      }

    }
    else if (url.pathname === "/checkDoor") {

      var val = String(doorSwitch.readSync());
      console.log(`Checked door status. It is ${val}`);
      resp.end(val);

    }
    else {
      resp.end("ERROR: Bad url");
    }

});

server.listen(9876);
console.log(`Server ready.`);