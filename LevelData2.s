*********************************************************************************************

                          opt         P=68020


*********************************************************************************************

                          incdir      "includes"
                          include     "macros.i"
                          include     "AB3DI.i"
                          include     "AB3DIRTG.i"

                          include     "exec/memory.i"
                          
*********************************************************************************************
; Debugging

USETESTLEVEL  EQU 1  

*********************************************************************************************
; Level definitions

wall                      SET         0
floor                     SET         1
roof                      SET         2
setclip                   SET         3
object                    SET         4
curve                     SET         5
light                     SET         6
water                     SET         7
bumpfloor                 SET         8
bumproof                  SET         9
smoothfloor               SET         10
smoothroof                SET         11
backdrop                  SET         12
seethruwall               SET         13

GreenStone                SET         0
MetalA                    SET         4096
MetalB                    SET         4096*2
MetalC                    SET         4096*3
Marble                    SET         4096*4
BulkHead                  SET         4096*5
SpaceWall                 SET         4096*6

Sand                      SET         0
MarbleFloor               SET         2

RoofLights                SET         256
GreyRoof                  SET         258

*********************************************************************************************
*********************************************************************************************

AllocLevelData:
                          SAVEREGS

                          move.l      #MEMF_FAST|MEMF_CLEAR,d1	
                          move.l      #LevelDataSize,d0
                          move.l      4.w,a6
                          jsr         _LVOAllocMem(a6)
                          move.l      d0,LEVELDATA

                          GETREGS  
                          rts

*********************************************************************************************
*********************************************************************************************

ReleaseLevelData:

                          IFNE        USETESTLEVEL
                          rts
                          ENDC

                          SAVEREGS

                          move.l      LEVELDATA,d1
                          beq         SkipLevelData

                          move.l      d1,a1
                          move.l      #LevelDataSize,d0
                          move.l      4.w,a6
                          jsr         _LVOFreeMem(a6)
                          move.l      #0,LEVELDATA

SkipLevelData:  
                          GETREGS  
                          rts

*********************************************************************************************
*********************************************************************************************

AllocLevelMemory:
                          SAVEREGS

                          IFNE        USETESTLEVEL
                          lea         TestLevelBin,a0
                          move.l      a0,LEVELDATA
                          lea         TestLevelGraphBin,a0
                          move.l      a0,LEVELGRAPHICS
                          lea         TestLevelclips,a0
                          move.l      a0,LEVELCLIPS
                          GETREGS
                          rts
                          ENDC

                          move.l      #MEMF_FAST|MEMF_CLEAR,d1
                          move.l      #LevelGraphicsSize,d0
                          move.l      4.w,a6
                          jsr         _LVOAllocMem(a6)
                          move.l      d0,LEVELGRAPHICS

                          move.l      #MEMF_FAST|MEMF_CLEAR,d1
                          move.l      #LevelClipsSize,d0
                          move.l      4.w,a6
                          jsr         _LVOAllocMem(a6)
                          move.l      d0,LEVELCLIPS

                          GETREGS  
                          rts

*********************************************************************************************
*********************************************************************************************

ReleaseLevelMemory:
  
                          IFNE        USETESTLEVEL
                          rts
                          ENDC

                          SAVEREGS

                          move.l      LEVELGRAPHICS,d1
                          beq         SkipLevelGraph

                          move.l      d1,a1
                          move.l      #LevelGraphicsSize,d0
                          move.l      4.w,a6
                          jsr         _LVOFreeMem(a6)
                          move.l      #0,LEVELGRAPHICS

SkipLevelGraph: 
                          move.l      LEVELCLIPS,d1
                          beq         SkipLevelClips

                          move.l      d1,a1
                          move.l      #LevelClipsSize,d0
                          move.l      4.w,a6
                          jsr         _LVOFreeMem(a6)
                          move.l      #0,LEVELCLIPS

SkipLevelClips:
                          GETREGS
                          rts

*********************************************************************************************
*********************************************************************************************

LoadLevel:
                          IFNE        USETESTLEVEL
                          rts
                          ENDC

                          SAVEREGS      

