*********************************************************************************************

                          opt              P=68020

*********************************************************************************************

                          incdir           "includes"
                          include          "macros.i"
                          include          "AB3DI.i"
                          include          "AB3DIRTG.i"

*********************************************************************************************

RTGScrWidthFLOOR           EQU RTGScrWidth
RTGScrWidthByteOffsetFLOOR EQU RTGScrWidthByteOffset
RTGScrHeightFLOOR          EQU RTGScrHeight

AB3dChunkyBufferFLOOR      EQU AB3dChunkyBuffer

*********************************************************************************************

FloorTileSizeMultiplier    EQU RTGMult*64                                                                 ; Sets the zoom of floor texture tile

*********************************************************************************************
; Floor polygon

numsidestd:               dc.w             0
bottomline:               dc.w             0

*********************************************************************************************

NewCornerBuff:            ds.l             RTGMult*100                                                    ; 100

*********************************************************************************************

itsafloordraw:
; a0 = ThisRoomToDraw+n
; If D0=1 then its a floor otherwise (=2) it's a roof.

                          move.w           #0,above

                          move.w           (a0)+,d6                                                       ; ypos of poly
                          move.w           d6,d7                                    
                          ext.l            d7
                          asl.l            #6,d7                                                          ; * 64
                          cmp.l            TOPOFROOM,d7
                          blt              checkForWater

                          cmp.l            BOTOFROOM,d7
                          bgt.s            dontDrawReturn
 
 ****************************************************************

                          move.w           leftclip(pc),d7
                          cmp.w            rightclip(pc),d7
                          bge.s            dontDrawReturn
 
 ****************************************************************

                          move.w           botclip,d7
                          sub.w            #(RTGScrHeightFLOOR/2),d7                                      ; 40
                          ble.s            dontDrawReturn

****************************************************************
; Floor / Roof

                          sub.w            flooryoff,d6                                                   ; ypos of poly
                          bgt              below                                                          ; Debug: below
                          blt.s            aboveplayer                                                    ; Debug: aboveplayer

****************************************************************
; Inside water?

                          tst.b            useWater
                          beq.s            .notwater
 
                          move.l           Roompt,a1
                          move.w           (a1),d7
                          cmp.w            currzone,d7
                          bne.s            .notwater

                          st               fillScrnWater

.notwater:

****************************************************************
; Exit

dontDrawReturn:
                          move.w           (a0)+,d6                                                       ; sides-1
                          add.w            d6,d6
                          add.w            d6,a0
                          lea              4+6(a0),a0
                          rts

****************************************************************
; Water
; a0=?

checkForWater:
                          tst.b            useWater
                          beq.s            .notwater
 
                          move.l           Roompt,a1
                          move.w           (a1),d7
                          cmp.w            currzone,d7
                          bne.s            .notwater
 
                          move.b           #$f,fillScrnWater

.notwater:
                          move.w           (a0)+,d6                                                       ; sides-1
                          add.w            d6,d6
                          add.w            d6,a0
                          lea              4+6(a0),a0

                          rts

****************************************************************
; Roof

aboveplayer:

****************************************************************
; Water?

                          tst.b            useWater
                          beq.s            .notwater
 
                          move.l           Roompt,a1
                          move.w           (a1),d7
                          cmp.w            currzone,d7
                          bne.s            .notwater
 
                          move.b           #$f,fillScrnWater

.notwater:

****************************************************************
; Roof?

                          btst             #1,d0
                          beq.s            dontDrawReturn

****************************************************************

                          move.w           #(RTGScrHeightFLOOR/2),d7
                          sub.w            topclip,d7 
                          ble.s            dontDrawReturn

****************************************************************

                          move.w           #1,d0
                          move.w           d0,above

                          neg.w            d6                                                             ; flooryoff

****************************************************************
; Floor

below:
                          btst             #0,d0
                          beq.s            dontDrawReturn

****************************************************************

                          move.w           d6,distaddr

                          muls             #64,d6                                                         ; ? 
                          move.l           d6,ypos

                          divs             d7,d6                                                          ; zpos of bottom visible line
                          move.w           d6,minz

                          move.w           d7,bottomline

****************************************************************
; Go round each point finding out if it should be visible or not.

                          move.l           a0,-(a7)

                          move.w           (a0)+,d7                                                       ; number of sides

                          move.l           #Rotated,a1
                          move.l           #OnScreen,a2
                          move.l           #NewCornerBuff,a3
                          moveq            #0,d4
                          moveq            #0,d5
                          moveq            #0,d6
                          clr.b            anyclipping
 
cornerProcessLoop:
                          move.w           (a0)+,d0                                                       ; point

****************************************************************

                          move.w           6(a1,d0.w*8),d1                                                ; a1=Rotated
                          ble.b            .canttell
 
 ****************************************************************
 
                          move.w           (a2,d0.w*2),d3                                                 ; a2=OnScreen

                          cmp.w            leftclip,d3
                          bgt.s            .nol

                          st               d4
                          st               anyclipping

                          bra.s            .nos

****************************************************************

.nol:
                          cmp.w            rightclip,d3
                          blt.s            .nor

                          st               d6
                          st               anyclipping

                          bra.s            .nos

****************************************************************

.nor:
                          st               d5

.nos:
                          bra.b            .cantell

****************************************************************

.canttell:
                          st               d5
                          st               anyclipping

****************************************************************

.cantell:
                          dbra             d7,cornerProcessLoop
 
                          move.l           (a7)+,a0

****************************************************************

                          tst.b            d5
                          bne.s            someFloorToDraw

                          eor.b            d4,d6
                          bne              dontDrawReturn

****************************************************************

someFloorToDraw:
                          tst.b            useGouraud
                          bne              GouraudSides

*********************************************************************************************
*********************************************************************************************
; Plain sides

                          move.w           #RTGScrHeightFLOOR,top
                          move.w           #-1,bottom
                          move.w           #0,drawit
                          move.l           #Rotated,a1
                          move.l           #OnScreen,a2

****************************************************************

                          move.w           (a0)+,d7                                                       ; no of sides (a0 = ThisRoomToDraw+n)

sideLoop:
                          move.w           minz,d6

                          move.w           (a0)+,d1
                          move.w           (a0),d3
                          move.w           6(a1,d1*8),d4                                                  ;first z (a1=Rotated)
                          cmp.w            d6,d4
                          bgt.b            firstinfront

                          move.w           6(a1,d3*8),d5                                                  ; sec z (a1=Rotated)
                          cmp.w            d6,d5
                          ble              bothbehind

