*********************************************************************************************

                          opt                P=68020

*********************************************************************************************

                          incdir             "includes"
                          include            "macros.i"
                          include            "AB3DI.i"
                          include            "AB3DIRTG.i"

*********************************************************************************************

RTGScrWidthPAUSE            EQU RTGScrWidth
RTGScrWidthByteOffsetPAUSE  EQU RTGScrWidthByteOffset
AB3dChunkyBufferPAUSE       EQU AB3dChunkyBuffer

*********************************************************************************************
                          IFNE               USE1X1
RTGTextByteoffsetPAUSE      EQU (RTGScrWidthByteOffsetPAUSE/4)                          
                          ENDC  

                          IFEQ               USE1X1
RTGTextByteoffsetPAUSE      EQU 0
                          ENDC  

                          IFEQ               USE1X1
                          IFNE               USE2X2SCALED
AB3dDrawChunkyFunctionPAUSE EQU DrawScaledAB3dChunkyBuffer
                          ENDC
                          ENDC
                          IFEQ               USE2X2SCALED
AB3dDrawChunkyFunctionPAUSE EQU DrawAB3dChunkyBuffer
                          ENDC

*********************************************************************************************
; Options:
; FAST buffer on/off
; Floors Gouraud/Textured/Plain
;
; FIRST HALVE SCREEN BRIGHTNESS
;
; 8 pixels per char
; 12 chars per line


PauseOpts: 
                          lea                AB3dChunkyBufferPAUSE,a3
                          add.l              #RTGTextByteoffsetPAUSE,a3

                          bsr                DrawPauseScrn

                          WAITFORVERTBREQ                                            

.waitpress:
                          jsr                HandleP96RTGWindowInputs
                          bsr                ChangeOpts

                          tst.b              $19(a5)                                 ; 'p' Pause key
                          bne.s              .unp

                          btst               #3,Buttons 
                          bne.s              .waitpress

.unp:
.wr2:
                          tst.b              $19(a5)                                 ; 'p' Pause key
                          bne.s              .wr2

                          btst               #3,Buttons 
                          beq.s              .wr2

                          rts

*********************************************************************************************

CheckUpDown:
                          btst               #1,$dff00c
                          sne                d0
                          btst               #1,$dff00d
                          sne                d1
                          btst               #0,$dff00c
                          sne                d2
                          btst               #0,$dff00d
                          sne                d3
                          eor.b              d0,d2
                          eor.b              d1,d3
 
                          moveq              #0,d6
                          move.l             #KeyMap,a5
                          move.b             forward_key,d6
                          tst.b              (a5,d6.w)
                          sne                d0
                          or.b               d0,d2
                          move.b             backward_key,d6
                          tst.b              (a5,d6.w)
                          sne                d1
                          or.b               d1,d3
                          rts

*********************************************************************************************

ChangeOpts:
                          lea                AB3dChunkyBufferPAUSE,a3  
                          add.l              #RTGTextByteoffsetPAUSE,a3

***************************************************************

                          bsr                CheckUpDown
                          tst.b              d2                                      ; forward_key
                          beq.s              notopchange

***************************************************************

                          move.w             #1,d0

***************************************************************

                          muls               #12,d0
                          add.l              #FBUFFOPTS,d0                           ; OFF / ON
                          move.l             d0,a0
                          move.l             #FBUFFOPTLINE,a1
                          bsr                PUTINPLINE
 
                          bsr                DrawPauseScrn
 
 ***************************************************************

.WWWWWWWW:
                          bsr                CheckUpDown
                          tst.b              d2
                          bne.s              .WWWWWWWW

***************************************************************

notopchange:
                          tst.b              d3                                      ; backward_key
                          beq.s              nobotchange

***************************************************************

                          move.w             BOTPOPT,d0
                          addq               #1,d0
                          and.w              #3,d0
                          move.w             d0,BOTPOPT

***************************************************************

                          clr.b              anyFloor
                          clr.b              selectGouraud
                          st                 useBlackFloor
                          move.l             #SimpleFloorLine,TheFloorLineRoutine    ; AB3DI

***************************************************************

                          cmp.w              #2,d0
                          bgt.s              .nofloor
                          beq.s              .plainfloor
               
                          tst.w              d0
                          bgt.s              .textureonly

                          st                 selectGouraud

.textureonly:
                          move.l             #FloorLine,TheFloorLineRoutine          ; AB3DI

.plainfloor:
                          st                 anyFloor
                          clr.b              useBlackFloor                              ; AB3DI

.nofloor:

***************************************************************

                          muls               #12,d0
                          add.l              #FLOOROPTS,d0
                          move.l             d0,a0
                          move.l             #FLOOROPTLINE,a1
                          bsr                PUTINPLINE
 
                          bsr                DrawPauseScrn

***************************************************************

billythe:
                          bsr                CheckUpDown
                          tst.b              d3
                          bne.s              billythe

***************************************************************

nobotchange:
                          rts

*********************************************************************************************

TheFloorLineRoutine:      dc.l               FloorLine

