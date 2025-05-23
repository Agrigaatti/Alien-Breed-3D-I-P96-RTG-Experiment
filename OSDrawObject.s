*********************************************************************************************

                          opt              P=68020

*********************************************************************************************

                          incdir           "includes"
                          include          "macros.i"
                          include          "AB3DI.i"
                          include          "AB3DIRTG.i"

*********************************************************************************************

RTGScrWidthOBJECT           EQU RTGScrWidth
RTGScrWidthByteOffsetOBJECT EQU RTGScrWidthByteOffset
RTGScrHeightOBJECT          EQU RTGScrHeight

AB3dChunkyBufferOBJECT      EQU AB3dChunkyBuffer

*********************************************************************************************

currzone:                 dc.w             0

*********************************************************************************************

ty3d:                     dc.l             -100*1024
by3d:                     dc.l             1*1024

*********************************************************************************************

TOPOFROOM:                dc.l             0
BOTOFROOM:                dc.l             0
AFTERWATTOP:              dc.l             0
AFTERWATBOT:              dc.l             0
BEFOREWATTOP:             dc.l             0
BEFOREWATBOT:             dc.l             0
ROOMBACK:                 dc.l             0

*********************************************************************************************

objclipt:                 dc.w             0
objclipb:                 dc.w             0

leftclipb:                dc.w             0
rightclipb:               dc.w             RTGScrWidthOBJECT

*********************************************************************************************

ObjDraw:
                          move.w           (a0)+,d0
                          cmp.w            #1,d0
                          blt.s            beforewat
                          beq.s            afterwat
                          bgt.s            fullroom

********************************************************

beforewat:
                          move.l           BEFOREWATTOP,ty3d
                          move.l           BEFOREWATBOT,by3d
                          bra.s            donetopbot

********************************************************

afterwat:
                          move.l           AFTERWATTOP,ty3d
                          move.l           AFTERWATBOT,by3d
                          bra.s            donetopbot

********************************************************

fullroom:
                          move.l           TOPOFROOM(pc),ty3d
                          move.l           BOTOFROOM(pc),by3d

********************************************************

donetopbot:

 ********************************************************
                        ; move.l (a0)+,by3d
                        ; move.l (a0)+,ty3d
 ********************************************************

                          movem.l          d0-d7/a1-a6,-(a7)

                          move.w           rightclip,d0
                          sub.w            leftclip,d0
                          subq             #1,d0
                          ble              doneallinfront

                          SUPERVISOR       SetInstCacheOn

                          move.l           ObjectData,a1
                          move.l           #ObjRotated,a2
                          
                          move.l           #depthtable,a3
                          move.l           a3,a4
                          move.w           #RTGScrHeightOBJECT-1,d7

********************************************************

emptytab:
                          move.l           #$80010000,(a3)+
                          dbra             d7,emptytab
 
 ********************************************************

                          moveq            #0,d0

insertanobj:
                          move.w           (a1),d1
                          blt              sortedall
                          move.w           GraphicRoom(a1),d2
                          cmp.w            currzone(pc),d2
                          beq.s            itsinthiszone 

notinthiszone:
                          adda.w           #64,a1
                          addq             #1,d0
                          bra              insertanobj

********************************************************

itsinthiszone:
                          move.b           DOUPPER,d4
                          move.b           objInTop(a1),d3
                          eor.b            d4,d3
                          bne.s            notinthiszone

                          move.w           2(a2,d1.w*8),d1                                                               ; zpos
                          move.l           #depthtable-4,a4

********************************************************

stillinfront:
                          addq             #4,a4
                          cmp.w            (a4),d1
                          blt              stillinfront

********************************************************

                          move.l           #enddepthtab-4,a5

finishedshift:
                          move.l           -(a5),4(a5)
                          cmp.l            a4,a5
                          bgt.s            finishedshift

********************************************************

                          move.w           d1,(a4)
                          move.w           d0,2(a4)
 
                          adda.w           #64,a1
                          addq             #1,d0
 
                          bra              insertanobj

********************************************************

sortedall:
                          move.l           #depthtable,a3

gobackanddoanother:
                          move.w           (a3)+,d0
                          ble.s            doneallinfront
 
                          move.w           (a3)+,d0
                          bsr              DrawtheObject

                          bra              gobackanddoanother

********************************************************

doneallinfront
                          movem.l          (a7)+,d0-d7/a1-a6
                          rts

*********************************************************************************************

depthtable:               ds.l             RTGScrHeightOBJECT                                                            ;80
enddepthtab:

*********************************************************************************************

DrawtheObject:

                          movem.l          d0-d7/a0-a6,-(a7)
  
                          move.l           ObjectData,a0
                          lea              ObjRotated,a1
                          asl.w            #6,d0
                          adda.w           d0,a0
 
                          move.w           (a0),d0
                          move.w           2(a1,d0.w*8),d1                                                               ; z pos
 
                          move.w           leftclip,leftclipb                                                            ; Use own clip
                          move.w           rightclip,rightclipb
 
                          cmp.b            #$ff,6(a0)
                          bne              BitMapObj

                          bsr              PolygonObj

                          GETREGS
                          rts

*********************************************************************************************

glassobj:
                          move.w           (a0)+,d0                                                                      ; pt num
                          move.w           2(a1,d0.w*8),d1
                          cmp.w            #50,d1
                          ble              objbehind
 
 ********************************************************

                          move.w           topclip,d2
                          move.w           botclip,d3
 
                          move.l           ty3d,d6
                          sub.l            yoff,d6
                          divs             d1,d6
                          add.w            #(RTGScrHeightOBJECT/2),d6
                          cmp.w            d3,d6
                          bge              objbehind

********************************************************

                          cmp.w            d2,d6
                          bge.s            .okobtc

                          move.w           d2,d6
                      
.okobtc:
                          move.w           d6,objclipt

                          move.l           by3d,d6
                          sub.l            yoff,d6
                          divs             d1,d6
                          add.w            #(RTGScrHeightOBJECT/2),d6
                          cmp.w            d2,d6
                          ble              objbehind

********************************************************

                          cmp.w            d3,d6
                          ble.s            .okobbc

                          move.w           d3,d6

.okobbc:
                          move.w           d6,objclipb

                          move.l           4(a1,d0.w*8),d0
                          move.l           (a0)+,d2                                                                      ; height
                          ext.l            d2
                          asl.l            #7,d2                                                                         ; * 128
                          sub.l            yoff,d2

                          divs             d1,d2	
                          add.w            #(RTGScrHeightOBJECT/2)-1,d2                                                  ; (height/2) - 1?
 
                          divs             d1,d0
                          add.w            #(RTGScrWidthOBJECT/2)-1,d0                                                   ; x pos of middle

; Need to calculate:
; Width of object in pixels
; height of object in pixels
; horizontal constants
; vertical constants.

                          move.l           #objectConstTab,a3

                          moveq            #0,d3
                          moveq            #0,d4
                          move.b           (a0)+,d3
                          move.b           (a0)+,d4
                          asl.w            #7,d3                                                                         ; * 128
                          asl.w            #7,d4                                                                         ; * 128
                          divs             d1,d3                                                                         ; width in pixels
                          divs             d1,d4                                                                         ; height in pixels
                          sub.w            d4,d2
                          sub.w            d3,d0
                          
                          cmp.w            rightclipb,d0
                          bge              objbehind

********************************************************

                          add.w            d3,d3
                          cmp.w            objclipb,d2
                          bge              objbehind

********************************************************

                          add.w            d4,d4
 
                          move.w           d3,realwidth
                          move.w           d4,realheight
 
; OBTAIN POINTERS TO HORIZ AND VERT CONSTANTS FOR MOVING ACROSS AND DOWN THE OBJECT GRAPHIC.
 
                          move.w           d1,d7
                          moveq            #0,d6
                          move.b           6(a0),d6
                          add.w            d6,d6
                          mulu             d6,d7
                          move.b           -2(a0),d6
                          divu             d6,d7
                          swap             d7
                          clr.w            d7
                          swap             d7

                          lea              (a3,d7.l*8),a2                                                                ; pointer to horiz const
                          move.w           d1,d7
                          move.b           7(a0),d6
                          add.w            d6,d6
                          mulu             d6,d7
                          move.b           -1(a0),d6
                          divu             d6,d7
                          swap             d7
                          clr.w            d7
                          swap             d7
                          lea              (a3,d7.l*8),a3                                                                ; pointer to vertical c.

; CLIP OBJECT TO TOP AND BOTTOM OF THE VISIBLE DISPLAY

                          moveq            #0,d7
                          cmp.w            objclipt,d2
                          bge.s            .objfitsontop

                          sub.w            objclipt,d2
                          add.w            d2,d4                                                                         ; new height in pixels
                          ble              objbehind                                                                     ; nothing to draw

********************************************************

                          move.w           d2,d7
                          neg.w            d7                                                                            ; factor to mult. constants by at top of obj.
                          move.w           objclipt,d2

.objfitsontop:
                          move.w           objclipb,d6
                          sub.w            d2,d6
                          cmp.w            d6,d4
                          ble.s            .objfitsonbot
 
                          move.w           d6,d4

.objfitsonbot:
                          subq             #1,d4
                          blt              objbehind

********************************************************

                          move.l           #onToScr,a6
                          move.l           (a6,d2.w*4),d2

                          movem.l          a0,-(a7) 
                          lea              AB3dChunkyBufferOBJECT,a0
                          add.l            a0,d2	
                          movem.l          (a7)+,a0
                          
                          move.l           d2,topPt 
 
                          move.l           #WorkSpace,a5
                          move.l           #glassballData,a4
                          cmp.w            leftclipb,d0
                          bge.s            .okonleft

                          sub.w            leftclipb,d0
                          add.w            d0,d3
                          ble              objbehind
 
 ********************************************************

                          move.w           (a2),d1
                          move.w           2(a2),d2
                          neg.w            d0
                          muls             d0,d1
                          mulu             d0,d2
                          swap             d2
                          add.w            d2,d1
                          asl.w            #7,d1
                          lea              (a5,d1.w),a5
                          lea              (a4,d1.w),a4
 
                          move.w           leftclipb,d0

.okonleft:
                          move.w           d0,d6
                          add.w            d3,d6
                          sub.w            rightclipb,d6
                          blt.s            .okrightside

                          sub.w            #1,d3
                          sub.w            d6,d3

.okrightside:
                          move.l           #objintocop,a1
                          lea              (a1,d0.w*2),a1

                          move.w           (a3),d5
                          move.w           2(a3),d6
                          muls             d7,d5
                          mulu             d7,d6
                          swap             d6
                          add.w            d6,d5

********************************************************
                        ; add.w 2(a0),d5	; d5 contains top offset into each strip.
