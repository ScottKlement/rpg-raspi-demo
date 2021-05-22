**free
//
//  This program acts as a REST API that is called by the Raspberry Pi
//  when the state of the door switch changes.  It will send the new
//  door state to the RASPIR program via the DOORSWITCH data queue.
//
//                                          Scott Klement 2021-05-21
//
//  To compile:
//    *> CRTRPGMOD DOORSWITCH SRCFILE(QRPGLESRC) DBGVIEW(*LIST)
//    *> CRTPGM    DOORSWITCH MODULE(*PGM) BNDSRVPGM(QHTTPSVR/QZHBCGI) -
//    *>            ACTGRP(KLEMENT)
//
//  This program is meant to be run in the 57xx-DG1
//  IBM HTTP Server (powered by Apache).  See the sample
//  httpd.conf included with this source code for an example
//  of how Apache should be configured.
//

ctl-opt option(*srcstmt: *nodebugio);

dcl-pr QtmhWrStout extproc(*dclcase);
   DtaVar    pointer value;
   DtaVarLen int(10) const;
   ErrorCode char(32767) options(*varsize);
end-pr;

dcl-pr getenv pointer extproc(*dclcase);
   var pointer value options(*string);
end-pr;

dcl-ds ignore qualified;
   bytesProv int(10) inz(0);
   bytesAvail int(10) inz(0);
end-ds;

dcl-pr QSNDDTAQ extpgm('QSYS/QSNDDTAQ');
  DataQueue    char(10)     const;
  DataQueueLib char(10)     const;
  DataLength   packed(5: 0) const;
  Data         char(32767)  options(*varsize) const;
end-pr;

dcl-c REQUIRED_PART const('/api/doorswitch/');
dcl-c CRLF x'0d25';

dcl-s doorState int(10);
dcl-s env pointer;
dcl-s pos int(10);
dcl-s url varchar(1000) inz('');
dcl-s result varchar(1000);

monitor;

  env = getenv('REQUEST_URI');
  if env <> *null;
    url = %str(env);
    pos = %scan(REQUIRED_PART: url) + %len(REQUIRED_PART);
    doorState = %int(%subst(url: pos));
  endif;

  QSNDDTAQ( 'DOORSWITCH'
          : '*LIBL'
          : 80
          : '*DOOR' + %char(doorState) );

  result = 'Status: 200 OK' + CRLF
         + 'Content-Type: text/plain' + CRLF
         + CRLF
         + 'success';

on-error;

  result = 'Status: 400 Bad Request' + CRLF
         + 'Content-Type: text/plain' + CRLF
         + CRLF
         + 'failed';

endmon;

QtmhWrStout( %addr(result:*data): %len(result): ignore );

return; 
