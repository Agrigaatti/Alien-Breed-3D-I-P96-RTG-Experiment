*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

PLR2_mouse_control:

                          jsr        ReadMouse
                          jsr        PLR2_alwayskeys
                          move.l     #SineTable,a0
                          move.w     PLR2s_angspd,d1
                          move.w     angpos,d0
                          and.w      #8190,d0
                          move.w     d0,PLR2s_angpos
                          move.w     (a0,d0.w),PLR2s_sinval
                          adda.w     #2048,a0
                          move.w     (a0,d0.w),PLR2s_cosval

                          move.l     PLR2s_xspdval,d6
                          move.l     PLR2s_zspdval,d7

                          neg.l      d6
                          ble.s      .nobug1
                          asr.l      #1,d6
                          add.l      #1,d6
                          bra.s      .bug1
.nobug1
                          asr.l      #1,d6
.bug1:

                          neg.l      d7
                          ble.s      .nobug2
                          asr.l      #1,d7
                          add.l      #1,d7
                          bra.s      .bug2
.nobug2
                          asr.l      #1,d7
.bug2: 

                          move.w     ymouse,d3
                          sub.w      oldymouse,d3
                          add.w      d3,oldymouse
                          asr.w      #1,d3
                          cmp.w      #50,d3
                          ble.s      .nofastfor
                          move.w     #50,d3
.nofastfor:
                          cmp.w      #-50,d3
                          bge.s      .nofastback
                          move.w     #-50,d3
.nofastback:

                          tst.b      PLR2_Ducked
                          beq.s      .nohalve
                          asr.w      #1,d3
.nohalve

                          move.w     d3,d2
                          asl.w      #4,d2
                          move.w     d2,d1
 
                          move.w     d1,d2
                          add.w      PLR2_bobble,d1
                          and.w      #8190,d1
                          move.w     d1,PLR2_bobble
                          add.w      PLR2_clumptime,d2
                          move.w     d2,d1
                          and.w      #4095,d2
                          move.w     d2,PLR2_clumptime
                          and.w      #-4096,d1
                          beq.s      .noclump
 
                          bsr        PLR2clump
 
.noclump


                          move.w     PLR2s_sinval,d1
                          move.w     PLR2s_cosval,d2
 
                          move.w     d2,d4
                          move.w     d1,d5
                          muls       lrs,d4
                          muls       lrs,d5
 

                          muls       d3,d2
                          muls       d3,d1
                          sub.l      d4,d1
                          add.l      d5,d2

                          sub.l      d1,d6
                          sub.l      d2,d7
                          add.l      d6,PLR2s_xspdval
                          add.l      d7,PLR2s_zspdval
                          move.l     PLR2s_xspdval,d6
                          move.l     PLR2s_zspdval,d7
                          add.l      d6,PLR2s_xoff
                          add.l      d7,PLR2s_zoff

                          tst.b      PLR2_fire
                          beq.s      .firenotpressed
; fire was pressed last time.
                          ;btst       #6,$bfe001
                          btst       #0,Buttons 
                          bne.s      .firenownotpressed
; fire is still pressed this time.
                          st         PLR2_fire
                          bra        .donePLR2
 
.firenownotpressed:
; fire has been released.
                          clr.b      PLR2_fire
                          bra        .donePLR2
 
.firenotpressed

; fire was not pressed last frame...
                          ;btst       #6,$bfe001
                          btst       #0,Buttons 
; if it has still not been pressed, go back above
                          bne.s      .firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
                          st         PLR2_clicked
                          st         PLR2_fire

.donePLR2:

                          bsr        Plr2Fall
 
                          rts

PLR2_alwayskeys
                          move.l     #KeyMap,a5
                          moveq      #0,d7
                          move.b     operate_key,d7
                          move.b     (a5,d7.w),d1
                          beq.s      .nottapped
                          tst.b      OldSpace
                          bne.s      .nottapped
                          st         PLR2_SPCTAP
.nottapped:
                          move.b     d1,OldSpace

                          move.b     duck_key,d7
                          tst.b      (a5,d7.w)
                          beq.s      .notduck
                          clr.b      (a5,d7.w)
                          move.l     #playerheight,PLR2s_targheight
                          not.b      PLR2_Ducked
                          beq.s      .notduck
                          move.l     #playercrouched,PLR2s_targheight
.notduck:

                          move.l     PLR2_Roompt,a4
                          move.l     ToZoneFloor(a4),d0
                          sub.l      ToZoneRoof(a4),d0
                          tst.b      PLR2_StoodInTop
                          beq.s      .usebottom
                          move.l     ToUpperFloor(a4),d0
                          sub.l      ToUpperRoof(a4),d0
.usebottom:

                          cmp.l      #playerheight+3*1024,d0
                          bgt.s      .oktostand
                          st         PLR2_Ducked
                          move.l     #playercrouched,PLR2s_targheight
