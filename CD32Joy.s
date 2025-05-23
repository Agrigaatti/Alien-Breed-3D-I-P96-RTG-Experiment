*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

                          incdir     "includes"
                          include    "AB3DI.i"
                          include    "macros.i"
                          include    "defs.i"

                          include    "libraries/lowlevel.i"

*********************************************************************************************

OpenLowLevelLibrary:

                          lea        LowLevelName(pc),a1
                          moveq      #0,d0
                          move.l     4.w,a6
                          jsr        _LVOOpenLibrary(a6)
                          move.l     d0,LowLevelBase

                          rts

*********************************************************************************************

CloseLowLevelLibrary:

                          move.l     LowLevelBase(pc),a1
                          tst.l      a1
                          beq.s      .Exit

                          move.l     4.w,a6
                          jsr        _LVOCloseLibrary(a6)

.Exit:
                          rts

*********************************************************************************************
; XDEF _ReadJoy
; pass port number in d0 0-3

_ReadJoy1:
                          move.l     a6,-(a7)
                          move.l     #1,d0
                          move.l     LowLevelBase(pc),a6
                          jsr        _LVOReadJoyPort(a6)
                          move.l     (a7)+,a6
                          move.l     d0,d1

            ; and.l #$00FF000F,d0

                          and.l      #JP_TYPE_MASK,d1

; bits in d1

                          cmp.l      #JP_TYPE_NOTAVAIL,d1 	
                          beq.b      .Empty

                          cmp.l      #JP_TYPE_GAMECTLR,d1 
                          beq.b      .GameCtrl

                          cmp.l      #JP_TYPE_MOUSE,d1    
                          beq        .Mouse

                          cmp.l      #JP_TYPE_JOYSTK,d1   
                          beq        .Joystick

            ; cmp.l	#JP_TYPE_UNKNOWN,d1  

; type is an unknown type 

.Empty:
                          rts

.GameCtrl:

;	these are the bit defs..
;
;     JPF_BUTTON_BLUE         Blue - Stop
;     JPF_BUTTON_RED          Red - Select
;     JPF_BUTTON_YELLOW       Yellow - Repeat
;     JPF_BUTTON_GREEN        Green - Shuffle
;     JPF_BUTTON_FORWARD      Charcoal - Forward
;     JPF_BUTTON_REVERSE      Charcoal - Reverse
;     JPF_BUTTON_PLAY         Grey - Play/Pause
;     JPF_JOY_UP              Up
;     JPF_JOY_DOWN            Down
;     JPF_JOY_LEFT            Left
;     JPF_JOY_RIGHT           Right

                          move.l     #KeyMap,a5
                          moveq      #0,d5
                          move.b     forward_key,d5
                          move.l     d0,d1
                          and.l      #JPF_JOY_UP,d0
                          sne        (a5,d5.w)
                          move.b     backward_key,d5
                          move.l     d1,d0
                          and.l      #JPF_JOY_DOWN,d0
                          sne        (a5,d5.w)
                          move.b     turn_left_key,d5
                          move.l     d1,d0
                          and.l      #JPF_JOY_LEFT,d0
                          sne        (a5,d5.w)
                          move.b     turn_right_key,d5
                          move.l     d1,d0
                          and.l      #JPF_JOY_RIGHT,d0
                          sne        (a5,d5.w)

                          move.b     fire_key,d5
                          move.l     d1,d0
                          and.l      #JPF_BUTTON_GREEN,d0
                          sne        (a5,d5.w)

                          move.b     operate_key,d5
                          move.l     d1,d0
                          and.l      #JPF_BUTTON_YELLOW,d0
                          sne        (a5,d5.w)

                          move.b     run_key,d5
                          move.l     d1,d0
                          and.l      #JPF_BUTTON_RED,d0
                          sne        (a5,d5.w)

                          move.b     duck_key,d5
                          move.l     d1,d0
                          and.l      #JPF_BUTTON_BLUE,d0
                          beq.s      .notduckbutpre
                          tst.b      .ducklast
                          bne.s      .notduckbut
                          st         .ducklast
                          sne        (a5,d5.w)

.notduckbutpre:
                          clr.b      .ducklast

