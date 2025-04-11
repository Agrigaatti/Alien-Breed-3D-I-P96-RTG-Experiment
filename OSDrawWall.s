*********************************************************************************************

                          opt              P=68020

*********************************************************************************************

                          incdir           "includes"
                          include          "macros.i"
                          include          "AB3DI.i"
                          include          "AB3DIRTG.i"

*********************************************************************************************

                          IFND             ENABLESEEWALL
ENABLESEEWALL             EQU 1
                          ENDC  

*********************************************************************************************

RTGScrWidthWALL           EQU RTGScrWidth
RTGScrWidthByteOffsetWALL EQU RTGScrWidthByteOffset
RTGScrHeightWALL          EQU RTGScrHeight

AB3dChunkyBufferWALL      EQU AB3dChunkyBuffer

Use1X1WALL                EQU USE1X1
Max3dDivWALL              EQU max3DDiv

*********************************************************************************************

WallTextureBrightOff      EQU 300

WallPackLsrA              EQU 5                                                        ; 5 (/ 32)
WallPackLsrB              EQU 2                                                        ; 2 (/ 4)

WallPackAndA              EQU 31                                                       ; 31  
WallPackAndB              EQU 63                                                       ; 63  

*********************************************************************************************


                          IFEQ             Use1X1WALL
WallUseSimpleValue        EQU $b000/2                                                  ; 45056
                          ENDC
                          IFNE             Use1X1WALL
WallUseSimpleValue        EQU $b000                                                    ; 45056
                          ENDc

*********************************************************************************************
; Store offsets

STELeftX                  EQU 0
STERightX                 EQU 2

STELeftBm                 EQU 4
STERightBm                EQU 6

STELeftDist               EQU 8
STERightDist              EQU 10

STELeftTop                EQU 12
STERightTop               EQU 14

STELeftBot                EQU 16
STERightBot               EQU 18

; Gouraud?
STELeftA                  EQU 20
STERightA                 EQU 22

STELeftB                  EQU 24
STERightB                 EQU 26

STELeftC                  EQU 28
STERightC                 EQU 30

*********************************************************************************************

leftclip:                 dc.w             0
rightclip:                dc.w             0

*********************************************************************************************

deftopclip:               dc.w             0                                           ; No direct use
defbotclip:               dc.w             0                                           ; No direct use

********************************************************************************************

wallLeftClip:             dc.w             0
wallRightClip:            dc.w             RTGScrWidthWALL
wallLeftClipAndLast:      dc.w             0

*********************************************************************************************

pointBrightsPtr:          dc.l             0                                           ; Wall uses

midpt:                    dc.l             0
dist1:                    dc.l             0
dist2:                    dc.l             0

valAnd:                   dc.w             0                                           ; Wall uses .w
valShift:                 dc.w             0                                           ; Wall uses .w
horAnd:                   dc.w             0                                           ; Wall uses .w

sinval:                   dc.w             0
cosval:                   dc.w             0

oldxoff:                  dc.w             0
oldzoff:                  dc.w             0

topclip:                  dc.w             0                                           ; Wall uses
botclip:                  dc.w             0                                           ; Wall uses

seethru:                  dc.w             0                                           ; Wall uses


*********************************************************************************************

timesLargeThru:

val                       SET              RTGScrWidthByteOffsetWALL
                          REPT             RTGScrHeightWALL
                          dc.l             val
val                       SET              val+RTGScrWidthByteOffsetWALL
                          ENDR

*********************************************************************************************

totalYOff:                dc.w             0                                           ; .w
wallYOff:                 dc.w             0                                           ; .w

*********************************************************************************************
; Wall polygon

leftend:                  dc.w             0
wallbrightoff:            dc.w             0

*********************************************************************************************
; Wall tiles

PaletteAddr:              dc.l             0
ChunkAddr:                dc.l             0

*********************************************************************************************
*********************************************************************************************
; Main

itsaWallDraw:
                          
                          move.l           #Rotated,a5
                          move.l           #OnScreen,a6
 
                          move.w           (a0)+,d0                                    ; 0 : 
                          move.w           (a0)+,d2                                    ; 2 : 
                          
                          move.w           (a0)+,leftend                               ; 4 :

                          move.w           (a0)+,d5                                    ; 6 :    
                          move.w           (a0)+,d1                                    ; 8 :    
                          asl.w            #4,d1                                       ; * 16
                          move.w           d1,fromTile
 
                          move.w           (a0)+,d1                                    ; 10 : YOffset
                          move.w           d1,totalYOff
 
                          move.w           (a0)+,d1                                    ; 12 : Wall texture nbr
                          move.l           #wallTiles,a3
                          move.l           (a3,d1.w*4),a3
                          move.l           a3,PaletteAddr

                          add.l            #64*32,a3
                          move.l           a3,ChunkAddr
 
                          move.w           ZoneBright,angBright

                          move.b           (a0)+,valAnd+1                     
                          move.b           (a0)+,valShift+1
                          move.w           (a0)+,horAnd

                          move.w           totalYOff,d1
                          add.w            wallYOff,d1

                          IFNE             Use1X1WALL 
                          asr.l            #1,d1                                       ; / 2 Debug 
                          ENDc

                          and.w            valAnd,d1
                          move.w           d1,totalYOff

                          move.l           yoff,d6
                          move.l           (a0)+,topofwall
                          sub.l            d6,topofwall
                          move.l           (a0)+,botofwall
                          sub.l            d6,botofwall
 
                          move.w           (a0)+,wallbrightoff

**************************************************

                          move.l           topofwall,d3
                          cmp.l            botofwall,d3
                          bge              wallfacingaway
 
                          tst.w            6(a5,d0*8)
                          bgt.s            cantell

                          tst.w            6(a5,d2*8)
                          ble              wallfacingaway

                          bra              cliptotestfirstbehind

**************************************************

cantell:
                          tst.w            6(a5,d2*8)
                          ble.s            cliptotestsecbehind
                          
                          bra              pastclip

**************************************************

cliptotestfirstbehind:
                          move.l           (a5,d0*8),d3                                ; a5 = Rotated
                          sub.l            (a5,d2*8),d3
                          move.w           6(a5,d0*8),d6
                          sub.w            6(a5,d2*8),d6
                          divs             d6,d3
                          muls             6(a5,d2*8),d3
                          neg.l            d3
                          add.l            (a5,d2*8),d3

                          move.w           (a6,d2*2),d6
                          sub.w            #(RTGScrWidthWALL/2)-1,d6                   ; (WallWidth/2)-1
                          ext.l            d6
                          cmp.l            d6,d3
                          bge              wallfacingaway

                          bra              cant_tell

**************************************************

                          bra              pastclip

**************************************************