****************************************************************
; line must be on left and partially behind.

                          sub.w            d5,d4
                          move.l           (a1,d1*8),d0                                                   ; (a1=Rotated)
                          sub.l            (a1,d3*8),d0                                                   ; (a1=Rotated)

                          asr.l            #7,d0                                                          ; / 128
                          sub.w            d5,d6
                          muls             d6,d0                                                          ; new x coord
                          divs             d4,d0
                          ext.l            d0
                          asl.l            #7,d0                                                          ; * 128

                          add.l            (a1,d3*8),d0                                                   ; (a1=Rotated)

                          move.w           minz,d4
                          move.w           (a2,d3*2),d2                                                   ; (a2=OnScreen)
                          divs             d4,d0
                          add.w            #(RTGScrWidthFLOOR/2)-1,d0

                          move.l           ypos,d3
                          divs             d5,d3
                          move.w           bottomline,d1

                          bra.b            lineclipped

****************************************************************

firstinfront:
                          move.w           6(a1,d3*8),d5                                                  ; sec z
                          cmp.w            d6,d5
                          bgt.b            bothinfront

****************************************************************
; line must be on right and partially behind.

                          sub.w            d4,d5                                                          ; dz
                          move.l           (a1,d3*8),d2
                          
                          sub.l            (a1,d1*8),d2                                                   ; dx
                          sub.w            d4,d6

                          asr.l            #7,d2                                                          ; / 128
                          muls             d6,d2                                                          ; new x coord
                          divs             d5,d2
                          ext.l            d2
                          asl.l            #7,d2                                                          ; * 128

                          add.l            (a1,d1*8),d2

                          move.w           minz,d5
                          move.w           (a2,d1*2),d0
                          divs             d5,d2
                          add.w            #(RTGScrWidthFLOOR/2)-1,d2

                          move.l           ypos,d1
                          divs             d4,d1
                          move.w           bottomline,d3

                          bra.b            lineclipped

****************************************************************

bothinfront:
; Also, usefully enough, both are on-screen so no bottom clipping is needed.

                          move.w           (a2,d1*2),d0                                                   ; first x
                          move.w           (a2,d3*2),d2                                                   ; second x
                          move.l           ypos,d1
                          move.l           d1,d3
                          divs             d4,d1                                                          ; first y
                          divs             d5,d3                                                          ; second y

****************************************************************

lineclipped:
                          move.l           #rightSideTab,a3

                          cmp.w            d1,d3
                          beq              lineflat

                          st               drawit
                          bgt              lineonright

****************************************************************

                          move.l           #leftSideTab,a3
                          exg              d1,d3
                          exg              d0,d2
 
                          lea              (a3,d1*2),a3                                                   ; a3=leftSideTab
 
****************************************************************
; Top
                          cmp.w            top(pc),d1
                          bge.s            .nonewtop

                          move.w           d1,top

.nonewtop:

****************************************************************
; Bottom

                          cmp.w            bottom(pc),d3
                          ble.s            .nonewbot

                          move.w           d3,bottom

.nonewbot:

****************************************************************

                          sub.w            d1,d3                                                          ; dy
                          sub.w            d0,d2                                                          ; dx
                          blt.b            .linegoingleft

****************************************************************

                          subq.w           #1,d0

                          ext.l            d2
                          divs             d3,d2
                          move.w           d2,d6
                          swap             d2

                          move.w           d3,d4
                          move.w           d3,d5
                          subq             #1,d5
                          move.w           d6,d1
                          addq             #1,d1

****************************************************************

.pixlopright:
                          move.w           d0,(a3)+                                                       ; a3=leftSideTab
                          sub.w            d2,d4
                          bge.s            .nobigstep

                          add.w            d1,d0
                          add.w            d3,d4

                          dbra             d5,.pixlopright

                          bra              lineflat

.nobigstep:
                          add.w            d6,d0
                          dbra             d5,.pixlopright

                          bra              lineflat

****************************************************************

.linegoingleft:
                          subq.w           #1,d0
 
                          neg.w            d2

                          ext.l            d2
                          divs             d3,d2
                          move.w           d2,d6
                          swap             d2

                          move.w           d3,d4
                          move.w           d3,d5
                          subq             #1,d5

                          move.w           d6,d1
                          addq             #1,d1

****************************************************************

.pixlopleft:
                          sub.w            d2,d4
                          bge.s            .nobigstepl

                          sub.w            d1,d0
                          add.w            d3,d4
                          move.w           d0,(a3)+                                                       ; a3=leftSideTab

                          dbra             d5,.pixlopleft

                          bra              lineflat
  
.nobigstepl:
                          sub.w            d6,d0
                          move.w           d0,(a3)+                                                       ; a3=leftSideTab
                          dbra             d5,.pixlopleft
 
                          bra.b            lineflat
 
****************************************************************
****************************************************************

lineonright:
                          lea              (a3,d1*2),a3                                                   ; a3=rightSideTab
 
 ****************************************************************

                          cmp.w            top(pc),d1
                          bge.s            .nonewtop
                          move.w           d1,top

.nonewtop:
 
 ****************************************************************

                          cmp.w            bottom(pc),d3
                          ble.s            .nonewbot
                          move.w           d3,bottom

.nonewbot:
 
 ****************************************************************

                          sub.w            d1,d3                                                          ; dy
                          sub.w            d0,d2                                                          ; dx
                          blt.b            .linegoingleft

                          ext.l            d2
                          divs             d3,d2
                          move.w           d2,d6
                          swap             d2

                          move.w           d3,d4
                          move.w           d3,d5
                          subq             #1,d5
                          move.w           d6,d1
                          addq             #1,d1

.pixlopright:
                          sub.w            d2,d4
                          bge.s            .nobigstep

                          add.w            d1,d0
                          add.w            d3,d4
                          move.w           d0,(a3)+                                                       ; a3=rightSideTab
                          dbra             d5,.pixlopright

                          bra.b            lineflat
  
.nobigstep:
                          add.w            d6,d0
                          move.w           d0,(a3)+
                          dbra             d5,.pixlopright

                          bra.b            lineflat

****************************************************************

.linegoingleft:
                          neg.w            d2

                          ext.l            d2
                          divs             d3,d2
                          move.w           d2,d6
                          swap             d2

                          move.w           d3,d4
                          move.w           d3,d5
                          subq             #1,d5
                          move.w           d6,d1
                          addq             #1,d1

.pixlopleft:
                          move.w           d0,(a3)+                                                       ; a3=rightSideTab
                          sub.w            d2,d4
                          bge.s            .nobigstepl

                          sub.w            d1,d0
                          add.w            d3,d4

                          dbra             d5,.pixlopleft

                          bra.b            lineflat
  
.nobigstepl:
                          sub.w            d6,d0
                          dbra             d5,.pixlopleft

****************************************************************
****************************************************************

lineflat:
bothbehind:
                          dbra             d7,sideLoop

****************************************************************

                          bra              pastSides

*********************************************************************************************
*********************************************************************************************
; Gouraud sides

fbr:                      dc.w             0
sbr:                      dc.w             0

*********************************************************************************************

GouraudSides:

                          move.w           #RTGScrHeightFLOOR,top
                          move.w           #-1,bottom
                          move.w           #0,drawit
                          move.l           #Rotated,a1
                          move.l           #OnScreen,a2

                          move.w           (a0)+,d7                                                       ; no of sides