.oktostand:

                          move.l     PLR2s_height,d0
                          move.l     PLR2s_targheight,d1
                          cmp.l      d1,d0
                          beq.s      .noupordown
                          bgt.s      .crouch
                          add.l      #1024,d0
                          bra.b      .noupordown
.crouch:
                          sub.l      #1024,d0
.noupordown:
                          move.l     d0,PLR2s_height

                          tst.b      $27(a5)                             ; K
                          beq.s      .notselkey
                          st         PLR2KEYS
                          clr.b      PLR2PATH
                          clr.b      PLR2MOUSE
                          clr.b      PLR2JOY
                          clr.b      PLR2MOUSEKBD

.notselkey:
                          tst.b      $26(a5)                             ; J
                          beq.s      .notseljoy
                          clr.b      PLR2KEYS
                          clr.b      PLR2PATH
                          clr.b      PLR2MOUSE
                          st         PLR2JOY
                          clr.b      PLR2MOUSEKBD

.notseljoy:
                          tst.b      $37(a5)                             ; M
                          beq.s      .notselmouse
                          clr.b      PLR2KEYS
                          clr.b      PLR2PATH
                          st         PLR2MOUSE
                          clr.b      PLR2JOY
                          clr.b      PLR2MOUSEKBD

.notselmouse:
                          tst.b      $36(a5)                             ; N (New mouse kbd)
                          beq.s      .notselmousekbd
                          clr.b      PLR2KEYS
                          clr.b      PLR2PATH
                          clr.b      PLR2MOUSE
                          clr.b      PLR2JOY
                          st         PLR2MOUSEKBD

.notselmousekbd:
                          lea        1(a5),a4
                          lea        PLR2_GunData,a3
                          move.l     #GUNVALS,a2
                          move.w     #4,d1

.pickweap:
                          move.b     (a2)+,d0                            ; number of gun
                          tst.b      (a4)+
                          beq.s      .notgotweap
                          moveq      #0,d2
                          move.b     d0,d2
                          asl.w      #5,d2
                          tst.b      7(a3,d2.w)
                          beq.s      .notgotweap
                          move.b     d0,PLR2_GunSelected
                     
.notgotweap:
                          dbra       d1,.pickweap
 
                          tst.b      $43(a5)
                          beq.s      .notswapscr
                          tst.b      lastscr
                          bne.s      .notswapscr2
                          st         lastscr
 
                          not.b      bigSmall
                          beq.s      .dosmall
 
                          ; ToDo: Support for screen size
                          bra        .notswapscr2
 
.dosmall:
                          ; ToDo: Support for screen size
                          bra        .notswapscr2
 
.notswapscr:
                          clr.b      lastscr

.notswapscr2:
                          rts

*********************************************************************************************

PLR2_mousekbd_control:
                
                          include    "Plr2WasdControl.s"

                          bsr        Plr2Fall
                          rts

*********************************************************************************************

PLR2_keyboard_control:

                          move.l     #SineTable,a0
 
                          jsr        PLR2_alwayskeys
                          move.l     #KeyMap,a5

                          move.w     PLR2s_angpos,d0
                          move.w     PLR2s_angspd,d3
                          move.w     #35,d1
                          move.w     #2,d2
                          moveq      #0,d7
                          move.b     run_key,d7
                          tst.b      (a5,d7.w)
                          beq.s      .nofaster
                          move.w     #60,d1
                          move.w     #3,d2
.nofaster:
                          tst.b      PLR2_Ducked
                          beq.s      .nohalve
                          asr.w      #1,d2
.nohalve

                          moveq      #0,d4 
 
                          move.w     d3,d5
                          add.w      d5,d5
                          add.w      d5,d3
                          asr.w      #2,d3
                          bge.s      .nneg
                          addq       #1,d3
.nneg:
 
                          move.b     turn_left_key,templeftkey
                          move.b     turn_right_key,temprightkey
                          move.b     sidestep_left_key,tempslkey
                          move.b     sidestep_right_key,tempsrkey
 
                          move.b     force_sidestep_key,d7
                          tst.b      (a5,d7.w)
                          beq        .noalwayssidestep
 
                          move.b     templeftkey,tempslkey
                          move.b     temprightkey,tempsrkey
                          move.b     #255,templeftkey
                          move.b     #255,temprightkey
 
.noalwayssidestep:
 
 
                          move.b     templeftkey,d7
                          tst.b      (a5,d7.w)
                          beq.s      .noleftturn
                          sub.w      #10,d3
.noleftturn
                          move.l     #KeyMap,a5
                          move.b     temprightkey,d7
                          tst.b      (a5,d7.w)
                          beq.s      .norightturn
                          add.w      #10,d3