cliptotestsecbehind:
                          move.l           (a5,d2*8),d3
                          sub.l            (a5,d0*8),d3
                          move.w           6(a5,d2*8),d6
                          sub.w            6(a5,d0*8),d6
                          divs             d6,d3
                          muls             6(a5,d0*8),d3
                          neg.l            d3
                          add.l            (a5,d0*8),d3

                          move.w           (a6,d0*2),d6
                          sub.w            #(RTGScrWidthWALL/2)-1,d6                   ; (WallWidth/2)-1
                          ext.l            d6
                          cmp.l            d6,d3
                          ble              wallfacingaway

                          bra              cant_tell

**************************************************

pastclip:
                          move.w           (a6,d0*2),d3
                          cmp.w            #RTGScrWidthWALL-1,d3                       ; width max?
                          bgt              wallfacingaway

                          cmp.w            (a6,d2*2),d3
                          bge              wallfacingaway

                          tst.w            (a6,d2*2)
                          blt.s            wallfacingaway

**************************************************

cant_tell:
                          movem.l          d7/a0/a5/a6,-(a7)
                          
                          move.l           (a5,d0*8),a0
                          move.w           6(a5,d0*8),d1

                          move.l           (a5,d2*8),a2
                          move.w           6(a5,d2*8),d3
 
                          move.l           pointBrightsPtr,a5

                          move.w           (a5,d0.w*4),d0
                          add.w            #WallTextureBrightOff,d0                    ; Texture bright
                          add.w            wallbrightoff,d0
                          move.w           d0,leftwallbright

                          move.w           (a5,d2.w*4),d0
                          add.w            #WallTextureBrightOff,d0                    ; Texture bright
                          add.w            wallbrightoff,d0
                          move.w           d0,rightwallbright

                          move.w           leftend(pc),d4
                          move.l           #Max3dDivWALL,d7 
                          bsr              WallDraw

                          movem.l          (a7)+,d7/a0/a5/a6

wallfacingaway:
                          rts

*********************************************************************************************
; The screendivide routine is simpler using 
; a0 = left pixel
; a2 = right pixel
; d0 = left dist
; d2 = right dist
; d4 = left strip
; d5 = right strip
;
; (a0)=leftx
; 2(a0)=rightx
;
; 4(a0)=leftbm
; 6(a0)=rightbm
;
; 8(a0)=leftdist
; 10(a0)=rightdist
;
; 12(a0)=lefttop
; 14(a0)=righttop
;
; 16(a0)=leftbot
; 18(a0)=rightbot

DoLeftEnd:
; a0 = #store
; d7 = #maxScrDiv

                          move.w           wallLeftClip,d0
                          sub.w            #1,d0
                          move.w           d0,wallLeftClipAndLast

****************************************************************

                          move.w           STELeftX(a0),d0                             ; a0 = store
                          move.w           STERightX(a0),d1
                          sub.w            d0,d1
                          bge              someToDraw
                          rts

*********************************************************************************************

itertab:                  include          "data/rtg/math/iterfile.s"
                          cnop             0,64

*********************************************************************************************

someToDraw:
                          move.w           itertab(pc,d1.w*4),d7
                          swap             d0
                          move.w           itertab+2(pc,d1.w*4),d6
                          clr.w            d0
                          swap             d1
                          clr.w            d1
                          asr.l            d6,d1                                       ; / n
                          move.l           d1,STELeftX(a0)      

                          moveq            #0,d1
                          move.w           STELeftBm(a0),d1

                          moveq            #0,d2
                          move.w           STERightBm(a0),d2

                          sub.w            d1,d2
                          swap             d1
                          swap             d2
                          asr.l            d6,d2                                       ; / n
                          move.l           d2,STELeftBm(a0)
 
                          moveq            #0,d2
                          move.w           STELeftDist(a0),d2

                          moveq            #0,d3
                          move.w           STERightDist(a0),d3

                          sub.w            d2,d3
                          swap             d2
                          swap             d3
                          asr.l            d6,d3                                       ; / n
                          move.l           d3,STELeftDist(a0)

                          moveq            #0,d3
                          move.w           STELeftTop(a0),d3

                          moveq            #0,d4
                          move.w           STERightTop(a0),d4

                          sub.w            d3,d4
                          swap             d3
                          swap             d4
                          asr.l            d6,d4                                       ; / n
                          move.l           d4,STELeftTop(a0)
 
                          moveq            #0,d4
                          move.w           STELeftBot(a0),d4

                          moveq            #0,d5
                          move.w           STERightBot(a0),d5

                          sub.w            d4,d5
                          swap             d4
                          swap             d5
                          asr.l            d6,d5                                       ; / n
                          move.l           d5,STELeftBot(a0)

****************************************************************
; Gouraud shading
                          moveq            #0,d5
                          move.w           STERightB(a0),d5

                          sub.w            STELeftB(a0),d5

                          add.w            d5,d5
                          swap             d5
                          asr.l            d6,d5                                       ; / n
                          move.l           d5,STELeftC(a0)

                          moveq            #0,d5
                          move.w           STELeftB(a0),d5

                          add.w            d5,d5
                          swap             d5
 
                          bra              screenDivide                                ; skip forward

*********************************************************************************************

itercount:                dc.w             0

*********************************************************************************************
*********************************************************************************************
; Seewall

screenDivideThru:

scrDrawLoop1:
                          move.w           (a0)+,d0                                    ; x
                          lea              AB3dChunkyBufferWALL,a3            
                          lea              (a3,d0.w*2),a3                              ; RTG buffer  

                          move.l           (a0)+,d1                                    ; y
                          swap             d1

                          move.w           d1,d6
                          and.w            horAnd,d6
                          move.l           (a0)+,d2
                          swap             d2
                          add.w            fromTile(pc),d6
                          add.w            d6,d6
                          move.w           d6,a5
                          move.l           (a0)+,d3
                          swap             d3
                          add.l            #divThreeTab,a5
                          move.w           (a5),StripData

                          move.l           ChunkAddr,a5
                          moveq            #0,d6
                          move.b           StripData,d6
                          add.w            d6,d6                                       ; * 2  
                          move.w           valShift,d4
                          asl.w            d4,d6                                       ; * valShift
                          add.w            d6,a5
                          
                          move.l           (a0)+,d4
                          swap             d4
                          move.w           d2,d6
                          asr.w            #7,d6                                       ; / 128
                          add.w            angBright(pc),d6
                          bge.s            .brnotneg

                          moveq            #0,d6

.brnotneg:
                          cmp.w            #32,d6   
                          blt.s            .brnotpos

                          move.w           #32,d6

.brnotpos:
                          move.l           PaletteAddr,a2
                          move.l           a2,a4
                          add.w            ffScrPickHowBrightSeeWall(pc,d6*2),a2

                          move.w           d7,-(a7)
                          bsr              ScreenWallStripDrawThru
                          move.w           (a7)+,d7
 
                          dbra             d7,scrDrawLoop1

                          rts

*********************************************************************************************

ffScrPickHowBrightSeeWall:
                          SCALE

*********************************************************************************************
*********************************************************************************************