sideLoopGOUR:
                          move.w           minz,d6

                          move.w           (a0)+,d1
                          move.w           (a0),d3

                          move.l           pointBrightsPtr,a4
                          move.w           (a4,d1.w*4),fbr
                          move.w           (a4,d3.w*4),sbr
 
                          move.w           6(a1,d1*8),d4                                                  ;first z
                          cmp.w            d6,d4
                          bgt.b            firstinfrontGOUR
                          
                          move.w           6(a1,d3*8),d5                                                  ; sec z
                          cmp.w            d6,d5
                          ble              bothbehindGOUR

; line must be on left and partially behind.
                          sub.w            d5,d4
 
                          move.w           fbr,d0
                          sub.w            sbr,d0
                          sub.w            d5,d6
                          muls             d6,d0
                          divs             d4,d0
                          add.w            sbr,d0
                          move.w           d0,fbr
 
                          move.l           (a1,d1*8),d0
                          sub.l            (a1,d3*8),d0

                          asr.l            #7,d0                                                          ; / 128
                          muls             d6,d0                                                          ; new x coord
                          divs             d4,d0
                          ext.l            d0
                          asl.l            #7,d0                                                          ; * 128

                          add.l            (a1,d3*8),d0

                          move.w           minz,d4
                          move.w           (a2,d3*2),d2
                          divs             d4,d0
                          add.w            #(RTGScrWidthFLOOR/2)-1,d0

                          move.l           ypos,d3
                          divs             d5,d3
 
                          move.w           bottomline,d1 

                          bra.b            lineclippedGOUR

****************************************************************

firstinfrontGOUR:
                          move.w           6(a1,d3*8),d5                                                  ; sec z
                          cmp.w            d6,d5
                          bgt.b            bothinfrontGOUR

; line must be on right and partially behind.
                          sub.w            d4,d5                                                          ; dz

                          move.w           sbr,d2
                          sub.w            fbr,d2
                          sub.w            d4,d6
                          muls             d6,d2
                          divs             d5,d2
                          add.w            fbr,d2
                          move.w           d2,sbr

                          move.l           (a1,d3*8),d2
                          sub.l            (a1,d1*8),d2                                                   ; dx

                          asr.l            #7,d2                                                          ; / 128
                          muls             d6,d2                                                          ; new x coord
                          divs             d5,d2
                          ext.l            d2
                          asl.l            #7,d2                                                          ; * 128

                          add.l            (a1,d1*8),d2

                          move.w           minz,d5
                          move.w           (a2,d1*2),d0
                          divs             d5,d2
                          add.w            #(RTGScrWidthFLOOR/2)-1,d2

                          move.l           ypos,d1
                          divs             d4,d1
                          move.w           bottomline,d3

                          bra.b            lineclippedGOUR

****************************************************************

bothinfrontGOUR:
; Also, usefully enough, both are on-screen so no bottom clipping is needed.

                          move.w           (a2,d1*2),d0                                                   ; first x
                          move.w           (a2,d3*2),d2                                                   ; second x
                          move.l           ypos,d1
                          move.l           d1,d3
                          divs             d4,d1                                                          ; first y
                          divs             d5,d3                                                          ; second y

lineclippedGOUR:
                          move.l           #rightSideTab,a3

                          cmp.w            d1,d3
                          bne.b            linenotflatGOUR

                          bra              lineflatGOUR

****************************************************************

linenotflatGOUR:
                          st               drawit
                          bgt              lineonrightGOUR

                          move.l           #leftSideTab,a3
                          exg              d1,d3
                          exg              d0,d2
 
                          lea              (a3,d1*2),a3                                                   ; leftSideTab+offset
                          lea              leftbrighttab-leftSideTab(a3),a4                               ; leftbrighttab+offset
 
                          cmp.w            top(pc),d1
                          bge.s            .nonewtop
                          move.w           d1,top

.nonewtop:
                          cmp.w            bottom(pc),d3
                          ble.s            .nonewbot
                          move.w           d3,bottom

.nonewbot:
                          sub.w            d1,d3                                                          ; dy
                          sub.w            d0,d2                                                          ; dx
 
                          blt.b            .linegoingleft
                          subq.w           #1,d0

                          ext.l            d2
                          divs             d3,d2
                          move.w           d2,d6
                          swap             d2
                          move.w           d2,a5

                          move.w           d3,d4
                          move.w           d3,d5
                          subq             #1,d5
                          move.w           d6,d1
                          addq             #1,d1
                          move.w           d1,a6

                          moveq            #0,d1
                          move.w           sbr,d1
                          move.w           fbr,d2
                          sub.w            d1,d2
                          ext.l            d2
                          asl.w            #8,d2                                                          ; * 256
                          asl.w            #3,d2                                                          ; * 8
                          divs             d3,d2 
                          ext.l            d2
                          asl.l            #5,d2                                                          ; * 32 (5) 

                          swap             d1

****************************************************************

.pixlopright:
                          move.w           d0,(a3)+
                          swap             d1
                          move.w           d1,(a4)+
                          swap             d1
                          add.l            d2,d1

                          sub.w            a5,d4
                          bge.s            .nobigstep

                          add.w            a6,d0
                          add.w            d3,d4
                          dbra             d5,.pixlopright

                          bra              lineflatGOUR

****************************************************************

.nobigstep:
                          add.w            d6,d0
                          dbra             d5,.pixlopright

                          bra              lineflatGOUR

****************************************************************

.linegoingleft:
                          subq.w           #1,d0
 
                          neg.w            d2

                          ext.l            d2
                          divs             d3,d2
                          move.w           d2,d6
                          swap             d2

                          move.w           d3,d4
                          move.w           d3,d5
                          subq             #1,d5

                          move.w           d6,d1
                          addq             #1,d1
                          move.w           d1,a6
                          move.w           d2,a5

                          moveq            #0,d1
                          move.w           sbr,d1
                          move.w           fbr,d2
                          sub.w            d1,d2
                          ext.l            d2
                          asl.w            #8,d2                                                          ; * 256
                          asl.w            #3,d2                                                          ; * 8
                          divs             d3,d2 
                          ext.l            d2
                          asl.l            #5,d2                                                          ; * 32
                          swap             d1

.pixlopleft:
                          swap             d1
                          move.w           d1,(a4)+
                          swap             d1
                          add.l            d2,d1

                          sub.w            a5,d4
                          bge.s            .nobigstepl
                          sub.w            a6,d0
                          add.w            d3,d4
                          move.w           d0,(a3)+
                          dbra             d5,.pixlopleft

                          bra              lineflatGOUR

****************************************************************

.nobigstepl:
                          sub.w            d6,d0
                          move.w           d0,(a3)+
                          dbra             d5,.pixlopleft
                          bra              lineflatGOUR
 