.norightturn
 
                          cmp.w      d1,d3
                          ble.s      .okrspd
                          move.w     d1,d3
.okrspd:
                          neg.w      d1
                          cmp.w      d1,d3
                          bge.s      .oklspd
                          move.w     d1,d3
.oklspd:
 
                          add.w      d3,d0
                          add.w      d3,d0
                          move.w     d3,PLR2s_angspd
 
                          move.b     tempslkey,d7
                          tst.b      (a5,d7.w)
                          beq.s      .noleftslide
                          add.w      d2,d4
                          add.w      d2,d4
                          asr.w      #1,d4
.noleftslide
                          move.l     #KeyMap,a5
                          move.b     tempsrkey,d7
                          tst.b      (a5,d7.w)
                          beq.s      .norightslide
                          add.w      d2,d4
                          add.w      d2,d4
                          asr.w      #1,d4
                          neg.w      d4
.norightslide
  
noslide2:
  
                          and.w      #8191,d0
                          move.w     d0,PLR2s_angpos
 
                          move.w     (a0,d0.w),PLR2s_sinval
                          adda.w     #2048,a0
                          move.w     (a0,d0.w),PLR2s_cosval

                          move.l     PLR2s_xspdval,d6
                          move.l     PLR2s_zspdval,d7

                          neg.l      d6
                          ble.s      .nobug1
                          asr.l      #3,d6
                          add.l      #1,d6
                          bra.s      .bug1
.nobug1
                          asr.l      #3,d6
.bug1:

                          neg.l      d7
                          ble.s      .nobug2
                          asr.l      #3,d7
                          add.l      #1,d7
                          bra.s      .bug2
.nobug2
                          asr.l      #3,d7
.bug2: 

                          moveq      #0,d3
 
                          moveq      #0,d5
                          move.b     forward_key,d5
                          tst.b      (a5,d5.w)
                          beq.s      .noforward
                          neg.w      d2
                          move.w     d2,d3
 
.noforward:
                          move.b     backward_key,d5
                          tst.b      (a5,d5.w)
                          beq.s      .nobackward
                          move.w     d2,d3
.nobackward:
 
                          move.w     d3,d2
                          asl.w      #6,d2
                          move.w     d2,d1
; add.w d2,d1
; add.w d2,d1
                          move.w     d1,d2
                          add.w      PLR2_bobble,d1
                          and.w      #8190,d1
                          move.w     d1,PLR2_bobble
                          add.w      PLR2_clumptime,d2
                          move.w     d2,d1
                          and.w      #4095,d2
                          move.w     d2,PLR2_clumptime
                          and.w      #-4096,d1
                          beq.s      .noclump

                          bsr        PLR2clump
 
.noclump

 
                          move.w     PLR2s_sinval,d1
                          muls       d3,d1
                          move.w     PLR2s_cosval,d2
                          muls       d3,d2

                          sub.l      d1,d6
                          sub.l      d2,d7
                          move.w     PLR2s_sinval,d1
                          muls       d4,d1
                          move.w     PLR2s_cosval,d2
                          muls       d4,d2
                          sub.l      d2,d6
                          add.l      d1,d7
 
                          add.l      d6,PLR2s_xspdval
                          add.l      d7,PLR2s_zspdval
                          move.l     PLR2s_xspdval,d6
                          move.l     PLR2s_zspdval,d7
                          add.l      d6,PLR2s_xoff
                          add.l      d7,PLR2s_zoff
 
                          move.b     fire_key,d5
                          tst.b      PLR2_fire
                          beq.s      .firenotpressed
; fire was pressed last time.
                          tst.b      (a5,d5.w)
                          beq.s      .firenownotpressed
; fire is still pressed this time.
                          st         PLR2_fire
                          bra        .doneplr2
 
.firenownotpressed:
; fire has been released.
                          clr.b      PLR2_fire
                          bra        .doneplr2
 
.firenotpressed

; fire was not pressed last frame...

                          tst.b      (a5,d5.w)
; if it has still not been pressed, go back above
                          beq.s      .firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
                          st         PLR2_clicked
                          st         PLR2_fire

.doneplr2:

                          bsr        Plr2Fall


                          rts

*********************************************************************************************

PLR2_JoyStick_control:

                          jsr        _ReadJoy2
                          bra        PLR2_keyboard_control

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
                          ;btst       #7,$bfe001                          ; LMB port 2
                          btst       #3,Buttons 
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


                          bra        PLR2_keyboard_control
 

                          jsr        PLR2_alwayskeys

                          move.w     PLR2s_angpos,d0
                          move.w     #70,d1
                          move.w     #7,d2
                          tst.b      $61(a5)
                          beq.s      .nofaster
                          move.w     #120,d1
                          move.w     #10,d2
.nofaster:

                          tst.b      PLR2_Ducked
                          beq.s      .nohalve
                          asr.w      #1,d2