********************************************************

                          add.l            #$80000000,d5
 	
                          move.l           (a2),d6
                          moveq.l          #0,d7
                          move.l           a5,midobj
                          move.l           a4,midglass
                          move.l           (a3),d2
                          swap             d2
                          move.l           #times128,a0

                          SAVEREGS  
 
                          move.w           d3,d1
                          ext.l            d1
                          swap             d1
                          move.w           d4,d2
                          ext.l            d2
                          swap             d2
                          asr.l            #6,d1
                          asr.l            #6,d2
                          move.w           d1,d5
                          move.w           d2,d6
                          swap             d1
                          add.w            d1,d1
                          swap             d2

                          muls             #RTGScrWidthByteOffsetOBJECT,d2

                          move.l           #WorkSpace,a0
                          move.w           #63,d0

********************************************************
; Loop

.readinto:
                          swap             d0
                          move.w           #63,d0
                          move.l           topPt(pc),a6
                          adda.w           (a1),a6
                          add.w            d1,a1                                                                         ; .w add OK
                          add.w            d5,d7
                          bcc.s            .noadmoreh
                          addq             #2,a1                                                                         ; .w add OK

.noadmoreh:
                          swap             d7
                          move.w           #0,d7

********************************************************
; Loop

.readintodown:
                          move.w           (a6),d3                                                                       ; a6 = Chunky ptr
                          move.w           d3,(a0)+
                          add.w            d2,a6                                                                         ; a6 = Chunky ptr, d2 = ToDo

                          add.w            d6,d7
                          bcc.s            .noadmore

                          adda.l           #RTGScrWidthByteOffsetOBJECT,a6

.noadmore:
                          dbra             d0,.readintodown
                          swap             d0
                          swap             d7
                          dbra             d0,.readinto

                          GETREGS

********************************************************

                          move.l           #darkentab,a2

.drawrightside:
                          swap             d7
                          move.l           midglass(pc),a4
                          adda.w           (a0,d7.w*2),a4
                          swap             d7
                          add.l            d6,d7

                          move.l           topPt(pc),a6
                          adda.w           (a1)+,a6

                          move.l           d5,d1

                          move.w           d4,-(a7)
                          swap             d3

********************************************************

.drawavertstrip:
                          move.w           (a4,d1.w*2),d3
                          blt.s            .itsbackground

                          move.w           (a5,d3.w*2),d3
                          
                          movem.l          d2,-(a7)  
                          move.w           (a2,d3.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a6)                                                                       ; To RTG Buffer
                          movem.l          (a7)+,d2

.itsbackground:
                          adda.l           #RTGScrWidthByteOffsetOBJECT,a6

                          addx.l           d2,d1
                          dbra             d4,.drawavertstrip

********************************************************

                          swap             d3
                          move.w           (a7)+,d4

                          dbra             d3,.drawrightside

********************************************************

                          GETREGS

                          rts

*********************************************************************************************

realwidth:                dc.w             0
realheight:               dc.w             0

*********************************************************************************************

midglass:                 dc.l             0

*********************************************************************************************

times128:
val                       SET              0
                          REPT             100
                          dc.w             val*128
val                       SET              val+1
                          ENDR

*********************************************************************************************

BitMapObj:

                          tst.l            8(a0)
                          blt              glassobj
 
                          move.w           (a0)+,d0                                                                      ; pt num
                          move.w           2(a1,d0.w*8),d1
                          cmp.w            #50,d1
                          ble              objbehind
 
 ********************************************************

                          move.w           topclip,d2
                          move.w           botclip,d3
 
                          move.l           ty3d,d6
                          sub.l            yoff,d6
                          divs             d1,d6
                          add.w            #RTGScrHeightOBJECT/2,d6
                          cmp.w            d3,d6
                          bge              objbehind

********************************************************

                          cmp.w            d2,d6
                          bge.s            .okobtc
                          move.w           d2,d6
.okobtc:
                          move.w           d6,objclipt

                          move.l           by3d,d6
                          sub.l            yoff,d6
                          divs             d1,d6
                          add.w            #RTGScrHeightOBJECT/2,d6
                          cmp.w            d2,d6
                          ble              objbehind

********************************************************

                          cmp.w            d3,d6
                          ble.s            .okobbc

                          move.w           d3,d6

.okobbc:
                          move.w           d6,objclipb

                          move.l           4(a1,d0.w*8),d0
                          move.w           d1,d6
                          asr.w            #7,d6
                          add.w            (a0)+,d6
                          bge.s            brighttoonot
                          moveq            #0,d6
brighttoonot
                          sub.l            a4,a4
                          move.w           objscalecols(pc,d6.w*2),a4
                          bra              pastobjscale

*********************************************************************************************

objscalecols:
                          dcb.w            2,64*0
                          dcb.w            4,64*1
                          dcb.w            4,64*2
                          dcb.w            4,64*3
                          dcb.w            4,64*4
                          dcb.w            4,64*5
                          dcb.w            4,64*6
                          dcb.w            4,64*7
                          dcb.w            4,64*8
                          dcb.w            4,64*9
                          dcb.w            4,64*10
                          dcb.w            4,64*11
                          dcb.w            4,64*12
                          dcb.w            4,64*13
                          dcb.w            20,64*14

*********************************************************************************************

pastobjscale:

                          move.w           (a0)+,d2                                                                      ; height
                          ext.l            d2
                          asl.l            #7,d2
                          sub.l            yoff,d2
                          divs             d1,d2	
                          add.w            #(RTGScrHeightOBJECT/2)-1,d2                                                  ; (height/2) - 1?  
 
                          divs             d1,d0
                          add.w            #(RTGScrWidthOBJECT/2)-1,d0                                                   ; (width/2) - 1? x pos of middle

; Need to calculate:
; Width of object in pixels
; height of object in pixels
; horizontal constants
; vertical constants.

                          move.l           #objectConstTab,a3

                          moveq            #0,d3
                          moveq            #0,d4
                          move.b           (a0)+,d3
                          move.b           (a0)+,d4
                          lsl.w            #7,d3
                          lsl.w            #7,d4
                          divs             d1,d3                                                                         ; width in pixels
                          divs             d1,d4                                                                         ; height in pixels
                          sub.w            d4,d2
                          sub.w            d3,d0
                          cmp.w            rightclipb,d0
                          bge              objbehind

********************************************************

                          add.w            d3,d3
                          cmp.w            objclipb,d2
                          bge              objbehind

********************************************************

                          add.w            d4,d4
 
; OBTAIN POINTERS TO HORIZ AND VERT CONSTANTS FOR MOVING ACROSS AND DOWN THE OBJECT GRAPHIC.

                          move.l           #Objects,a5
                          move.w           (a0),d7
                          asl.w            #4,d7
                          adda.w           d7,a5                                                                         ; ptr to object data.
                          move.l           (a5)+,WAD_PTR
                          move.l           (a5)+,PTR_PTR
                          add.l            4(a5),a4
                          move.l           (a5),a5 
                          move.w           2(a0),d7
                          move.l           (a5,d7.w*4),d7
                          move.w           d7,DOWN_STRIP
                          move.l           PTR_PTR,a5
                          swap             d7
                          adda.w           d7,a5
 
                          move.w           d1,d7
                          moveq            #0,d6
                          move.b           6(a0),d6
                          add.w            d6,d6
                          mulu             d6,d7
                          moveq            #0,d6
                          move.b           -2(a0),d6
                          divu             d6,d7
                          swap             d7
                          clr.w            d7
                          swap             d7
                          lea              (a3,d7.l*8),a2                                                                ; pointer to horiz const
                          move.w           d1,d7
                          move.b           7(a0),d6
                          add.w            d6,d6
                          mulu             d6,d7
                          moveq            #0,d6
                          move.b           -1(a0),d6
                          divu             d6,d7
                          swap             d7
                          clr.w            d7
                          swap             d7
                          lea              (a3,d7.l*8),a3                                                                ; pointer to vertical c.

; CLIP OBJECT TO TOP AND BOTTOM OF THE VISIBLE DISPLAY

                          moveq            #0,d7
                          cmp.w            objclipt,d2
                          bge.s            objfitsontop

                          sub.w            objclipt,d2
                          add.w            d2,d4                                                                         ;new height in pixels
                          ble              objbehind                                                                     ; nothing to draw

********************************************************

                          move.w           d2,d7
                          neg.w            d7                                                                            ; factor to mult. constants by at top of obj.
                          move.w           objclipt,d2

objfitsontop:
                          move.w           objclipb,d6
                          sub.w            d2,d6
                          cmp.w            d6,d4
                          ble.s            objfitsonbot
 
                          move.w           d6,d4

objfitsonbot:
                          subq             #1,d4
                          blt              objbehind

********************************************************

                          move.l           #onToScr,a6
                          move.l           (a6,d2.w*4),d2
                          movem.l          a0,-(a7) 
                          lea              AB3dChunkyBufferOBJECT,a0
                          add.l            a0,d2
                          movem.l          (a7)+,a0
                          move.l           d2,topPt

                          cmp.w            leftclipb,d0
                          bge.s            okonleft

                          sub.w            leftclipb,d0
                          add.w            d0,d3
                          ble              objbehind
 
 ********************************************************

                          move.w           (a2),d1
                          move.w           2(a2),d2
                          neg.w            d0
                          muls             d0,d1
                          mulu             d0,d2
                          swap             d2
                          add.w            d2,d1
                          lea              (a5,d1.w*4),a5
 
                          move.w           leftclipb,d0

okonleft:
                          move.w           d0,d6
                          add.w            d3,d6
                          sub.w            rightclipb,d6
                          blt.s            okrightside

                          sub.w            #1,d3
                          sub.w            d6,d3

okrightside:
                          move.l           #objintocop,a1                                                                ; XTOCOPX
                          lea              (a1,d0.w*2),a1

                          move.w           (a3),d5
                          move.w           2(a3),d6
                          muls             d7,d5
                          mulu             d7,d6
                          swap             d6
                          add.w            d6,d5
                          add.w            DOWN_STRIP(PC),d5                                                             ; d5 contains top offset into each strip.
                          add.l            #$80000000,d5
 	
                          move.l           (a2),a2
                          moveq.l          #0,d7
                          move.l           a5,midobj
                          move.l           (a3),d2
                          swap             d2

********************************************************

drawrightside:
                          swap             d7
                          move.l           midobj(pc),a5
                          lea              (a5,d7.w*4),a5
                          swap             d7
                          add.l            a2,d7
                          move.l           WAD_PTR(PC),a0

                          move.l           topPt(pc),a6

                          adda.w           (a1)+,a6

                          move.l           (a5),d1
                          beq              blankstrip
 
                          and.l            #$ffffff,d1
                          add.l            d1,a0

                          move.b           (a5),d1
                          cmp.b            #1,d1
                          bgt              ThirdThird
                          beq.s            SecThird

                          move.l           d5,d6
                          move.l           d5,d1
                          move.w           d4,-(a7)

.drawavertstrip
                          move.b           1(a0,d1.w*2),d0
                          and.b            #%00011111,d0
                          beq.s            .dontplotthisoneitsblack
                          
                          movem.l          d2,-(a7)  
                          move.w           (a4,d0.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a6)                                                                       ; To RTG Buffer
                          movem.l          (a7)+,d2