screenDivide:
; a0 = Store

                          or.l             #$ffff0000,d7
                          move.w           wallLeftClipAndLast(pc),d6
                          move.l           #WorkSpace,a2

                          move.l           STELeftX(a0),a3
                          move.l           STELeftBm(a0),a4
                          move.l           STELeftDist(a0),a5
                          move.l           STELeftTop(a0),a6
                          move.l           STELeftBot(a0),a1
                          move.l           STELeftC(a0),a0

****************************************************

scrDivLop:
                          swap             d0
                          cmp.w            d6,d0
                          bgt              scrNotOffLeft

                          swap             d0
                          add.l            a4,d1
                          add.l            a5,d2
                          add.l            a6,d3
                          add.l            a1,d4
                          add.l            a3,d0
                          add.l            a0,d5

                          dbra             d7,scrDivLop
                          rts

****************************************************

scrNotOffLeft:
                          move.w           d0,d6

                          cmp.w            wallRightClip(pc),d0
                          bge.s            outOfCalc                                   ;  (not) greater than or equal
 
scrnotoffright:
                          move.w           d0,(a2)+                                    ; STELeftX
                          move.l           d1,(a2)+                                    ; STELeftBm+STERightBm
                          move.l           d2,(a2)+                                    ; STELeftDist+STERightDist
                          move.l           d3,(a2)+                                    ; STELeftTop+STERightTop
                          move.l           d4,(a2)+                                    ; STELeftBot+STERightBot
                          move.l           d5,(a2)+                                    ; STELeftC+STERightC
                          swap             d0
                          add.l            a3,d0
                          add.l            a4,d1
                          add.l            a5,d2
                          add.l            a6,d3
                          add.l            a1,d4
                          add.l            a0,d5
                          
                          add.l            #$10000,d7
                          dbra             d7,scrDivLop

****************************************************

outOfCalc:
                          swap             d7
                          tst.w            d7
                          bge              somethingToDraw
                          rts

*********************************************************************************************

middleline:               dc.w             0

*********************************************************************************************

fromTile:                 dc.l             0
fromquartertile:          dc.l             0
swapbrights:              dc.w             0
angBright:                dc.w             0

leftside:                 dc.b             0
rightside:                dc.b             0
firstleft:                dc.w             0

                          cnop             0,64

*********************************************************************************************
*********************************************************************************************

somethingToDraw:
                          move.l           #wallConstTab,a1
                          move.l           #WorkSpace,a0

*********************************************************************
; Seewall?

                          IFNE             ENABLESEEWALL
                          tst.b            seethru
                          bne              screenDivideThru
                          ENDC

*********************************************************************
; Normal wall

scrDrawloop0:
; a5=?
                          move.w           (a0)+,d0                                    ; STELeftX
                          
                          lea              AB3dChunkyBufferWALL,a3
                          lea              (a3,d0.w*2),a3                              ; RTG buffer

                          move.l           (a0)+,d1                                    ; STELeftBm + STERightBm             
                          swap             d1                                          ; STERightBm

                          move.w           d1,d6                                 
                          and.w            horAnd,d6

                          move.l           (a0)+,d2                                    ; STELeftDist + STERightDist
                          swap             d2                                          ; STERightDist

                          add.w            fromTile(pc),d6
                          add.w            d6,d6
                          move.w           d6,a5

                          move.l           (a0)+,d3                                    ; STELeftTop + STERightTop
                          swap             d3                                          ; STERightTop

                          add.l            #divThreeTab,a5
                          move.w           (a5),StripData

                          move.l           ChunkAddr,a5
                          moveq            #0,d6
                          move.b           StripData,d6
                          add.w            d6,d6                                       ; * 2
                          move.w           valShift,d4
                          asl.w            d4,d6
                          add.w            d6,a5

                          move.l           (a0)+,d4                                    ; STELeftBot + STERightBot
                          swap             d4                                          ; STERightBot

                          move.w           d2,d6
                          asr.w            #7,d6                                       ; / 128
                          
                          move.l           (a0)+,d5                                    ; STELeftC + STERightC
                          swap             d5                                          ; STERightC
                          
                          ext.w            d5
                          add.w            d5,d6
                          bge.s            .brNotNeg

                          moveq            #0,d6

.brNotNeg:
                          cmp.w            #64,d6
                          blt.s            .brNotPos

                          move.w           #64,d6

.brNotPos:
                          move.l           PaletteAddr,a2
                          move.l           a2,a4
                          add.w            ffScrPickHowBrightNormalWall(pc,d6*2),a2

                          move.w           d7,-(a7)
                          bsr              ScreenWallStripDraw
                          move.w           (a7)+,d7
 
                          dbra             d7,scrDrawloop0
 
                          rts

*********************************************************************************************

ffScrPickHowBrightNormalWall:
                          SCALE

*********************************************************************************************

divThreeTab:
val                       SET              0
                          REPT             255                                         ; 130
                          dc.b             val,0
                          dc.b             val,1
                          dc.b             val,2
val                       SET              val+1
                          ENDR

*********************************************************************************************

StripData:                dc.w             0

*********************************************************************************************
; using a0=left pixel
; a2= right pixel
; d0= left height
; d2= right height
; d4 = left strip
; d5 = right strip

; Routine to draw a wall;
; pass it X and Z coords of the endpoints
; and the start and end length, and a number
; representing the number of the wall.

; a0=x1 d1=z1 a2=x2 d3=z2
; d4=sl d5=el
; a1 = strip buffer

*********************************************************************************************

store:                    ds.l             RTGMult*4*500

*********************************************************************************************
; Curve drawing routine. We have to know:
; The top and bottom of the wall
; The point defining the centre of the arc
; the point defining the starting point of the arc
; the start and end angles of the arc
; The start and end positions along the bitmap of the arc
; Which bitmap to use for the arc

xmiddle:                  dc.w             0
zmiddle:                  SET              2
                          dc.w             0
xradius:                  SET              4
                          dc.w             0
zradius:                  SET              6
                          dc.w             0
startbitmap:              SET              8
                          dc.w             0
bitmapcounter:            SET              10
                          dc.w             0
brightmult:               SET              12
                          dc.w             0
angadd:                   SET              14
                          dc.l             0
xmiddlebig:               SET              18
                          dc.l             0
basebright:               SET              22
                          dc.w             0
shift:                    SET              24
                          dc.w             0
count:                    SET              26
                          dc.w             0

*********************************************************************************************
*********************************************************************************************

subdividevals:
                          dc.w             2,4
                          dc.w             3,8
                          dc.w             4,16
                          dc.w             5,32
                          dc.w             6,64
                          dc.w             7,128
                          dc.w             8,256
                          dc.w             9,512
                          dc.w             10,1024
                          dc.w             11,2048
                          dc.w             12,4096
                          dc.w             13,8192
                          dc.w             14,16384
                          dc.w             15,32768

