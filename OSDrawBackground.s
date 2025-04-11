*********************************************************************************************

                          opt              P=68020

*********************************************************************************************

                          incdir           "includes"
                          include          "macros.i"
                          include          "AB3DI.i"
                          include          "AB3DIRTG.i"

*********************************************************************************************

RTGScrWidthBG           EQU RTGScrWidth
RTGScrWidthByteOffsetBG EQU RTGScrWidthByteOffset

AB3dChunkyBufferBG      EQU AB3dChunkyBuffer

*********************************************************************************************

BackPictureWidth        EQU 96
BackPictureHeight       EQU 20

*********************************************************************************************
; RTG

MakeBackROut:
                          rts

*********************************************************************************************

PutInBackDrop:
; Add background picture

                          SAVEREGS

                          move.w           tmpAngPos,d5
                          and.w            #8191,d5
                          muls             #432,d5
                          divs             #8192,d5
                          muls             #38*2,d5

                          SUPERVISOR       SetInstCacheOn

                          lea              AB3dChunkyBufferBG,a0  
                          add.l            #RTGScrWidthByteOffsetBG,a0     

                          lea              EndBackPicture,a3

                          lea              BackPicture,a1
                          add.l            d5,a1

                          move.w           #RTGScrWidthBG-1,d3

************************************************************

fromBack:
val                       SET              0
                          REPT             BackPictureHeight-1
                          move.l           (a1)+,d0                                ; a1=BackPicture

                          move.w           d0,d2
                          C12BITTOHICOL
                          move.w           d2,(val+RTGScrWidthByteOffsetBG)(a0)
                          swap             d0

                          move.w           d0,d2
                          C12BITTOHICOL                          
                          move.w           d2,val(a0)
                          
val                       SET              val+(RTGScrWidthByteOffsetBG*2)
                          ENDR

************************************************************
; Fill empty space

val                       SET              val
                          REPT             (RTGScrHeight/3)-BackPictureHeight
                          move.w           d2,val(a0)
val                       SET              val+(RTGScrWidthByteOffsetBG)
                          ENDR

************************************************************

                          cmp.l            a3,a1
                          blt.s            .notOffRightEnd

                          move.l           #BackPicture,a1
                   
.notOffRightEnd:
                          addq             #2,a0                                   ; a0=AB3dChunkyBufferBG
                          dbra             d3,fromBack
 
                          GETREGS
                          rts

*********************************************************************************************

tmpAngPos:                dc.l             0

*********************************************************************************************

BackPicture:              incbin           "data/gfx/backfile"
EndBackPicture:
                          cnop             0,32

*********************************************************************************************