BOTPOPT:                  dc.w               0
anyFloor:                 dc.w               0

*********************************************************************************************

PUTINPLINE:
                          moveq              #11,d7

.pppp:
                          move.b             (a0)+,(a1)+
                          dbra               d7,.pppp
                          rts

*********************************************************************************************

pBuffPt:                  dc.l               0
pausePt:                  dc.l               0

*********************************************************************************************

DrawPauseScrn:

                          move.l             #pauseFont,a0
                          move.l             #PauseTxt,a1
                          move.l             a3,a2
                          bsr                DrawPauseBlock
                          bsr                DrawPauseBlock
                          bsr                DrawPauseBlock

                          jsr                AB3dDrawChunkyFunctionPAUSE
                          rts

*********************************************************************************************

DrawPauseBlock:
                          move.w             #3,d0

.across:
                          moveq              #0,d1
                          moveq              #0,d2
                          moveq              #9,d3
                          moveq              #0,d5

.down:
                          moveq              #0,d4
                          move.b             (a1,d2.w),d4
                          add.w              #12,d2
                          sub.b              #'A',d4
                          bge                .itsalet

                          moveq              #7,d6

.dospc:
                          move.w             (a3,d5.l),d1
                          and.w              #$7bde,d1                               ; $eee -> %0111101111011110 -> $7bde
                          lsr.w              #1,d1
                          move.w             d1,(a2,d5.l)

                          move.w             2(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1
                          move.w             d1,2(a2,d5.l)

                          move.w             4(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1
                          move.w             d1,4(a2,d5.l)

                          move.w             6(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1
                          move.w             d1,6(a2,d5.l)

                          move.w             8(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1
                          move.w             d1,8(a2,d5.l)

                          move.w             10(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1
                          move.w             d1,10(a2,d5.l)

                          move.w             12(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1
                          move.w             d1,12(a2,d5.l)

                          move.w             14(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1
                          move.w             d1,14(a2,d5.l)

                          add.l              #RTGScrWidthByteOffsetPAUSE,d5  

                          dbra               d6,.dospc
                          bra                .nolet

.itsalet:
                          asl.w              #7,d4
                          lea                (a0,d4.w),a5
                          moveq              #7,d6

.dolet: 
                          move.w             (a5)+,d1
                          bne.s              .okpix1
                          move.w             (a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1

.okpix1:
                          move.w             d1,(a2,d5.l)

                          move.w             (a5)+,d1
                          bne.s              .okpix2
                          move.w             2(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1

.okpix2:
                          move.w             d1,2(a2,d5.l)

                          move.w             (a5)+,d1
                          bne.s              .okpix3
                          move.w             4(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1

.okpix3:
                          move.w             d1,4(a2,d5.l)

                          move.w             (a5)+,d1
                          bne.s              .okpix4
                          move.w             6(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1

.okpix4:
                          move.w             d1,6(a2,d5.l)

                          move.w             (a5)+,d1
                          bne.s              .okpix5
                          move.w             8(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1

.okpix5:
                          move.w             d1,8(a2,d5.l)

                          move.w             (a5)+,d1
                          bne.s              .okpix6
                          move.w             10(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1

.okpix6:
                          move.w             d1,10(a2,d5.l)

                          move.w             (a5)+,d1
                          bne.s              .okpix7
                          move.w             12(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1

.okpix7:
                          move.w             d1,12(a2,d5.l)

                          move.w             (a5)+,d1
                          bne.s              .okpix8
                          move.w             14(a3,d5.l),d1
                          and.w              #$7bde,d1
                          lsr.w              #1,d1

.okpix8:
                          move.w             d1,14(a2,d5.l)

                          add.l              #RTGScrWidthByteOffsetPAUSE,d5  

                          dbra               d6,.dolet

.nolet:
                          dbra               d3,.down

                          add.w              #2*8,a3
                          add.w              #2*8,a2
                          
                          addq               #1,a1
                          dbra               d0,.across 

                          rts

*********************************************************************************************

PauseTxt:
;                                             012345678901
                          dc.b               '            '                          ; 0
                          dc.b               '            '                          ; 1
                          dc.b               'FAST  BUFFER'                          ; 2
FBUFFOPTLINE:
                          dc.b               '    ON      '                          ; 3
                          dc.b               '            '                          ; 4
                          dc.b               'FLOOR DETAIL'                          ; 5
FLOOROPTLINE:
                          dc.b               '  GOURAUD   '                          ; 6
                          dc.b               '            '                          ; 7
                          dc.b               '            '                          ; 8
                          dc.b               '            '                          ; 9

FBUFFOPTS:
                          dc.b               '    OFF     '
                          dc.b               '    ON      '
 
FLOOROPTS:
                          dc.b               '  GOURAUD   '
                          dc.b               '  TEXTURED  '
                          dc.b               'PLAIN SHADED'
                          dc.b               '    NONE    '

*********************************************************************************************

pauseFont:                incbin             "data/rtg/fonts/pause_font.raw"

*********************************************************************************************