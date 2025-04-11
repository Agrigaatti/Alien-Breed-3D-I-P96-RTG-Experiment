*********************************************************************************************
; Inline include

*********************************************************************************************

                          opt              P=68020

*********************************************************************************************

                          incdir           "includes"
                          include          "macros.i"
                          include          "AB3DIRTG.i"

*********************************************************************************************

RTGScrWidthLIGHT           EQU RTGScrWidth
RTGScrWidthByteOffsetLIGHT EQU RTGScrWidthByteOffset
RTGScrHeightLIGTH          EQU RTGScrHeight

AB3dChunkyBufferLIGHT      EQU AB3dChunkyBuffer

*********************************************************************************************

LightDraw:
; d0 = x
; d1 = y
; a0 = ?
; a1 = "data/helper/XTOCOPX" - No more
; a4 = "data/helper/OldBrightenFile.s"

                          SAVEREGS

                          move.w             (a0)+,d0
                          move.w             (a0)+,d1

                          lea                Rotated,a1
                          move.w             6(a1,d0.w*8),d2
                          ble.s              oneEndBehind

                          move.w             6(a1,d1.w*8),d3
                          bgt.s              bothEndsInFront

oneEndBehind:
                          GETREGS  
                          rts

**************************************************************

bothEndsInFront:
                          lea                OnScreen,a2

                          move.w             (a2,d0.w*2),d0
                          bge.s              okLeftEnd
                          moveq              #0,d0

okLeftEnd:
                          move.w             (a2,d1.w*2),d1
                          bgt.s              someVis

                          GETREGS
                          rts

**************************************************************

someVis:
                          cmp.w              #RTGScrWidthROTATE-1,d0                      ; width max?
                          ble.s              someVis2

                          GETREGS                          
                          rts

**************************************************************

someVis2:
                          cmp.w              #RTGScrWidthROTATE-1,d1                      ; width max?
                          ble.s              okRightEnd

                          move.w             #RTGScrWidthROTATE-1,d1

okRightEnd:
                          sub.w              d0,d1
                          blt                wrongbloodywayround

                          lea              brightenTab,a4
                          lea              AB3dChunkyBufferLIGHT,a3
                          move.w           #RTGScrWidthByteOffsetLIGHT,d6

                          move.w           #RTGScrHeightLIGTH-1,d7           ; height-1           

.lacross0:
                          move.w           d7,d3
                          
                          move.l           a3,a2
                          adda.w           #2,a2

.ldown0:
                          add.w            d6,a2

                          move.w           (a2),d2                           ; From RTG buffer       
                          CHICOLTO12BIT
                          move.w           (a4,d2.w*2),(a2)                  ; To RTG buffer

                          dbra             d3,.ldown0
                          dbra             d1,.lacross0

wrongbloodywayround:
                          GETREGS
                          rts

*********************************************************************************************