lineonrightGOUR:
                          lea              (a3,d1*2),a3
                          lea              rightbrighttab-rightSideTab(a3),a4
 
                          cmp.w            top(pc),d1
                          bge.s            .nonewtop
                          move.w           d1,top

.nonewtop:
                          cmp.w            bottom(pc),d3
                          ble.s            .nonewbot
                          move.w           d3,bottom

.nonewbot:
                          sub.w            d1,d3                                                          ; dy
                          sub.w            d0,d2                                                          ; dx
                          blt.b            .linegoingleft

                          ext.l            d2
                          divs             d3,d2
                          move.w           d2,d6
                          swap             d2

                          move.w           d3,d4
                          move.w           d3,d5
                          subq             #1,d5
                          move.w           d6,d1
                          addq             #1,d1

                          move.w           d1,a6
                          move.w           d2,a5

                          moveq            #0,d1
                          move.w           fbr,d1
                          move.w           sbr,d2
                          sub.w            d1,d2
                          ext.l            d2
                          asl.w            #8,d2                                                          ; * 256
                          asl.w            #3,d2                                                          ; * 8
                          divs             d3,d2 
                          ext.l            d2
                          asl.l            #5,d2                                                          ; * 32
                          swap             d1

.pixlopright:
                          swap             d1
                          move.w           d1,(a4)+
                          swap             d1
                          add.l            d2,d1

                          sub.w            a5,d4
                          bge.s            .nobigstep
                          add.w            a6,d0
                          add.w            d3,d4
                          move.w           d0,(a3)+
                          dbra             d5,.pixlopright

                          bra.b            lineflatGOUR
 
 ****************************************************************

.nobigstep:
                          add.w            d6,d0
                          move.w           d0,(a3)+
                          dbra             d5,.pixlopright

                          bra.b            lineflatGOUR

****************************************************************

.linegoingleft:
                          neg.w            d2

                          ext.l            d2
                          divs             d3,d2
                          move.w           d2,d6
                          swap             d2

                          move.w           d3,d4
                          move.w           d3,d5
                          subq             #1,d5
                          move.w           d6,d1
                          addq             #1,d1
                          move.w           d1,a6
                          move.w           d2,a5

                          moveq            #0,d1
                          move.w           fbr,d1
                          move.w           sbr,d2
                          sub.w            d1,d2
                          ext.l            d2
                          asl.w            #8,d2                                                          ; * 256
                          asl.w            #3,d2                                                          ; * 8
                          divs             d3,d2 
                          ext.l            d2
                          asl.l            #5,d2                                                          ; * 32
                          swap             d1

.pixlopleft:
                          swap             d1
                          move.w           d1,(a4)+
                          swap             d1
                          add.l            d2,d1

                          move.w           d0,(a3)+
                          sub.w            a5,d4
                          bge.s            .nobigstepl

                          sub.w            a6,d0
                          add.w            d3,d4
                          dbra             d5,.pixlopleft
 
                          bra.b            lineflatGOUR
 
 ****************************************************************

.nobigstepl:
                          sub.w            d6,d0
                          dbra             d5,.pixlopleft

****************************************************************

lineflatGOUR:
bothbehindGOUR:
                          dbra             d7,sideLoopGOUR

*********************************************************************************************
*********************************************************************************************

pastSides:
; a0 = ThisRoomToDraw+n

                          addq             #2,a0
 
                          move.w           #RTGScrWidthByteOffsetFLOOR,linedir

                          lea              AB3dChunkyBufferFLOOR,a6                                       
                          lea              RTGScrWidthByteOffsetFLOOR*((RTGScrHeightFLOOR/2)+1)(a6),a6

                          move.w           (a0)+,scaleval
                          move.w           (a0)+,whichtile
                          move.w           (a0)+,d6
                          add.w            ZoneBright,d6
                          move.w           d6,lighttype

                          move.w           above(pc),d6
                          beq.b            groundfloor

****************************************************************
; on ceiling:

                          move.w           #-RTGScrWidthByteOffsetFLOOR,linedir
                          suba.l           #RTGScrWidthByteOffsetFLOOR,a6

****************************************************************

groundfloor:
                          move.w           xoff,d6
                          move.w           zoff,d7
                          
                          add.w            xwobxoff,d7
                          add.w            xwobzoff,d6

                          swap             d6
                          swap             d7
                          clr.w            d6
                          clr.w            d7

****************************************************************

                          move.w           scaleval(pc),d3
                          beq.s            .samescale
                          bgt.s            .scaledown
                          neg.w            d3
                          asr.l            d3,d7                                                          ; / n
                          asr.l            d3,d6                                                          ; / n
                          bra.s            .samescale

*************************************************************

.scaledown:
                          asl.l            d3,d6                                                          ; * n
                          asl.l            d3,d7                                                          ; * n

****************************************************************

.samescale
                          IFNE             USE1X1
                          ;asr.l            #1,d6                                                          ; x Debug: * 2 Hack!
                          ENDC

                          IFNE             USE1X1
                          ;asl.l            #1,d7                                                          ; z Debug: * 2 Hack!
                          ENDC

                          move.l           d6,sxoff
                          move.l           d7,szoff

                          bra              pastscale 

*********************************************************************************************

top:                      dc.w             0
bottom:                   dc.w             0
ypos:                     dc.l             0
nfloors:                  dc.w             0
lighttype:                dc.w             0
above:                    dc.w             0 
linedir:                  dc.w             0
distaddr:                 dc.w             0
 
minz:                     dc.w             0

leftSideTab:              ds.w             RTGMult*180
rightSideTab:             ds.w             RTGMult*180

leftbrighttab:            ds.w             RTGMult*180
rightbrighttab:           ds.w             RTGMult*180
 
pointBrights:             dc.l             0
currentPointBrights:      ds.l             RTGMult*1000

movespd:                  dc.w             0
largespd:                 dc.l             0
disttobot:                dc.w             0

*********************************************************************************************

pastscale:

                          tst.b            drawit(pc)
                          beq              dontdrawfloor

****************************************************************

                          move.l           a0,-(a7)

                          move.l           #leftSideTab,a4
                          move.w           top(pc),d1
 
                          move.w           #(RTGScrHeightFLOOR/2)-1,d7                                    ; (height/2) - 1? 39
                          sub.w            d1,d7
                          move.w           d7,disttobot
 
                          move.w           bottom(pc),d7

                          tst.w            above
                          beq.s            clipfloor
 
 ****************************************************************

                          move.w           #(RTGScrHeightFLOOR/2),d3
                          move.w           d3,d4
                          sub.w            topclip,d3
                          sub.w            botclip,d4

                          cmp.w            d3,d1
                          bge              predontdrawfloor

                          cmp.w            d4,d7
                          blt              predontdrawfloor

                          cmp.w            d4,d1
                          bge.s            .nocliptoproof

                          move.w           d4,d1

.nocliptoproof:
                          cmp.w            d3,d7
                          blt.b            doneclip

                          move.w           d3,d7

                          bra.b            doneclip

****************************************************************