*********************************************************************************************

CurveDraw:
; a0 = ThisRoomToDraw+n
                          move.w           (a0)+,d0                                    ; centre of rotation / ypos of poly
                          move.w           (a0)+,d1                                    ; point on arc

                          move.l           #Rotated,a1
                          move.l           #xmiddle,a2

                          move.l           (a1,d0.w*8),d2
                          move.l           d2,18(a2)                                   ; xmiddlebig  

                          asr.l            #7,d2                                       ; / 128
                          move.l           (a1,d1.w*8),d4
                          asr.l            #7,d4                                       ; / 128
                          sub.w            d2,d4
                          move.w           d2,(a2)                                     ; xmiddle
                          move.w           d4,4(a2)                                    ; xradius
                          move.w           6(a1,d0.w*8),d2
                          move.w           6(a1,d1.w*8),d4
                          sub.w            d2,d4
                          move.w           d2,2(a2)                                    ; zmiddle  
                          asr.w            #1,d4                                       ; / 2
                          move.w           d4,6(a2)                                    ; zradius  

                          move.w           (a0)+,d4                                    ; start of bitmap
                          move.w           (a0)+,d5                                    ; end of bitmap
                          
                          move.w           d4,8(a2)                                    ; startbitmap
                          sub.w            d4,d5
                          move.w           d5,10(a2)                                   ; bitmapcounter  
                          
                          move.w           (a0)+,d4
                          ext.l            d4
                          move.l           d4,14(a2)

                          move.w           (a0)+,d4
                          move.l           #subdividevals,a3
                          move.l           (a3,d4.w*4),shift(a2)
 
                          move.l           #wallTiles,a3
                          add.l            (a0)+,a3
                          adda.w           wallYOff,a3
                          move.l           a3,fromTile

                          move.w           (a0)+,basebright(a2)
                          move.w           (a0)+,brightmult(a2)
                          move.l           (a0)+,topofwall
                          move.l           (a0)+,botofwall
                          move.l           yoff,d6
                          sub.l            d6,topofwall
                          sub.l            d6,botofwall

                          move.l           #databuffer,a1
                          move.l           #SineTable,a3
                          lea              2048(a3),a4
                          moveq            #0,d0
                          moveq            #0,d1
                          move.w           count(a2),d7

DivideCurve:
                          move.l           d0,d2
                          move.w           shift(a2),d4                                ; 24
                          asr.l            d4,d2                                       ; / shift
                          move.w           (a3,d2.w*2),d4
                          move.w           d4,d5
                          move.w           (a4,d2.w*2),d3
                          move.w           d3,d6
                          muls.w           4(a2),d3                                    ; xradius
                          muls.w           6(a2),d4                                    ; zradius
                          muls.w           4(a2),d5                                    ; xradius   
                          muls.w           6(a2),d6                                    ; zradius   
                          sub.l            d4,d3
                          add.l            d6,d5
                          asl.l            #2,d5                                       ; * 4
                          asr.l            #8,d3                                       ; / 256
                          add.l            18(a2),d3                                   ; xmiddlebig  
                          swap             d5
                          move.w           basebright(a2),d6
                          move.w           brightmult(a2),d4
                          muls             d5,d4
                          swap             d4
                          add.w            d4,d6
 
                          add.w            2(a2),d5
                          move.l           d3,(a1)+
                          move.w           d5,(a1)+
                          move.w           d1,d2
                          move.w           shift(a2),d4
                          asr.w            d4,d2                                       ; / shift
                          add.w            8(a2),d2
                          move.w           d2,(a1)+
                          move.w           d6,(a1)+

                          add.l            14(a2),d0  
                          add.w            10(a2),d1
                          dbra             d7,DivideCurve
 
                          move.l           a0,-(a7)

                          bsr              curvecalc

                          move.l           (a7)+,a0

                          rts
 
*********************************************************************************************

curvecalc:
                          move.l           #databuffer,a1
                          move.w           count(a2),d7
                          subq             #1,d7

.findfirstinfront:
                          move.l           (a1)+,d1
                          move.w           (a1)+,d0
                          bgt.s            .foundinfront

                          move.w           (a1)+,d4
                          move.w           (a1)+,d6
                          dbra             d7,.findfirstinfront

                          SUPERVISOR       SetInstCacheOn
                          rts                                                          ; no two points were in front
 
 *****************************************************************
 
.foundinfront:
                          move.w           (a1)+,d4
                          move.w           (a1)+,d6

 ; d1=left x, d4=left end, d0=left dist
 ; d6=left angbright 
 
                          divs             d0,d1
                          add.w            #(RTGScrWidthWALL/2)-1,d1                   ; (WallWidth / 2 -1)
 
                          move.l           topofwall(pc),d5
                          divs             d0,d5
                          add.w            #RTGScrHeightWALL/2,d5                      ; Height
                          move.w           d5,strtop

                          move.l           botofwall(pc),d5
                          divs             d0,d5
                          add.w            #RTGScrHeightWALL/2,d5                      ; Height
                          move.w           d5,strbot
 
 *****************************************************************

                          SUPERVISOR       SetInstCacheOff
 
.computeloop:
                          move.w           4(a1),d2
                          bgt.s            .infront                                    ; Not
 
                          SUPERVISOR       SetInstCacheOn
                          rts

*****************************************************************

.infront:
                          move.l           #store,a0
                          move.l           (a1),d3
                          move.w           6(a1),d5

                          add.w            8(a1),d6
                          asr.w            #1,d6                                       ; / 2
                          move.w           d6,angBright

                          divs             d2,d3
                          add.w            #(RTGScrWidthWALL/2)-1,d3                   ; (WallWidth/2)-1

                          move.w           strtop(pc),12(a0)
                          move.w           strbot(pc),16(a0)

                          move.l           topofwall(pc),d6
                          divs             d2,d6
                          add.w            #RTGScrHeightWALL/2,d6
                          move.w           d6,strtop

                          move.w           d6,14(a0)

                          move.l           botofwall(pc),d6
                          divs             d2,d6
                          add.w            #RTGScrHeightWALL/2,d6
                          move.w           d6,strbot
                          
                          move.w           d6,18(a0)

                          move.w           d3,2(a1)
                          blt.s            .allOffLeftPart                             ; Not

                          cmp.w            #RTGScrWidthWALL-1,d1                       ; width max?
                          bgt.s            .allOffLeftPart                             ; Not

                          cmp.w            d1,d3
                          blt.s            .allOffLeftPart                             ; Not

*****************************************************************

                          move.w           d1,(a0)
                          move.w           d3,2(a0)
                          move.w           d4,4(a0)
                          move.w           d5,6(a0)
                          move.w           d0,8(a0)
                          move.w           d2,10(a0)

                          move.w           d7,-(a7)
                          move.w           #maxScrDiv,d7
                          bsr              DoLeftEnd
                          move.w           (a7)+,d7

*****************************************************************