.dontplotthisoneitsblack:
                          adda.l           #RTGScrWidthByteOffsetOBJECT,a6

                          add.l            d2,d6
                          addx.w           d2,d1
                          dbra             d4,.drawavertstrip
                          move.w           (a7)+,d4

blankstrip:
                          dbra             d3,drawrightside

                          bra              objbehind

********************************************************

SecThird:
                          move.l           d5,d1
                          move.l           d5,d6
                          move.w           d4,-(a7)

.drawavertstrip
                          move.w           (a0,d1.w*2),d0
                          lsr.w            #5,d0
                          and.w            #%11111,d0
                          beq.s            .dontplotthisoneitsblack

                          movem.l          d2,-(a7)  
                          move.w           (a4,d0.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a6)                                                                       ; To RTG Buffer
                          movem.l          (a7)+,d2

.dontplotthisoneitsblack:
                          adda.l           #RTGScrWidthByteOffsetOBJECT,a6

                          add.l            d2,d6
                          addx.w           d2,d1
                          dbra             d4,.drawavertstrip

                          move.w           (a7)+,d4
                          dbra             d3,drawrightside

                          bra.s            objbehind

********************************************************

ThirdThird:
                          move.l           d5,d1
                          move.l           d5,d6
                          move.w           d4,-(a7)

.drawavertstrip
                          move.b           (a0,d1.w*2),d0
                          lsr.b            #2,d0
                          and.b            #%11111,d0
                          beq.s            .dontplotthisoneitsblack

                          movem.l          d2,-(a7)  
                          move.w           (a4,d0.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a6)                                                                       ; To RTG Buffer
                          movem.l          (a7)+,d2

.dontplotthisoneitsblack:
                          adda.l           #RTGScrWidthByteOffsetOBJECT,a6

                          add.l            d2,d6
                          addx.w           d2,d1
                          dbra             d4,.drawavertstrip

                          move.w           (a7)+,d4
                          dbra             d3,drawrightside
 
objbehind:
                          GETREGS
                          rts

*********************************************************************************************

midx:                     dc.w             0
objpixwidth:              dc.w             0
tmptst:                   dc.l             0
topPt:                    dc.l             0
doneit:                   dc.w             0
replaceend:               dc.w             0
saveend:                  dc.w             0
midobj:                   dc.l             0
obadd:                    dc.l             0 
DOWN_STRIP:               dc.w             0
WAD_PTR:                  dc.l             0
PTR_PTR:                  dc.l             0

*********************************************************************************************

                          ds.w             2*100
objintocop:               include          "data/rtg/helper/xtocopx.s"
                          ds.w             2*100

*********************************************************************************************

objBright:                dc.w             0
objAng:                   dc.w             0

*********************************************************************************************
*********************************************************************************************
; Handle vector object - exit

polybehind:               rts

*********************************************************************************************
; Handle vector object 

PolygonObj:
; a0 = object data 
; a1 = Object rotated

***************************************************************
                        ; move.w 4(a0),d0	; ypos
                        ; move.w 2(a0),d1
                        ; add.w #2,d1
                        ; add.w d1,d0
                        ; cmp.w #-48,d0
                        ; blt nobounce
                        ; neg.w d1
                        ; add.w d1,d0
                        ;nobounce:
                        ; move.w d1,2(a0)
                        ; move.w d0,4(a0)

                        ; add.w #80*2,boxang
                        ; and.w #8191,boxang
***************************************************************

                          move.w           objVectFacing(a0),objAng

                          move.w           (a0)+,d0                                                                      ; objVectUnknown0
                          move.w           2(a1,d0.w*8),d1                                                               ; zpos of mid
                          ble              polybehind

                          move.w           (a0),d2                                                                       ; objVectBright                      
                          move.w           d1,d3
                          asr.w            #7,d3
                          add.w            d3,d2
                          move.w           d2,objBright

                          move.w           topclip,d2
                          move.w           botclip,d3
 
                          move.w           d2,objclipt
                          move.w           d3,objclipb

***************************************************************
; Dont use d1 here.

                          move.w           6(a0),d5                                                                      ; objVectNumber - Vector object number (d5)
                          move.l           #POLYOBJECTS,a3
                          move.l           (a3,d5.w*4),a3
                          move.l           a3,START_OF_OBJ

                          move.w           (a3)+,num_points
                          move.w           (a3)+,d6                                                                      ; num_frames
 
                          move.l           a3,POINTER_TO_POINTERS
                          lea              (a3,d6.w*2),a3
                          move.l           a3,LinesPtr
 
                          moveq            #0,d5               
                          move.l           POINTER_TO_POINTERS,a4
                          move.w           (a4,d5.w*2),d5
                          add.l            START_OF_OBJ,d5
                          move.l           d5,PtsPtr
                          move.l           d5,a3

                          move.w           num_points,d5
                          subq             #1,d5

                          move.l           #boxrot,a4
 
                          move.w           objAng,d2
                          sub.w            #2048,d2
                          sub.w            angpos,d2
                          and.w            #8191,d2
                          move.l           #SineTable,a2
                          lea              (a2,d2.w),a5
                          move.l           #boxbrights,a6
 	
                          move.w           (a5),d6
                          move.w           2048(a5),d7
 		
rotobj:
                          move.w           (a3),d2                                                                       ; xpt
                          move.w           2(a3),d3                                                                      ; ypt
                          move.w           4(a3),d4                                                                      ; zpt
 
                          add.w            d2,d2
                          add.w            d3,d3
                          add.w            d4,d4

                          muls             d7,d4
                          muls             d6,d2
                          sub.l            d4,d2
                          asr.l            #8,d2
                          move.l           d2,(a4)+
                          ext.l            d3
                          asl.l            #7,d3
                          move.l           d3,(a4)+
                          move.w           (a3),d2
                          move.w           4(a3),d4
                          muls             d6,d4
                          muls             d7,d2
                          add.l            d2,d4
                          add.l            d4,d4
                          add.l            d4,d4
                          swap             d4
                          move.w           d4,(a4)+

                          add.w            #20,d4
                          asr.w            #2,d4

                          move.w           d4,(a6)+

                          addq             #6,a3
                          dbra             d5,rotobj 

***************************************************************

                          move.l           4(a1,d0.w*8),d0                                                               ; xpos of mid

                          move.w           num_points,d7
                          move.l           #boxrot,a2
                          move.l           #boxonscr,a3
                          move.l           #boxbrights,a6
                          move.w           2(a0),d2                                                                      ; objVectUnknown4
                          subq             #1,d7
 
                          ext.l            d2
                          asl.l            #7,d2
                          sub.l            yoff,d2

convtoscr:
                          move.l           (a2),d3
                          add.l            d0,d3
                          move.l           d3,(a2)+
                          move.l           (a2),d4
                          add.l            d2,d4
                          move.l           d4,(a2)+
                          move.w           (a2),d5
                          add.w            d1,d5
                          ble              polybehind

                          move.w           d5,(a2)+
 
                          divs             d5,d3
                          divs             d5,d4
                          add.w            #(RTGScrWidthOBJECT/2)-1,d3
                          add.w            #RTGScrHeightOBJECT/2,d4
                          move.w           d3,(a3)+
                          move.w           d4,(a3)+

***************************************************************

                          move.w           (a6),d3
 
                          cmp.w            #13,d3
                          ble.s            okdark

                          move.w           #13,d3

okdark:
                          cmp.w            #0,d3
                          bge.s            okbr

                          move.w           #0,d3

okbr:
                          move.w           d3,(a6)+
                          dbra             d7,convtoscr

***************************************************************

                          move.l           LinesPtr,a1

***************************************************************
; Now need to sort parts of object into order.

                          move.l           #PartBuffer,a0
                          move.l           a0,a2
                          move.w           #31,d0

clrpartbuff:
                          move.w           #$8001,(a2)                                                                   ; %100000000 00000001
                          addq             #4,a2          
                          dbra             d0,clrpartbuff

                          move.l           #boxrot,a2
 
PutinParts:
                          move.w           (a1)+,d7
                          blt              doneallparts

                          move.w           (a1)+,d6
                          move.l           (a2,d6.w),d0
                          asr.l            #7,d0
                          muls             d0,d0
                          move.l           4(a2,d6.w),d2
                          asr.l            #7,d2
                          muls             d2,d2
                          add.l            d2,d0 
                          move.w           8(a2,d6.w),d2
                          muls             d2,d2
                          add.l            d2,d0

                          move.l           #PartBuffer-8,a0

stillfront:
                          addq             #8,a0
                          cmp.l            (a0),d0
                          blt              stillfront
                          move.l           #endparttab-8,a5

domoreshift:
                          move.l           -8(a5),(a5)
                          move.l           -4(a5),4(a5)
                          subq             #8,a5
                          cmp.l            a0,a5
                          bgt.s            domoreshift

                          move.l           d0,(a0)
                          move.w           d7,4(a0)

                          bra              PutinParts

doneallparts:
                          move.l           #PartBuffer,a0

Partloop:
                          move.l           (a0)+,d7
                          blt              nomoreparts

***************************************************************

                          moveq            #0,d0
                          move.w           (a0),d0
                          addq             #4,a0
                          add.l            START_OF_OBJ,d0
                          move.l           d0,a1
                          move.w           #0,firstpt

polyloo:
                          tst.w            (a1)                                                                          ; a1 = ?
                          blt.s            nomorepolys

                          movem.l          a0/a1/d7,-(a7)
                          bsr              doapoly
                          movem.l          (a7)+,a0/a1/d7
 
                          move.w           (a1),d0
                          lea              18(a1,d0.w*4),a1
 
                          bra.s            polyloo

***************************************************************

nomorepolys:
                          bra              Partloop

***************************************************************

nomoreparts:
                          rts

*********************************************************************************************

firstpt:                  dc.w             0

PartBuffer:               ds.w             2*32
endparttab:

polybright:               dc.l             0

*********************************************************************************************

doapoly:
; Draw vector object to screen
; a1 = Object ptr
; a6 = copper list
; a0 = PartBuffer

                          move.w           #960,Left
                          move.w           #-10,Right
 
                          move.w           (a1)+,d7                                                                      ; lines to draw 
                          move.w           (a1)+,preholes
                          move.w           12(a1,d7.w*4),pregour

                          move.l           #boxonscr,a3
                          move.w           firstpt(pc),d0
                          lea              (a3,d0.w*4),a3

                          move.w           (a1),d0                                                                       
                          move.w           4(a1),d1                                                                      
                          move.w           8(a1),d2

                          move.w           2(a3,d0.w*4),d3
                          move.w           2(a3,d1.w*4),d4
                          move.w           2(a3,d2.w*4),d5

                          move.w           (a3,d0.w*4),d0
                          move.w           (a3,d1.w*4),d1
                          move.w           (a3,d2.w*4),d2

                          sub.w            d1,d0                                                                         ;x1
                          sub.w            d1,d2                                                                         ;x2
                          sub.w            d4,d3                                                                         ;y1
                          sub.w            d4,d5                                                                         ;y2

                          muls             d3,d2
                          muls             d5,d0
                          sub.l            d0,d2
                          ble              polybehind

                          move.l           d2,polybright