clipfloor:
                          move.w           botclip,d4
                          sub.w            #(RTGScrHeightFLOOR/2),d4
                          cmp.w            d4,d1
                          bge              predontdrawfloor

                          move.w           topclip,d3
                          sub.w            #(RTGScrHeightFLOOR/2),d3
                          cmp.w            d3,d1
                          bge.s            .nocliptopfloor

                          move.w           d3,d1

.nocliptopfloor: 
                          cmp.w            d3,d7
                          ble              predontdrawfloor

                          cmp.w            d4,d7
                          blt.s            .noclipbotfloor

                          move.w           d4,d7

.noclipbotfloor:

****************************************************************

doneclip:
                          lea              (a4,d1*2),a4
                        
                          move.w           distaddr,d0
                          muls             #FloorTileSizeMultiplier,d0 
                          move.l           d0,a2

                          sub.w            d1,d7
                          ble              predontdrawfloor 

                          move.w           d1,d0
                          bne.s            .notzero

                          moveq            #1,d0

.notzero:
                          muls             linedir,d1                                                     ; top*linedir
                          add.l            d1,a6                                                          ; a6=RTG buffer
                          move.l           #floorScaleCols,a1                                             
                          move.l           LineRoutineToUse,a5
 
 ****************************************************************
 
                          tst.b            useGouraud
                          bne              doGouraudFloor
 
 ****************************************************************

                          tst.b            anyclipping
                          beq.b            doFloorNoClip

****************************************************************

dofloor:
                          move.w           leftclip(pc),d3
                          move.w           rightclip(pc),d4
                          move.w           rightSideTab-leftSideTab(a4),d2                                ; a4 = leftsidetab
 
                          addq             #1,d2
                          cmp.w            d3,d2
                          ble.s            nodrawline
                          
                          cmp.w            d4,d2
                          ble.s            noclipright

                          move.w           d4,d2

noclipright:
                          move.w           (a4),d1
                          cmp.w            d4,d1
                          bge.s            nodrawline

                          cmp.w            d3,d1
                          bge.s            noclipleft

                          move.w           d3,d1

noclipleft:
                          cmp.w            d1,d2
                          ble.s            nodrawline

                          move.w           d1,leftedge
                          move.w           d2,rightedge

                          move.l           a6,a3                                                          ; a6 = RTG Buffer
                          movem.l          d0/d7/a2/a4/a5/a6,-(a7)
                          move.l           a2,d7                                                          ; a2 = distance*multiplier
                          divs             d0,d7                                                          ; d0 = top
                          move.w           d7,d0
                          jsr              (a5)
                          movem.l          (a7)+,d0/d7/a2/a4/a5/a6

nodrawline:
                          subq.w           #1,disttobot
                          adda.w           linedir(pc),a6                                                 ; a6 = RTG Buffer
                          
                          addq             #2,a4
                          addq             #1,d0

                          subq             #1,d7
                          bgt.b            dofloor

predontdrawfloor:
                          move.l           (a7)+,a0

dontdrawfloor:
                          rts

*********************************************************************************************

anyclipping:              dc.w             0

*********************************************************************************************

doFloorNoClip:
                          move.w           rightSideTab-leftSideTab(a4),d2                                ; a4=leftSideTab
                          addq             #1,d2
                          move.w           (a4)+,d1

                          move.w           d1,leftedge
                          move.w           d2,rightedge

                          move.l           a6,a3
                          movem.l          d0/d7/a2/a4/a5/a6,-(a7)
                          move.l           a2,d7
                          divs             d0,d7
                          move.w           d7,d0
                          jsr              (a5)
                          movem.l          (a7)+,d0/d7/a2/a4/a5/a6

                          subq.w           #1,disttobot
                          adda.w           linedir(pc),a6

                          addq             #1,d0
                          subq             #1,d7
                          bgt.b            doFloorNoClip

                          bra.b            predontdrawfloor

*********************************************************************************************
*********************************************************************************************

doGouraudFloor:
                          tst.b            anyclipping
                          beq              doFloorNoClipGouraud
 
dofloorGOUR:
                          move.w           leftclip(pc),d3
                          move.w           rightclip(pc),d4
                          move.w           rightSideTab-leftSideTab(a4),d2

                          move.w           d2,d5
                          sub.w            (a4),d5
                          addq             #1,d5
                          moveq            #0,d6
 
                          addq             #1,d2
                          cmp.w            d3,d2
                          ble              nodrawlineGOUR

                          cmp.w            d4,d2
                          ble.s            nocliprightGOUR

                          move.w           d4,d2

nocliprightGOUR:
                          move.w           (a4),d1
                          cmp.w            d4,d1
                          bge              nodrawlineGOUR

                          cmp.w            d3,d1
                          bge.s            noclipleftGOUR

                          move.w           d3,d6
                          subq             #1,d6
                          sub.w            d1,d6
                          move.w           d3,d1

noclipleftGOUR:
                          cmp.w            d1,d2
                          ble              nodrawlineGOUR

                          move.w           d1,leftedge
                          move.w           d2,rightedge

                          move.l           a2,d2
                          divs             d0,d2
                          move.w           d2,dst
                          asr.w            #7,d2                                                          ; / 128 

                          moveq            #0,d1
                          moveq            #0,d3
                          move.w           leftbrighttab-leftSideTab(a4),d1
                          add.w            d2,d1
                          bge.s            .okbl
                          moveq            #0,d1

.okbl:
                          asr.w            #1,d1                                                          ; / 2
                          cmp.w            #14,d1
                          ble.s            .okdl

                          move.w           #14,d1

.okdl:
                          move.w           rightbrighttab-leftSideTab(a4),d3
                          add.w            d2,d3
                          bge.s            .okbr
                          moveq            #0,d3

.okbr:
                          asr.w            #1,d3                                                          ; / 2
                          cmp.w            #14,d3
                          ble.s            .okdr

                          move.w           #14,d3

.okdr:
                          sub.w            d1,d3
                          asl.w            #8,d1                                                          ; * 256
                          move.l           d1,leftbright
                          swap             d3
                          tst.l            d3
                          bgt.s            .okItsPosAlready 
                          neg.l            d3
                          asr.l            #5,d3                                                          ; / 32
                          divs             d5,d3
                          neg.w            d3
                          bra.s            .okNowItsNeg
 
.okItsPosAlready:
                          asr.l            #5,d3                                                          ; / 32
                          divs             d5,d3

.okNowItsNeg:
                          muls             d3,d6                                                          
                          add.w            #256*8,d6
                          asr.w            #3,d6                                                          ; / 8
                          clr.b            d6
                          add.w            d6,leftbright+2
 
                          ext.l            d3
                          asl.l            #5,d3                                                          ; * 32
                          swap             d3
                          asl.w            #8,d3                                                          ; * 256
                          move.l           d3,brightspd
 
                          move.l           a6,a3                                                          ; a6 => a3 = frompt
                          movem.l          d0/d7/a2/a4/a5/a6,-(a7)
                          move.w           dst,d0
                          lea              floorScaleCols,a1
                          move.l           floortile,a0
                          adda.w           whichtile,a0
                          jsr              pastFloorBright
                          movem.l          (a7)+,d0/d7/a2/a4/a5/a6