.allOffLeftPart:
                          move.l           (a1)+,d1
                          move.w           (a1)+,d0
                          move.w           (a1)+,d4
                          move.w           (a1)+,d6

                          dbra             d7,.computeloop
 
                          SUPERVISOR       SetInstCacheOn
                          rts

*********************************************************************************************

iters:                    dc.w             0
multcount:                dc.w             0

*********************************************************************************************
*********************************************************************************************

WallDraw:
; a5 = pointBrightsPtr
; d0 = rightwallbright
; d1 = 
; d3 = 
; d4 = leftend
; d7 = Max3dDivWALL

                          tst.w            d1
                          bgt.s            oneinfront1

                          tst.w            d3
                          bgt.s            oneinfront

                          rts

oneinfront1:
                          tst.w            d3
                          ble.s            oneinfront

******************************************************

; Bothinfront!

                          nop

oneinfront:
                          ;move.w           #16,d7                                ; Max3dDivWALL
                          move.w           #2,d6
 
                          move.w           d3,d0
                          sub.w            d1,d0
                          bge.s            notnegzdiff

                          neg.w            d0

notnegzdiff:
                          cmp.w            #1024,d0
                          blt.s            nd01

                          add.w            d7,d7                                       ; d7 * 2
                          add.w            #1,d6

nd01:
                          cmp.w            #512,d0
                          blt.s            nd0 

                          add.w            d7,d7                                       ; d7 * 2
                          add.w            #1,d6

                          bra              nha

nd0:
                          cmp.w            #256,d0
                          bgt.s            nh1

                          asr.w            #1,d7                                       ; d7 / 2
                          subq             #1,d6

nh1:
                          cmp.w            #128,d0
                          bgt.s            nh2

                          asr.w            #1,d7                                       ; d7 / 2
                          subq             #1,d6

nh2:
nha:
                          move.w           d3,d0                                       ; d3 = enpoint

                          cmp.w            d1,d3
                          blt.s            rightnearest                                ; less than

                          move.w           d1,d0

rightnearest:
                          cmp.w            #64,d0
                          bgt.s            nd1

                          addq             #1,d6
                          add.w            d7,d7                                       ; d7 * 2

nd1:
                          cmp.w            #128,d0
                          blt.s            nh3

                          asr.w            #1,d7                                       ; d7 / 2
                          subq             #1,d6
                          blt.s            nh3

                          cmp.w            #256,d0
                          blt.s            nh3

                          asr.w            #1,d7                                       ; d7 / 2
                          subq             #1,d6

nh3:

******************************************************

                          move.w           d6,iters

                          subq             #1,d7
                          move.w           d7,multcount

******************************************************

                          move.l           #databuffer,a3
                          move.l           a0,d0
                          move.l           a2,d2

                          move.l           d0,(a3)+                                    ; 0 +4
                          add.l            d2,d0

                          move.w           d1,(a3)+                                    ; 4 +2 Endpoint 1
                          asr.l            #1,d0                                       ; d0 / 2  

                          move.w           d4,(a3)+                                    ; 6 +2 d4 = leftend

                          move.w           leftwallbright,d6
                          move.w           d6,(a3)+                                    ; 8 +2  
 
                          add.w            d5,d4
                          move.l           d0,(a3)+                                    ; 10 +4

                          add.w            d3,d1
                          asr.w            #1,d1                                       ; d1 / 2
                          move.w           d1,(a3)+                                    ; 14 +2  

                          asr.w            #1,d4                                       ; d4 / 2
                          move.w           d4,(a3)+                                    ; 16 +2   
 
                          add.w            rightwallbright,d6
                          asr.w            #1,d6                                       ; d6 / 2
                          move.w           d6,(a3)+                                    ; 18 +2  
 
                          move.l           d2,(a3)+                                    ; 20 +4 
                          move.w           d3,(a3)+                                    ; 24 +2 
                          move.w           d5,(a3)+                                    ; 26 +2 
                          move.w           rightwallbright,(a3)+                       ; 28 +2 
 
 ******************************************************
; We now have the two endpoints and the midpoint
; so we need to perform 1 iteration of the inner
; loop, the first time.
 
; Decide how often to subdivide by how far away the wall is, and
; how perp. it is to the player.
******************************************************

                          move.l           #databuffer,a0
                          move.l           #databuffer2,a1
 
                          move.w           iters,d6
                          blt              noiters

                          move.l           #1,a2
 
iterloop:
                          move.l           a0,a3
                          move.l           a1,a4
                          move.w           a2,d7                                       ; Middleloop counter
                          exg              a0,a1

                          move.l           (a3)+,d0
                          move.w           (a3)+,d1
                          move.l           (a3)+,d2

middleloop:
                          move.l           d0,(a4)+
                          move.l           (a3)+,d3
                          add.l            d3,d0
                          move.w           d1,(a4)+
                          asr.l            #1,d0                                       ; / 2
                          move.w           (a3)+,d4
                          add.w            d4,d1
                          move.l           d2,(a4)+
                          asr.w            #1,d1                                       ; / 2
                          move.l           (a3)+,d5
                          add.l            d5,d2
                          move.l           d0,(a4)+
                          asr.l            #1,d2                                       ; / 2
                          move.w           d1,(a4)+
                          move.l           d2,(a4)+
 
                          move.l           d3,(a4)+
                          move.l           (a3)+,d0
                          add.l            d0,d3
 
                          move.w           d4,(a4)+
                          asr.l            #1,d3                                       ; / 2
                          move.w           (a3)+,d1
                          add.w            d1,d4
                          move.l           d5,(a4)+
                          asr.w            #1,d4                                       ; / 2
                          move.l           (a3)+,d2
                          add.l            d2,d5
                          move.l           d3,(a4)+
                          asr.l            #1,d5                                       ; / 2
                          move.w           d4,(a4)+
                          move.l           d5,(a4)+

                          subq             #1,d7
                          bgt.s            middleloop

                          move.l           d0,(a4)+
                          move.w           d1,(a4)+
                          move.l           d2,(a4)+
 
                          add.w            a2,a2
 
                          dbra             d6,iterloop

******************************************************

noiters:
CalcAndDraw:
                          SUPERVISOR       SetInstCacheOn
 
                          move.l           a0,a1
                          move.w           multcount,d7

.findfirstinfront:
                          move.l           (a1)+,d1
                          move.w           (a1)+,d0
                          bgt.s            .foundinfront

                          move.l           (a1)+,d4
                          dbra             d7,.findfirstinfront

                          rts                                                          ; no two points were in front
 
 ******************************************************

.foundinfront:
                          move.w           (a1)+,d4
                          move.w           (a1)+,lbr
                  
 ; d1=left x, d4=left end, d0=left dist 
 
                          divs             d0,d1
                          add.w            #(RTGScrWidthWALL/2)-1,d1                   ; (WallWidth/2)-1
 
                          move.l           topofwall(pc),d5
                          divs             d0,d5
                          add.w            #RTGScrHeightWALL/2,d5
                          move.w           d5,strtop

                          move.l           botofwall(pc),d5
                          divs             d0,d5
                          add.w            #RTGScrHeightWALL/2,d5
                          move.w           d5,strbot
 
