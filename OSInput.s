*********************************************************************************************

                          opt            P=68020

*********************************************************************************************

                          incdir         "includes"
                          include        "macros.i"

                          include        "intuition/intuition.i"
                          include        "intuition/screens.i"
                          include        "graphics/displayinfo.i"
                          include        "graphics/modeid.i"
                          include        "graphics/gfx.i"
                          include        "graphics/gfxbase.i"
                          include        "graphics/copper.i"
                          include        "graphics/videocontrol.i"
                          include        "exec/ports.i"
                          include        "exec/memory.i"
                          include        "exec/types.i"
                          include        "exec/io.i"
                          include        "exec/interrupts.i"
                          include        "dos/dos.i"
                          include        "dos/dosextens.i"
                          include        "workbench/startup.i"
                          include        "hardware/intbits.i"
                          include        "devices/inputevent.i"
                          include        "devices/keyboard.i"
                          include        "devices/gameport.i"
                          include        "devices/input.i"
                          
*********************************************************************************************

WaitAndHandleP96RTGWindowInputs:

                          SAVEREGS
                          
                          move.l         PipPort,d0
                          beq            exitInputHandling

                          move.l         d0,a0
                          move.l         $4,a6
                          jsr            _LVOWaitPort(a6)

                          bra            nextMessage

*********************************************************************

HandleP96RTGWindowInputs:

                          SAVEREGS

*********************************************************************
; Got messages?

nextMessage:
                          move.l         PipPort,a0
                          move.l         $4,a6
                          jsr            _LVOGetMsg(a6)
                          tst.l          d0                                                             
                          beq            exitInputHandling

*********************************************************************
; Handle message

                          move.l         d0,a0
                          move.l         im_Class(a0),-(a7)
                          move.w         im_Code(a0),-(a7)

                          move.l         d0,a1
                          move.l         $4,a6
                          jsr            _LVOReplyMsg(a6)

                          moveq          #0,d1
                          move.w         (a7)+,d1
                          move.l         (a7)+,d0

*********************************************************************
; Window
                          lea            StateRegistry,a0
                          cmp.l          #IDCMP_ACTIVEWINDOW,d0
                          bne            notActive

                          move.w         #1,asr_IsActive(a0)
                          bra            contNxtMsg
notActive:

                          cmp.l          #IDCMP_INACTIVEWINDOW,d0
                          bne            notInActive
                           
                          move.w         #0,asr_IsActive(a0)
                          bra            contNxtMsg
notInActive:


*********************************************************************
; Close window

                          cmp.l          #IDCMP_CLOSEWINDOW,d0
                          bne            notClose
                          
***************************************************
; Handle mors
;                            cmp.b       #'n',mors
;                            beq         setMorsQ

;                            move.b      #'n',mors                              
;                            bra         setMorsN

; setMorsQ:        
;                            move.b      #'q',mors                              ; Quit
; setMorsN:

***************************************************
; Handle keymap

;                           lea         KeyMap,a0
;                           move.b      #$ff,$45(a0)                           ; Esc

notClose:

*********************************************************************

contNxtMsg:
                          bra            nextMessage

*********************************************************************

exitInputHandling:
                        
                          GETREGS
                          rts
                          
*********************************************************************************************
*********************************************************************************************

AddControlGrabber:
; a0 = State Registry (ptr)

                          SAVEREGS
                          move.l         a0,-(a7)

                          move.l         $4,a6
                          jsr            _LVOCreateMsgPort(a6)
                          move.l         d0,grabPort

                          move.l         d0,a0
                          move.l         #IOSTD_SIZE,d0
                          move.l         $4,a6
                          jsr            _LVOCreateIORequest(a6)
                          move.l         d0,grabRequest

                          move.l         d0,a1
                          lea            grabDeviceName,a0
                          move.l         #0,d0
                          move.l         #0,d1
                          move.l         $4,a6
                          jsr            _LVOOpenDevice(a6)

                          move.l         #IS_SIZE,d0
                          move.l         #MEMF_PUBLIC!MEMF_CLEAR,d1
                          move.l         $4,a6 
                          jsr            _LVOAllocMem(a6)
                          move.l         d0,grabIntEvent

                          move.l         d0,a0
                          move.l         (a7)+,IS_DATA(a0)
                          lea            GrabControlHandler,a1
                          move.l         a1,IS_CODE(a0)

                          move.b         #127,LN+LN_PRI(a0)
                          lea            grabName,a1  
                          move.l         a1,LN+LN_NAME(a0)

                          move.l         grabRequest,a1
                          move.l         grabIntEvent,IO_DATA(a1)
                          move.w         #IND_ADDHANDLER,IO_COMMAND(a1)
                          move.l         $4,a6
                          jsr            _LVODoIO(a6)

                          GETREGS
                          rts