nodrawlineGOUR:
                          subq.w           #1,disttobot

                          adda.w           linedir(pc),a6
                          addq             #2,a4
                          addq             #1,d0
                          subq             #1,d7
                          bgt              dofloorGOUR

predontdrawfloorGOUR:
                          move.l           (a7)+,a0

dontdrawfloorGOUR:
                          rts

*********************************************************************************************
*********************************************************************************************

doFloorNoClipGouraud:
                          move.w           rightSideTab-leftSideTab(a4),d2
                          addq             #1,d2
                          move.w           (a4),d1
                          move.w           d1,leftedge
                          move.w           d2,rightedge

                          sub.w            d1,d2

                          move.l           a2,d6
                          divs             d0,d6
                          move.w           d6,d5
                          asr.w            #7,d5                                                          ; / 128

                          moveq            #0,d1
                          moveq            #0,d3
                          move.w           leftbrighttab-leftSideTab(a4),d1
                          add.w            d5,d1
                          bge.s            .okbl
                          moveq            #0,d1

.okbl:
                          asr.w            #1,d1                                                          ; / 2
                          cmp.w            #14,d1
                          ble.s            .okdl
                          move.w           #14,d1

.okdl: 
                          move.w           rightbrighttab-leftSideTab(a4),d3
                          add.w            d5,d3
                          bge.s            .okbr
                          moveq            #0,d3

.okbr:
                          asr.w            #1,d3                                                          ; / 2
                          cmp.w            #14,d3
                          ble.s            .okdr
                          move.w           #14,d3

.okdr:
                          sub.w            d1,d3
                          asl.w            #8,d1                                                          ; * 256
                          move.l           d1,leftbright
                          swap             d3
                          asr.l            #5,d3                                                          ; / 32
                          divs             d2,d3
                          ext.l            d3
                          asl.l            #5,d3                                                          ; * 32
                          swap             d3
                          asl.w            #8,d3                                                          ; * 256
                          move.l           d3,brightspd

                          move.l           a6,a3                                                          ; a6 => a3 = frompt
                          movem.l          d0/d7/a2/a4/a5/a6,-(a7)
                          move.w           d6,d0
                          move.w           d0,dst
                          lea              floorScaleCols,a1
                          move.l           floortile,a0
                          adda.w           whichtile,a0
                          jsr              pastFloorBright
                          movem.l          (a7)+,d0/d7/a2/a4/a5/a6

                          subq.w           #1,disttobot
                          adda.w           linedir(pc),a6
                          addq             #2,a4
                          addq             #1,d0
                          subq             #1,d7
                          bgt              doFloorNoClipGouraud

                          bra              predontdrawfloorGOUR

*********************************************************************************************

dists:                    ; incbin "floordists"
drawit:                   dc.w             0

dst:                      dc.w             0

*********************************************************************************************
; Ptr to routine

LineRoutineToUse:         dc.l             0

*********************************************************************************************
*********************************************************************************************
; Render modes from the pause UI:
;  - Gouraud : Texture + gouraud
;  - Textured : Only texture
;  - Plain Shaded : Filled vector
;  - None : Black
*********************************************************************************************

STRIPWIDTH                 EQU (RTGScrWidth/3)                                                            ; 96/3=32 -> 192/3=64

*********************************************************************************************

pastFloorBright:
; a0=floortile
; a1=floorScaleCols
; d0=Distance - dst
; a6/a3=frompt

                          move.w           d0,d1
                          muls             cosval,d1                                                      ; change in x across whole width

                          move.w           d0,d2
                          muls             sinval,d2                                                      ; change in z across whole width

                          IFNE             USE1X1
                          asr.l            #1,d2                                                          ; Debug: / 2 Hack!
                          ENDC
                          neg.l            d2

*************************************************************

scaleprog:
                          move.w           scaleval(pc),d3
                          beq.s            .samescale
                          bgt.s            .scaledown
                          neg.w            d3
                          asr.l            d3,d1                                                          ; / n
                          asr.l            d3,d2                                                          ; / n
                          bra.s            .samescale

*************************************************************

.scaledown:
                          asl.l            d3,d1                                                          ; * n
                          asl.l            d3,d2                                                          ; * n

*************************************************************
; zcos

.samescale:
                          move.l           d1,d3                                                          ;	zcos
                          move.l           d3,d6
                          move.l           d3,d5                                                         

                          asr.l            #1,d6                                                          ; zcos / 2
                          add.l            d6,d3                                                          ; zcos + (zcos / 2)
                          asr.l            #1,d3                                                          ; (zcos + (zcos / 2)) / 2

*************************************************************
; zsin

                          move.l           d2,d4                                                          ; zsin
                          move.l           d4,d6

                          asr.l            #1,d6                                                          ; zsin / 2
                          add.l            d4,d6                                                          ; (zsin / 2) + zsin  
                          add.l            d3,d4                                                          ; zsin + zcos
                          neg.l            d4                                                             ; (zsin + zcos) * -1 (start x)

                          asr.l            #1,d6                                                          ; ((zsin / 2) + zsin) / 2
                          sub.l            d6,d5                                                          ; (((zsin / 2) + zsin) / 2) - zcos (start z)

                          add.l            sxoff,d4 
                          add.l            szoff,d5                                                       

                          IFNE             USE1X1
                          asl.l            #1,d4                                                          ; Debug: * 2 Hack!
                          ENDC

                          IFNE             USE1X1
                          ;asl.l            #1,d5                                                          ; Debug: * 2 Hack!
                          ENDC 

 *************************************************************

                          moveq            #0,d6
                          move.w           leftedge(pc),d6
                          beq.s            nomultleft
 
 *************************************************************

                          move.l           d1,a4
                          move.l           d2,a5
 
                          muls.l           d6,d3:d1                                                       ; x  
                          asr.l            #6,d1                                                          ; / 64
                          add.l            d1,d4

                          muls.l           d6,d3:d2                                                       ; z      
                          asr.l            #6,d2                                                          ; / 64
                          add.l            d2,d5
 
                          move.l           a4,d1
                          move.l           a5,d2

*************************************************************

nomultleft:
                          move.w           d4,startsmoothx
                          move.w           d5,startsmoothz

                          swap             d4
                          asr.l            #8,d5                                                          ; / 256
                          and.w            #63,d4
                          and.w            #63*256,d5
                          move.b           d4,d5

                          asr.l            #6,d1                                                          ; / 64
                          asr.l            #6,d2                                                          ; / 64

                          move.w           d1,a4
                          move.w           d2,a5
                          asr.l            #8,d2                                                          ; / 256
                          and.w            #%0011111100000000,d2
                          swap             d1
                          add.w            d1,d2
                          move.w           #%11111100111111,d1
                          and.w            d1,d5
                          swap             d5

                          move.w           startsmoothz,d5
                          swap             d5
                          
                          swap             d2
                          move.w           a5,d2
                          swap             d2
 