.notduckbut:
                          move.b     force_sidestep_key,d5
                          move.l     d1,d0
                          and.l      #JPF_BUTTON_FORWARD,d0
                          sne        (a5,d5.w)

                          move.l     d1,d0
                          and.l      #JPF_BUTTON_REVERSE,d0
                          beq.s      .nonextweappre
                          tst.b      .heldlast
                          bne.s      .nonextweap
                          st         .heldlast
                          moveq      #0,d0
                          moveq      #0,d2
                          move.b     PLR1_GunSelected,d2
                          move.l     #PLR1_GunData,a6
                          move.l     #GUNVALS,a5

.findcurrent: 
                          cmp.b      (a5,d0.w),d2
                          beq.s      .foundcurrent
                          add.b      #1,d0
                          bra        .findcurrent

.foundcurrent:
                          moveq      #0,d2

.picknext:
                          add.b      #1,d0
                          cmp.b      #4,d0
                          ble.s      .notfirst
                          move.b     #0,d0

.notfirst:
                          moveq      #0,d2
                          moveq      #0,d3 
                          move.b     (a5,d0.w),d2
                          move.b     d2,d3
                          lsl.w      #5,d2
                          tst.b      7(a6,d2.w)
                          beq.s      .picknext
                          move.b     d3,PLR1_GunSelected
 
                          bra        .nonextweap
 
.nonextweappre:
                          clr.b      .heldlast

.nonextweap:
                          rts

*********************************************************************************************

.heldlast:                dc.b       0
.ducklast:                dc.b       0

*********************************************************************************************

.Joystick:

                          move.l     #KeyMap,a5
                          move.l     #SineTable,a0

                          btst       #1,$dff00c
                          sne        d0
                          btst       #1,$dff00d
                          sne        d1
                          btst       #0,$dff00c
                          sne        d2
                          btst       #0,$dff00d
                          sne        d3
                          moveq      #0,d5
                          move.b     fire_key,d5
                          ;btst       #7,$bfe001                ; LMB port 2
                          btst.b     #3,Buttons 
                          seq        (a5,d5.w)

                          move.b     turn_left_key,d5
                          move.b     d0,(a5,d5.w)
                          move.b     turn_right_key,d5
                          move.b     d1,(a5,d5.w)
                          eor.b      d0,d2
                          move.b     forward_key,d5
                          move.b     d2,(a5,d5.w)
                          eor.b      d1,d3
                          move.b     backward_key,d5
                          move.b     d3,(a5,d5.w)
                          rts

.Mouse:
                          rts

_ReadJoy2:
                          move.l     a6,-(a7)
                          move.l     #1,d0
                          move.l     LowLevelBase(pc),a6
                          jsr        _LVOReadJoyPort(a6)

                          move.l     (a7)+,a6
                          move.l     d0,d1

            ; and.l #$00FF000F,d0

                          and.l      #JP_TYPE_MASK,d1

; bits in d1

                          cmp.l      #JP_TYPE_NOTAVAIL,d1 	
                          beq.b      .Empty

                          cmp.l      #JP_TYPE_GAMECTLR,d1 
                          beq.b      .GameCtrl

                          cmp.l      #JP_TYPE_MOUSE,d1    
                          beq        .Mouse

                          cmp.l      #JP_TYPE_JOYSTK,d1   
                          beq        .Joystick

            ; cmp.l	#JP_TYPE_UNKNOWN,d1  

; type is an unknown type 

.Empty:
                          rts

.GameCtrl:

;	these are the bit defs..
;
;     JPF_BUTTON_BLUE         Blue - Stop
;     JPF_BUTTON_RED          Red - Select
;     JPF_BUTTON_YELLOW       Yellow - Repeat
;     JPF_BUTTON_GREEN        Green - Shuffle
;     JPF_BUTTON_FORWARD      Charcoal - Forward
;     JPF_BUTTON_REVERSE      Charcoal - Reverse
;     JPF_BUTTON_PLAY         Grey - Play/Pause
;     JPF_JOY_UP              Up
;     JPF_JOY_DOWN            Down
;     JPF_JOY_LEFT            Left
;     JPF_JOY_RIGHT           Right

                          move.l     #KeyMap,a5
                          moveq      #0,d5
                          move.b     forward_key,d5
                          move.l     d0,d1
                          and.l      #JPF_JOY_UP,d0
                          sne        (a5,d5.w)
                          move.b     backward_key,d5
                          move.l     d1,d0
                          and.l      #JPF_JOY_DOWN,d0
                          sne        (a5,d5.w)
                          move.b     turn_left_key,d5
                          move.l     d1,d0
                          and.l      #JPF_JOY_LEFT,d0
                          sne        (a5,d5.w)
                          move.b     turn_right_key,d5
                          move.l     d1,d0
                          and.l      #JPF_JOY_RIGHT,d0
                          sne        (a5,d5.w)

                          move.b     fire_key,d5
                          move.l     d1,d0
                          and.l      #JPF_BUTTON_GREEN,d0
                          sne        (a5,d5.w)

                          move.b     operate_key,d5
                          move.l     d1,d0
                          and.l      #JPF_BUTTON_YELLOW,d0
                          sne        (a5,d5.w)

                          move.b     run_key,d5
                          move.l     d1,d0
                          and.l      #JPF_BUTTON_RED,d0
                          sne        (a5,d5.w)

                          move.b     duck_key,d5
                          move.l     d1,d0
                          and.l      #JPF_BUTTON_BLUE,d0
                          beq.s      .notduckbutpre
                          tst.b      .ducklast
                          sne        (a5,d5.w)
                          bne.s      .notduckbut
                          st         .ducklast
                          bra        .notduckbut