********************************************************************

                          clr.b            drawit

                          tst.b            Gouraud(pc)
                          bne.s            usegour

                          bsr              putinlines

                          bra.s            dontusegour

********************************************************************

usegour:
                          bsr              putingourlines

********************************************************************

dontusegour:
                          move.w           #RTGScrWidthByteOffsetOBJECT,linedir
                          lea              AB3dChunkyBufferOBJECT,a6                                                     ; Copper chunky

                          tst.b            drawit(pc)
                          beq              polybehind

********************************************************************

                          move.l           #PolyTopTab,a4
                          move.w           Left(pc),d1
                          move.w           Right(pc),d7

                          move.w           leftclipb,d3
                          move.w           rightclipb,d4
                          cmp.w            d3,d7
                          ble              polybehind

********************************************************************

                          cmp.w            d4,d1
                          bge              polybehind

********************************************************************

                          cmp.w            d3,d1
                          bge              .notop
                          move.w           d3,d1

.notop
                          cmp.w            d4,d7
                          ble              .nobot
                          move.w           d4,d7

.nobot
 
 *******************************************************

                          lea              (a4,d1.w*8),a4
                          sub.w            d1,d7
                          ble              polybehind

********************************************************************

                          move.l           #objintocop,a2
                          lea              (a2,d1.w*2),a2

                          moveq            #0,d0

                          move.w           (a1)+,a0                                                                      ; a1 = object ptr
                          add.l            #TextureMaps,a0

                          move.l           polybright,d1
                          asl.l            #3,d1                                                                         ; * 8
                          divs             (a1)+,d1
 
                          tst.b            Holes
                          bne              gotholesin

                          tst.b            Gouraud(pc)
                          bne              gotlurvelyshading

********************************************************************

                          move.l           #objscalecols,a1
                          neg.w            d1
                          add.w            #14,d1
                          move.w           objBright(pc),d0
                          add.w            d0,d1
                          bge.s            toobright

                          move.w           #0,d1

toobright:
                          move.w           (a1,d1.w*2),d1
                          asl.w            #3,d1                                                                         ; * 8

********************************************************************

                          move.l           #TexturePal,a1
                          add.w            d1,a1                    

********************************************************************

dopoly:
                          move.w           #0,offtopby

                          move.l           a6,a3                                                                         ; a3 = Copper chunky
                          adda.w           (a2)+,a3

                          move.w           (a4),d1
                          cmp.w            objclipb,d1
                          bge              nodl

                          move.w           PolyBotTab-PolyTopTab(a4),d2

                          cmp.w            objclipt,d2
                          ble              nodl

                          cmp.w            objclipt,d1
                          bge.s            nocl

                          move.w           objclipt,d3
                          sub.w            d1,d3
                          move.w           d3,offtopby
                          move.w           objclipt,d1

nocl: 
                          move.w           d2,d0
                          cmp.w            objclipb,d2
                          ble.s            nocr
                          move.w           objclipb,d2

nocr:
                     ; d1=top end
                     ; d2=bot end
	
                          move.w           2+PolyBotTab-PolyTopTab(a4),d3
                          move.w           4+PolyBotTab-PolyTopTab(a4),d4
	
                          moveq            #0,d5
                          move.w           2(a4),d5
                          move.w           4(a4),d6
 
                          sub.w            d5,d3
                          sub.w            d6,d4
 
                          asl.w            #8,d3
                          asl.w            #8,d4
                          ext.l            d3
                          ext.l            d4
 
                          and.b            #63,d5
                          and.b            #63,d6
                          lsl.w            #8,d6
                          move.b           d5,d6                                                                         ; starting pos
                          moveq.l          #0,d5
                          move.w           d6,d5
 
                          sub.w            d1,d2
                          ble              nodl

                          move.w           #0,tstdca
                          sub.w            d1,d0
                          tst.w            offtopby
                          beq.s            .notofftop
                          move.l           d3,-(a7)
                          move.l           d4,-(a7)
                          add.w            offtopby,d0
 	
                          muls             offtopby,d3
                          muls             offtopby,d4
                          divs             d0,d3
                          divs             d0,d4
                          asl.l            #8,d3
                          asl.l            #8,d4
                          move.w           d3,tstdca
                          swap             d3
                          swap             d4
                          and.w            #63,d3
                          and.w            #63,d4
                          asl.w            #8,d4
                          move.b           d3,d4
                          add.l            d4,d5 
                          move.l           (a7)+,d4
                          move.l           (a7)+,d3

.notofftop: 
                          divs             d0,d3
                          divs             d0,d4
                          ext.l            d3
                          ext.l            d4
                          asl.l            #8,d3
                          asl.l            #8,d4

                          move.w           d3,a5
                          swap             d3
                          swap             d4
                          asl.w            #8,d4
                          move.b           d3,d4
                          move.l           d4,d6
                          add.w            #256,d6
 
                          move.w           tstdca,d3
 
                          add.l            onToScr(pc,d1.w*4),a3

********************************************************************

                          move.w           #63*256+63,d1
                          and.w            d1,d4
                          and.w            d1,d6
                          moveq            #0,d0
                          subq             #1,d2

drawpol:
                          and.w            d1,d5
                          move.b           (a0,d5.w*4),d0                                                                ; a0 = TextureMaps

                          movem.l          d2,-(a7)  
                          move.w           (a1,d0.w*2),d2                                                                ; a1 = TexturePal, to copper screen
                          C12BITTOHICOL
                          move.w           d2,(a3)                                                                       ; To RTG buffer
                          movem.l          (a7)+,d2

                          adda.l           #RTGScrWidthByteOffsetOBJECT,a3

                          add.w            a5,d3
                          addx.l           d6,d5

                          dbcs             d2,drawpol2
                          dbcc             d2,drawpol

                          bra.s            pastit

********************************************************************

drawpol2:
                          and.w            d1,d5
                          move.b           (a0,d5.w*4),d0                                                                ; a0 = TextureMaps

                          movem.l          d2,-(a7)  
                          move.w           (a1,d0.w*2),d2                                                                ; a1 = TexturePal, to copper screen
                          C12BITTOHICOL
                          move.w           d2,(a3)                                                                       ; To RTG buffer
                          movem.l          (a7)+,d2

                          adda.l           #RTGScrWidthByteOffsetOBJECT,a3

                          add.w            a5,d3
                          addx.l           d4,d5
                          dbcs             d2,drawpol2
                          dbcc             d2,drawpol

pastit:
nodl:
                          addq             #8,a4
                          dbra             d7,dopoly

********************************************************************

                          rts

*********************************************************************************************

onToScr:
val                       SET              RTGScrWidthByteOffsetOBJECT
                          REPT             RTGMult*90
                          dc.l             val
val                       SET              val+RTGScrWidthByteOffsetOBJECT
                          ENDR

*********************************************************************************************

tstdca:                   dc.l             0
offtopby:                 dc.w             0
LinesPtr:                 dc.l             0
PtsPtr:                   dc.l             0

*********************************************************************************************

gotlurvelyshading:
; a6 = copper list
; a0 = TextureMaps

                          move.l           #TexturePal,a1

*****************************************************
; Originally commented out
                   
;                      neg.w       d1
;                      add.w       #14,d1
;                      bge.s       toobrightg
;                      move.w      #0,d1

;toobrightg:
;                      asl.w       #8,d1
;                      lea         (a1,d1.w*2),a1
***************************************************** 

dopolyg:
                          move.l           a6,a3
                          move.w           #0,offtopby
                          adda.w           (a2)+,a3
                          move.w           (a4),d1
                          cmp.w            objclipb,d1
                          bge              nodlg
                          moveq            #0,d2
                          move.w           PolyBotTab-PolyTopTab(a4),d2
                          cmp.w            objclipt(pc),d2
                          ble              nodlg
                          cmp.w            objclipt(pc),d1
                          bge.s            noclg
                          move.w           objclipt,d3
                          sub.w            d1,d3
                          move.w           d3,offtopby
                          move.w           objclipt(pc),d1
noclg: 
                          move.w           d2,d0
                          cmp.w            objclipb(pc),d2
                          ble.s            nocrg
                          move.w           objclipb(pc),d2
nocrg:

                     ; d1=top end
                     ; d2=bot end
	
                          move.w           2+PolyBotTab-PolyTopTab(a4),d3
                          move.w           4+PolyBotTab-PolyTopTab(a4),d4
	
                          moveq            #0,d5
                          move.w           2(a4),d5
                          move.w           4(a4),d6
 
                          sub.w            d5,d3
                          sub.w            d6,d4
 
                          asl.w            #8,d3
                          asl.w            #8,d4
                          ext.l            d3
                          ext.l            d4
 
                          and.b            #63,d5
                          and.b            #63,d6
                          lsl.w            #8,d6
                          move.b           d5,d6                                                                         ; starting pos
                          moveq.l          #0,d5
                          move.w           d6,d5
 
                          sub.w            d1,d2
                          ble              nodlg

                          move.w           #0,tstdca
                          sub.w            d1,d0
                          tst.w            offtopby
                          beq.s            .notofftop
                          move.l           d3,-(a7)
                          move.l           d4,-(a7)
                          add.w            offtopby,d0

                          muls             offtopby,d3
                          muls             offtopby,d4
                          divs             d0,d3
                          divs             d0,d4
                          asl.l            #8,d3
                          asl.l            #8,d4
                          move.w           d3,tstdca
                          swap             d3
                          swap             d4
                          and.w            #63,d3
                          and.w            #63,d4
                          asl.w            #8,d4
                          move.b           d3,d4
                          add.l            d4,d5
                          move.l           (a7)+,d4
                          move.l           (a7)+,d3
.notofftop

                          divs             d0,d3
                          divs             d0,d4
                          ext.l            d3
                          ext.l            d4
                          asl.l            #8,d3
                          asl.l            #8,d4

                          add.l            onToScrG(pc,d1.w*4),a3

                          move.w           6+PolyBotTab-PolyTopTab(a4),d1
                          move.w           6(a4),d6
                          sub.w            d6,d1
                          swap             d1
                          clr.w            d1
                          asr.l            #8,d1
                          divs             d0,d1
                          asl.l            #8,d1
                          swap             d1
                          asl.w            #8,d1
 
                          move.w           d3,d0
                          swap             d0
                          move.w           d1,d0
                          move.w           d2,d1
                          move.l           d1,d2
                          move.l           d0,a5
                          move.w           tstdca,d0
                          swap             d0
                          move.w           d6,d0
                          asl.w            #8,d0
                          swap             d3
                          swap             d4
                          asl.w            #8,d4
                          move.b           d3,d4
                          move.l           d4,d6
                          add.w            #256,d6
 
                          moveq            #0,d1
                          move.w           #63*256+63,d1                                                                 ; 16191 = %00111111 00111111
                          and.w            d1,d4
                          and.w            d1,d6

                          dbra             d2,drawpolg