*************************************************************
 
                          move.w           d6,a2                                                          ; d6 = leftedge

                          move.l           d2,d6
                          add.w            #256,d6
 
                          moveq            #0,d0

                          tst.w            a2
                          beq              startatleftedge
 
*************************************************************

                          move.w           widthleft(pc),d4                                               
                          move.w           rightedge(pc),d3

                          cmp.w            #(STRIPWIDTH-1),a2
                          bgt.s            notinfirststrip

                          lea              (a3,a2.w*2),a3                                                 ; RTG buffer

                          cmp.w            #STRIPWIDTH,d3
                          ble.s            allinfirststrip

                          move.w           #STRIPWIDTH,d7
                          sub.w            d7,d3
                          sub.w            a2,d7
                          bra              intofirststrip

*************************************************************

allinfirststrip:
                          sub.w            a2,d3
                          move.w           d3,d7
                          move.w           #0,d4
                          bra.b            allintofirst

*************************************************************

notinfirststrip:
                          sub.w            #STRIPWIDTH,a2                                                 ; y pixels?
                          sub.w            #STRIPWIDTH,d3

                          adda.w           #(STRIPWIDTH+1)*2,a3                                           ; RTG buffer (width)
                          
                          cmp.w            #(STRIPWIDTH-1),a2
                          bgt.s            notstartinsec
                          
                          lea              (a3,a2.w*2),a3                                                 ; RTG buffer

                          cmp.w            #STRIPWIDTH,d3
                          ble.s            allinsecstrip

                          move.w           #STRIPWIDTH,d7
                          sub.w            d7,d3
                          sub.w            a2,d7
                          move.w           d3,d4
                          bra.b            allintofirst

*************************************************************

allinsecstrip:
                          sub.w            a2,d3
                          move.w           d3,d7
                          move.w           #0,d4
                          bra.b            allintofirst
                          rts
                
*************************************************************

notstartinsec:

                          sub.w            #STRIPWIDTH,a2
                          sub.w            #STRIPWIDTH,d3

                          adda.w           #(STRIPWIDTH+1)*2,a3                                           ; RTG buffer
                          lea              (a3,a2.w*2),a3                                                 ; RTG buffer

                          cmp.w            #STRIPWIDTH,d3
                          ble.s            allinthirdstrip

                          move.w           #STRIPWIDTH,d7
                          sub.w            d7,d3
                          sub.w            a2,d7
                          move.w           d3,d4
                          bra.b            allintofirst
                          rts

*************************************************************

allinthirdstrip:
                          sub.w            a2,d3
                          move.w           d3,d7
                          move.w           #0,d4
                          bra.b            allintofirst
                          rts

*************************************************************

startatleftedge:
                          move.w           rightedge(pc),d3
                          sub.w            a2,d3
 
                          move.w           d3,d7
                          cmp.w            #STRIPWIDTH,d7
                          ble.s            .notoowide

                          move.w           #STRIPWIDTH,d7

.notoowide:
                          sub.w            d7,d3

intofirststrip:
                          move.w           d3,d4

allintofirst:
                          move.w           startsmoothx,d3

****************************************************************
; Gouraud (floor/ceiling)
; d2=
; d5=startsmoothz.w+?
; a0=

                          tst.b            useGouraud
                          bne              GouraudFloor

****************************************************************
; Water

                          tst.b            useWater
                          bne              TexturedWater
 
****************************************************************
; Bumpmap (floor/ceiling)

                          tst.b            useBumpmap
                          bne.s            BumpmapFloor

****************************************************************

ordinary:
                          moveq            #0,d0
                          dbra             d7,acrossScrnBumpmap
                          rts

*********************************************************************************************

useBumpmap:               dc.w             0                                                              ; .w
useSmoothBumpmap:         dc.w             0                                                              ; .w
useGouraud:               dc.w             0                                                              ; .w
useBlackFloor:            dc.w             0

selectGouraud:            dc.w             0                                                              ; .w

*********************************************************************************************
*********************************************************************************************
; Bumpmap floor draw

                          include          "OSBumpmap.s"
                          cnop             0,64

*********************************************************************************************
*********************************************************************************************

leftbright:               dc.l             0
brightspd:                dc.l             0

*********************************************************************************************
*********************************************************************************************
; Gouraud floor chunky draw

GouraudFloor:
; d7=width?
; d4=width?

                          move.l           leftbright,d0
                          move.l           brightspd,d1
                          
                          dbra             d7,acrossScrnGouraud
                          rts

********************************************************************************************* 

backBeforeGouraud:

                          and.w            #63*256+63,d5
                          move.b           (a0,d5.w*4),d0
                          add.l            d1,d0
                          bcc.s            .nomoreb

                          add.w            #256,d0                                                        ; 256

.nomoreb:
                          add.w            a4,d3

                          move.w           (a1,d0.w*2),(a3)                                               ; floorScaleCols To RTG buffer
                          addq             #2,a3

                          addx.l           d6,d5   

                          dbcs             d7,acrossScrnGouraud
                          dbcc             d7,backBeforeGouraud

                          bra.s            past1gour

*******************************************************************

acrossScrnGouraud:
; d5
; a0
; d2
                          and.w            #63*256+63,d5

                          move.b           (a0,d5.w*4),d0
                          add.l            d1,d0
                          bcc.s            .nomoreb

                          add.w            #256,d0                                                        ; 256

.nomoreb:
                          add.w            a4,d3
                          
                          move.w           (a1,d0.w*2),(a3)                                               ; floorScaleCols To RTG buffer
                          addq             #2,a3

                          addx.l           d2,d5

                          dbcs             d7,acrossScrnGouraud
                          dbcc             d7,backBeforeGouraud

*******************************************************************

past1gour:
                          bcc.s            gotoacrossgour

                          move.w           d4,d7
                          bne.s            .notdoneyet

                          move.l           d0,leftbright
 
                          rts

*******************************************************************

.notdoneyet:
                          cmp.w            #STRIPWIDTH,d7
                          ble.s            .notoowide
                
                          move.w           #STRIPWIDTH,d7

.notoowide:
                          sub.w            d7,d4  

                         ; addq         #2,a3                    ; a3 = frompt
                         ; addq         #4,a3                    ; a3 = frompt

                          dbra             d7,backBeforeGouraud
                          rts

*******************************************************************

gotoacrossgour:
                          move.w           d4,d7
                          bne.s            .notdoneyet
                          rts

*******************************************************************

.notdoneyet:
                          cmp.w            #STRIPWIDTH,d7
                          ble.s            .notoowide

                          move.w           #STRIPWIDTH,d7

