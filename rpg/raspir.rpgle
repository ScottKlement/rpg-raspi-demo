**free
//
//  RPG Program to Demonstrate a Raspberry Pi
//                                     Scott Klement 2021-05-21
//
//  To Compile:
//    * First install HTTPAPI, and add to your library list.
//    *> CRTDSPF FILE(RASPID) SRCFILE(QDDSSRC)
//    *> CRTBNDRPG PGM(RASPIR) SRCFILE(QRPGLESRC) DBGVIEW(LIST)
//
//
ctl-opt dftactgrp(*no) actgrp(*new) option(*srcstmt:*nodebugio) bnddir('HTTPAPI');

dcl-f RASPID workstn usropn indds(dsp);

/copy httpapi_h

dcl-pr QRCVDTAQ extpgm('QSYS/QRCVDTAQ');
  dataQueue    char(10)      const;
  dataQueueLib char(10)      const;
  dataLength   packed(5: 0);
  data         char(32767)   options(*varsize);
  wait         packed(5: 0)  const;
end-pr;

dcl-pr QCMDEXC extpgm('QSYS/QCMDEXC');
  command      char(2000)    const;
  length       packed(15: 5) const;
  igc          char(3)       const options(*nopass);
end-pr;

dcl-ds dsp qualified;
  Exit   ind pos(3);
  Relay  ind pos(8);
  Flash  ind pos(10);
  Opened ind pos(99);
end-ds;

dcl-c RPI_URL 'http://172.16.1.139:9876';

dcl-s dqrec char(80);
dcl-s dqlen packed(5: 0);
dcl-s startStatus varchar(100);

// -------------------------------------------------------
//   Setup Data Queue.
//
//     This is used by the /doorswitch REST API to send
//     us the door status when it changes.
//
//     Connect it to the display file so that we can wait
//     on either the user submitting the display or the
//     door status changing.
// -------------------------------------------------------

callp(e) QCMDEXC('DLTDTAQ DTAQ(DOORSWITCH)': 2000);

QCMDEXC('CRTDTAQ DTAQ(DOORSWITCH) +
                 TYPE(*STD) +
                 MAXLEN(80) +
                 FORCE(*NO) +
                 TEXT(''Raspberry Pi Door Switch'') +
                 SEQ(*FIFO)': 2000);

QCMDEXC('OVRDSPF FILE(RASPID) DTAQ(DOORSWITCH)': 2000);


// -------------------------------------------------------
//   Check to see what the door switch currently says
//   so that we can start the screen with the right value
// -------------------------------------------------------

http_setOption('timeout': '10');

monitor;
  startStatus = http_string('GET': RPI_URL + '/checkDoor');
  if startStatus = '1' or startStatus = '0';
    updateDoor(startStatus);
  endif;
on-error;
  updateDoor(*on);
endmon;


// -------------------------------------------------------
//    Main loop
//     1. WRITE screen so that the user can see/use it.
//     2. Wait on data queue
//     3. If data queue indicates input from the
//        display file, read the display and act on it
//        accordingly.
//     4. If data queue indicates input from the door
//        switch, update the display with the new value
//     5. Repeat steps 1-4 until F3 was indicated in
//        step 3.
// -------------------------------------------------------

open RASPID;

dou dsp.Exit = *on;

  dsp.Exit = *off;
  dsp.Relay = *off;
  dsp.Flash = *off;

  write RASPI1;

  dqrec = *blanks;
  dqlen = %size(dqrec);

  QRCVDTAQ('DOORSWITCH': '*LIBL': dqlen: dqrec: -1);
  if %len(dqrec) < 5;
    leave;
  endif;

  if %subst(dqrec:1:5) = '*DSPF';

    read(e) RASPI1;

    select;
    when %error = *on;
    when dsp.Exit = *on;   // F3=Exit
      leave;
    when dsp.Relay = *on;  // F8 = Toggle relay
      ToggleRelay();
    when dsp.Flash  = *on; // F10 = Flash LEDs
      FlashLeds();
    other;
      ToggleLED(Color);    // Toggle one LED
    endsl;

  endif;

  if %subst(dqrec:1:5) = '*DOOR';

    UpdateDoor(%subst(dqrec:6));

  endif;

enddo;

close RASPID;
QCMDEXC('DLTDTAQ DTAQ(DOORSWITCH)': 2000);

*inlr = *on;


// -------------------------------------------------------------------
//   Toggle the state of the relay.
// -------------------------------------------------------------------
dcl-proc ToggleRelay;

  http_string('GET': RPI_URL + '/toggleRelay');

end-proc;


// -------------------------------------------------------------------
//   Flash all of the LEDs on, then off again
// -------------------------------------------------------------------
dcl-proc FlashLeds;

    http_string('GET': RPI_URL + '/flashLeds');

end-proc;


// -------------------------------------------------------------------
//   Toggle a specific LED
// -------------------------------------------------------------------
dcl-proc ToggleLED;

  dcl-pi *n;
    LED char(1);
  end-pi;

  if (LED >= '1' and LED <= '5');
    http_string('GET': RPI_URL + '/toggleLed?' + LED);
  endif;

end-proc;



// -------------------------------------------------------------------
//   update the door status on the screen
// -------------------------------------------------------------------
dcl-proc UpdateDoor;

  dcl-pi *n;
    OPENED char(1) const;
  end-pi;

  if OPENED = *on;
    DOORSTATE = ' OPEN ';
    dsp.Opened = *on;
  else;
    DOORSTATE = 'CLOSED';
    dsp.Opened = *off;
  endif;

end-proc; 