*********************************************************************************************

onToScrG:
val                       SET              RTGScrWidthByteOffsetOBJECT
                          REPT             RTGMult*90
                          dc.l             val
val                       SET              val+RTGScrWidthByteOffsetOBJECT
                          ENDR

*********************************************************************************************

drawpolg: 
                          and.w            #63*256+63,d5                                                                 ; 16191 = %00111111 00111111
                          move.b           (a0,d5.w*4),d0                                                                ; a0 = texturemaps

                          movem.l          d2,-(a7)  
                          move.w           (a1,d0.w*2),d2                                                                ; a1 = texturepal
                          C12BITTOHICOL
                          move.w           d2,(a3)                                                                       ; To RTG buffer
                          movem.l          (a7)+,d2

                          adda.l           #RTGScrWidthByteOffsetOBJECT,a3

                          add.l            d2,d1
                          bcc.s            nonewb
                          add.w            #256,d0                                                                       ; 256 = $100

nonewb:
                          add.l            a5,d0
                          addx.l           d6,d5

                          dbcs             d2,drawpol2g
                          dbcc             d2,drawpolg

                          bra.s            pastitg

*****************************************************

drawpol2g:
                          and.w            #63*256+63,d5                                                                 ; 16191 = %00111111 00111111
                          move.b           (a0,d5.w*4),d0                                                                ; a0 = texturemaps

                          movem.l          d2,-(a7)  
                          move.w           (a1,d0.w*2),d2                                                                ; a1 = texturepal 
                          C12BITTOHICOL
                          move.w           d2,(a3)                                                                       ; To RTG buffer
                          movem.l          (a7)+,d2

                          adda.l           #RTGScrWidthByteOffsetOBJECT,a3

                          add.l            d2,d1
                          bcc.s            nonewb2
                          add.w            #256,d0                                                                       ; 256 = $100

nonewb2:
                          add.l            a5,d0
                          addx.l           d4,d5
                          dbcs             d2,drawpol2g

                          dbcc             d2,drawpolg

pastitg:
nodlg:
                          addq             #8,a4
                          dbra             d7,dopolyg
                          rts

*********************************************************************************************

gotholesin:
                          move.l           #TexturePal,a1

*****************************************************  

                          neg.w            d1
                          add.w            #14,d1
                          bge.s            toobrighth
                          move.w           #0,d1

toobrighth:
                          asl.w            #8,d1
                          lea              (a1,d1.w*2),a1

*****************************************************

dopolyh:
                          move.l           a6,a3
                          adda.w           (a2)+,a3
                          move.w           (a4),d1
                          cmp.w            objclipb,d1
                          bge              nodlh

                          move.w           PolyBotTab-PolyTopTab(a4),d2

                          cmp.w            objclipt,d2
                          ble              nodlh

                          cmp.w            objclipt,d1
                          bge.s            noclh

                          move.w           objclipt,d1

noclh: 
                          move.w           d2,d0
                          cmp.w            objclipb,d2
                          ble.s            nocrh
                          move.w           objclipb,d2

nocrh:

                     ; d1=top end
                     ; d2=bot end
	
                          move.w           2+PolyBotTab-PolyTopTab(a4),d3
                          move.w           4+PolyBotTab-PolyTopTab(a4),d4
	
                          moveq            #0,d5
                          move.w           2(a4),d5
                          move.w           4(a4),d6
 
                          sub.w            d5,d3
                          sub.w            d6,d4
 
                          asl.w            #8,d3
                          asl.w            #8,d4
                          ext.l            d3
                          ext.l            d4
 
                          and.b            #63,d5
                          and.b            #63,d6
                          lsl.w            #8,d6
                          move.b           d5,d6                                                                         ; starting pos
                          moveq            #-1,d5
                          lsr.l            #1,d5
                          move.w           d6,d5
 
                          sub.w            d1,d2
                          ble              nodlh

                          sub.w            d1,d0

                          divs             d0,d3
                          divs             d0,d4
                          ext.l            d3
                          ext.l            d4
                          asl.l            #8,d3
                          asl.l            #8,d4
                          move.w           d3,a5
                          swap             d3
                          swap             d4
                          asl.w            #8,d4
                          move.b           d3,d4
                          move.l           d4,d6
                          add.w            #256,d6
 
                          moveq            #-1,d3
                          lsr.w            #1,d3
 
                          add.l            onToScrH(pc,d1.w*4),a3

                          move.w           #63*256+63,d1
                          and.w            d1,d4
                          and.w            d1,d6
                          moveq            #0,d0
                          subq             #1,d2

drawpolh:
                          and.w            d1,d5
                          move.b           (a0,d5.w*4),d0                                                                ; a0 = texturemap
                          beq.s            dontplot

                          movem.l          d2,-(a7)  
                          move.w           (a1,d0.w*2),d2                                                                ; a1 = texturepal 
                          C12BITTOHICOL
                          move.w           d2,(a3)                                                                       ; To RTG buffer
                          movem.l          (a7)+,d2

dontplot:
                          adda.w           #RTGScrWidthByteOffsetOBJECT,a3

                          add.w            a5,d3
                          addx.l           d6,d5

                          dbcs             d2,drawpol2h
                          dbcc             d2,drawpolh

                          bra.s            pastith

*****************************************************

drawpol2h:
                          and.w            d1,d5
                          move.b           (a0,d5.w*4),d0                                                                ; a0 = texturemap
                          beq.s            dontplot2

                          movem.l          d2,-(a7)  
                          move.w           (a1,d0.w*2),d2                                                                ; a1 = texturepal 
                          C12BITTOHICOL
                          move.w           d2,(a3)                                                                       ; To RTG buffer
                          movem.l          (a7)+,d2

dontplot2:
                          adda.l           #RTGScrWidthByteOffsetOBJECT,a3

                          add.w            a5,d3
                          addx.l           d4,d5
                          dbcs             d2,drawpol2h

                          dbcc             d2,drawpolh

*****************************************************

pastith:
nodlh:
                          addq             #8,a4
                          dbra             d7,dopolyh

                          rts

*********************************************************************************************

onToScrH:
val                       SET              0
                          REPT             RTGMult*90
                          dc.l             val
val                       SET              val+RTGScrWidthByteOffsetOBJECT
                          ENDR
                          EVEN

*********************************************************************************************

pregour:                  dc.b             0
Gouraud:                  dc.b             0
preholes:                 dc.b             0
Holes:                    dc.b             0

*********************************************************************************************

putinlines:
; a1 = Object ptr
; a3 = boxonscr
; 
                          move.w           (a1),d0
                          move.w           4(a1),d1

                          move.w           (a3,d0.w*4),d2
                          move.w           2(a3,d0.w*4),d3
                          move.w           (a3,d1.w*4),d4
                          move.w           2(a3,d1.w*4),d5
 
                          cmp.w            d2,d4
                          beq              thislineflat
                          bgt              thislineontop

                          move.l           #PolyBotTab,a4
                          exg              d2,d4
                          exg              d3,d5
 
                          cmp.w            rightclipb,d2
                          bge              thislineflat
                          cmp.w            leftclipb,d4
                          ble              thislineflat
                          move.w           rightclipb,d6
                          sub.w            d4,d6
                          ble.s            .clipr
                          move.w           #0,-(a7)
                          cmp.w            Right(pc),d4
                          ble.s            .nonewbot
                          move.w           d4,Right
                          bra.s            .nonewbot
 
.clipr:
                          move.w           d6,-(a7)
                          move.w           rightclipb,Right
                          sub.w            #1,Right

.nonewbot:
                          move.w           #0,offleftby
                          move.w           d2,d6
                          cmp.w            leftclipb,d6
                          bge              .okt
                          move.w           leftclipb,d6
                          sub.w            d2,d6
                          move.w           d6,offleftby
                          add.w            d2,d6

.okt:
                          st               drawit
                          lea              (a4,d6.w*8),a4
                          cmp.w            Left(pc),d6
                          bge.s            .nonewtop

                          move.w           d6,Left

.nonewtop:
                          sub.w            d3,d5                                                                         ; dy
                          swap             d3
                          clr.w            d3                                                                            ; d2=xpos
                          sub.w            d2,d4                                                                         ; dx > 0
                          swap             d5
                          clr.w            d5
                          asr.l            #8,d5
                          divs             d4,d5
                          ext.l            d5
                          asl.l            #8,d5                                                                         ; dx constant
                          moveq            #0,d2
                          move.b           2(a1),d2
                          moveq            #0,d6
                          move.b           6(a1),d6
                          sub.w            d6,d2
                          swap             d2
                          swap             d6
                          clr.w            d2
                          clr.w            d6                                                                            ; d6=xbitpos
                          asr.l            #8,d2
                          divs             d4,d2
                          ext.l            d2
                          asl.l            #8,d2                                                                         ; d3=xbitconst
                          move.l           d5,a5                                                                         ; a5=dy constant
                          move.l           d2,a6                                                                         ; a6=xbitconst

                          moveq            #0,d5
                          move.b           3(a1),d5
                          moveq            #0,d2
                          move.b           7(a1),d2
                          sub.w            d2,d5
                          swap             d2
                          swap             d5
                          clr.w            d2                                                                            ; d3=ybitpos
                          clr.w            d5
                          asr.l            #8,d5
                          divs             d4,d5
                          ext.l            d5
                          asl.l            #8,d5                                                                         ; d4=ybitconst


                          add.w            (a7)+,d4
                          sub.w            offleftby(pc),d4
                          blt              thislineflat

                          tst.w            offleftby(pc)
                          beq.s            .noneoffleft
                          move.w           d4,-(a7)
                          move.w           offleftby(pc),d4
                          dbra             d4,.calcnodraw

                          bra              .nodrawoffleft

*****************************************************

.calcnodraw:
                          add.l            a5,d3
                          add.l            a6,d6
                          add.l            d5,d2
                          dbra             d4,.calcnodraw

.nodrawoffleft:
                          move.w           (a7)+,d4

.noneoffleft:
.putinline:
                          swap             d3
                          move.w           d3,(a4)+
                          swap             d3
                          swap             d6
                          move.w           d6,(a4)+
                          swap             d6
                          swap             d2
                          move.w           d2,(a4)
                          addq             #4,a4
                          swap             d2

                          add.l            a5,d3
                          add.l            a6,d6
                          add.l            d5,d2

                          dbra             d4,.putinline

                          bra              thislineflat

*****************************************************

