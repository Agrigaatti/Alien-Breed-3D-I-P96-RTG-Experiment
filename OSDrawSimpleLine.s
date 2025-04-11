*********************************************************************************************

                          opt           P=68020

*********************************************************************************************

                          incdir        "includes"
                          include       "macros.i"
                          include       "AB3DI.i"
                          include       "AB3DIRTG.i"
                          
*********************************************************************************************

SimpleFloorLine:
; Right then, time for the floor routine...
; For test purposes, give it
; a6 = chunky
; a3 = point to screen (fromPt - ptr to first col register)
; d0 = z distance away
; and sinval+cosval must be set up.
; See LineRoutineToUse
                        
                          SUPERVISOR    SetInstCacheOff

                          move.l        #doAcrossLine,a1                                                     
                          clr.l         d1
                          clr.l         d3

                          move.w        leftedge(pc),d1     
                          move.w        rightedge(pc),d3
                          sub.w         d1,d3

                          lea           (a1,d1.w*4),a1                          ; Start "move.w d0,n(a1)" = $3740,n           

                          move.w        (a1,d3.w*4),d4                          ; Backup
                          move.w        #$4e75,(a1,d3.w*4)                      ; End "rts" = $4e75

                          tst.b         useBlackFloor
                          beq           .notBlackFloor

                          moveq         #0,d0
                          bra           .doBlack

***********************************************************

.notBlackFloor:
                          move.l        #PlainScale,a2
 
                          move.w        d0,d2
                          move.w        lighttype,d1
                          asr.w         #8,d2                                   ; / 256
                          addq.w        #5,d1
                          add.w         d2,d1
                          bge.s         .fixedbright

                          moveq         #0,d1

.fixedbright:
                          cmp.w         #28,d1
                          ble.s         .smallbright

                          move.w        #28,d1

.smallbright:
                          lea           (a2,d1.w*2),a2
                          move.w        whichtile,d0
                          move.w        d0,d1
                          and.w         #$3,d1
                          and.w         #$300,d0
                          lsl.b         #6,d1                                   ; * 64
                          move.b        d1,d0
                          move.w        d0,tstwhich
                          move.w        (a2,d0.w),d0
 
 ***********************************************************

.doBlack:
                          jsr           (a1)
                          
                          move.w        d4,(a1,d3.w*4)                          ; Restore

                          SUPERVISOR    SetInstCacheOn
                          rts

*********************************************************************************************
; $00180, $0000, $00182, $0000..,bplcon3.w, value.w, $00180, $0000, 
; => line: 32*4 + 4 + 32*4 + 4 + 32*4
; Note: Caller modifies this code! 
; Originally "move.w d0,val(a3)" ($3740,val) but build change it to one word command.

doAcrossLine:

val                       SET           0
                          REPT          (RTGScrWidth*RTGScrHeight)    ; 256
                          dc.w          $3740,val
val                       SET           val+2
                          ENDR

                          rts

*********************************************************************************************

tstwhich:                 dc.w          0                                       ; .w
whichtile:                dc.w          0                                       ; .w

*********************************************************************************************

leftedge:                 dc.w          0                                       ; .w
rightedge:                dc.w          0                                       ; .w

*********************************************************************************************

                          cnop          0,32
PlainScale:               include       "data/rtg/math/plainscale.s"
                          cnop          0,32

*********************************************************************************************