.notduckbutpre:
                          clr.b      .ducklast

.notduckbut:
                          move.b     force_sidestep_key,d5
                          move.l     d1,d0
                          and.l      #JPF_BUTTON_FORWARD,d0
                          sne        (a5,d5.w)

                          move.l     d1,d0
                          and.l      #JPF_BUTTON_REVERSE,d0
                          beq.s      .nonextweappre
                          tst.b      .heldlast
                          bne.s      .nonextweap
                          st         .heldlast
                          moveq      #0,d0
                          move.b     PLR2_GunSelected,d2
                          move.l     #PLR2_GunData,a6
                          move.l     #GUNVALS,a5

.findcurrent: 
                          cmp.b      (a5,d0.w),d2
                          beq.s      .foundcurrent
                          add.b      #1,d0
                          bra        .findcurrent

.foundcurrent: 
                          moveq      #0,d2

.picknext:
                          add.b      #1,d0
                          cmp.b      #4,d0
                          ble.s      .notfirst
                          move.b     #0,d0

.notfirst:
                          moveq      #0,d2
                          moveq      #0,d3
                          move.b     (a5,d0.w),d2
                          move.b     d2,d3
                          lsl.w      #5,d2
                          tst.b      7(a6,d2.w)
                          beq.s      .picknext
                          move.b     d3,PLR2_GunSelected
 
                          bra        .nonextweap
 
.nonextweappre:
                          clr.b      .heldlast

.nonextweap:
                          rts

*********************************************************************************************

.heldlast:                dc.b       0
.ducklast:                dc.b       0

*********************************************************************************************

.Joystick:

                          move.l     #KeyMap,a5
                          move.l     #SineTable,a0

                          btst       #1,$dff00c
                          sne        d0
                          btst       #1,$dff00d
                          sne        d1
                          btst       #0,$dff00c
                          sne        d2
                          btst       #0,$dff00d
                          sne        d3
                          moveq      #0,d5
                          move.b     fire_key,d5
                          ;btst       #7,$bfe001                ; LMB port 2
                          btst.b     #3,Buttons 
                          seq        (a5,d5.w)

                          move.b     turn_left_key,d5
                          move.b     d0,(a5,d5.w)
                          move.b     turn_right_key,d5
                          move.b     d1,(a5,d5.w)
                          eor.b      d0,d2
                          move.b     forward_key,d5
                          move.b     d2,(a5,d5.w)
                          eor.b      d1,d3
                          move.b     backward_key,d5
                          move.b     d3,(a5,d5.w)
                          rts

.Mouse:
                          rts

;BUTVALS
; dc.l JPF_BUTTON_BLUE         Blue - Stop
; dc.l JPF_BUTTON_RED          Red - Select
; dc.l JPF_BUTTON_YELLOW       Yellow - Repeat
; dc.l JPF_BUTTON_GREEN        Green - Shuffle
; dc.l JPF_BUTTON_FORWARD      Charcoal - Forward
; dc.l JPF_BUTTON_REVERSE      Charcoal - Reverse
; dc.l JPF_BUTTON_PLAY         Grey - Play/Pause
; dc.l JPF_JOY_UP              Up
; dc.l JPF_JOY_DOWN            Down
; dc.l JPF_JOY_LEFT            Left
; dc.l JPF_JOY_RIGHT           Right

*********************************************************************************************

LowLevelBase:             dc.l       0
LowLevelName:             dc.b       'lowlevel.library',0
                          cnop       0,32

*********************************************************************************************