.computeloop:
                          move.w           4(a1),d2
                          bgt.s            .infront
                          rts

******************************************************

.infront:
                          move.l           #store,a0
                          move.l           (a1),d3
                          divs             d2,d3
                          move.w           6(a1),d5
                          add.w            #(RTGScrWidthWALL/2)-1,d3                   ; (WallWidth/2)-1

                          move.w           strtop(pc),12(a0)
                          move.l           topofwall(pc),d6
                          divs             d2,d6
                          move.w           strbot(pc),16(a0)

                          add.w            #RTGScrHeightWALL/2,d6
                          move.w           d6,strtop

                          move.w           d6,14(a0)
                          move.l           botofwall(pc),d6
                          divs             d2,d6

                          add.w            #(RTGScrHeightWALL/2)+1,d6                  ; 41 (WallWidth/2)-7
                          move.w           d6,strbot
                          
                          move.w           d6,18(a0)
                          move.w           d3,2(a1)

                          cmp.w            wallLeftClip(pc),d3
                          blt.s            .alloffleft

                          cmp.w            wallRightClip(pc),d1
                          bge.s            .alloffright

******************************************************
 
                          move.w           d1,(a0)
                          move.w           d3,2(a0)
                          move.w           d4,4(a0)
                          move.w           d5,6(a0)
                          move.w           d0,8(a0)
                          move.w           d2,10(a0)
 
                          move.w           lbr,d5
                          sub.w            #WallTextureBrightOff,d5                    ; Texture bright
                          ext.w            d5
                          move.w           d5,24(a0)

                          move.w           8(a1),d5
                          sub.w            #WallTextureBrightOff,d5                    ; Texture bright
                          ext.w            d5
                          move.w           d5,26(a0)
 
                          movem.l          d7/a1,-(a7)
                          move.w           #maxScrDiv,d7
                          bsr              DoLeftEnd
                          movem.l          (a7)+,d7/a1

******************************************************

.alloffleft:
                          move.l           (a1)+,d1
                          move.w           (a1)+,d0
                          move.w           (a1)+,d4
                          move.w           (a1)+,lbr

                          dbra             d7,.computeloop
                          rts

******************************************************

.alloffright:
                          rts

*********************************************************************************************

lbr:                      dc.w             0
leftwallbright:           dc.w             0
rightwallbright:          dc.w             0
strtop:                   dc.w             0
strbot:                   dc.w             0
 
databuffer:               ds.l             RTGMult*4*600
databuffer2:              ds.l             RTGMult*4*600

*********************************************************************************************
; Need a routine which takes...?
; Top Y (3d)
; Bottom Y (3d)
; distance
; height of each tile (number and routine addr)
; And produces the appropriate strip on the
; screen.

topofwall:                dc.l             0
botofwall:                dc.l             0

*********************************************************************************************

nostripq:                 rts

*********************************************************************************************

ScreenWallStripDraw:
; a1=constTab
; d4.w = height
                          move.w           d4,d6
                          
                          cmp.w            topclip(pc),d6
                          blt.s            nostripq

                          cmp.w            botclip(pc),d3
                          bgt.s            nostripq
 
                          cmp.w            botclip(pc),d6
                          ble.s            noclipbot

                          move.w           botclip(pc),d6

noclipbot:
                          move.w           d3,d5
                          cmp.w            topclip(pc),d5
                          bge.s            nocliptop

                          move.w           topclip(pc),d5

                          sub.w            d5,d6                                       ; height to draw.
                          ble.s            nostripq
 
                          bra              goToEnd
 
 *********************************************************************************************

nocliptop:
                          sub.w            d5,d6                                       ; height to draw.
                          ble.s            nostripq
 
                          bra              goToEnd

*********************************************************************************************

wlcnt:                    dc.w             0 

*********************************************************************************************

                          CNOP             0,128 

*********************************************************************************************
*********************************************************************************************
; Draw far away walls

