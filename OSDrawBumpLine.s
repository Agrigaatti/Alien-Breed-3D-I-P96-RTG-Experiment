*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

                          incdir     "includes"
                          include    "macros.i"
                          include    "AB3DI.i"
                          include    "AB3DIRTG.i"
                          
*********************************************************************************************

BumpLine:
; see LineRoutineToUse

                          tst.b      useSmoothBumpmap
                          beq.s      .chunky
 
                          move.l     #smoothTile,a0
                          lea        smoothScaleCols,a1

                          bra.b      .pastast

********************************************************

.chunky:
                          moveq      #0,d2

                          move.l     #bumpTile,a0
                          move.w     whichtile,d2
                          adda.w     d2,a0

                          ror.l      #2,d2                             ; / 2
                          lsr.w      #6,d2                             ; / 64
                          rol.l      #2,d2                             ; * 2
                          and.w      #15,d2                            ; %1111

                          move.l     #bumpConstCols,a1
                          move.w     (a1,d2.w*2),bumpConstCol
                          
                          lea        bumpScaleCols,a1
 
 ********************************************************

.pastast:
                          move.w     lighttype,d1
                          move.w     d0,dst
                          move.w     d0,d2

                          asr.w      #8,d2
                          addq.w     #5,d1

                          add.w      d2,d1
                          bge.s      .fixedbright

                          moveq      #0,d1

.fixedbright:
                          cmp.w      #28,d1
                          ble.s      .smallbright

                          move.w     #28,d1

.smallbright:
                          add.l      floorBright(pc,d1.w*4),a1
                          
                          bra        pastFloorBright
 
*********************************************************************************************

bumpScaleCols:            include    "data/rtg/pal/BumpPalScaled.s"
                          cnop       0,32

*********************************************************************************************