thislineontop:
                          move.l           #PolyTopTab,a4
 
                          cmp.w            rightclipb,d2
                          bge              thislineflat
                          cmp.w            leftclipb,d4
                          ble              thislineflat
                          move.w           rightclipb,d6
                          sub.w            d4,d6
                          ble.s            .clipr
                          move.w           #0,-(a7)
                          cmp.w            Right(pc),d4
                          ble.s            .nonewbot
                          move.w           d4,Right
 
                          bra.s            .nonewbot
 
 *****************************************************

.clipr:
                          move.w           d6,-(a7)
                          move.w           rightclipb,Right
                          sub.w            #1,Right

.nonewbot:
                          move.w           #0,offleftby
                          move.w           d2,d6
                          cmp.w            leftclipb,d6
                          bge              .okt
                          move.w           leftclipb,d6
                          sub.w            d2,d6
                          move.w           d6,offleftby
                          add.w            d2,d6

.okt:
                          st               drawit
                          lea              (a4,d6.w*8),a4
                          cmp.w            Left(pc),d6
                          bge.s            .nonewtop
                          move.w           d6,Left

.nonewtop:
                          sub.w            d3,d5                                                                         ; dy
                          swap             d3
                          clr.w            d3                                                                            ; d2=xpos
                          sub.w            d2,d4                                                                         ; dx > 0
                          swap             d5
                          clr.w            d5
                          asr.l            #8,d5
                          divs             d4,d5
                          ext.l            d5
                          asl.l            #8,d5                                                                         ; dx constant
                          moveq            #0,d2
                          move.b           6(a1),d2
                          moveq            #0,d6
                          move.b           2(a1),d6
                          sub.w            d6,d2
                          swap             d2
                          swap             d6
                          clr.w            d2
                          clr.w            d6                                                                            ; d6=xbitpos
                          asr.l            #8,d2
                          divs             d4,d2
                          ext.l            d2
                          asl.l            #8,d2                                                                         ; d3=xbitconst
                          move.l           d5,a5                                                                         ; a5=dy constant
                          move.l           d2,a6                                                                         ; a6=xbitconst

                          moveq            #0,d5
                          move.b           7(a1),d5
                          moveq            #0,d2
                          move.b           3(a1),d2
                          sub.w            d2,d5
                          swap             d2
                          swap             d5
                          clr.w            d2                                                                            ; d3=ybitpos
                          clr.w            d5
                          asr.l            #8,d5
                          divs             d4,d5
                          ext.l            d5
                          asl.l            #8,d5                                                                         ; d4=ybitconst

                          add.w            (a7)+,d4
                          sub.w            offleftby(pc),d4
                          blt.s            thislineflat

                          tst.w            offleftby(pc)
                          beq.s            .noneoffleft
                          move.w           d4,-(a7)
                          move.w           offleftby(pc),d4
                          dbra             d4,.calcnodraw

                          bra              .nodrawoffleft

*****************************************************

.calcnodraw:
                          add.l            a5,d3
                          add.l            a6,d6
                          add.l            d5,d2
                          dbra             d4,.calcnodraw

.nodrawoffleft:
                          move.w           (a7)+,d4

.noneoffleft:
.putinline:
                          swap             d3
                          move.w           d3,(a4)+
                          swap             d3
                          swap             d6
                          move.w           d6,(a4)+
                          swap             d6
                          swap             d2
                          move.w           d2,(a4)
                          addq             #4,a4
                          swap             d2

                          add.l            a5,d3
                          add.l            a6,d6
                          add.l            d5,d2

                          dbra             d4,.putinline

thislineflat:
                          addq             #4,a1
                          dbra             d7,putinlines

                          addq             #4,a1

                          rts

*********************************************************************************************
*********************************************************************************************

putingourlines:
; a1 = Object ptr
; a3 = boxonscr

                          move.l           #boxbrights,a2
                          move.w           firstpt,d0
                          lea              (a2,d0.w*2),a2

piglloop:
                          move.w           (a1),d0
                          move.w           4(a1),d1

                          move.w           (a3,d0.w*4),d2
                          move.w           2(a3,d0.w*4),d3
                          move.w           (a3,d1.w*4),d4
                          move.w           2(a3,d1.w*4),d5
 
                          cmp.w            d2,d4
                          beq              thislineflatgour
                          bgt              thislineontopgour

                          move.l           #PolyBotTab,a4
                          exg              d2,d4
                          exg              d3,d5
 
                          cmp.w            rightclipb,d2
                          bge              thislineflatgour
                          cmp.w            leftclipb,d4
                          ble              thislineflatgour
                          move.w           rightclipb,d6
                          sub.w            d4,d6
                          ble.s            .clipr
                          move.w           #0,-(a7)
                          cmp.w            Right(pc),d4
                          ble.s            .nonewbot
                          move.w           d4,Right
                          bra.s            .nonewbot
 
.clipr
                          move.w           d6,-(a7)
                          move.w           rightclipb,Right
                          sub.w            #1,Right

.nonewbot:
                          move.w           #0,offleftby
                          move.w           d2,d6
                          cmp.w            leftclipb,d6
                          bge              .okt
                          move.w           leftclipb,d6
                          sub.w            d2,d6
                          move.w           d6,offleftby
                          add.w            d2,d6

.okt:
                          st               drawit
                          lea              (a4,d6.w*8),a4
                          cmp.w            Left(pc),d6
                          bge.s            .nonewtop
                          move.w           d6,Left

.nonewtop:
                          sub.w            d3,d5                                                                         ; dy
                          swap             d3
                          clr.w            d3                                                                            ; d2=xpos
                          sub.w            d2,d4                                                                         ; dx > 0
                          swap             d5
                          clr.w            d5
                          asr.l            #8,d5
                          divs             d4,d5
                          ext.l            d5
                          asl.l            #8,d5                                                                         ; dx constant
                          moveq            #0,d2
                          move.b           2(a1),d2
                          moveq            #0,d6
                          move.b           6(a1),d6
                          sub.w            d6,d2
                          swap             d2
                          swap             d6
                          clr.w            d2
                          clr.w            d6                                                                            ; d6=xbitpos
                          asr.l            #8,d2
                          divs             d4,d2
                          ext.l            d2
                          asl.l            #8,d2                                                                         ; d3=xbitconst
                          move.l           d5,a5                                                                         ; a5=dy constant
                          move.l           d2,a6                                                                         ; a6=xbitconst

                          moveq            #0,d5
                          move.b           3(a1),d5
                          moveq            #0,d2
                          move.b           7(a1),d2
                          sub.w            d2,d5
                          swap             d2
                          swap             d5
                          clr.w            d2                                                                            ; d3=ybitpos
                          clr.w            d5
                          asr.l            #8,d5
                          divs             d4,d5
                          ext.l            d5
                          asl.l            #8,d5                                                                         ; d4=ybitconst

                          move.w           (a2,d1.w*2),d1
                          move.w           (a2,d0.w*2),d0
                          sub.w            d1,d0
                          swap             d0
                          swap             d1
                          clr.w            d0
                          clr.w            d1
                          asr.l            #8,d0
                          divs             d4,d0
                          ext.l            d0
                          asl.l            #8,d0

                          add.w            (a7)+,d4
                          sub.w            offleftby(pc),d4
                          blt              thislineflatgour

                          tst.w            offleftby(pc)
                          beq.s            .noneoffleft
                          move.w           d4,-(a7)
                          move.w           offleftby(pc),d4
                          dbra             d4,.calcnodraw
                          bra              .nodrawoffleft

.calcnodraw:
                          add.l            d0,d1
                          add.l            a5,d3
                          add.l            a6,d6
                          add.l            d5,d2
                          dbra             d4,.calcnodraw

.nodrawoffleft:
                          move.w           (a7)+,d4

.noneoffleft:
.putinline:
                          swap             d3
                          move.w           d3,(a4)+
                          swap             d3
                          swap             d6
                          move.w           d6,(a4)+
                          swap             d6
                          swap             d2
                          move.w           d2,(a4)+
                          swap             d2
                          swap             d1
                          move.w           d1,(a4)+
                          swap             d1

                          add.l            d0,d1
                          add.l            a5,d3
                          add.l            a6,d6
                          add.l            d5,d2

                          dbra             d4,.putinline

                          bra              thislineflatgour
 
thislineontopgour:
                          move.l           #PolyTopTab,a4
 
                          cmp.w            rightclipb,d2
                          bge              thislineflatgour

                          cmp.w            leftclipb,d4
                          ble              thislineflatgour

                          move.w           rightclipb,d6

                          sub.w            d4,d6
                          ble.s            .clipr

                          move.w           #0,-(a7)

                          cmp.w            Right(pc),d4
                          ble.s            .nonewbot

                          move.w           d4,Right

                          bra.s            .nonewbot
 
.clipr:
                          move.w           d6,-(a7)
                          move.w           rightclipb,Right
                          sub.w            #1,Right

.nonewbot:
                          move.w           #0,offleftby
                          move.w           d2,d6

                          cmp.w            leftclipb,d6
                          bge              .okt

                          move.w           leftclipb,d6
                          sub.w            d2,d6
                          move.w           d6,offleftby
                          add.w            d2,d6

.okt:
                          st               drawit
                          lea              (a4,d6.w*8),a4
                          cmp.w            Left(pc),d6
                          bge.s            .nonewtop
                          move.w           d6,Left

.nonewtop:
                          sub.w            d3,d5                                                                         ; dy
                          swap             d3
                          clr.w            d3                                                                            ; d2=xpos
                          sub.w            d2,d4                                                                         ; dx > 0
                          swap             d5
                          clr.w            d5
                          asr.l            #8,d5
                          divs             d4,d5
                          ext.l            d5
                          asl.l            #8,d5                                                                         ; dx constant
                          moveq            #0,d2
                          move.b           6(a1),d2
                          moveq            #0,d6
                          move.b           2(a1),d6
                          sub.w            d6,d2
                          swap             d2
                          swap             d6
                          clr.w            d2
                          clr.w            d6                                                                            ; d6=xbitpos
                          asr.l            #8,d2
                          divs             d4,d2
                          ext.l            d2
                          asl.l            #8,d2                                                                         ; d3=xbitconst
                          move.l           d5,a5                                                                         ; a5=dy constant
                          move.l           d2,a6                                                                         ; a6=xbitconst

                          moveq            #0,d5
                          move.b           7(a1),d5
                          moveq            #0,d2
                          move.b           3(a1),d2
                          sub.w            d2,d5
                          swap             d2
                          swap             d5
                          clr.w            d2                                                                            ; d3=ybitpos
                          clr.w            d5
                          asr.l            #8,d5
                          divs             d4,d5
                          ext.l            d5
                          asl.l            #8,d5                                                                         ; d4=ybitconst

                          move.w           (a2,d1.w*2),d1
                          move.w           (a2,d0.w*2),d0
                          sub.w            d0,d1
                          swap             d0
                          swap             d1
                          clr.w            d0
                          clr.w            d1
                          asr.l            #8,d1
                          divs             d4,d1
                          ext.l            d1
                          asl.l            #8,d1

                          add.w            (a7)+,d4
                          sub.w            offleftby(pc),d4
                          blt.s            thislineflatgour

                          tst.w            offleftby(pc)
                          beq.s            .noneoffleft
                          move.w           d4,-(a7)
                          move.w           offleftby(pc),d4
                          dbra             d4,.calcnodraw
                          bra              .nodrawoffleft