drawwallPACK0:
; a2 = palette
; a3 = rtg buffer
; a5 = chunky
; d0 = RTGScrWidthByteOffsetWALL
; d2 = ?
; d3 = ?
; d4 = chunky offset
; d6 = Loop by height to draw
; d7 = valAnd

                          and.w            d7,d4
                          move.b           1(a5,d4.w*2),d1
                          and.b            #WallPackAndA,d1

                          add.l            d3,d4

                          move.l           d2,-(a7)
                          move.w           (a2,d1.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

                          adda.l           d0,a3                                       ; a3+RTGScrWidthByteOffsetWALL
                          addx.w           d2,d4

                          dbra             d6,drawwallPACK0
                          rts

*********************************************************************************************

                          CNOP             0,4 

*********************************************************************************************

drawwallPACK1:
; a5 = Chunky
; a2 = palette
; d4 = off set to chuky
; d6 = Loop by height to draw.
; d7 = valAnd

                          and.w            d7,d4
                          move.w           (a5,d4.w*2),d1
                          lsr.w            #WallPackLsrA,d1                            ; / 32
                          and.w            #WallPackAndA,d1

                          add.l            d3,d4

                          move.l           d2,-(a7)
                          move.w           (a2,d1.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

                          adda.l           d0,a3
                          addx.w           d2,d4

                          dbra             d6,drawwallPACK1

                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

drawwallPACK2:
; a5 = Chunky
; a2 = palette
; d4 = off set to chuky
; d6 = Loop by height to draw.
; d7 = valAnd

                          and.w            d7,d4
                          move.b           (a5,d4.w*2),d1
                          lsr.b            #WallPackLsrB,d1                            ; / 4

                          add.l            d3,d4

                          move.l           d2,-(a7)
                          move.w           (a2,d1.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

                          adda.l           d0,a3
                          addx.w           d2,d4

                          dbra             d6,drawwallPACK2
                          rts

*********************************************************************************************

useSimple:
                          mulu             d3,d4
                          add.l            d0,d4
                          swap             d4
                          add.w            totalYOff(pc),d4

clipTopUseSimple:
                          move.w           valAnd,d7
                          move.l           #RTGScrWidthByteOffsetWALL,d0
                          moveq            #0,d1
                          and.w            d7,d4
                          move.l           d2,d5
                          clr.w            d5

                          cmp.b            #1,StripData+1
                          dbge             d6,simplewalliPACK0
                          dbne             d6,simplewalliPACK1
                          dble             d6,simplewalliPACK2

                          rts

*********************************************************************************************
*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************
*********************************************************************************************
; Draw close walls

simplewalliPACK0:
; a5 = chunky
; a2 = palette

                          move.b           1(a5,d4.w*2),d1
                          and.b            #WallPackAndA,d1
                          move.w           (a2,d1.w*2),d3

simplewallPACK0:
                          move.l           d2,-(a7)
                          move.w           d3,d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

                          adda.l           d0,a3

                          add.l            d2,d4
                          bcc.s            .noread

                          addq             #1,d4
                          and.w            d7,d4
                          move.b           1(a5,d4.w*2),d1
                          and.b            #WallPackAndA,d1
                          move.w           (a2,d1.w*2),d3

.noread:
                          dbra             d6,simplewallPACK0
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

simplewalliPACK1:

                          move.w           (a5,d4.w*2),d1
                          lsr.w            #WallPackLsrA,d1                            ; * 32
                          and.w            #WallPackAndA,d1
                          move.w           (a2,d1.w*2),d3

simplewallPACK1:
                          move.l           d2,-(a7)
                          move.w           d3,d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

                          adda.l           d0,a3

                          add.l            d5,d4
                          bcc.s            .noread

                          addq             #1,d4
                          and.w            d7,d4
                          move.w           (a5,d4.w*2),d1
                          lsr.w            #WallPackLsrA,d1                            ; * 32
                          and.w            #WallPackAndA,d1
                          move.w           (a2,d1.w*2),d3

.noread:
                          dbra             d6,simplewallPACK1
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

simplewalliPACK2:

                          move.b           (a5,d4.w*2),d1
                          lsr.b            #WallPackLsrB,d1                            ; * 4
                          and.b            #WallPackAndA,d1
                          move.w           (a2,d1.w*2),d3

simplewallPACK2:
                          move.l           d2,-(a7)
                          move.w           d3,d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

                          adda.l           d0,a3

                          add.l            d5,d4
                          bcc.s            .noread

                          addq             #1,d4
                          and.w            d7,d4
                          move.b           (a5,d4.w*2),d1

                          lsr.b            #2,d1                                       ; * 4
                          move.w           (a2,d1.w*2),d3

.noread:
                          dbra             d6,simplewallPACK2
                          rts

*********************************************************************************************

goToEnd:
; a1=ConstTab
; a3=RTG buffer
; a5=Chunky
; a2=palette
; d2=left/right distance
; d6=height to draw
; d5=?
 
                          add.l            timesLarge(pc,d5.w*4),a3                    ; RTG buffer Faraway

                          move.w           d5,d4

                          move.l           4(a1,d2.w*8),d0                       
                          move.l           (a1,d2.w*8),d2      

                          IFNE             Use1X1WALL
                          asr.l            #1,d2                                       ; / 2 Debug: Hack!
                          ENDC

                          moveq            #0,d3
                          move.w           d2,d3
                          swap             d2

                          tst.w            d2
                          bne.s            .notsimple

                          cmp.l            #WallUseSimpleValue,d3
                          ble              useSimple

.notsimple:
                          mulu             d3,d4
                          muls             d2,d5                                 
                          add.l            d0,d4
                          swap             d4
                          add.w            d5,d4
                          add.w            totalYOff(pc),d4
                    
cliptop:
                          move.w           valAnd,d7
                          move.l           #RTGScrWidthByteOffsetWALL,d0
                          moveq            #0,d1
                          and.w            d7,d4
                          move.l           d2,d3
                          clr.w            d3

                          cmp.b            #1,StripData+1
                          dbge             d6,drawwallPACK0
                          dbne             d6,drawwallPACK1
                          dble             d6,drawwallPACK2

                          rts

*********************************************************************************************
*********************************************************************************************

timesLarge:

val                       SET              RTGScrWidthByteOffsetWALL
                          REPT             RTGScrHeightWALL                            ; 80
                          dc.l             val
val                       SET              val+RTGScrWidthByteOffsetWALL
                          ENDR

*********************************************************************************************

nostripqthru:
                          rts

*********************************************************************************************

ScreenWallStripDrawThru:
; a1 = 
; a4 = PaletteAddress
; a5 = ChunkyAddress

                          move.w           d4,d6

                          cmp.w            topclip(pc),d6
                          blt.s            nostripqthru

                          cmp.w            botclip(pc),d3
                          bgt.s            nostripqthru
 
                          cmp.w            botclip(pc),d6
                          ble.s            .noclipbot

                          move.w           botclip(pc),d6

.noclipbot:
                          move.w           d3,d5
                          cmp.w            topclip(pc),d5
                          bge.s            .nocliptop
                          
                          move.w           topclip(pc),d5

                          sub.w            d5,d6                                       ; height to draw.
                          ble.s            nostripqthru
 
                          bra              goToEndThru
 
.nocliptop:

                          sub.w            d5,d6                                       ; height to draw.
                          ble.s            nostripqthru
 
                          bra              goToEndThru

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

drawwalldimthruPACK0:
                          and.w            d7,d4
                          move.b           1(a5,d4.w*2),d1
                          and.b            #WallPackAndA,d1
                          beq.s            .holey

                          move.l           d2,-(a7)
                          move.w           (a4,d1.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

.holey:
                          adda.l           d0,a3

                          add.l            d3,d4
                          addx.w           d2,d4
                          dbra             d6,drawwallthruPACK0
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

drawwallthruPACK0:
                          and.w            d7,d4
                          move.b           1(a5,d4.w*2),d1
                          and.b            #WallPackAndA,d1
                          beq.s            .holey

                          move.l           d2,-(a7)
                          move.w           (a2,d1.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

.holey:
                          adda.l           d0,a3

                          add.l            d3,d4
                          addx.w           d2,d4
                          dbra             d6,drawwalldimthruPACK0

nostripthru:
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

drawwalldimthruPACK1:
                          and.w            d7,d4
                          move.w           (a5,d4.w*2),d1
                          lsr.w            #WallPackLsrA,d1                            ; * 32
                          and.w            #WallPackAndA,d1
                          beq.s            .holey

                          move.l           d2,-(a7)
                          move.w           (a4,d1.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

.holey:
                          adda.l           d0,a3

                          add.l            d3,d4
                          addx.w           d2,d4
                          dbra             d6,drawwallthruPACK1
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

drawwallthruPACK1:
                          and.w            d7,d4
                          move.w           (a5,d4.w*2),d1
                          lsr.w            #WallPackLsrA,d1                            ; * 32
                          and.w            #WallPackAndA,d1
                          beq.s            .holey

                          move.l           d2,-(a7)
                          move.w           (a2,d1.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

.holey:
                          adda.l           d0,a3

                          add.l            d3,d4
                          addx.w           d2,d4
                          dbra             d6,drawwalldimthruPACK1
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

drawwalldimthruPACK2:
                          and.w            d7,d4
                          move.b           (a5,d4.w*2),d1
                          lsr.b            #WallPackLsrB,d1                            ; * 4
                          and.b            #WallPackAndA,d1
                          beq.s            .holey

                          move.l           d2,-(a7)
                          move.w           (a4,d1.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

.holey:
                          adda.l           d0,a3

                          add.l            d3,d4
                          addx.w           d2,d4
                          dbra             d6,drawwallthruPACK2
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

drawwallthruPACK2:
                          and.w            d7,d4
                          move.b           (a5,d4.w*2),d1
                          lsr.b            #WallPackLsrB,d1                            ; * 4
                          and.b            #WallPackAndA,d1
                          beq.s            .holey

                          move.l           d2,-(a7)
                          move.w           (a2,d1.w*2),d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

.holey:
                          adda.l           d0,a3

                          add.l            d3,d4
                          addx.w           d2,d4
                          dbra             d6,drawwalldimthruPACK2
                          rts

*********************************************************************************************
*********************************************************************************************

useSimpleThru:
                          mulu             d3,d4
                          add.l            d0,d4
                          swap             d4
                          add.w            totalYOff(pc),d4

clipTopUseSimpleThru:
                          moveq            #WallPackAndB,d7                   
                          move.l           #RTGScrWidthByteOffsetWALL,d0
                          moveq            #0,d1

                          cmp.l            a4,a2
                          blt.s            usea2thru
                          
                          move.l           a4,a2

usea2thru:
                          and.w            d7,d4
                          move.l           d2,d5
                          clr.w            d5
 
                          cmp.b            #1,StripData+1
                          dbge             d6,simplewallthruiPACK0
                          dbne             d6,simplewallthruiPACK1
                          dble             d6,simplewallthruiPACK2
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************
*********************************************************************************************

simplewallthruiPACK0:
                          move.b           1(a5,d4.w*2),d1
                          and.b            #WallPackAndA,d1
                          move.w           (a2,d1.w*2),d3

simplewallthruPACK0:
                          move.l           d2,-(a7)
                          move.w           d3,d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

                          adda.l           d0,a3

                          add.l            d5,d4
                          bcc.s            noreadthruPACK0

maybeholePACK0:
                          addx.w           d2,d4
                          and.w            d7,d4
                          move.b           1(a5,d4.w*2),d1
                          and.b            #WallPackAndA,d1
                          beq.s            holeysimplePACK0

                          move.w           (a2,d1.w*2),d3
                          dbra             d6,simplewallthruPACK0
                          rts

noreadthruPACK0:
                          addx.w           d2,d4
                          dbra             d6,simplewallthruPACK0
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

simplewallholePACK0:
                          adda.l           d0,a3

                          add.l            d5,d4
                          bcs.s            maybeholePACK0

                          addx.w           d2,d4

holeysimplePACK0:
                          and.w            d7,d4
                          dbra             d6,simplewallholePACK0
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

simplewallthruiPACK1:
                          move.w           (a5,d4.w*2),d1
                          lsr.w            #WallPackLsrA,d1                            ; * 32
                          and.w            #WallPackAndA,d1
                          move.w           (a2,d1.w*2),d3

simplewallthruPACK1:
                          move.l           d2,-(a7)
                          move.w           d3,d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

                          adda.l           d0,a3

                          add.l            d5,d4
                          bcc.s            noreadthruPACK1

maybeholePACK1:
                          addx.w           d2,d4
                          and.w            d7,d4
                          move.w           (a5,d4.w*2),d1
                          lsr.w            #WallPackLsrA,d1                            ; * 32
                          and.w            #WallPackAndA,d1
                          beq.s            holeysimplePACK1

                          move.w           (a2,d1.w*2),d3
                          dbra             d6,simplewallthruPACK1
                          rts

noreadthruPACK1:
                          addx.w           d2,d4
                          dbra             d6,simplewallthruPACK1
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

simplewallholePACK1:
                          adda.l           d0,a3

                          add.l            d5,d4
                          bcs.s            maybeholePACK1

                          addx.w           d5,d4

holeysimplePACK1:
                          and.w            d7,d4
                          dbra             d6,simplewallholePACK1
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

simplewallthruiPACK2:
                          move.b           (a5,d4.w*2),d1
                          lsr.b            #WallPackLsrB,d1                            ; * 4
                          and.b            #WallPackAndA,d1
                          move.w           (a2,d1.w*2),d3

simplewallthruPACK2:
                          move.l           d2,-(a7)
                          move.w           d3,d2
                          C12BITTOHICOL
                          move.w           d2,(a3)                                     ; To RTG buffer
                          move.l           (a7)+,d2

                          adda.l           d0,a3

                          add.l            d5,d4
                          bcc.s            noreadthruPACK2

maybeholePACK2:
                          addx.w           d2,d4
                          and.w            d7,d4
                          move.b           (a5,d4.w*2),d1
                          lsr.b            #WallPackLsrB,d1                            ; * 4
                          and.b            #WallPackAndA,d1
                          beq.s            holeysimplePACK2

                          move.w           (a2,d1.w*2),d3
                          dbra             d6,simplewallthruPACK2
                          rts

noreadthruPACK2:
                          addx.w           d2,d4
                          dbra             d6,simplewallthruPACK2
                          rts

*********************************************************************************************

                          CNOP             0,4

*********************************************************************************************

simplewallholePACK2:
                          adda.l           d0,a3

                          add.l            d5,d4
                          bcs.s            maybeholePACK2

                          addx.w           d2,d4

holeysimplePACK2:
                          and.w            d7,d4
                          dbra             d6,simplewallholePACK2
                          rts

*********************************************************************************************

goToEndThru:
                          add.l            timesLargeThru(pc,d5.w*2),a3                ; Faraway

                          move.w           d5,d4
                          
                          move.l           4(a1,d2.w*8),d0
                          move.l           (a1,d2.w*8),d2

                          IFNE             Use1X1WALL                          
                          asr.l            #1,d2                                       ; / 2 Debug: Hack!
                          ENDC  

                          moveq            #0,d3
                          move.w           d2,d3
                          swap             d2

                          tst.w            d2
                          bne.s            .notsimple
                          
                          cmp.l            #WallUseSimpleValue,d3                      ; 45056
                          ble              useSimpleThru

.notsimple:
                          mulu             d3,d4
                          muls             d2,d5
                          add.l            d0,d4
                          swap             d4
                          add.w            d5,d4
                          add.w            wallYOff(pc),d4

cliptopthru:
                          moveq            #WallPackAndB,d7
                          move.l           #RTGScrWidthByteOffsetWALL,d0
                          moveq            #0,d1
 
                          move.l           d2,d3
                          clr.w            d3

                          cmp.b            #1,StripData+1
                          dbge             d6,drawwallthruPACK0
                          dbne             d6,drawwallthruPACK1
                          dble             d6,drawwallthruPACK2
 
                          rts

*********************************************************************************************
; TODO: Own fixed file for 1x1?

wallConstTab:             include          "data/rtg/math/wallconstantfile.s"
                          CNOP             0,32

*********************************************************************************************

wallTiles:                ds.l             4*40
; Wall textures

*********************************************************************************************