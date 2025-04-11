*********************************************************************************************
; Inline include

*********************************************************************************************

                          opt              P=68020

*********************************************************************************************

                          incdir           "includes"
                          include          "macros.i"
                          include          "AB3DI.i"
                          include          "AB3DIRTG.i"

*********************************************************************************************

RTGScrWidthByteOffsetGUN EQU RTGScrWidthByteOffset
RTGScrMidByteOffsetGUN   EQU RTGScrMidByteOffset
RTGScrHeightGUN          EQU RTGScrHeight

AB3dChunkyBufferGUN      EQU AB3dChunkyBuffer

*********************************************************************************************

GunDataWidth             EQU 96
GunDataHeight            EQU 80

GunYOffsetScale          EQU ((RTGScrHeightGUN/100)*80)

*********************************************************************************************
; a5 = Data source (12bit chunky pixels)
; a0 = wad
                          SAVEREGS
                          
                          moveq            #0,d6
                          lea              AB3dChunkyBufferGUN,a6
                          move.w           d7,d6
                          add.l            #GunYOffsetScale,d6
                          muls             #RTGScrWidthByteOffsetGUN,d6
                          add.l            d6,a6    

                          add.l            #(RTGScrWidthByteOffsetGUN/2)-(GunDataWidth),a6 

                          move.w           #GunDataWidth-1,d0
                          bsr.b            .drawChunk

                          GETREGS
                          rts 
 
*********************************************************************************************

.drawChunk:
; d0=Count of color registers (31)
; d7=YOffset
; a6=fromPt + offset to lines start (Copper chunky screen)
; a4=Data source (12bit chunky pixels)
; a5=Ptr to gun

                          move.w           #GunDataHeight,d3                                ; 78
                          sub.w            d7,d3

                          move.l           a6,a3                                            ; a6 = AB3dChunkyBuffer + offset

                          move.b           (a5),d2
                          move.l           (a5)+,d1
                          bne.s            .noblank

                          addq             #2,a6                                            ; skip x pixel
                          dbra             d0,.drawChunk 
                          rts
 
 *******************************************************************

.noblank:
                          and.l            #$ffffff,d1                                      ; 24 bit
                          lea              (a0,d1.l),a1
                          cmp.b            #1,d2
                          bgt              .thirdd
                          beq              .secc

*******************************************************************

.drawdown0:
                          move.w           (a1)+,d2
                          and.w            #%11111,d2
                          beq.s            .itsblank0

                          move.w           (a4,d2.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)

.itsblank0:
                          lea              RTGScrWidthByteOffsetGUN(a3),a3
                          dbra             d3,.drawdown0

                          addq             #2,a6                                            ; skip x pixel
                          dbra             d0,.drawChunk
                          rts

*******************************************************************

.secc:
.drawdown1:
                          move.w           (a1)+,d2
                          lsr.w            #5,d2
                          and.w            #%11111,d2
                          beq.s            .itsblank1

                          move.w           (a4,d2.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)

.itsblank1:
                          lea              RTGScrWidthByteOffsetGUN(a3),a3
                          dbra             d3,.drawdown1

                          addq             #2,a6                                            ; skip x pixel
                          dbra             d0,.drawChunk
                          rts

*******************************************************************

.thirdd:
.drawdown2:
                          move.b           (a1),d2
                          addq             #2,a1
                          lsr.b            #2,d2
                          and.w            #%11111,d2
                          beq.s            .itsblank2

                          move.w           (a4,d2.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)

.itsblank2:
                          lea              RTGScrWidthByteOffsetGUN(a3),a3
                          dbra             d3,.drawdown2

                          addq             #2,a6                                            ; skip x pixel
                          dbra             d0,.drawChunk
                          rts

*********************************************************************************************