.calcnodraw:
                          add.l            d1,d0
                          add.l            a5,d3
                          add.l            a6,d6
                          add.l            d5,d2
                          dbra             d4,.calcnodraw

.nodrawoffleft:
                          move.w           (a7)+,d4

.noneoffleft:
.putinline:
                          swap             d3
                          move.w           d3,(a4)+
                          swap             d3
                          swap             d6
                          move.w           d6,(a4)+
                          swap             d6
                          swap             d2
                          move.w           d2,(a4)+
                          swap             d2
                          swap             d0
                          move.w           d0,(a4)+
                          swap             d0
 
                          add.l            d1,d0
                          add.l            a5,d3
                          add.l            a6,d6
                          add.l            d5,d2

                          dbra             d4,.putinline

thislineflatgour:
                          addq             #4,a1
                          dbra             d7,piglloop
                          addq             #4,a1
                          rts

*********************************************************************************************

offleftby:                dc.w             0
Left:                     dc.w             0
Right:                    dc.w             0

*********************************************************************************************
*********************************************************************************************

POINTER_TO_POINTERS:      dc.l             0 
START_OF_OBJ:             dc.l             0
num_points:               dc.w             0

*********************************************************************************************

POLYOBJECTS:
                          dc.l             spider_des
                          dc.l             medi_des
                          dc.l             exit_des                                                                      ; agi: from rtg version
                          dc.l             crate_des
                          dc.l             terminal_des
                          dc.l             blue_des                                                                      ; agi: from rtg version
                          dc.l             green_des                                                                     ; agi: from rtg version
                          dc.l             red_des                                                                       ; agi: from rtg version
                          dc.l             yellow_des                                                                    ; agi: from rtg version
                          dc.l             gas_des                                                                       ; agi: from rtg version
 
*********************************************************************************************

spider_des:               incbin           "vectorobjects/robot.vec"
medi_des:                 incbin           "vectorobjects/medipac.vec"
exit_des:                 incbin           "vectorobjects/exitsign.vec"                                                  
crate_des:                incbin           "vectorobjects/crate.vec"
terminal_des:             incbin           "vectorobjects/terminal.vec"
blue_des:                 incbin           "vectorobjects/blueind.vec"                                                   
green_des:                incbin           "vectorobjects/Greenind.vec"                                                  
red_des:                  incbin           "vectorobjects/Redind.vec"                                                    
yellow_des:           ;incbin      "vectorobjects/yellowind.vec"
                          include          "vectorobjects/yellowind.vec.s"                                                 
gas_des:                  incbin           "vectorobjects/gaspipe.vec"                                                   

*********************************************************************************************

boxonscr:                 ds.l             RTGMult*2*250
boxrot:                   ds.l             RTGMult*3*250

boxbrights: 
                          dc.w             0
                          dc.w             12
                          dc.w             12
                          dc.w             12
                          dc.w             12
                          dc.w             0
                          ds.w             50

boxang:                   dc.w             0 

                          ds.w             RTGMult*96*4
PolyBotTab:               ds.w             RTGMult*96*4
                          ds.w             RTGMult*96*4
PolyTopTab:               ds.w             RTGMult*96*4
                          ds.w             RTGMult*96*4

offset:                   dc.w             0
timer:                    dc.w             0

*********************************************************************************************

Objects:
; Lookup table for OBJECT GRAPHIC TYPE
; in object data (offset 8)
;0
                          dc.l             ALIEN_WAD,ALIEN_PTR,ALIEN_FRAMES,ALIEN_PAL
;1
                          dc.l             PICKUPS_WAD,PICKUPS_PTR,PICKUPS_FRAMES,PICKUPS_PAL
;2
                          dc.l             BIGBULLET_WAD,BIGBULLET_PTR,BIGBULLET_FRAMES,BIGBULLET_PAL
;3
                          dc.l             UGLYMONSTER_WAD,UGLYMONSTER_PTR,UGLYMONSTER_FRAMES,UGLYMONSTER_PAL
;4
                          dc.l             FLYINGMONSTER_WAD,FLYINGMONSTER_PTR,FLYINGMONSTER_FRAMES,FLYINGMONSTER_PAL
;5
                          dc.l             KEYS_WAD,KEYS_PTR,KEYS_FRAMES,KEYS_PAL
;6
                          dc.l             ROCKETS_WAD,ROCKETS_PTR,ROCKETS_FRAMES,ROCKETS_PAL
;7
                          dc.l             BARREL_WAD,BARREL_PTR,BARREL_FRAMES,BARREL_PAL
;8
                          dc.l             BIGBULLET_WAD,BIGBULLET_PTR,EXPLOSION_FRAMES,EXPLOSION_PAL
;9
                          dc.l             GUNS_WAD,GUNS_PTR,GUNS_FRAMES,GUNS_PAL
;10:
                          dc.l             MARINE_WAD,MARINE_PTR,MARINE_FRAMES,MARINE_PAL
;11:
                          dc.l             BIGALIEN_WAD,BIGALIEN_PTR,BIGALIEN_FRAMES,BIGALIEN_PAL
;12:
                          dc.l             0,0,LAMPS_FRAMES,LAMPS_PAL
;13:
                          dc.l             0,0,WORM_FRAMES,WORM_PAL
;14:
                          dc.l             0,0,BIGCLAWS_FRAMES,BIGCLAWS_PAL
;15:
                          dc.l             0,0,TREE_FRAMES,TREE_PAL
;16:
                          dc.l             0,0,TOUGHMARINE_FRAMES,TOUGHMARINE_PAL
;17:
                          dc.l             0,0,FLAMEMARINE_FRAMES,FLAMEMARINE_PAL

*********************************************************************************************

ALIEN_WAD:           ; incbin "ALIEN2.wad"
ALIEN_PTR:           ; incbin "ALIEN2.ptr"
ALIEN_FRAMES:
; walking=0-3
                          dc.w             0,0
                          dc.w             64*4,0 
                          dc.w             64*4*2,0
                          dc.w             64*4*3,0
                          dc.w             64*4*4,0
                          dc.w             64*4*5,0
                          dc.w             64*4*6,0
                          dc.w             64*4*7,0
                          dc.w             64*4*8,0
                          dc.w             64*4*9,0
                          dc.w             64*4*10,0
                          dc.w             64*4*11,0
                          dc.w             64*4*12,0
                          dc.w             64*4*13,0
                          dc.w             64*4*14,0
                          dc.w             64*4*15,0
;Exploding=16-31
                          dc.w             4*(64*16),0
                          dc.w             4*(64*16+16),0
                          dc.w             4*(64*16+32),0
                          dc.w             4*(64*16+48),0
 
                          dc.w             4*(64*16),16
                          dc.w             4*(64*16+16),16
                          dc.w             4*(64*16+32),16
                          dc.w             4*(64*16+48),16
 
                          dc.w             4*(64*16),32
                          dc.w             4*(64*16+16),32
                          dc.w             4*(64*16+32),32
                          dc.w             4*(64*16+48),32
 
                          dc.w             4*(64*16),48
                          dc.w             4*(64*16+16),48
                          dc.w             4*(64*16+32),48
                          dc.w             4*(64*16+48),48
;dying=32-33
                          dc.w             64*4*17,0
                          dc.w             64*4*18,0

 
ALIEN_PAL:                incbin           "pal/alien2.pal"
                          even

*********************************************************************************************

PICKUPS_WAD:          ; incbin "Pickups.wad"
PICKUPS_PTR:          ; incbin "PICKUPS.ptr"
PICKUPS_FRAMES:
; medikit=0
                          dc.w             0,0
; big gun=1
                          dc.w             0,32
; bullet=2
                          dc.w             64*4,32
; Ammo=3
                          dc.w             32*4,0 
;battery=4
                          dc.w             64*4,0
;Rockets=5
                          dc.w             192*4,0
;gunpop=6-16
                          dc.w             128*4,0
                          dc.w             (128+16)*4,0
                          dc.w             (128+32)*4,0
                          dc.w             (128+48)*4,0
                          dc.w             128*4,16
                          dc.w             (128+16)*4,16
                          dc.w             (128+32)*4,16
                          dc.w             (128+48)*4,16
                          dc.w             128*4,32
                          dc.w             (128+16)*4,32
                          dc.w             (128+32)*4,32
                          dc.w             (64+16)*4,32
                          dc.w             (64*4),48
                          dc.w             (64+16)*4,48

; RocketLauncher=20
                          dc.w             (64+32)*4,0
 
;grenade = 21-24
                          dc.w             64*4,32
                          dc.w             (64+16)*4,32
                          dc.w             (64+16)*4,48
                          dc.w             64*4,48

; shotgun = 25
                          dc.w             128*4,32

; grenade launcher =26
                          dc.w             256*4,0

; shotgun shells*4=27
                          dc.w             64*3*4,32
; shotgun shells*20=28
                          dc.w             (64*3+32)*4,0
; grenade clip=29
                          dc.w             (64*3+32)*4,32
 
 
PICKUPS_PAL:              incbin           "pal/PICKUPS.PAL"
                          even

*********************************************************************************************

BIGBULLET_WAD:          ; incbin "bigbullet.wad"
BIGBULLET_PTR:          ; incbin "bigbullet.ptr"
BIGBULLET_FRAMES:
                          dc.w             0,0
                          dc.w             0,32
                          dc.w             32*4,0
                          dc.w             32*4,32
                          dc.w             64*4,0
                          dc.w             64*4,32
                          dc.w             96*4,0
                          dc.w             96*4,32
 
                          dc.w             128*4,0
                          dc.w             128*4,32
                          dc.w             32*5*4,0
                          dc.w             32*5*4,32
                          dc.w             32*6*4,0
                          dc.w             32*6*4,32
                          dc.w             32*7*4,0
                          dc.w             32*7*4,32
                          dc.w             32*8*4,0
                          dc.w             32*8*4,32
                          dc.w             32*9*4,0
                          dc.w             32*9*4,32

BIGBULLET_PAL             incbin           "pal/bigbullet.pal"
                          even

*********************************************************************************************

EXPLOSION_FRAMES:
                          dc.w             0,0
                          dc.w             64*4,0
                          dc.w             64*4*2,0
                          dc.w             64*4*3,0
                          dc.w             64*4*4,0
                          dc.w             64*4*5,0
                          dc.w             64*4*6,0
                          dc.w             64*4*7,0
                          dc.w             64*4*8,0

EXPLOSION_PAL             incbin           "pal/explosion.pal"
                          even

*********************************************************************************************
; Missing ugly monster

