*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

                          incdir     "includes"
                          include    "macros.i"
                          include    "AB3DI.i"
                          include    "AB3DIRTG.i"

*********************************************************************************************

FloorLine:
; d0=Current zone
; see LineRoutineToUse

                          move.l     floortile,a0
                          adda.w     whichtile,a0
                          move.w     lighttype,d1
                          
                          move.w     d0,dst
                          move.w     d0,d2

*****************************************************
; Old version
                          asr.w      #8,d2                        ; / 256
                          addq.w     #5,d1

                          add.w      d2,d1
                          bge.s      .fixedbright

                          moveq      #0,d1

.fixedbright:
                          cmp.w      #28,d1
                          ble.s      .smallbright

                          move.w     #28,d1

.smallbright:
                          lea        floorScaleCols,a1
                          add.l      floorBright(pc,d1.w*4),a1
                          
                          bra        pastFloorBright

*********************************************************************************************