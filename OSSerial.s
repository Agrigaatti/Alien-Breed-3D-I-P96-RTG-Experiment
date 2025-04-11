*********************************************************************************************

                          opt            P=68020

*********************************************************************************************

                          incdir         "includes"
                          include        "macros.i"

                          include        "exec/ports.i"
                          include        "exec/memory.i"
                          include        "exec/types.i"
                          include        "exec/io.i"
                          include        "devices/serial.i"

*********************************************************************************************

OpenSerialIO:
; 19200 baud, 8 bits, no parity
; 9600 baud, 8 bits, no parity

                          STOREREGS

                          move.l         $4,a6
                          jsr            _LVOCreateMsgPort(a6)
                          move.l         d0,serPort

                          move.l         d0,a0
                          move.l         #IOEXTSER_SIZE,d0
                          move.l         $4,a6
                          jsr            _LVOCreateIORequest(a6)
                          move.l         d0,serRequest

                          move.l         d0,a1
                          move.b         #SERF_XDISABLED!SERF_RAD_BOOGIE,IO_SERFLAGS(a1)
                          move.l         #19200,IO_BAUD(a1)
                          move.b         #8,IO_READLEN(a1)
                          move.b         #8,IO_WRITELEN(a1)
                          move.b         #1,IO_STOPBITS(a1)

                          lea            SerDeviceName,a0
                          move.l         #1,d0
                          move.l         #0,d1
                          move.l         $4,a6
                          jsr            _LVOOpenDevice(a6)

                          moveq          #0,d0
                          RESTOREREGS
                          rts

*********************************************************************************************
*********************************************************************************************

CloseSerialIO:

                          STOREREGS

                          move.l         serRequest,a1
                          move.l         $4,a6
                          jsr            _LVOCheckIO(a6)    
                          tst            d0
                          bne            .continueClosing

                          move.l         serRequest,a1
                          move.l         $4,a6
                          jsr            _LVOAbortIO(a6)    

                          move.l         serRequest,a1
                          move.l         $4,a6
                          jsr            _LVOWaitIO(a6)    

.continueClosing:                          
                          move.l         serRequest,a1
                          move.l         $4,a6
                          jsr            _LVOCloseDevice(a6)

                          move.l         serRequest,a0
                          move.l         $4,a6
                          jsr            _LVODeleteIORequest(a6)

                          move.l         serPort,a0
                          move.l         $4,a6
                          jsr            _LVODeleteMsgPort(a6)

                          moveq          #0,d0
                          RESTOREREGS
                          rts

*********************************************************************************************
*********************************************************************************************

serPort:                  dc.l           0
serRequest:               dc.l           0

SerDeviceName:            dc.b           "serial.device",0
                          even

*********************************************************************************************
