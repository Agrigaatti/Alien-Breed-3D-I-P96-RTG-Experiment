*********************************************************************************************
; Inline include

*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

                          incdir     "includes"
                          include    "macros.i"
                          include    "AB3DI.i"
                          include    "AB3DIRTG.i"

*********************************************************************************************

RTGScrWidthWATER           EQU RTGScrWidth
RTGScrWidthByteOffsetWATER EQU RTGScrWidthByteOffset
RTGScrHeightWATER          EQU RTGScrHeight

AB3dChunkyBufferWATER      EQU AB3dChunkyBuffer

*********************************************************************************************

WaterOffset                EQU (RTGScrHeightWATER/3)

*********************************************************************************************
; Water 
; Note: Use LEA with neagtive offset

                          move.w     #3,d5

                          tst.b      fillScrnWater
                          beq        noWaterFull
                          bgt.b      okNotHalf

                          moveq      #1,d5

****************************************************************

okNotHalf:
                          bclr.b     #1,$bfe001                                          ; Filter / led off

****************************************************************

                          lea        AB3dChunkyBufferWATER,a0
                          lea        (RTGScrWidthByteOffsetWATER*RTGScrHeightWATER)(a0),a0 

                          move.w     #RTGScrWidthWATER-1,d0                        

waterWidthLoop:
                          move.w     d5,d1
                          move.l     a0,a1

waterHeightLoop:

val                       SET        RTGScrWidthByteOffsetWATER*(WaterOffset-1)
                          REPT       (WaterOffset)
                          and.w      #%1111111111,val(a1)
val                       SET        val-RTGScrWidthByteOffsetWATER                      
                          ENDR

                          lea        -(RTGScrWidthByteOffsetWATER*WaterOffset)(a1),a1
                          dbra       d1,waterHeightLoop

                          addq       #2,a0
                          dbra       d0,waterWidthLoop       

                          rts

****************************************************************

noWaterFull:
                          bset.b     #1,$bfe001                                          ; Filter / led on
                          rts

*********************************************************************************************