*********************************************************************************************

RemoveControlGrabber:

                          SAVEREGS

                          move.l         grabRequest,d0
                          beq            skipCleanup

                          move.l         d0,a1
                          move.l         grabIntEvent,IO_DATA(a1)
                          move.l         #ie_SIZEOF,IO_LENGTH(a1)
                          move.w         #IND_REMHANDLER,IO_COMMAND(a1)
                          move.l         $4,a6
                          jsr            _LVODoIO(a6)
                          move.l         #0,grabIntEvent

                          move.l         grabIntEvent,a1
                          move.l         #IS_SIZE,d0
                          move.l         $4,a6
                          jsr            _LVOFreeMem(a6)
                          move.l         #0,grabIntEvent
                         
                          move.l         grabRequest,a1
                          move.l         $4,a6
                          jsr            _LVOCloseDevice(a6)

                          move.l         grabRequest,a0
                          move.l         $4,a6
                          jsr            _LVODeleteIORequest(a6)
                          move.l         #0,grabRequest

                          move.l         grabPort,a0
                          move.l         $4,a6
                          jsr            _LVODeleteMsgPort(a6)
                          move.l         #0,grabPort

                          skipCleanup    :
                          jsr            ResetP96RTGWindowPointer

                          GETREGS
                          rts

*********************************************************************************************

GrabControlHandler:
; a0 = event
; a1 = state registry (ptr) 
                          move.l         a0,-(a7)

                          cmp.w          #1,asr_IsActive(a1)
                          bne            .notActive

.check:
                          cmp.b          #IECLASS_POINTERPOS,ie_Class(a0)
                          beq            .handle

                          cmp.b          #IECLASS_NEWPOINTERPOS,ie_Class(a0)
                          beq            .handle

                          cmp.b          #IECLASS_RAWKEY,ie_Class(a0)
                          bne            .skipRawKey

                          jsr            HandleRawKey

                          bra            .next

.skipRawKey:
                          cmp.b          #IECLASS_RAWMOUSE,ie_Class(a0)
                          bne            .skipRawMouse

                          jsr            HandleRawMouse

                          tst.w          asr_TrapMouse(a1)
                          beq            .next

                          bra            .handle

.skipRawMouse:
                          bra            .next

.handle:
                          move.b         #IECLASS_NULL,ie_Class(a0)

.next:
                          move.l         ie_NextEvent(a0),a0
                          move.l         a0,d1
                          bne            .check

.notActive:
                          move.l         (a7)+,d0
                          rts

*********************************************************************************************

HandleRawKey:
; a0 = event
; a1 = state registry
; https://github.com/LambdaCalculus379/bstone-amiga/blob/master/lowlevel.c

                          SAVEREGS
                          moveq          #0,d0
                          moveq          #0,d1
                          move.w         ie_Code(a0),d0                         ;  raw keycode
                          move.w         d0,d1
                          and.w          #$7f,d0

                          cmp.b          #$ff,d0
                          beq            .skipRawKey     
                          move.b         d1,asr_RawKey(a1)
.skipRawKey:

                          lea            KeyMap,a0
                          ;tst.b       d0
                          ;bmi.b       .key_up
                          btst           #7,d1
                          bne            .key_up

                          move.b         #$ff,(a0,d0.w)
                          move.b         d0,lastpressed
                          bra.b          .key_cont2

.key_up:
                          move.b         #$00,(a0,d0.w)

.key_cont2:
                          GETREGS
                          rts

*********************************************************************************************

HandleRawMouse:
; a0 = event
; a1 = state registry

                          SAVEREGS
 
 *********************************************************************************
 ; Handle buttons
                          moveq          #0,d0
                          move.w         ie_Code(a0),d0

                          move.w         d0,asr_RawMouse(a1)

                          cmp.w          #IECODE_NOBUTTON,d0
                          beq            .buttonReady

                          bset.b         #3,asr_Buttons(a1)                     ; Mouse 1 Left
                          bclr.b         #4,asr_Buttons(a1)                     ; Mouse 1 Right
                          bclr.b         #5,asr_Buttons(a1)                     ; Mouse 1 Middle

                          moveq          #0,d1
                          move.w         d0,d1
                          and.w          #IECODE_UP_PREFIX,d1                  
                          beq            .btnPressed                       
                          moveq          #1,d1                                  ; 1=Released, 0=Pressed