UGLYMONSTER_WAD:        ; incbin "uglymonster.wad"
UGLYMONSTER_PTR:        ; incbin "uglymonster.ptr"
UGLYMONSTER_FRAMES:   
                          dc.w             0,0

UGLYMONSTER_PAL:          incbin           "pal/uglymonster.pal"
                          even

*********************************************************************************************

FLYINGMONSTER_WAD:      ; incbin "FLYINGalien.wad"
FLYINGMONSTER_PTR:      ; incbin "FLYINGalien.ptr"
FLYINGMONSTER_FRAMES:
                          dc.w             0,0
                          dc.w             64*4,0 
                          dc.w             64*4*2,0 
                          dc.w             64*4*3,0 
                          dc.w             64*4*4,0 
                          dc.w             64*4*5,0 
                          dc.w             64*4*6,0 
                          dc.w             64*4*7,0 
                          dc.w             64*4*8,0 
                          dc.w             64*4*9,0 
                          dc.w             64*4*10,0 
                          dc.w             64*4*11,0 
                          dc.w             64*4*12,0 
                          dc.w             64*4*13,0 
                          dc.w             64*4*14,0 
                          dc.w             64*4*15,0 
                          dc.w             64*4*16,0 
                          dc.w             64*4*17,0 
                          dc.w             64*4*18,0 
                          dc.w             64*4*19,0 
                          dc.w             64*4*20,0 
 
FLYINGMONSTER_PAL:        incbin           "pal/FLYINGalien.pal"
                          even

*********************************************************************************************

KEYS_WAD:               ; incbin "keys.wad"
KEYS_PTR:               ; incbin "KEYS.PTR"
KEYS_FRAMES:
                          dc.w             0,0
                          dc.w             0,32
                          dc.w             32*4,0
                          dc.w             32*4,32

KEYS_PAL:                 incbin           "pal/keys.pal"
                          even

*********************************************************************************************

ROCKETS_WAD:            ; incbin "ROCKETS.wad"
ROCKETS_PTR:            ; incbin "ROCKETS.ptr"
ROCKETS_FRAMES:
;rockets=0 to 3
                          dc.w             0,0
                          dc.w             32*4,0
                          dc.w             0,32
                          dc.w             32*4,32

;Green bullets = 4 to 7
                          dc.w             64*4,0
                          dc.w             (64+32)*4,0
                          dc.w             64*4,32
                          dc.w             (64+32)*4,32

;Blue Bullets = 8 to 11
                          dc.w             128*4,0
                          dc.w             (128+32)*4,0
                          dc.w             128*4,32
                          dc.w             (128+32)*4,32
 
 
ROCKETS_PAL:              incbin           "pal/ROCKETS.pal"
                          even

*********************************************************************************************

BARREL_WAD:             ; incbin "BARREL.wad"
BARREL_PTR:             ; incbin "BARREL.ptr"
BARREL_FRAMES:
                          dc.w             0,0
 
BARREL_PAL:               incbin           "pal/BARREL.pal"
                          even

*********************************************************************************************

GUNS_WAD:               ; incbin "guns.wad"
GUNS_PTR:               ; incbin "GUNS.PTR"
GUNS_FRAMES:

                          dc.w             96*4*20,0
                          dc.w             96*4*21,0
                          dc.w             96*4*22,0
                          dc.w             96*4*23,0
 
                          dc.w             96*4*4,0
                          dc.w             96*4*5,0
                          dc.w             96*4*6,0
                          dc.w             96*4*7,0

                          dc.w             96*4*16,0
                          dc.w             96*4*17,0
                          dc.w             96*4*18,0
                          dc.w             96*4*19,0

                          dc.w             96*4*12,0
                          dc.w             96*4*13,0
                          dc.w             96*4*14,0
                          dc.w             96*4*15,0
 
                          dc.w             96*4*24,0
                          dc.w             96*4*25,0
                          dc.w             96*4*26,0
                          dc.w             96*4*27,0

                          dc.w             0,0
                          dc.w             0,0
                          dc.w             0,0
                          dc.w             0,0

                          dc.w             0,0
                          dc.w             0,0
                          dc.w             0,0
                          dc.w             0,0

                          dc.w             96*4*0,0
                          dc.w             96*4*1,0
                          dc.w             96*4*2,0
                          dc.w             96*4*3,0 

GUNS_PAL:                 incbin           "pal/newgunsinhand.pal"
                          even

*********************************************************************************************

MARINE_WAD:             ; incbin "newMarine.wad"
MARINE_PTR:             ; incbin "newMARINE.ptr"
MARINE_FRAMES:
                          dc.w             0,0
                          dc.w             64*4,0
                          dc.w             (64*2)*4,0
                          dc.w             (64*3)*4,0
                          dc.w             (64*4)*4,0
                          dc.w             (64*5)*4,0
                          dc.w             (64*6)*4,0
                          dc.w             (64*7)*4,0
                          dc.w             (64*8)*4,0
                          dc.w             (64*9)*4,0
                          dc.w             (64*10)*4,0
                          dc.w             (64*11)*4,0
                          dc.w             (64*12)*4,0
                          dc.w             (64*13)*4,0
                          dc.w             (64*14)*4,0
                          dc.w             (64*15)*4,0
                          dc.w             (64*16)*4,0
                          dc.w             (64*17)*4,0
                          dc.w             (64*18)*4,0

MARINE_PAL:               incbin           "pal/newmarine.pal"
                          even

*********************************************************************************************

TOUGHMARINE_FRAMES:
                          dc.w             0,0
                          dc.w             64*4,0
                          dc.w             (64*2)*4,0
                          dc.w             (64*3)*4,0
                          dc.w             (64*4)*4,0
                          dc.w             (64*5)*4,0
                          dc.w             (64*6)*4,0
                          dc.w             (64*7)*4,0
                          dc.w             (64*8)*4,0
                          dc.w             (64*9)*4,0
                          dc.w             (64*10)*4,0
                          dc.w             (64*11)*4,0
                          dc.w             (64*12)*4,0
                          dc.w             (64*13)*4,0
                          dc.w             (64*14)*4,0
                          dc.w             (64*15)*4,0
                          dc.w             (64*16)*4,0
                          dc.w             (64*17)*4,0
                          dc.w             (64*18)*4,0

TOUGHMARINE_PAL:          incbin           "pal/toughmutant.pal"
                          even

*********************************************************************************************

FLAMEMARINE_FRAMES:
                          dc.w             0,0
                          dc.w             64*4,0
                          dc.w             (64*2)*4,0
                          dc.w             (64*3)*4,0
                          dc.w             (64*4)*4,0
                          dc.w             (64*5)*4,0
                          dc.w             (64*6)*4,0
                          dc.w             (64*7)*4,0
                          dc.w             (64*8)*4,0
                          dc.w             (64*9)*4,0
                          dc.w             (64*10)*4,0
                          dc.w             (64*11)*4,0
                          dc.w             (64*12)*4,0
                          dc.w             (64*13)*4,0
                          dc.w             (64*14)*4,0
                          dc.w             (64*15)*4,0
                          dc.w             (64*16)*4,0
                          dc.w             (64*17)*4,0
                          dc.w             (64*18)*4,0

FLAMEMARINE_PAL:          incbin           "pal/flamemutant.pal"
                          even

*********************************************************************************************

BIGALIEN_WAD:           ; incbin "BIGSCARYALIEN.wad"
BIGALIEN_PTR:           ; incbin "BIGSCARYALIEN.ptr"
BIGALIEN_FRAMES:
; walking=0-3
                          dc.w             0,0
                          dc.w             128*4,0
                          dc.w             128*4*2,0
                          dc.w             128*4*3,0

BIGALIEN_PAL:             incbin           "pal/BIGSCARYALIEN.pal"
                          even

*********************************************************************************************

LAMPS_FRAMES:
                          dc.w             0,0

LAMPS_PAL:                incbin           "pal/LAMPS.pal"
                          even

*********************************************************************************************

WORM_FRAMES:
                          dc.w             0,0
                          dc.w             90*4,0
                          dc.w             90*4*2,0
                          dc.w             90*4*3,0
                          dc.w             90*4*4,0
                          dc.w             90*4*5,0
                          dc.w             90*4*6,0
                          dc.w             90*4*7,0
                          dc.w             90*4*8,0
                          dc.w             90*4*9,0
                          dc.w             90*4*10,0
                          dc.w             90*4*11,0
                          dc.w             90*4*12,0
                          dc.w             90*4*13,0
                          dc.w             90*4*14,0
                          dc.w             90*4*15,0
                          dc.w             90*4*16,0
                          dc.w             90*4*17,0
                          dc.w             90*4*18,0
                          dc.w             90*4*19,0
                          dc.w             90*4*20,0

WORM_PAL:                 incbin           "pal/worm.pal"
                          even

*********************************************************************************************

BIGCLAWS_FRAMES:
                          dc.w             0,0
                          dc.w             128*4,0
                          dc.w             128*4*2,0
                          dc.w             128*4*3,0
                          dc.w             128*4*4,0
                          dc.w             128*4*5,0
                          dc.w             128*4*6,0
                          dc.w             128*4*7,0
                          dc.w             128*4*8,0
                          dc.w             128*4*9,0
                          dc.w             128*4*10,0
                          dc.w             128*4*11,0
                          dc.w             128*4*12,0
                          dc.w             128*4*13,0
                          dc.w             128*4*14,0
                          dc.w             128*4*15,0
                          dc.w             128*4*16,0
                          dc.w             128*4*17,0

BIGCLAWS_PAL:             incbin           "pal/bigclaws.pal"
                          even

*********************************************************************************************

TREE_FRAMES:
                          dc.w             0,0
                          dc.w             64*4,0
                          dc.w             64*2*4,0
                          dc.w             64*3*4,0

                          dc.w             0,0
                          dc.w             64*4,0
                          dc.w             64*2*4,0
                          dc.w             64*3*4,0

                          dc.w             0,0
                          dc.w             64*4,0
                          dc.w             64*2*4,0
                          dc.w             64*3*4,0

                          dc.w             0,0
                          dc.w             64*4,0
                          dc.w             64*2*4,0
                          dc.w             64*3*4,0
 
                          dc.w             0,0
                          dc.w             0,0
 
                          dc.w             32*8*4,0
                          dc.w             32*9*4,0
                          dc.w             32*10*4,0
                          dc.w             32*11*4,0
 
TREE_PAL:                 incbin           "pal/tree.pal"
                          even

*********************************************************************************************

ObAdds:                 ; incbin "ALIEN1.ptr"
objpal:                 ; incbin "ALIEN1.pal"

*********************************************************************************************

TextureMaps:              include          "texturemaps/TextureMaps.s"
                          even
                          
TexturePal:               include          "texturemaps/OldTexturePalScaled.s"
                          even

*********************************************************************************************

testval:                  dc.l             0

*********************************************************************************************

objectConstTab:           include          "data/rtg/math/objectconstantfile.s"
                          even

*********************************************************************************************