.nohalve:

                          moveq      #0,d4 
; tst.b $67(a5)
; bne.s slidelr
 
                          tst.b      $4f(a5)
                          beq.s      .noleftturn
                          sub.w      d1,d0
.noleftturn
                          move.l     #KeyMap,a5
                          tst.b      $4e(a5)
                          beq.s      .norightturn
                          add.w      d1,d0
.norightturn
; bra.s noslide

.slidelr:
                          tst.b      $39(a5)
                          beq.s      .noleftslide
                          move.w     d2,d4
                          asr.w      #1,d4
.noleftslide
                          move.l     #KeyMap,a5
                          tst.b      $3a(a5)
                          beq.s      .norightslide
                          sub.w      d2,d4
                          asr.w      #1,d4
.norightslide
  
.noslide:
  
                          and.w      #8191,d0
                          move.w     d0,PLR2s_angpos
 
                          move.w     (a0,d0.w),PLR2s_sinval
                          adda.w     #2048,a0
                          move.w     (a0,d0.w),PLR2s_cosval

                          move.l     PLR2s_xspdval,d6
                          move.l     PLR2s_zspdval,d7

                          neg.l      d6
                          ble.s      .nobug1
                          asr.l      #1,d6
                          add.l      #1,d6
                          bra.s      .bug1
.nobug1
                          asr.l      #1,d6
.bug1:

                          neg.l      d7
                          ble.s      .nobug2
                          asr.l      #1,d7
                          add.l      #1,d7
                          bra.s      .bug2
.nobug2
                          asr.l      #1,d7
.bug2: 

                          moveq      #0,d3
 
                          tst.b      $4c(a5)
                          beq.s      .noforward
                          neg.w      d2
                          move.w     d2,d3
.noforward:
                          tst.b      $4d(a5)
                          beq.s      .nobackward
                          move.w     d2,d3
.nobackward:
 
                          move.w     d3,d2
                          asl.w      #4,d2
                          move.w     d2,d1
                          add.w      d2,d1
                          add.w      d2,d1
                          add.w      PLR2_bobble,d1
                          and.w      #8190,d1
                          move.w     d1,PLR2_bobble
 
                          move.w     PLR2s_sinval,d1
                          muls       d3,d1
                          move.w     PLR2s_cosval,d2
                          muls       d3,d2

                          sub.l      d1,d6
                          sub.l      d2,d7
                          move.w     PLR2s_sinval,d1
                          muls       d4,d1
                          move.w     PLR2s_cosval,d2
                          muls       d4,d2
                          sub.l      d2,d6
                          add.l      d1,d7
 
                          add.l      d6,PLR2s_xspdval
                          add.l      d7,PLR2s_zspdval
                          move.l     PLR2s_xspdval,d6
                          move.l     PLR2s_zspdval,d7
                          add.l      d6,PLR2s_xoff
                          add.l      d7,PLR2s_zoff
 
                          tst.b      PLR2_fire
                          beq.s      .firenotpressed
; fire was pressed last time.
                          tst.b      $65(a5)
                          beq.s      .firenownotpressed
; fire is still pressed this time.
                          st         PLR2_fire
                          bra        .donePLR2
 
.firenownotpressed:
; fire has been released.
                          clr.b      PLR2_fire
                          bra        .donePLR2
 
.firenotpressed

; fire was not pressed last frame...

                          tst.b      $65(a5)
; if it has still not been pressed, go back above
                          beq.s      .firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
                          st         PLR2_clicked
                          st         PLR2_fire

.donePLR2:

                          bsr        Plr2Fall

                          rts

*********************************************************************************************

PLR2_clumptime:           dc.w       0
PLR2_msbActinDelay:       dc.w       0

*********************************************************************************************

PLR2clump:

                          movem.l    d0-d7/a0-a6,-(a7)
                          move.l     PLR2_Roompt,a0
                          move.w     ToFloorNoise(a0),d0

                          move.l     ToZoneWater(a0),d1
                          cmp.l      ToZoneFloor(a0),d1
                          bge.s      THERESNOWATER2
 
                          cmp.l      PLR2_yoff,d1
                          blt.s      THERESNOWATER2
 
                          move.w     #6-23,d0

THERESNOWATER2:


                          tst.b      PLR2_StoodInTop
                          beq.s      .okinbot
                          move.w     ToUpperFloorNoise(a0),d0
.okinbot:

                          add.w      #23,d0
                          move.w     d0,Samplenum
                          move.w     #0,Noisex
                          move.w     #100,Noisez
                          move.w     #80,Noisevol
                          move.b     #$f9,IDNUM
                          clr.b      notifplaying
                          jsr        MakeSomeNoise
 
                          movem.l    (a7)+,d0-d7/a0-a6

                          rts