.notoowide:
                          sub.w            d7,d4  

                         ; addq         #2,a3                    ; a3 = frompt
                         ; addq         #4,a3                    ; a3 = frompt

                          dbra             d7,acrossScrnGouraud
                          rts

*********************************************************************************************
*********************************************************************************************

startsmoothx:             dc.w             0
                          dc.w             0

*********************************************************************************************

startsmoothz:             dc.w             0
                          dc.w             0

*********************************************************************************************

floorBright:
                          dc.l             512*0
                          
                          dc.l             512*1
                          dc.l             512*1

                          dc.l             512*2
                          dc.l             512*2
 
                          dc.l             512*3
                          dc.l             512*3

                          dc.l             512*4
                          dc.l             512*4

                          dc.l             512*5
                          dc.l             512*5

                          dc.l             512*6
                          dc.l             512*6

                          dc.l             512*7
                          dc.l             512*7
 
                          dc.l             512*8
                          dc.l             512*8

                          dc.l             512*9
                          dc.l             512*9

                          dc.l             512*10
                          dc.l             512*10

                          dc.l             512*11
                          dc.l             512*11

                          dc.l             512*12
                          dc.l             512*12
 
                          dc.l             512*13
                          dc.l             512*13

                          dc.l             512*14
                          dc.l             512*14

*********************************************************************************************

widthleft:                dc.w             0
scaleval:                 dc.w             0
sxoff:                    dc.l             0
szoff:                    dc.l             0
scosval:                  dc.w             0
ssinval:                  dc.w             0

*********************************************************************************************
; Line draws

                          include          "OSDrawSimpleLine.s"  

*********************************************************************************************

                          include          "OSDrawFloorLine.s"  

*********************************************************************************************

                          include          "OSDrawBumpLine.s"  

*********************************************************************************************
; Floor bumpmap

smoothScaleCols:          
                          incbin           "data/pal/SmoothBumpPalScaled" 
                          even

smoothTile:               incbin           "data/gfx/SmoothBumpTile" 
                          even

bumpConstCols:      
                          incbin           "data/pal/ConstCols"      
                          even

bumpTile:                 incbin           "data/gfx/BumpTile"
                          even

*********************************************************************************************
; Floor bumpmap

bumpConstCol:             dc.w             0

*********************************************************************************************	
; Floor 

floorScaleCols:
; .w 96*40 = 3840?
                          include          "data/rtg/pal/FloorPalScaledHiColor.s"
                          ds.w             RTGMult*4*256,0
                          even

*********************************************************************************************
; Floor 

floortile:                dc.l             0

*********************************************************************************************
*********************************************************************************************
; Begin water draw

*********************************************************************************************
; Water variables

watertoUse:               dc.l             waterFile
waterpt:                  dc.l             waterList

*********************************************************************************************

waterList:
                          dc.l             waterFile
                          dc.l             waterFile+2
                          dc.l             waterFile+256
                          dc.l             waterFile+256+2
                          dc.l             waterFile+512
                          dc.l             waterFile+512+2
                          dc.l             waterFile+768
                          dc.l             waterFile+768+2
                        ; dc.l waterfile+768
                        ; dc.l waterfile+512+2
                        ; dc.l waterfile+512
                        ; dc.l waterfile+256+2
                        ; dc.l waterfile+256
                        ; dc.l waterfile+2
endWaterList:

*********************************************************************************************

wtan:                     dc.w             0
waterOff:                 dc.w             0

*********************************************************************************************

TexturedWater:
; d1=Current zone
; a3=fromPt (copper list)

                          add.w            waterOff,d5

                          move.l           #brightenTabWater,a1                                                      
                          move.w           dst,d0
                          clr.b            d0
 
                          add.w            d0,d0
                          cmp.w            #12*512,d0
                          blt.s            .noTooWater

                          move.w           #12*512,d0
 
.noTooWater:
                          adda.w           d0,a1

                          move.w           dst,d0
                          asl.w            #7,d0                                                          ; * 128
                          add.w            wtan,d0
                          and.w            #8191,d0
                          move.l           #SineTable,a0
                          move.w           (a0,d0.w),d0
                          ext.l            d0
 
                          move.w           dst,d3
                          add.w            #300,d3
                          divs             d3,d0
                          asr.w            #6,d0                                                          ; / 64
                          addq             #2,d0
                          cmp.w            disttobot,d0
                          blt.s            okNotOffBototot

***********************************************************

                          move.w           disttobot,d0
                          subq             #1,d0

okNotOffBototot:
                          muls             #RTGScrWidthByteOffsetFLOOR,d0                                 ; * CopLineSpace

                          tst.w            above
                          beq.s            nonnnnneg
                          neg.l            d0

nonnnnneg:
                          move.l           d0,a6
                          move.l           watertoUse,a0
                          move.w           startsmoothx,d3
                          dbra             d7,acrossScrnWater
                          rts

***********************************************************

backBeforeWater:
                          and.w            d1,d5
                          move.w           (a0,d5.w*4),d0                                                 ; a0 = watertoUse

                          movem.l          d2,-(a7)
                          move.w           (a3,a6.w),d2
                          CHICOLTO12BIT
                          move.b           d2,d0                                                          ; a3 = frompt => d0 = Hi water+LO buffer

                          move.w           (a1,d0.w*2),(a3)                                               ; From brightentab To RTG buffer
                          addq             #2,a3                             
                          movem.l          (a7)+,d2

                          add.w            a4,d3
                          addx.l           d6,d5

                          dbcs             d7,acrossScrnWater
                          dbcc             d7,backBeforeWater
                          bcc              past1w

                          add.w            #256,d5 

                          bra              past1w

*********************************************************************************************

acrossScrnWater:
                          and.w            d1,d5
                          move.w           (a0,d5.w*4),d0

                          movem.l          d2,-(a7)
                          move.w           (a3,a6.w),d2
                          CHICOLTO12BIT
                          move.b           d2,d0                                                          ; a3 = frompt => d0 = Hi water + LO buffer

                          move.w           (a1,d0.w*2),(a3)                                               ; From brightentab To RTG buffer
                          addq             #2,a3
                          movem.l          (a7)+,d2

                          add.w            a4,d3
                          addx.l           d2,d5

                          dbcs             d7,acrossScrnWater

                          dbcc             d7,backBeforeWater
                          bcc.s            past1w

                          add.w            #256,d5 

*******************************************************************

past1w:
                          move.w           d4,d7
                          bne.s            .notdoneyet
                          rts

***********************************************************

.notdoneyet:
                          cmp.w            #STRIPWIDTH,d7
                          ble.s            .notoowide                                                     ; Less than or equal

                          move.w           #STRIPWIDTH,d7

.notoowide:
                          sub.w            d7,d4
                          dbra             d7,acrossScrnWater
                          rts

*********************************************************************************************

useWater:                 dc.w             0
                          dc.w             0

*********************************************************************************************

waterFile:                incbin           "data/helper/waterfile"
                          even

; End water draw
*********************************************************************************************
*********************************************************************************************