********************************************************************                          
; twolev.bin

                          move.l      doslib,a6
                          move.l      #LDname,d1                             
                          move.l      #1005,d2
                          jsr         _LVOOpen(a6)
                          move.l      d0,LDhandle

                          IFNE        NOLEVELUNPACK
                          move.l      doslib,a6
                          move.l      d0,d1
                          move.l      LEVELDATA,d2                           ; => LEVELDATA
                          move.l      #LevelDataSize,d3
                          jsr         _LVORead(a6)

                          move.l      doslib,a6
                          move.l      LDhandle,d1
                          jsr         _LVOClose(a6)
                          ENDc

                          IFEQ        NOLEVELUNPACK
                          move.l      doslib,a6
                          move.l      d0,d1
                          move.l      LEVELCLIPS,d2                          ; => LEVELDATA
                          move.l      #LevelClipsSize,d3
                          jsr         _LVORead(a6)

                          move.l      doslib,a6
                          move.l      LDhandle,d1
                          jsr         _LVOClose(a6)

                          move.l      LEVELCLIPS,d0
                          moveq       #0,d1
                          move.l      LEVELDATA,a0
                          lea         WorkSpace,a1
                          lea         $0.w,a2
                          jsr         UnLHA
                          ENDC  

********************************************************************
; twolev.graph.bin

                          move.l      doslib,a6
                          move.l      #LGname,d1                             
                          move.l      #1005,d2
                          jsr         _LVOOpen(a6)
                          move.l      d0,LGhandle

                          IFNE        NOLEVELUNPACK
                          move.l      doslib,a6
                          move.l      d0,d1
                          move.l      LEVELGRAPHICS,d2                       ; => LEVELGRAPHICS
                          move.l      #LevelGraphicsSize,d3
                          jsr         _LVORead(a6)

                          move.l      doslib,a6
                          move.l      LGhandle,d1
                          jsr         _LVOClose(a6)
                          ENDC  

                          IFEQ        NOLEVELUNPACK
                          move.l      doslib,a6
                          move.l      d0,d1
                          move.l      LEVELCLIPS,d2                          ; => LEVELGRAPHICS
                          move.l      #LevelClipsSize,d3
                          jsr         _LVORead(a6)

                          move.l      doslib,a6
                          move.l      LGhandle,d1
                          jsr         _LVOClose(a6)

                          move.l      LEVELCLIPS,d0
                          moveq       #0,d1
                          move.l      LEVELGRAPHICS,a0
                          lea         WorkSpace,a1
                          lea         $0.w,a2
                          jsr         UnLHA
                          ENDC  

********************************************************************
; twolev.clips

                          move.l      doslib,a6
                          move.l      #LCname,d1                             
                          move.l      #1005,d2
                          jsr         _LVOOpen(a6)
                          move.l      d0,LChandle

                          IFNE        NOLEVELUNPACK
                          move.l      doslib,a6
                          move.l      d0,d1
                          move.l      LEVELCLIPS,d2                          ; => LEVELCLIPS
                          move.l      #LevelClipsSize,d3                     ; 16000 
                          jsr         _LVORead(a6)

                          move.l      doslib,a6
                          move.l      LChandle,d1
                          jsr         _LVOClose(a6)
                          ENDC  

                          IFEQ        NOLEVELUNPACK
                          move.l      doslib,a6
                          move.l      d0,d1
                          move.l      #WorkSpace+16384,d2                    ; => LEVELCLIPS
                          move.l      #16000,d3
                          jsr         _LVORead(a6)

                          move.l      doslib,a6
                          move.l      LChandle,d1
                          jsr         _LVOClose(a6)

                          move.l      #WorkSpace+16384,d0
                          moveq       #0,d1
                          move.l      LEVELCLIPS,a0
                          lea         WorkSpace,a1
                          lea         $0,a2
                          jsr         UnLHA
                          ENDC 

********************************************************************

                          GETREGS
                          rts

*********************************************************************************************
*********************************************************************************************