.btnPressed:
                          moveq          #0,d3
                          move.w         d0,d3
                          and.w          #$7f,d3                                ; scanCode = coin->ie_Code & ~IECODE_UP_PREFIX;

************************************************
; Mouse 0 Left
                          cmp.w          #IECODE_LBUTTON,d3
                          bne            .skipLButton

                          tst            d1 
                          bne            .notLDown  

                          bclr.b         #0,asr_Buttons(a1)
                          bra            .buttonReady

.notLDown:
                          bset.b         #0,asr_Buttons(a1)

.skipLButton:

************************************************
; Mouse 0 Right
                          cmp.w          #IECODE_RBUTTON,d3
                          bne            .skipRButton

                          tst            d1 
                          bne            .notRDown  

                          bclr.b         #1,asr_Buttons(a1)
                          bra            .buttonReady

.notRDown:
                          bset.b         #1,asr_Buttons(a1)

.skipRButton:

************************************************
; Mouse 0 Middle
                          cmp.w          #IECODE_MBUTTON,d3
                          bne            .skipMButton

                          tst            d1 
                          bne            .notMDown  

                          bclr.b         #2,asr_Buttons(a1)
                          bra            .buttonReady

.notMDown:
                          bset.b         #2,asr_Buttons(a1)

.skipMButton:

************************************************

.buttonReady:

*********************************************************************************
; Handle mouse move
; joy0dat / joy1dat
; 
                          moveq          #0,d0  
                          move.w         ie_X(a0),d0
                          add.b          d0,asr_Mouse0X(a1)                     ;  raw keycode

                          moveq          #0,d0  
                          move.w         ie_Y(a0),d0
                          add.b          d0,asr_Mouse0Y(a1)                     ;  raw keycode

                          GETREGS
                          rts
 
*********************************************************************************************

grabPort:                 dc.l           0
grabRequest:              dc.l           0

grabDeviceName:           dc.b           "input.device",0
                          cnop           0,32

*********************************************************************************************

grabIntEvent:             dc.l           0
grabNode:                 dc.l           0

*********************************************************************************************

grabName:                 dc.b           "AB3D mouse trap!",0
                          cnop           0,32

*********************************************************************************************

nullPointer:              dcb.b          128,0
                          cnop           0,32

*********************************************************************************************
*********************************************************************************************

StateRegistry:
; struct AB3DStateRegistry 

; Game states
IsActive:                 dc.w           1                                      ; Is window activ?
TrapMouse:                dc.w           0                                      ; Trap mouse pointer?

; Control states
Buttons:                  dc.b           %00011011                              ; 2 = Mouse0Middle, 1 = Mouse0Right, 0 = Mouse0Left (0=Fire)
                                                                                ; 5 = Mouse1Middle, 4 = Mouse1Right, 3 = Mouse1Left

JoyMove:                  dc.b           %00000000                              ; 0 = Joy0UP, 1 = Joy0DOWN, 2=Joy0LEFT, 3=Joy0RIGHT
                                                                                ; 4 = Joy1UP, 5 = Joy1DOWN, 6=Joy1LEFT, 7=Joy1RIGHT

Mouse0X:                  dc.b           0                                      ; Delta value
Mouse0Y:                  dc.b           0                                      ; Delta value

RawKey:                   dc.w           0                                      ; Raw key value
RawMouse:                 dc.w           0                                      ; Raw mouse value

*********************************************************************************************
*********************************************************************************************
; Debug prints

txtActive:                dc.b           "Active",0
txtInActive:              dc.b           "InActive",0
txtCount:                 dc.b           "Count: %lx",0
txtClass:                 dc.b           "Class: %lx",0
txtClose:                 dc.b           "Close window",0
txtRawKey:                dc.b           "Rawkey: %lx",0
txtKey:                   dc.b           "Key: %lx",0

txtMouseMove:             dc.b           "MMove: %ld %ld",0
txtMouseBtn:              dc.b           "MBtn:  %ld",0
                          cnop           0,32

datCount:                 dc.l           0    
datClass:                 dc.l           0    
datRawKey:                dc.l           0  
datKey:                   dc.l           0
datMouseBtn:              dc.l           0
datMouseMove:             dc.l           0
                          dc.l           0  

*********************************************************************************************
*********************************************************************************************