InitPlayer:
; Set up initila position of player

                          move.l      LEVELDATA,a1
                          move.w      4(a1),d0
                          move.l      zoneAdds,a0
                          move.l      (a0,d0.w*4),d0
                          add.l       LEVELDATA,d0
                          move.l      d0,PLR1_Roompt

                          move.l      PLR1_Roompt,a0
                          move.l      ToZoneFloor(a0),d0
                          sub.l       #playerheight,d0
                          move.l      d0,PLR1s_yoff
                          move.l      d0,PLR1_tyoff
                          move.l      d0,PLR1_yoff
                          move.l      PLR1_Roompt,PLR1_OldRoompt

                          move.w      (a1),PLR1s_xoff
                          move.w      2(a1),PLR1s_zoff 
                    
                          move.w      (a1),PLR1_xoff
                          move.w      2(a1),PLR1_zoff 

                          cmp.w       #1,MPMode
                          bne.b       skipLevelCoop

*************************************************************

                          move.l      PLR1_Roompt,PLR2_Roompt
                          move.l      PLR2_Roompt,PLR2_OldRoompt  

                          move.l      PLR1s_yoff,d0
                          move.l      d0,PLR2s_yoff
                          move.l      d0,PLR2_tyoff
                          move.l      d0,PLR2_yoff
 
                          move.w      PLR1s_xoff,PLR2s_xoff

                          move.w      PLR1s_zoff,d0
                          add.l       #100,d0           
                          move.w      d0,PLR2s_zoff 

                          move.w      PLR1_xoff,PLR2_xoff
                          move.w      PLR1_zoff,PLR2_zoff                 
                    
                          bra         continueLevel

*************************************************************

skipLevelCoop:
                          move.l      LEVELDATA,a1
                          move.w      10(a1),d0
                          move.l      zoneAdds,a0
                          move.l      (a0,d0.w*4),d0
                          add.l       LEVELDATA,d0
                          move.l      d0,PLR2_Roompt
                    
                          move.l      PLR2_Roompt,a0
                          move.l      ToZoneFloor(a0),d0
                          sub.l       #playerheight,d0
                          move.l      d0,PLR2s_yoff
                          move.l      d0,PLR2_tyoff
                          move.l      d0,PLR2_yoff
                          move.l      PLR2_Roompt,PLR2_OldRoompt
                    
                          move.w      6(a1),PLR2s_xoff
                          move.w      8(a1),PLR2s_zoff 
                    
                          move.w      6(a1),PLR2_xoff
                          move.w      8(a1),PLR2_zoff

*************************************************************

continueLevel:
                          rts

*********************************************************************************************
; Floor lines:                                  
; A floor line is a line seperating two rooms.  
; The data for the line is therefore:           
; x,y,dx,dy,Room1,Room2                         
; For ease of editing the lines are initially   
; stored in the form startpt,endpt,Room1,Room2  
; and the program calculates x,y,dx and dy from 
; this information and stores it in a buffer.   

PointsToRotatePtr:        dc.l        0

*********************************************************************************************
; ROOM GRAPHICAL DESCRIPTIONS : WALLS AND FLOORS 

CONNECT_TABLE:            dc.l        0
ListOfGraphRooms:         dc.l        0
NastyShotData:            dc.l        0
ObjectPoints:             dc.l        0
PlayerShotData:           dc.l        0
ObjectData:               dc.l        0
FloorLines:               dc.l        0
Points:                   dc.l        0
PLR1_Obj:                 dc.l        0
PLR2_Obj:                 dc.l        0
ZoneGraphAdds:            dc.l        0
zoneAdds:                 dc.l        0
NumObjectPoints:          dc.w        0
LiftData:                 dc.l        0
DoorData:                 dc.l        0
SwitchData:               dc.l        0
CPtPos:                   dc.l        0
NumCPts:                  dc.w        0
OtherNastyData:           dc.l        0

*********************************************************************************************

LEVELDATA:                dc.l        0
LEVELGRAPHICS:            dc.l        0
LEVELCLIPS:               dc.l        0

*********************************************************************************************
; Test level

                          IFNE        USETESTLEVEL

TestLevelBin:             include     "data\rtg\level\twolev.bin.s"
                          dcb.b       20*1024,0  
                          cnop        0,32

TestLevelclips:           include     "data\rtg\level\twolev.clips.s"
                          dcb.b       20*1024,0  
                          cnop        0,32

TestLevelGraphBin:        include     "data\rtg\level\twolev.graph.bin.s"
                          dcb.b       20*1024,0  
                          cnop        0,32

                          ENDC

*********************************************************************************************