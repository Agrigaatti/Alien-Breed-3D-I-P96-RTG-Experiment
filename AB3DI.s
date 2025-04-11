*********************************************************************************************
* Alien Breed 3D I - P96PiP - HiColor15 (16bit) - Experiment 
* - For VS Code with Amiga Assembly extension (Paul Raingeard)
* - For WinUAE + P96 RTG + 68040 + JIT + 2mb CHIP + 2mb FAST + KS ROM v3.2
* - Based on the "4000test.s" source code
* - Uses P96 libraries for RTG graphics
* - Needs data files from the original game
*
* Original Team 17 sources : https://github.com/videogamepreservation/alienbreed3dii.git
* John Girvin's RTG version sources : https://github.com/mheyer32/ab3d-rtg
* Copper version sources : https://github.com/Agrigaatti/Alien-Breed-3D-I 
*
* Missing files : Vector objects (*ind, pipe, exit) are already copied from the John Girvin's rtg version
*                 Copy data ('includes', 'sounds' and 'levels') files from the original game to '\uae\dh0\disk' folder
*                 Buy the newest P96 library version from Individual Computers : https://icomp.de/shop-icomp/en/shop/product/p96-rtg-software-not-logged-in.html
*                 or get the shareware version 2.0 from aminet.net: https://aminet.net/package/driver/video/Picasso96
*                 Coded with the licensed P96 V3.4.1 libraries
*
* History :
*   12/2022 : Builds & runs & can play : Crom / Extend 
*   01/2023 : Added exit, wasd-control ('n'-key) and revealed few tech-tests : Crom / Extend 
*   01/2023 : Added auto save of level passwords on exit (use 'TAB'-key on main menu to change levels) : Crom / Extend
*   02/2023 : Added experimental co-op mode for the multiplayer game : Crom / Extend
*   08/2024 : P96 RTG experiment, no major rewrites : Crom / Extend
*
* Known issues:
* - Dead monsters get out of sync in the experimental co-operation multiplayer game. 
* - And lot of other issues...
* 
*********************************************************************************************

AB3DVERSION         EQU "0.40"                                                                  ; 4 chars
AB3DLABEL           EQU "ERTG"                                                                  ; 4 chars

*********************************************************************************************

; RTG
USE1X1              EQU 1                                                                       ; 1 = 1x1/192*160
USE2X2SCALED        EQU 0                                                                       ; 0 = 1x1/96*80, 1 = 2x2/96*80 

; Trainer
STARTLEVEL          EQU 0                                                                       ; Commecial levels: 0 => 1 First - 15 => Final
MULTIPASS           EQU 0                                                                                       
UNLIMITEDAMMO       EQU 0
UNLIMITEDHITS       EQU 0

; Features
ENABLETITLEMUSIC    EQU 1
ENABLEBGMUSIC       EQU 0
ENABLETIMER         EQU 0
ENABLEFACES         EQU 0
ENABLEGLASSBALL     EQU 0
ENABLEPATH          EQU 0                                                                       ; Note: Set first char to 'p' in the 'prefs' file
ENABLESEEWALL       EQU 0                                                                       ; Note: Not really tested!
ENABLEADVSERIAL     EQU 0                                                                       ; Note: Not tested!
ENABLEENDSCROLLTEST EQU 0

; Level packs
LEVELPACK           EQU 0                                                                       ; 0 = Commercial, 1 = Custom, 2 = Test
NOLEVELUNPACK       EQU 0                                                                       ; Is levels unpacked?

*********************************************************************************************

                          opt                P=68020                                            ;,OW+

*********************************************************************************************

                          incdir             "includes"
                          include            "AB3DI.i"
                          include            "AB3DIRTG.i"
                          include            "macros.i"
                          include            "defs.i"

                          include            "exec/memory.i"
                          include            "hardware/intbits.i"

*********************************************************************************************

                          SECTION            MainCode,CODE_F

*********************************************************************************************

Main:
; d0 = dosCmdLen
; a0 = dosCmdBuf

                          STOREREGS
                          move.l             #0,d0

*******************************************************************

                          jsr                OSAppStartup

*******************************************************************

                          jsr                InitOSBase
                          jsr                OpenConsole                             


*******************************************************************

                          jsr                OpenAudioIO
                          tst                d0
                          bne                exitByAudIO

                          jsr                OpenSerialIO
                          tst                d0
                          bne                exitBySerialIO

*******************************************************************

                          jsr                OpenP96RTGWindow
                          tst                d0
                          bne                exitByP96

*******************************************************************

                          lea                StateRegistry,a0
                          jsr                AddControlGrabber

*******************************************************************

                          jsr                SetupGame
                          jsr                PlayGame
                          jsr                TearDownGame

*******************************************************************

                          jsr                RemoveControlGrabber

*******************************************************************

                          jsr                CloseP96RTGWindow
exitByP96:

*******************************************************************

                          jsr                CloseSerialIO

exitBySerialIO
                          jsr                CloseAudioIO
                          
exitByAudIO:                          

*******************************************************************

                          jsr                CloseConsole

*******************************************************************

                          jsr                CleanupOSBase

*******************************************************************

                          jsr                OSAppExit

                          RESTOREREGS
                          rts

*********************************************************************************************
*********************************************************************************************

SetupGame:
; OS ok
                         
                          SUPERVISOR         SetDataCacheOff

*******************************************************************
; Multi player
; 19200 baud, 8 bits, no parity = 13
; 9600 baud, 8 bits, no parity = 372
; 1 / ((N+1) * 0.2794 microseconds) 

                          lea                $dff000,a6
                          move.w             #13,serper(a6)

*******************************************************************

                          clr.b              PLR1KEYS
                          clr.b              PLR1PATH
                          clr.b              PLR1MOUSE
                          clr.b              PLR1JOY
                          st                 PLR1MOUSEKBD        

                          clr.b              PLR2KEYS
                          clr.b              PLR2PATH
                          clr.b              PLR2MOUSE
                          clr.b              PLR2JOY
                          st                 PLR2MOUSEKBD  

*******************************************************************

                          jsr                OpenDosLibrary                                     ; AB3DI
                          jsr                OpenLowLevelLibrary                                ; CD32Joy

*******************************************************************

                          jsr                AllocTextScrn                                      ; AB3DI                                 
                          jsr                AllocLevelData

*******************************************************************

                          jsr                SetupTextScrn
                          jsr                ClearTextScrnSprites

*******************************************************************

                          move.l             4.w,a6
                          lea                CopInt,a1
                          moveq              #INTB_VERTB,d0
                          jsr                _LVOAddIntServer(a6)

*******************************************************************

                          ;move.l             4.w,a6
                          ;lea                KeyInt,a1
                          ;moveq              #INTB_PORTS,d0
                          ;DEL:jsr                _LVOAddIntServer(a6)

*******************************************************************

                          jsr                LoadPasswords

*******************************************************************

                          jsr                LoadPrefs

*******************************************************************

                          jsr                SetupMouseSensitivity

*******************************************************************
; Setup default rendering mode

                          st                 anyFloor
                          clr.b              useBlackFloor                           
                          st                 selectGouraud
                          move.l             #FloorLine,TheFloorLineRoutine          

*********************************************************************************************

                          move.l             #0,d0
                          rts

*********************************************************************************************
*********************************************************************************************

TearDownGame:

                          jsr                mt_end                                             ; Disable audio and volume down

*******************************************************************

                          move.l             4.w,a6
                          lea                CopInt,a1
                          moveq              #INTB_VERTB,d0
                          jsr                _LVORemIntServer(a6)

*******************************************************************

                          jsr                SavePasswords                                      ; LoadFromDisks

*******************************************************************

                          jsr                CloseLowLevelLibrary                               ; CD32Joy
                          jsr                CloseDosLibrary                                    ; AB3DI

*******************************************************************

                          jsr                ReleaseTextScrn                                    ; AB3DI
                          jsr                ReleaseLevelData
                          jsr                ReleaseLevelMemory                                 

*******************************************************************

                          jsr                ReleaseFloorMemory                                 ; LoadFromDisks
                          jsr                ReleaseObjectMemory                                ; LoadFromDisks
                          jsr                ReleaseSampleMemory                                ; LoadFromDisks

*******************************************************************

                          jsr                ReleaseWallMemory                                  ; WallChunk

*******************************************************************

                          jsr                ReleaseTitleMemory                                 ; ControlLoop

                          rts

********************************************************************************************

OpenDosLibrary:

                          move.l             4.w,a6
                          move.l             #doslibname,a1
                          moveq              #0,d0
                          jsr                _LVOOpenLibrary(a6)
                          move.l             d0,doslib

                          rts

*********************************************************************************************

CloseDosLibrary:

                          move.l             doslib,a1
                          tst.l              a1
                          beq.b              .Exit

                          move.l             4.w,a6
                          jsr                _LVOCloseLibrary(a6)

.Exit:
                          rts

*********************************************************************************************

LoadPrefs:

                          move.l             doslib,a6
                          move.l             #Prefsname,d1
                          move.l             #1005,d2
                          jsr                _LVOOpen(a6)
                          tst.l              d0
                          beq                skipPrefs
                          move.l             d0,Prefshandle

                          move.l             doslib,a6
                          move.l             d0,d1
                          move.l             #Prefsfile,d2
                          move.l             #50,d3
                          jsr                _LVORead(a6)

                          move.l             doslib,a6
                          move.l             Prefshandle,d1
                          jsr                _LVOClose(a6)

skipPrefs:
                          rts

*********************************************************************************************

SetupTextScrn:

                          move.l             TEXTSCRN,d0
                          move.w             d0,TSPTl
                          swap               d0
                          move.w             d0,TSPTh

                          rts

*********************************************************************************************

ClearTextScrnSprites:

                          move.l             #nullSpr,d0
                          move.w             d0,txs0l
                          move.w             d0,txs1l
                          move.w             d0,txs2l
                          move.w             d0,txs3l
                          move.w             d0,txs4l
                          move.w             d0,txs5l
                          move.w             d0,txs6l
                          move.w             d0,txs7l
                          swap               d0
                          move.w             d0,txs0h
                          move.w             d0,txs1h
                          move.w             d0,txs2h
                          move.w             d0,txs3h
                          move.w             d0,txs4h
                          move.w             d0,txs5h
                          move.w             d0,txs6h
                          move.w             d0,txs7h

                          rts

*********************************************************************************************
; Supervisor mode cache commands

                          include            "CacheControl.s"

*********************************************************************************************
; OS friendly

                          include            "OSFriendly.s"

*********************************************************************************************
; OS Base

                          include            "OSBase.s"

*********************************************************************************************
; OS P96 PiP Window

                          include            "OSWindow.s"

*********************************************************************************************
; OS P96 RTG handling

                          include            "OSP96rtg.s"

*********************************************************************************************
; OS Input

                          include            "OSInput.s"

*********************************************************************************************
; OS audio

                          include            "OSAudio.s"

*********************************************************************************************
; OS serial

                          include            "OSSerial.s"

*********************************************************************************************

DrawLevelText:

                          move.l             #LEVELTEXT,a0
                          move.w             PLOPT,d0

                          muls               #82*16,d0
                          add.l              d0,a0
 
                          move.w             #14,d7
                          move.w             #0,d0

DownText:
                          move.l             TEXTSCRN,a1
                          jsr                DrawLineOfText
                          addq               #1,d0
                          lea                82(a0),a0
                          dbra               d7,DownText
                          rts

*********************************************************************************************

DrawMasterText:

                          lea                MpMasterText(pc),a0
                          move.w             #14,d7
                          move.w             #0,d0

DownMasterText:
                          move.l             TEXTSCRN,a1
                          jsr                DrawLineOfText
                          addq               #1,d0
                          lea                82(a0),a0
                          dbra               d7,DownMasterText
                          rts

*********************************************************************************************

DrawSlaveText:

                          lea                MpSlaveText(pc),a0
                          move.w             #14,d7
                          move.w             #0,d0

DownSlaveText:
                          move.l             TEXTSCRN,a1
                          jsr                DrawLineOfText
                          addq               #1,d0
                          lea                82(a0),a0
                          dbra               d7,DownSlaveText
                          rts

*********************************************************************************************

FONTADDRS:
                          dc.l               ENDFONT0,CHARWIDTHS0
                          dc.l               ENDFONT1,CHARWIDTHS1
                          dc.l               ENDFONT2,CHARWIDTHS2

*********************************************************************************************						  
 
ENDFONT0:                 incbin             "data/fonts/endfont0"
CHARWIDTHS0:              incbin             "data/fonts/charwidths0"
ENDFONT1:                 incbin             "data/fonts/endfont1"
CHARWIDTHS1:              incbin             "data/fonts/charwidths1"
ENDFONT2:                 incbin             "data/fonts/endfont2"
CHARWIDTHS2:              incbin             "data/fonts/charwidths2"
                          even

*********************************************************************************************

DrawLineOfText:
; a1 = screen pointer
; a0 = text
; d0 = text line

                          movem.l            d0/a0/d7,-(a7)

                          muls               #80*16,d0
                          add.l              d0,a1                                              ; screen pointer
 
                          move.l             #FONTADDRS,a3
                          moveq              #0,d0
                          move.b             (a0)+,d0
                          move.l             (a3,d0.w*8),a2
                          move.l             4(a3,d0.w*8),a3
 
                          moveq              #0,d1                                              ; width counter:
                          move.w             #79,d6
                          tst.b              (a0)+
                          beq.s              NOTCENTRED

                          moveq              #-1,d5
                          move.l             a0,a4
                          moveq              #0,d2
                          moveq              #0,d3
                          move.w             #79,d0                                             ; number of chars

.addup:
                          addq               #1,d5
                          move.b             (a4)+,d2
                          move.b             -32(a3,d2.w),d4
                          add.w              d4,d3
                          cmp.b              #32,d2
                          beq.s              .DONTPUTIN

                          move.w             d5,d6
                          move.w             d3,d1

.DONTPUTIN:
                          dbra               d0,.addup
                          asr.w              #1,d1
                          neg.w              d1
                          add.w              #320,d1                                            ; horiz pos of start x

NOTCENTRED:
                          move.w             d6,d7

DOACHAR:
                          moveq              #0,d2
                          move.b             (a0)+,d2
                          sub.w              #32,d2
                          moveq              #0,d6
                          move.b             (a3,d2.w),d6
                          asl.w              #5,d2
                          lea                (a2,d2.w),a4                                       ; char font

val                       SET                0
                          REPT               16
                          move.w             (a4)+,d0
                          bfins              d0,val(a1){d1:d6}
val                       SET                val+80
                          ENDR

                          add.w              d6,d1
                          dbra               d7,DOACHAR
                          movem.l            (a7)+,d0/a0/d7
                          rts 
 
*********************************************************************************************

ClrWeenScrn:
                          move.l             TEXTSCRN,a0
                          move.w             #(10240/16)-1,d0
                          moveq              #$0,d1

.lll:
                          move.l             d1,(a0)+
                          move.l             d1,(a0)+
                          move.l             d1,(a0)+
                          move.l             d1,(a0)+
                          move.l             d1,(a0)+
                          move.l             d1,(a0)+
                          move.l             d1,(a0)+
                          move.l             d1,(a0)+
                          dbra               d0,.lll

                          rts

*********************************************************************************************

PlayTheGame:

********************************************************************
; Setup

                          jsr                ClearPiPWindow                                     ; RTG

                          move.w             #%1000001000001111,dmacon(a6)                      ; Enable audio dma (0-3=AUDEN)
                          move.w             #%1100011110000000,intena(a6)                      ; Enable channel block finnished (7-10=Audio channel 3 block finished)

********************************************************************
; Clear text

                          move.w             #0,TXTCOLL
                          bsr.b              ClrWeenScrn 

********************************************************************
; Select text

                          cmp.b              #'n',mors
                          bne.s              .noLevelText

                          bsr                DrawLevelText
                          bra                .noText

.noLevelText: 
                          cmp.b              #'m',mors
                          bne.s              .noMasterText

                          bsr                DrawMasterText
                          bra                .noText

.noMasterText: 
                          cmp.b              #'s',mors
                          bne                .noText

                          bsr                DrawSlaveText

.noText: 

********************************************************************
; RTG change

                          move.l             #Text24bitPalette,PtaPalettePtr
                          move.l             TEXTSCRN,PtaBplPtr
                          move.l             #PlaneBuffer0,PtaBplColBufPtr
                          move.l             #640,PtaBplWidth
                          move.l             #256,PtaBplHeight
                          move.l             #1,PtaBplCount
                          move.l             #0,PtaBplModulo
                          move.l             #0,PtaBplOffsetInBytes
                          jsr                CopyPlaneToColorBuffer

********************************************************************

                          move.l             #PlaneBuffer0,bplHiColBufPtr
                          move.l             #1,bplHiColRtgX
                          move.l             #1,bplHiColRtgY
                          jsr                DrawAB3dHiColor15BufferToWindow                          

; End of RTG change
********************************************************************
; Fadeup text

                          move.w             #$10,d0
                          move.w             #7,d1
 
fdup:
                          move.w             d0,TXTCOLL
                          
                          add.w              #$121,d0
                          WAITFORVERTBREQ

                          dbra               d1,fdup

********************************************************************
; Get level memory
 
                          jsr                AllocLevelMemory                                   

********************************************************************
; Setup player (MP: Send level number) 

                          lea                $dff000,a6
                          jsr                SetPlayers

********************************************************************
; Load level files
                          jsr                LoadLevel  

********************************************************************

                          cmp.b              #'s',Prefsfile+2
                          seq                STEREO

********************************************************************

                          lea                $dff000,a6
                          move.w             #$00ff,adkcon(a6)                                  ; Audio modulos

                          bra                blag

                          jsr                CloseAudioIO
                          rts

*********************************************************************************************

saveit:                   ds.l               10

*********************************************************************************************

doslibname:               dc.b               'dos.library',0
                          cnop               0,32

doslib:                   dc.l               0

*********************************************************************************************
; Menu status

mors:                     dc.w               0

*********************************************************************************************
; Level packs
                          IFEQ               LEVELPACK-2
                          include            "LevelPack-2-Test.s"
                          ENDC     

                          IFEQ               LEVELPACK-1
                          include            "LevelPack-1-Custom.s"
                          ENDC     

                          IFEQ               LEVELPACK
                          include            "LevelPack-0-Commercial.s"
                          ENDC     

*********************************************************************************************

LChandle:                 dc.l               0
                          cnop               0,32

*********************************************************************************************

Prefsname:                dc.b               'prefs',0
                          cnop               0,32

Prefshandle:              dc.l               0

Prefsfile:                dc.b               'k4nxs'
                          ds.b               50
                          cnop               0,32

*********************************************************************************************

CopInt:
                          dc.l               0,0
                          dc.b               NT_INTERRUPT,100
                          dc.l               CopIntName
                          dc.l               0
                          dc.l               cop_interrupt

CopIntName:               dc.b               "AB3D CopInt",0
                          cnop               0,32

*********************************************************************************************

KeyInt:
                          dc.l               0,0
                          dc.b               NT_INTERRUPT,127
                          dc.l               KeyIntName
                          dc.l               0
                          dc.l               key_interrupt

KeyIntName:               dc.b               "AB3D KeyInt",0
                          cnop               0,32

*********************************************************************************************

blag:
; Initialize level 
; Poke all clip offsets into correct bit of level data

****************************************************************
; Level graphics data

                          move.l             LEVELGRAPHICS,a0

                          move.l             (a0),a1                                            ; OffsetToDoors
                          add.l              a0,a1
                          move.l             a1,DoorData

                          move.l             4(a0),a1                                           ; OffsetToLifts
                          add.l              a0,a1
                          move.l             a1,LiftData

                          move.l             8(a0),a1                                           ; OffsetToSwitches
                          add.l              a0,a1
                          move.l             a1,SwitchData

                          move.l             12(a0),a1                                          ; OffsetToZoneGraph
                          add.l              a0,a1
                          move.l             a1,ZoneGraphAdds

                          adda.w             #16,a0                                             ; OffsetToZone
                          move.l             a0,zoneAdds

****************************************************************
; Level data

                          move.l             LEVELDATA,a1

                          move.w             14(a1),d0                                          ; NumberOfPoints
                          move.l             22(a1),a2                                          ; OffsetToPoints
                          add.l              a1,a2
                          move.l             a2,Points
                          lea                4(a2,d0.w*4),a2
                          move.l             a2,pointBrights

                          move.w             20(a1),NumObjectPoints

                          move.l             26(a1),a2                                          ; OffsetToFloorLines
                          add.l              a1,a2
                          move.l             a2,FloorLines

                          move.l             30(a1),a2                                          ; OffsetToObjectData
                          add.l              a1,a2
                          move.l             a2,ObjectData

****************************************************************
; Just for charles
                        ; sub.w #40,4(a2)             ; objUnknown4 (object y?)
                        ; move.w #$6060,6(a2)         ; objUnknown6
                        ; move.l #$d0000,8(a2)        ; objDeadFrameH
                        ; move.w #45*256+45,14(a2)    ; objUnknown14
****************************************************************

                          move.l             34(a1),a2                                          ; OffsetToPlayerShotData
                          add.l              a1,a2
                          move.l             a2,PlayerShotData

                          move.l             38(a1),a2                                          ; OffsetToNastyShotData
                          add.l              a1,a2
                          move.l             a2,NastyShotData                                   ; Max 20 shots
 
                          lea                64*20(a2),a2                                       ; OffsetToOtherNastyData   
                          move.l             a2,OtherNastyData
 
                          move.l             42(a1),a2                                          ; OffsetToObjectPoints
                          add.l              a1,a2
                          move.l             a2,ObjectPoints

                          move.l             46(a1),a2                                          ; OffsetToPlayerObject
                          add.l              a1,a2
                          move.l             a2,PLR1_Obj

                          move.l             50(a1),a2                                          ; OffsetToPlayer2Object
                          add.l              a1,a2
                          move.l             a2,PLR2_Obj

                        ; bra noclips
  
****************************************************************
; Level clips

                          move.l             LEVELCLIPS,a2
                          moveq              #0,d0
                          move.w             16(a1),d7                                          ; NumberOfZones

assignclips:
                          move.l             (a0)+,a3                                           ; a0=LevelGraphics + StartOfZoneOffsets => a3=Offset to zone at level data (= OffsetAdd)
                          add.l              a1,a3                                              ; a1=LevelData + OffsetAdds - a3=pointer to a zone at level data
                          adda.w             #ToListOfGraph,a3                                  ; pointer to zonelist

dowholezone:
                          tst.w              (a3)
                          blt.s              nomorethiszone

                          tst.w              2(a3)
                          blt.s              thisonenull

                          move.l             d0,d1
                          asr.l              #1,d1
                          move.w             d1,2(a3)

findnextclip:
                          cmp.w              #-2,(a2,d0.l)
                          beq.s              foundnextclip

                          addq.l             #2,d0
                          bra.s              findnextclip

foundnextclip:
                          addq.l             #2,d0

thisonenull:
                          addq               #8,a3 
                          bra.s              dowholezone

nomorethiszone:
                          dbra               d7,assignclips
 
                          lea                (a2,d0.l),a2
                          move.l             a2,CONNECT_TABLE
 
noclips:

****************************************************************
 
                          cmp.b              #'k',Prefsfile
                          bne.s              nkb
                          st                 PLR1KEYS
                          clr.b              PLR1PATH
                          clr.b              PLR1MOUSE
                          clr.b              PLR1JOY
                          clr.b              PLR1MOUSEKBD

nkb:
                          cmp.b              #'m',Prefsfile
                          bne.s              nmc
                          clr.b              PLR1KEYS
                          clr.b              PLR1PATH
                          st                 PLR1MOUSE
                          clr.b              PLR1JOY
                          clr.b              PLR1MOUSEKBD

nmc:
                          cmp.b              #'n',Prefsfile
                          bne.s              nmkbd
                          clr.b              PLR1KEYS
                          clr.b              PLR1PATH
                          clr.b              PLR1MOUSE
                          clr.b              PLR1JOY
                          st                 PLR1MOUSEKBD

nmkbd:
                          cmp.b              #'j',Prefsfile
                          bne.s              njc
                          clr.b              PLR1KEYS
                          clr.b              PLR1PATH
                          clr.b              PLR1MOUSE
                          st                 PLR1JOY
                          clr.b              PLR1MOUSEKBD

njc:
                          cmp.b              #'p',Prefsfile                                                       
                          bne.s              nfp
                          clr.b              PLR1KEYS
                          st                 PLR1PATH
                          clr.b              PLR1MOUSE
                          clr.b              PLR1JOY
                          clr.b              PLR1MOUSEKBD

nfp:

****************************************************************

                          clr.b              PLR1_StoodInTop

                          move.l             #playerheight,PLR1s_height
 
                          move.l             #empty,pos1LEFT
                          move.l             #empty,pos2LEFT
                          move.l             #empty,pos1RIGHT
                          move.l             #empty,pos2RIGHT
                          move.l             #emptyend,Samp0endLEFT
                          move.l             #emptyend,Samp1endLEFT
                          move.l             #emptyend,Samp0endRIGHT
                          move.l             #emptyend,Samp1endRIGHT
 
 ****************************************************************

                          move.l             #nullSpr,d0
                          move.w             d0,s4l
                          move.w             d0,s5l
                          move.w             d0,s6l
                          move.w             d0,s7l
                          swap               d0
                          move.w             d0,s4h
                          move.w             d0,s5h
                          move.w             d0,s6h
                          move.w             d0,s7h 
 
****************************************************************

                          move.l             #nullLine,d0
                          move.w             d0,n1l
                          swap               d0
                          move.w             d0,n1h
 
****************************************************************
 
                          move.l             Panel,d0
                          move.w             d0,p1l
                          swap               d0
                          move.w             d0,p1h
                          swap               d0
                          add.l              #40,d0                                             ; 320 pix
                          move.w             d0,p2l
                          swap               d0
                          move.w             d0,p2h
                          swap               d0
                          add.l              #40,d0
                          move.w             d0,p3l
                          swap               d0
                          move.w             d0,p3h
                          swap               d0
                          add.l              #40,d0
                          move.w             d0,p4l
                          swap               d0
                          move.w             d0,p4h
                          swap               d0
                          add.l              #40,d0
                          move.w             d0,p5l
                          swap               d0
                          move.w             d0,p5h
                          swap               d0
                          add.l              #40,d0
                          move.w             d0,p6l
                          swap               d0
                          move.w             d0,p6h
                          swap               d0
                          add.l              #40,d0
                          move.w             d0,p7l
                          swap               d0
                          move.w             d0,p7h
                          swap               d0
                          add.l              #40,d0
                          move.w             d0,p8l
                          swap               d0
                          move.w             d0,p8h
 
****************************************************************
; Timer screen setup

                          IFNE               ENABLETIMER
                          jsr                SetupCopperForTimerTest
                          ENDC 

****************************************************************
; Setup sprite borders
; Note: Same as in ScreenSetup.s

                          move.l             #borders,d0
                          move.w             d0,s0l
                          swap               d0
                          move.w             d0,s0h
                          move.l             #borders+2592,d0                                   ; $0A20
                          move.w             d0,s1l
                          swap               d0
                          move.w             d0,s1h
                          move.l             #borders+2592*2,d0
                          move.w             d0,s2l
                          swap               d0
                          move.w             d0,s2h
                          move.l             #borders+2592*3,d0
                          move.w             d0,s3l
                          swap               d0
                          move.w             d0,s3h
 
****************************************************************
; Setup sprites positions
; Note: Sprites are 64 bit wide and attached type!
;       (Control words are 64 bit wides also!)
; 
; SPRITE CONTROL WORD 1: SPRxPOS
;  Bits 15-8 contain the low 8 bits of VSTART
;  Bits  7-0 contain the high 8 bits of HSTART
;
; SPRITE CONTROL WORD 2: SPRxCTL
;  Bits 15-8          The low eight bits of VSTOP
;  Bit  7             (Used in attachment)
;  Bits 6-3           Unused (make zero)
;  Bit  2             The VSTART high bit
;  Bit  1             The VSTOP high bit
;  Bit  0             The HSTART low bit

                          move.w             #52*256+64,borders                                 ; X=64 Y=52
                          move.w             #212*256+0,borders+8                               ; YStop=212

                          move.w             #52*256+64,borders+2592                            ; X=64 Y=52
                          move.w             #212*256+128,borders+8+2592                        ; YStop=212 CTRL=%10000000 (ATTACH)

                          move.w             #52*256+192,borders+2592*2                         ; X=192 Y=52
                          move.w             #212*256+0,borders+8+2592*2                        ; YStop=212

                          move.w             #52*256+192,borders+2592*3                         ; X=192 Y=52
                          move.w             #212*256+128,borders+8+2592*3                      ; YStop=212 CTRL=%10000000 (ATTACH)
 
 ****************************************************************
; Faces

                          IFNE               ENABLEFACES
                          jsr                SetupCopperForFaceTest
                          ENDC

 ****************************************************************

                          move.l             #BigFieldCop,d0
                          move.w             d0,ocl
                          swap               d0
                          move.w             d0,och

****************************************************************

                          lea                $dff000,a6
                          bset.b             #1,$bfe001                                         ; LED / Filter
                          move.w             #$00ff,adkcon(a6)                                  ; Audio modulos

****************************************************************

                          move.l             #scrn,d0
                          move.w             d0,pl1l
                          swap               d0
                          move.w             d0,pl1h

                          move.l             #scrn+40,d0
                          move.w             d0,pl2l
                          swap               d0
                          move.w             d0,pl2h

                          move.l             #scrn+80,d0
                          move.w             d0,pl3l
                          swap               d0
                          move.w             d0,pl3h

                          move.l             #scrn+120,d0
                          move.w             d0,pl4l
                          swap               d0
                          move.w             d0,pl4h

                          move.l             #scrn+160,d0
                          move.w             d0,pl5l
                          swap               d0
                          move.w             d0,pl5h

                          move.l             #scrn+200,d0
                          move.w             d0,pl6l
                          swap               d0
                          move.w             d0,pl6h

                          move.l             #scrn+240,d0
                          move.w             d0,pl7l
                          swap               d0
                          move.w             d0,pl7h

****************************************************************

                          jsr                InitPlayer

****************************************************************
 ; Audio

                          lea                $dff000,a6
 
                          move.l             #null,$a0(a6)
                          move.w             #100,$a4(a6)
                          move.w             #443,$a6(a6)
                          move.w             #63,$a8(a6)

                          move.l             #null2,$b0(a6)
                          move.w             #100,$b4(a6)
                          move.w             #443,$b6(a6)
                          move.w             #63,$b8(a6)

                          move.l             #null4,$c0(a6)
                          move.w             #100,$c4(a6)
                          move.w             #443,$c6(a6)
                          move.w             #63,$c8(a6)

                          move.l             #null3,$d0(a6)
                          move.w             #100,$d4(a6)
                          move.w             #443,$d6(a6)
                          move.w             #63,$d8(a6)

****************************************************************

                          move.l             #tab,a1
                          move.w             #64,d7
                          move.w             #0,d6

outerlop:
                          move.l             #pretab,a0
                          move.w             #255,d5

scaledownlop:
                          move.b             (a0)+,d0
                          ext.w              d0
                          ext.l              d0
                          muls               d6,d0
                          asr.l              #6,d0
                          move.b             d0,(a1)+
                          dbra               d5,scaledownlop

                          addq               #1,d6
                          dbra               d7,outerlop
 
****************************************************************

                          lea                $dff000,a6

                          IFEQ               MULTIPASS
                          move.w             #0,Conditions              
                          ENDC
                          IFNE               MULTIPASS
                          move.w             #%111111111111,Conditions              
                          ENDC

                          cmp.b              #'n',mors
                          beq.s              .nokeys

                          cmp.w              #1,MPMode
                          beq.b              .nokeys

                          move.w             #%111111111111,Conditions                          ; Multi player game

.nokeys:

****************************************************************
; Cleanup keymap

                          move.l             #KeyMap,a5
                          clr.b              $45(a5)                                            ; Esc
                          clr.b              $19(a5)                                            ; Pause

****************************************************************

                          clr.b              UseAllChannels 

****************************************************************
; BG music

                          IFEQ               ENABLEBGMUSIC
                          cmp.b              #'b',Prefsfile+3
                          bne.s              .noback1
                          ENDC

                          move.l             #inGame,mt_data                         
                          jsr                mt_init

                          st                 CHANNELDATA
                          st                 CHANNELDATA+8
                          st                 CHANNELDATA+16
                          st                 CHANNELDATA+24

.noback1:
 
 ****************************************************************

                          move.l             SampleList+6*8,pos0LEFT
                          move.l             SampleList+6*8+4,Samp0endLEFT

                          move.l             #playerheight,PLR1s_targheight
                          move.l             #playerheight,PLR1s_height
                          move.l             #playerheight,PLR2s_targheight
                          move.l             #playerheight,PLR2s_height

****************************************************************

                        ; cmp.b              #'n',mors
                        ; beq.s              nohandshake
                                                
                        ; move.b             #%11011000,$bfd200
                        ; move.b             #%00010000,$bfd000

                        ;waitloop:
                        ; btst.b             #4,$bfd000
                        ; bne.s              waitloop
                        ; move.b             #%11000000,$bfd200
                                                
                        ;wtmouse:
                        ; btst               #6,$bfe001                                                           ; LMB port 1
                        ; bne.s              wtmouse
                                                
                        ;nohandshake:

****************************************************************

                          jsr                ClearKeyboard
                          jsr                MakeBackROut

****************************************************************

                          SUPERVISOR         SetInstCacheFreezeOff 
                          SUPERVISOR         SetDataCacheOn

****************************************************************

                          move.w             #0,hitcol
                          move.w             #0,hitcol2

****************************************************************
; Single- / Multiplayer

                          clr.b              MASTERQUITTING
                          cmp.b              #'n',mors
                          seq                SLAVEQUITTING                                                        

                          cmp.b              #'n',mors
                          beq.s              skipPlrEnergy
                          move.w             #PlayerMaxEnergy,PLR1_energy

skipPlrEnergy:                       
                          move.w             #PlayerMaxEnergy,PLR2_energy

                          cmp.b              #'n',mors
                          bne.s              NOCLTXT

****************************************************************
; Wait single player
 
                          move.b             #0,lastpressed

.wtpress:

****************************************************************
; RTG change

                          jsr                HandleP96RTGWindowInputs

; End of RTG change
****************************************************************

                          btst.b             #0,Buttons                                    
                          beq.s              CLOSETXT

                          btst.b             #3,Buttons                                    
                          beq.s              CLOSETXT
                          
                          tst.b              lastpressed
                          beq.s              .wtpress

CLOSETXT:

****************************************************************
; Fade text

                          lea                $dff000,a6

                          move.w             #$8f8,d0
                          move.w             #7,d1
 
fdup1:
                          move.w             d0,TXTCOLL
                          sub.w              #$121,d0

                          WAITFORVERTBREQ

                          dbra               d1,fdup1

                          move.w             #0,TXTCOLL

****************************************************************

NOCLTXT:

********************************************************************
; RTG change

                          jsr                ClearPiPWindow

; End of RTG change
********************************************************************

                          lea                $dff000,a6

                          clr.b              PLR1_Ducked
                          clr.b              PLR2_Ducked
                          clr.b              p1_ducked
                          clr.b              p2_ducked

****************************************************************
; Test end scroll text
                          
                          IFNE               ENABLEENDSCROLLTEST
                          bra                testEndScroll
                          ENDC

****************************************************************

                          st                 doAnything
                          jsr                ClearP96RTGWindowPointer
                          move.w             #1,TrapMouse

*********************************************************************************************
*********************************************************************************************
; Main loop
; mors (multi or single): m = master, s = slave, n = single, q = quit/exit

mainLoop:
                          jsr                HandleP96RTGWindowInputs

                          SAVEREGS
                          lea                conLayoutTxt,a0
                          lea                conLayoutData,a1

                          move.w             PLR1_xoff,(a1)
                          move.b             RawKey,3(a1)
                          move.w             PLR1_yoff,4(a1)
                          move.b             Mouse0X,7(a1)
                          move.w             PLR1_zoff,8(a1)
                          move.b             Mouse0Y,11(a1)
                          move.w             PLR1_angspd,12(a1)
                          move.w             PLR1_angpos,14(a1)
                          move.w             PLR1_GunSelected,16(a1)
                          move.w             PLR1_Zone,18(a1)

                          jsr                WriteToConsole
                          GETREGS

                          lea                $dff000,a6

****************************************************************
; SP pause
                          cmp.b              #'n',mors
                          bne.b              .skipSpPause

                          lea                KeyMap,a5
 
                          tst.b              $19(a5)                                            ; Pause key (down)
                          beq.s              .skipSpPause
                          clr.b              doAnything
 
.waitSpPauseRel:
                          tst.b              PLR1JOY
                          beq.s              .noSpJoy
                          jsr                _ReadJoy1

.noSpJoy:
                          tst.b              $19(a5)                                            ; Pause key (up)
                          bne.s              .waitSpPauseRel
                          
                          bsr                PauseOpts 
                          st                 doAnything

.skipSpPause:
                         
****************************************************************

                          st                 READCONTROLS

                          move.w             hitcol,d0
                          beq.s              nofadedownhc

                          sub.w              #$100,d0
                          move.w             d0,hitcol
                          move.w             d0,hitcol2

nofadedownhc:

****************************************************************
;  Multi player pause

                          cmp.b              #'n',mors
                          beq                skipMpPause

                          move.b             SLAVEPAUSE,d0
                          or.b               MASTERPAUSE,d0
                          beq                skipMpPause

                          clr.b              doAnything
 
.waitMpPauseRel:

                          cmp.b              #'m',mors
                          bne.s              .notMasterJoy

                          tst.b              PLR1JOY
                          beq.s              .notMasterJoy
                          jsr                _ReadJoy1

.notMasterJoy:
                          cmp.b              #'s',mors
                          bne.s              .notSlaveJoy

                          tst.b              PLR2JOY
                          beq.s              .notSlaveJoy
                          jsr                _ReadJoy2

.notSlaveJoy:
                          lea                KeyMap,a5

                          tst.b              $19(a5)                                            ; Pause key
                          bne.s              .waitMpPauseRel

                          bsr                PauseOpts
 
                          cmp.b              #'m',mors
                          bne.s              .notMasterSync

                          IFNE               ENABLEADVSERIAL
                          jsr                INITSEND                                           ; Sync slave
                          jsr                SENDLONG
                          jsr                SENDLAST
                          ENDC

                          IFEQ               ENABLEADVSERIAL
                          jsr                SENDFIRST
                          ENDC
                         
.notMasterSync:
                          cmp.b              #'s',mors
                          bne.s              .notSlaveSync

                          IFNE               ENABLEADVSERIAL
                          jsr                INITREC                                            ; Wait master
                          jsr                RECEIVE
                          ENDC

                          IFEQ               ENABLEADVSERIAL
                          jsr                RECFIRST
                          ENDC
                    
.notSlaveSync:
                          clr.b              SLAVEPAUSE
                          clr.b              MASTERPAUSE

                          st                 doAnything

skipMpPause: 

****************************************************************
; Sync to copper

                          lea                $dff000,a6
                          WAITFORVERTBREQ

****************************************************************
; Update chunky screen (copper list)

****************************************************************
; Handle selected gun for slave, master or single 

                          cmp.b              #'s',mors
                          bne.b              notSlavePlr2Gun

                          move.l             #PLR2_GunData,GunData
                          move.b             PLR2_GunSelected,GunSelected
                          
                          bra.b              donePlrGun

notSlavePlr2Gun:
                          move.l             #PLR1_GunData,GunData
                          move.b             PLR1_GunSelected,GunSelected

donePlrGun:

****************************************************************
; Anim water waves (watertoUse)

                          move.l             waterpt,a0
                          move.l             (a0)+,watertoUse
                          cmp.l              #endWaterList,a0
                          blt.s              okwat
                          move.l             #waterList,a0

okwat:
                          move.l             a0,waterpt

                          add.w              #640,wtan
                          and.w              #8191,wtan
                          addq.w             #1,waterOff
                          and.w              #63,waterOff

****************************************************************
; Face

                          IFNE               ENABLEFACES
                          jsr                PlaceFace
                          ENDC

****************************************************************
; Timer
                          IFNE               ENABLETIMER
                          jsr                InitTimer
                          ENDC

****************************************************************
; Gun ammo

                          move.l             GunData,a6
                          moveq              #0,d0
                          move.b             GunSelected,d0
                          lsl.w              #2,d0
                          lea                (a6,d0.w*8),a6
                          move.w             (a6),d0
                          asr.w              #3,d0

                          IFNE               UNLIMITEDAMMO
                          move.l             #63,d0
                          move.w             d0,(a6)
                          ENDC
                          
                          move.w             d0,Ammo

****************************************************************

                          move.l             PLR1_xoff,OLDX1
                          move.l             PLR1_zoff,OLDZ1

                          move.l             PLR2_xoff,OLDX2
                          move.l             PLR2_zoff,OLDZ2

****************************************************************
; Multi player

                          lea                $dff000,a6

                          cmp.b              #'m',mors
                          beq                handleMaster

                          cmp.b              #'s',mors
                          beq                handleSlave

****************************************************************
; Single player 

                          WAITFORVERTBREQ

                          move.l             GraphicsBase,a6  
                          jsr                _LVOWaitTOF(a6)

                          move.w             FramesToDraw,TempFrames
                          cmp.w              #15,TempFrames
                          blt.s              .okSingleFrame
                          
                          move.w             #15,TempFrames

.okSingleFrame:
                          move.w             #0,FramesToDraw

****************************************************************
; Cheat with player energy (JACKIE)

                          move.l             CHEATPTR,a4
                          add.l              #200000,a4
                          moveq              #0,d0
                          move.b             (a4),d0

                          move.l             #KeyMap,a5
                          tst.b              (a5,d0.w)                                          ; Current cheat key
                          beq.s              .nocheat
 
                          addq               #1,a4
                          cmp.l              #ENDCHEAT,a4
                          blt.s              .nocheat

                          cmp.w              #0,CHEATNUM
                          beq.s              .nocheat

                          subq.w             #1,CHEATNUM
                          move.l             #CHEATFRAME,a4
                          move.w             #PlayerMaxEnergy,PLR1_energy
                          bsr                EnergyBar

.nocheat:
                          sub.l              #200000,a4
                          move.l             a4,CHEATPTR

****************************************************************
; Single player 

                          move.w             PLR1_energy,Energy
                          move.l             PLR1s_xoff,p1_xoff
                          move.l             PLR1s_zoff,p1_zoff
                          move.l             PLR1s_yoff,p1_yoff
                          move.l             PLR1s_height,p1_height
                          move.w             PLR1s_angpos,p1_angpos
                          move.w             PLR1_bobble,p1_bobble
                          move.b             PLR1_clicked,p1_clicked
                          move.b             PLR1_fire,p1_fire
                          clr.b              PLR1_clicked
                          move.b             PLR1_SPCTAP,p1_spctap
                          clr.b              PLR1_SPCTAP
                          move.b             PLR1_Ducked,p1_ducked
                          move.b             PLR1_GunSelected,p1_gunselected

                          bsr                PLR1_Control

                          move.l             PLR1_Roompt,a0
                          move.l             ToZoneRoof(a0),SplitHeight
                          move.w             p1_xoff,THISPLRxoff
                          move.w             p1_zoff,THISPLRzoff
 
                          move.l             #$60000,p2_yoff
                          move.l             PLR2_Obj,a0
                          move.w             #-1,GraphicRoom(a0)
                          move.w             #-1,objZone(a0)
                          move.b             #0,objCanSee(a0)
                          move.l             #BollocksRoom,PLR2_Roompt
 
                          bra                doneTalking

****************************************************************
; Multi player - master

handleMaster:

                          move.l             #KeyMap,a5
                          tst.b              $19(a5)                                            ; 'p' Pause key
                          sne                MASTERPAUSE                                               

                          move.w             FramesToDraw,TempFrames
                          cmp.w              #15,TempFrames
                          blt.s              .okMasterFrame                                     ; skip if lower than 15

                          move.w             #15,TempFrames

.okMasterFrame:
                          move.w             #0,FramesToDraw

                          move.w             PLR1_energy,Energy   
                          move.l             PLR1s_xoff,p1_xoff
                          move.l             PLR1s_zoff,p1_zoff
                          move.l             PLR1s_yoff,p1_yoff
                          move.l             PLR1s_height,p1_height
                          move.w             PLR1s_angpos,p1_angpos
                          move.w             PLR1_bobble,p1_bobble
                          move.b             PLR1_clicked,p1_clicked
                          clr.b              PLR1_clicked
                          move.b             PLR1_fire,p1_fire
                          move.b             PLR1_SPCTAP,p1_spctap
                          clr.b              PLR1_SPCTAP
                          move.b             PLR1_Ducked,p1_ducked
                          move.b             PLR1_GunSelected,p1_gunselected

                          IFNE               ENABLEADVSERIAL
                          jsr                AdvSyncMaster
                          ENDC

                          IFEQ               ENABLEADVSERIAL
                          jsr                SyncMaster
                          ENDC

                          bsr                PLR1_Control
                          bsr                PLR2_Control

                          move.l             PLR1_Roompt,a0
                          move.l             ToZoneRoof(a0),SplitHeight
                          
                          move.w             p1_xoff,THISPLRxoff
                          move.w             p1_zoff,THISPLRzoff
 
                          bra                doneTalking

****************************************************************
; Multi player - slave

handleSlave:

                          move.l             #KeyMap,a5
                          tst.b              $19(a5)                                            ; 'p' Pause key
                          sne                SLAVEPAUSE

                          move.w             PLR2_energy,Energy
                          move.l             PLR2s_xoff,p2_xoff
                          move.l             PLR2s_zoff,p2_zoff
                          move.l             PLR2s_yoff,p2_yoff
                          move.l             PLR2s_height,p2_height
                          move.w             PLR2s_angpos,p2_angpos
                          move.w             PLR2_bobble,p2_bobble
                          move.b             PLR2_clicked,p2_clicked
                          clr.b              PLR2_clicked
                          move.b             PLR2_fire,p2_fire
                          move.b             PLR2_SPCTAP,p2_spctap
                          clr.b              PLR2_SPCTAP
                          move.b             PLR2_Ducked,p2_ducked
                          move.b             PLR2_GunSelected,p2_gunselected

                          IFNE               ENABLEADVSERIAL
                          jsr                AdvSyncSlave
                          ENDC

                          IFEQ               ENABLEADVSERIAL
                          jsr                SyncSlave
                          ENDC

                          bsr                PLR1_Control
                          bsr                PLR2_Control

                          move.l             PLR2_Roompt,a0
                          move.l             ToZoneRoof(a0),SplitHeight

                          move.w             p2_xoff,THISPLRxoff
                          move.w             p2_zoff,THISPLRzoff

****************************************************************

doneTalking:
                          lea                zoneBrightTable,a1
                          move.l             zoneAdds,a2

                          move.l             PLR2_ListOfGraphRooms,a0                           ; Slave
                          move.l             PLR2_PointsToRotatePtr,a5                          ; Slave
                          
                          cmp.b              #'s',mors
                          beq.s              doallz

                          move.l             PLR1_ListOfGraphRooms,a0                           ; Master / Single
                          move.l             PLR1_PointsToRotatePtr,a5                          ; Master / Single
 
doallz:
                          move.w             (a0),d0
                          blt.s              doneallz
                          addq.w             #8,a0
 
                          move.l             (a2,d0.w*4),a3
                          add.l              LEVELDATA,a3
                          move.w             ToZoneBrightness(a3),d2
                          blt.s              justbright

                          move.w             d2,d3
                          lsr.w              #8,d3
                          tst.b              d3
                          beq.s              justbright

                          lea                brightAnimTable,a4
                          move.w             -2(a4,d3.w*2),d2
 
justbright:
                          move.w             d2,(a1,d0.w*4)

                          move.w             ToUpperBrightness(a3),d2
                          blt.s              justbright2

                          move.w             d2,d3
                          lsr.w              #8,d3
                          tst.b              d3
                          beq.s              justbright2

                          lea                brightAnimTable,a4
                          move.w             -2(a4,d3.w*2),d2
 
justbright2:
                          move.w             d2,2(a1,d0.w*4)

                          bra.b              doallz

doneallz:
                          move.l             pointBrights,a2
                          lea                currentPointBrights,a3

justtheone:
                          move.w             (a5)+,d0
                          blt.s              whyTheHell

                          move.w             (a2,d0.w*4),d2

                          tst.b              d2
                          blt.s              .justbright

                          move.w             d2,d3
                          lsr.w              #8,d3
                          tst.b              d3
                          beq.s              .justbright

                          move.w             d3,d4
                          and.w              #$f,d3
                          lsr.w              #4,d4
                          addq.w             #1,d4

                          lea                brightAnimTable,a0
                          move.w             -2(a0,d3.w*2),d3
                          ext.w              d2
                          sub.w              d2,d3
                          muls               d4,d3
                          asr.w              #4,d3
                          add.w              d3,d2

.justbright:
                          ext.w              d2

                          move.w             d2,(a3,d0.w*4)
                          move.w             2(a2,d0.w*4),d2

                          tst.b              d2
                          blt.s              .justbright2
                          move.w             d2,d3
                          lsr.w              #8,d3
                          tst.b              d3
                          beq.s              .justbright2

                          move.w             d3,d4
                          and.w              #$f,d3
                          lsr.w              #4,d4
                          addq.w             #1,d4

                          lea                brightAnimTable,a0
                          move.w             -2(a0,d3.w*2),d3
                          ext.w              d2
                          sub.w              d2,d3
                          muls               d4,d3
                          asr.w              #4,d3
                          add.w              d3,d2

.justbright2:
                          ext.w              d2
                          move.w             d2,2(a3,d0.w*4)
                          bra.s              justtheone
 
whyTheHell:
                          cmp.b              #'n',mors
                          beq                nosee

****************************************************************
; Multi player 

                          move.l             PLR1_Roompt,FromRoom
                          move.l             PLR2_Roompt,ToRoom
                          move.w             p1_xoff,Viewerx
                          move.w             p1_zoff,Viewerz
                          move.l             p1_yoff,d0
                          asr.l              #7,d0
                          move.w             d0,Viewery
                          
                          move.w             p2_xoff,Targetx
                          move.w             p2_zoff,Targetz
                          move.l             p2_yoff,d0
                          asr.l              #7,d0
                          move.w             d0,Targety

                          move.b             PLR1_StoodInTop,ViewerTop
                          move.b             PLR2_StoodInTop,TargetTop
                          jsr                CanItBeSeen
 
                          move.l             PLR1_Obj,a0
                          move.b             CanSee,d0
                          and.b              #2,d0
                          move.b             d0,17(a0)

                          move.l             PLR2_Obj,a0
                          move.b             CanSee,d0
                          and.b              #1,d0
                          move.b             d0,17(a0)

****************************************************************

nosee:
                          move.l             PLR1_Obj,a0
                          move.b             #5,16(a0)

                          move.l             PLR2_Obj,a0
                          move.b             #11,16(a0)

                          move.w             TempFrames,d0
                          add.w              d0,p1_holddown
                          cmp.w              #30,p1_holddown
                          blt.s              oklength
                          move.w             #30,p1_holddown

oklength:
                          tst.b              p1_fire
                          bne.s              okstillheld
                          sub.w              d0,p1_holddown
                          bge.s              okstillheld
                          move.w             #0,p1_holddown
 
okstillheld:
                          move.w             TempFrames,d0
                          add.w              d0,p2_holddown
 
                          cmp.w              #30,p2_holddown
                          blt.s              oklength2
                          move.w             #30,p2_holddown

oklength2:
                          tst.b              p2_fire
                          bne.s              okstillheld2
                          sub.w              d0,p2_holddown
                          bge.s              okstillheld2
                          move.w             #0,p2_holddown

okstillheld2:

****************************************************************
                        ; move.l #PLR1_GunData,a1
                        ; move.w p1_holddown,d0
                        ; move.w #50,10+32*3(a1)
                        ;
                        ; move.l #PLR2_GunData,a1
                        ; move.w p2_holddown,d0
                        ; move.w #50,10+32*3(a1)
****************************************************************
 
                          move.w             TempFrames,d1
                          bgt.s              noze
                          moveq              #1,d1

noze:
                          move.w             PLR1_xoff,d0
                          sub.w              OLDX1,d0
                          asl.w              #4,d0
                          ext.l              d0
                          divs               d1,d0
                          move.w             d0,XDIFF1
                          move.w             PLR2_xoff,d0
                          sub.w              OLDX2,d0
                          asl.w              #4,d0
                          ext.l              d0
                          divs               d1,d0
                          move.w             d0,XDIFF2
                          move.w             PLR1_zoff,d0
                          sub.w              OLDZ1,d0
                          asl.w              #4,d0
                          ext.l              d0
                          divs               d1,d0
                          move.w             d0,ZDIFF1
                          move.w             PLR2_zoff,d0
                          sub.w              OLDZ2,d0
                          asl.w              #4,d0
                          ext.l              d0
                          divs               d1,d0
                          move.w             d0,ZDIFF2

                          cmp.b              #'s',mors
                          beq                drawSlavePlr2

****************************************************************
; Single player / Multi player - master 

                          bsr                USEPLR1
 
                          move.w             #0,scaleval
 
                          move.l             PLR1_xoff,xoff
                          move.l             PLR1_yoff,yoff
                          move.l             PLR1_zoff,zoff
                          move.w             PLR1_angpos,angpos
                          move.w             PLR1_cosval,cosval
                          move.w             PLR1_sinval,sinval
 
                          move.l             PLR1_ListOfGraphRooms,ListOfGraphRooms
                          move.l             PLR1_PointsToRotatePtr,PointsToRotatePtr
                          move.l             PLR1_Roompt,Roompt

                          bsr                OrderZones
                          jsr                ObjMoveAnim

                          bsr                EnergyBar
                          bsr                AmmoBar

                          move.w             #0,leftclip
                          move.w             #RTGScrWidth,rightclip
                          move.w             #0,deftopclip
 
                          move.w             #RTGScrHeight-1,defbotclip
                          move.w             #0,topclip
                          move.w             #RTGScrHeight-1,botclip

                          bsr                DrawDisplay 

****************************************************************
; Test glass routine:

                          IFNE               ENABLEGLASSBALL
                          jsr                TestGlassball
                          ENDC

****************************************************************************

                          bra                copyCopBuff

****************************************************************************
; Multiplayer - slave

drawSlavePlr2:
                          bsr                USEPLR2

                          move.w             #0,scaleval
                          
                          move.l             PLR2_xoff,xoff
                          move.l             PLR2_yoff,yoff
                          move.l             PLR2_zoff,zoff
                          move.w             PLR2_angpos,angpos
                          move.w             PLR2_cosval,cosval
                          move.w             PLR2_sinval,sinval 

                          move.l             PLR2_ListOfGraphRooms,ListOfGraphRooms
                          move.l             PLR2_PointsToRotatePtr,PointsToRotatePtr
                          move.l             PLR2_Roompt,Roompt

                          bsr                OrderZones
                          jsr                ObjMoveAnim

                          bsr                EnergyBar
                          bsr                AmmoBar

                          move.w             #0,leftclip
                          move.w             #RTGScrWidth,rightclip
                          move.w             #0,deftopclip

                          move.w             #RTGScrHeight-1,defbotclip
                          move.w             #0,topclip
                          move.w             #RTGScrHeight-1,botclip

                          bsr                DrawDisplay

**************************************************************************** 
; Copy from copbuff to chip ram

copyCopBuff:

 
********************************************************
; Clear workspace

                          lea                WorkSpace,a1
                          clr.l              (a1)
                          clr.l              4(a1)
                          clr.l              8(a1)
                          clr.l              12(a1)
                          clr.l              16(a1)
                          clr.l              20(a1)
                          clr.l              24(a1)
                          clr.l              28(a1)
 
****************************************************************************

                          cmp.b              #'n',mors
                          beq.s              plr1Only

****************************************************************************

                          move.l             PLR2_Roompt,a0
                          lea                ToListOfGraph(a0),a0

.doAllRoomsPlr2:
                          move.w             (a0),d0
                          blt.s              .allRoomsDonePlr2

                          addq               #8,a0
                          move.w             d0,d1
                          asr.w              #3,d0
                          bset               d1,(a1,d0.w)
                          bra.b              .doAllRoomsPlr2

.allRoomsDonePlr2:

****************************************************************************

plr1Only:
                          move.l             PLR1_Roompt,a0
                          lea                ToListOfGraph(a0),a0

.doAllRoomsPlr1:
                          move.w             (a0),d0
                          blt.s              .allRoomsDonePlr1

                          addq               #8,a0
                          move.w             d0,d1
                          asr.w              #3,d0
                          bset               d1,(a1,d0.w)
                          bra.b              .doAllRoomsPlr1

.allRoomsDonePlr1:

****************************************************************************
; Through all objects to set worry flag

                          move.l             ObjectData,a0
                          lea                -(ObjectSize)(a0),a0

.doallobs:
                          lea                ObjectSize(a0),a0
                          move.w             (a0),d0
                          blt.s              .allobsdone

                          move.w             objZone(a0),d0
                          blt.s              .doallobs

                          move.w             d0,d1
                          asr.w              #3,d0
                          btst               d1,(a1,d0.w)                                       ; a1 = WorkSpace
                          beq.s              .doallobs

                          or.b               #127,objWorry(a0)
                          bra.s              .doallobs

.allobsdone:

****************************************************************************
                        ; move.l #oldbrightentab,a0
                        ; move.l fromPt,a3                    ; Copper chunky
                        ; adda.w #(4*33)+(widthOffset*20),a3
                        ; move.w #20,d7
                        ; move.w #20,d6
                        ;horl:
                        ; move.w d6,d5
                        ; move.l a3,a1
                        ;vertl
                        ; move.w (a1),d0
                        ; move.w (a0,d0.w*2),(a1)
                        ; addq #4,a1
                        ; dbra d5,vertl
                        ; adda.w #widthOffset,a3
                        ; dbra d7,horl
                        ;lea                $dff000,a6
                        ; move.w #$300,col0(a6)
*******************************************************************

                          lea                $dff000,a6

                          move.l             #KeyMap,a5                                                           
                          tst.b              $45(a5)                                            ; (esc) Quit key
                          beq.s              noend
 
 *******************************************************************
 ; Single player quit

                          cmp.b              #'n',mors
                          beq                exitToMainMenu

 *******************************************************************
 ; Multi player quit

                          cmp.b              #'s',mors
                          bne.b              notSlaveQuit 
                          st                 SLAVEQUITTING

notSlaveQuit:
                          cmp.b              #'m',mors
                          bne.b              notMasterQuit 
                          st                 MASTERQUITTING
                          
notMasterQuit:
                        
*******************************************************************

noend:
                          tst.b              MASTERQUITTING
                          beq.s              .noQuit

                          tst.b              SLAVEQUITTING
                          beq.s              .noQuit

                          bra                exitToMainMenu                                     ; exit to main menu

.noQuit:

*******************************************************************

                          cmp.w              #1,MPMode
                          beq.b              .addExit

                          cmp.b              #'n',mors
                          bne.s              .noExit

.addExit:
                          move.l             PLR1_Roompt,a0
                          move.w             (a0),d0
                          move.w             PLOPT,d1
                          move.l             #ENDZONES,a0
                          cmp.w              (a0,d1.w*2),d0
                          beq                quitGame                                           ; exit to main menu

.noExit:
                          tst.w              PLR1_energy
                          ble                quitGame                                           ; exit to main menu

                          tst.w              PLR2_energy
                          ble                quitGame                                           ; exit to main menu

*********************************************************************************************
                        ; move.l             SwitchData,a0
                        ; tst.b              24+8(a0)
                        ; bne                quitGame
*********************************************************************************************

                          IFNE               ENABLETIMER
                          jsr                StopTimer
                          ENDC

**************************************************************************** 
; RTG Change:

                          SAVEREGS

********************************************************
; Panel palette
                        ;   lea                PanelPal,a5
                        ;   lea                Panel24bitPalette,a6
                        ;   move.l             #256,pp24ColorCount
                        ;   move.l             #0,pp24ColorOffset
                        ;   jsr                Parse24bitPalette

********************************************************
; Panel image
                          move.l             #Panel24bitPalette,PtaPalettePtr
                          move.l             Panel,PtaBplPtr
                          move.l             #PlaneBuffer0,PtaBplColBufPtr
                          move.l             #320,PtaBplWidth
                          move.l             #96,PtaBplHeight
                          move.l             #8,PtaBplCount
                          move.l             #(320/8)*7,PtaBplModulo
                          move.l             #0,PtaBplOffsetInBytes
                          jsr                CopyPlaneToColorBuffer

********************************************************
; Borders (spr)
; 4 sprites - 64 bit wide - 2592 bytes each
; 2+646 word pairs per sprite?

; Spr group 1 (attached)
; Sprites 1->0
                          lea                borders,a0
                          move.l             a0,StaSprPtr
                          lea                PanelSprColorBuffer0,a0
                          move.l             a0,StaColBufPtr
                          lea                PanelSprColorBufferHeight0,a0
                          move.l             a0,StaColBufHeightPtr
                          move.w             #0,StaColRegBase
                          move.l             #160,StaSprHeight
                          jsr                CopySpriteToColorBuffer

                          lea                borders,a0
                          add.l              #2592,a0
                          move.l             a0,StaSprPtr
                          lea                PanelSprColorBuffer0,a0
                          move.l             a0,StaColBufPtr
                          lea                PanelSprColorBufferHeight0,a0
                          move.l             a0,StaColBufHeightPtr
                          move.w             #0,StaColRegBase
                          move.l             #160,StaSprHeight
                          jsr                CopySpriteToColorBuffer

; Spr group 2 (attached)
; Sprites 3->2
                          lea                borders,a0
                          add.l              #2592*2,a0
                          move.l             a0,StaSprPtr
                          lea                PanelSprColorBuffer1,a0
                          move.l             a0,StaColBufPtr
                          lea                PanelSprColorBufferHeight1,a0
                          move.l             a0,StaColBufHeightPtr
                          move.w             #0,StaColRegBase
                          move.l             #160,StaSprHeight
                          jsr                CopySpriteToColorBuffer

                          lea                borders,a0
                          add.l              #2592*3,a0
                          move.l             a0,StaSprPtr
                          lea                PanelSprColorBuffer1,a0
                          move.l             a0,StaColBufPtr
                          lea                PanelSprColorBufferHeight1,a0
                          move.l             a0,StaColBufHeightPtr
                          move.w             #0,StaColRegBase
                          move.l             #160,StaSprHeight
                          jsr                CopySpriteToColorBuffer

*******************************************************************
; Panel
                          ;lea                HealthPal,a5
                          ;lea                Healt12bitPalette,a6
                          ;move.l             #80,gc12ColorCount
                          ;jsr                Get12bitColors

                          ;lea                PanelPal,a5
                          ;lea                Border24bitPalette,a6
                          ;move.l             #256,pp24ColorCount
                          ;move.l             #0,pp24ColorOffset
                          ;jsr                Parse24bitPalette

***************************************
; Left border

                          lea                PanelSprColorBuffer0,a0
                          move.l             a0,DscbColBuf
                          move.l             PanelSprColorBufferHeight0,DscbHeight
                          lea                Border24bitPalette,a0
                          move.l             a0,DscbPalettePtr
                          move.l             #(RTGCanvasWidth/4),DscbRtgX
                          move.l             #1,DscbRtgY
                          move.l             #1,DscForce
                          move.w             #15,DscbCopEffectCol                               ; Color 15 
                          move.l             #Healt12bitPalette,DscbCopEffectColBufPtr
                          jsr                DrawSpriteColorBuffer
                          
***************************************
; Right border

                          lea                PanelSprColorBuffer1,a0
                          move.l             a0,DscbColBuf
                          move.l             PanelSprColorBufferHeight1,DscbHeight
                          lea                Border24bitPalette,a0
                          move.l             a0,DscbPalettePtr
                          move.l             #(RTGCanvasWidth/4)+256,DscbRtgX
                          move.l             #1,DscbRtgY
                          move.l             #1,DscForce
                          move.w             #15,DscbCopEffectCol                               ; Color 15
                          move.l             #Healt12bitPalette,DscbCopEffectColBufPtr
                          jsr                DrawSpriteColorBuffer

***************************************
; Bottom panel

                          IFEQ               ENABLETIMER

                          ;move.l             #RTGPanelLeft,bplHiColBufPtr
                          ;move.l             #(RTGCanvasWidth/4),bplHiColRtgX
                          ;move.l             #0,bplHiColRtgY
                          ;jsr                DrawAB3dHiColor15BufferToWindow

                          ;move.l             #RTGPanelRight,bplHiColBufPtr
                          ;move.l             #(RTGCanvasWidth/4)+256,bplHiColRtgX
                          ;move.l             #0,bplHiColRtgY
                          ;jsr                DrawAB3dHiColor15BufferToWindow

                          ;move.l             #RTGPanelBottom,bplHiColBufPtr
                          move.l             #PlaneBuffer0,bplHiColBufPtr
                          move.l             #(RTGCanvasWidth/4),bplHiColRtgX
                          move.l             #256-96,bplHiColRtgY
                          jsr                DrawAB3dHiColor15BufferToWindow
                          
                          ENDC 

***************************************
; Timer
; width = 192
; height = 96 
                          IFNE               ENABLETIMER

                          move.l             #Panel24bitPalette,PtaPalettePtr
                          move.l             #TimerScr,PtaBplPtr
                          move.l             #PlaneBuffer0,PtaBplColBufPtr
                          move.l             #192,PtaBplWidth
                          move.l             #96,PtaBplHeight
                          move.l             #1,PtaBplCount 
                          move.l             #0,PtaBplModulo 
                          move.l             #0,PtaBplOffsetInBytes
                          jsr                CopyPlaneToColorBuffer

                          move.l             #PlaneBuffer0,bplHiColBufPtr
                          move.l             #(RTGCanvasWidth/3),bplHiColRtgX
                          move.l             #256-96,bplHiColRtgY
                          jsr                DrawAB3dHiColor15BufferToWindow

                          ENDC 

***************************************
; Faces
; width = 192 
; height = 32 
                          IFNE               ENABLEFACES

                          ;lea                FacesPal,a5
                          ;lea                Faces12bitPalette,a6
                          ;move.l             #32,pp12ColorCount
                          ;move.l             #0,pp12ColorOffset
                          ;jsr                Parse12bitPalette

                          move.l             #Faces12bitPalette,PtaPalettePtr
                          move.l             #facePlace,PtaBplPtr
                          move.l             #PlaneBuffer0,PtaBplColBufPtr
                          move.l             #192,PtaBplWidth
                          move.l             #32,PtaBplHeight
                          move.l             #5,PtaBplCount 
                          move.l             #0,PtaBplModulo 
                          move.l             #(192/8)*32,PtaBplOffsetInBytes
                          jsr                CopyPlaneToColorBuffer

                          move.l             #PlaneBuffer0,bplHiColBufPtr
                          move.l             #80,bplHiColSrcX
                          move.l             #0,bplHiColSrcY
                          move.l             #32,bplHiColSizeX
                          move.l             #32,bplHiColSizeY
                          move.l             #(RTGCanvasWidth/2)-(16),bplHiColRtgX
                          move.l             #256-68,bplHiColRtgY
                          jsr                CopyAB3dHiColor15BufferToWindow

                          ENDC
                            

*******************************************************************
; Chunky view


                          IFEQ               USE1X1
                          IFNE               USE2X2SCALED
                          jsr                DrawScaledAB3dChunkyBuffer
                          ;jsr                ClearAB3dChunkyBuffer
                          ENDC
                          ENDC
                          IFEQ               USE2X2SCALED
                          jsr                DrawAB3dChunkyBuffer
                          ;jsr                ClearAB3dChunkyBuffer
                          ENDC

**************************************************************************** 

                          GETREGS

; End of RTG Change
**************************************************************************** 

                          bra                mainLoop

*********************************************************************************************
; Multi player

MASTERQUITTING:           dc.b               0
SLAVEQUITTING:            dc.b               0
                          even

MASTERPAUSE:              dc.b               0
SLAVEPAUSE:               dc.b               0
                          even

*********************************************************************************************
; Pause options

                          include            "OSPauseOpts.s"  
                          even

*********************************************************************************************

ENDZONES:
; LEVEL 1
                          dc.w               132
; LEVEL 2
                          dc.w               149
; LEVEL 3
                          dc.w               155
; LEVEL 4
                          dc.w               107
; LEVEL 5
                          dc.w               67
; LEVEL 6
                          dc.w               132
; LEVEL 7
                          dc.w               203
; LEVEL 8
                          dc.w               166
; LEVEL 9
                          dc.w               118
; LEVEL 10
                          dc.w               102
; LEVEL 11
                          dc.w               103
; LEVEL 12
                          dc.w               2
; LEVEL 13
                          dc.w               98
; LEVEL 14
                          dc.w               0
; LEVEL 15
                          dc.w               148
; LEVEL 16
                          dc.w               103

*********************************************************************************************
*********************************************************************************************

ClearKeyboard:
; Clear keyboard buffer

                          move.l             #KeyMap,a5
                          moveq              #0,d0
                          move.w             #15,d1

clrKbdLoop:
                          move.l             d0,(a5)+
                          move.l             d0,(a5)+
                          move.l             d0,(a5)+
                          move.l             d0,(a5)+
                          dbra               d1,clrKbdLoop

                          rts

*********************************************************************************************
*********************************************************************************************

READCONTROLS:             dc.w               0

BollocksRoom:             dc.w               -1
                          ds.l               50

*********************************************************************************************

GUNYOFFS:
; GunYOffset in pixels

                          dc.w               20
                          dc.w               20
                          dc.w               0
                          dc.w               20
                          dc.w               20
                          dc.w               0
                          dc.w               0
                          dc.w               20

*********************************************************************************************

USEPLR1:

                          move.l             PLR1_Obj,a0 
                          move.l             ObjectPoints,a1
                          move.l             #ObjRotated,a2
                          move.w             (a0),d0
                          move.l             PLR1_xoff,(a1,d0.w*8)
                          move.l             PLR1_zoff,4(a1,d0.w*8)
                          move.l             PLR1_Roompt,a1

                          moveq              #0,d2
                          move.b             damagetaken(a0),d2
                          beq.b              .notbeenshot

                          move.w             #$f00,hitcol
                          move.w             #$f00,hitcol2

                          IFEQ               UNLIMITEDHITS
                          sub.w              d2,PLR1_energy
                          ENDC

                          IFNE               ENABLEFACES
                          move.l             #painFace,facesPtr
                          move.w             #-1,facesCounter
                          ENDC                          

                          SAVEREGS
                          move.b             #$fb,IDNUM
                          move.w             #19,Samplenum
                          clr.b              notifplaying
                          move.w             #0,Noisex
                          move.w             #0,Noisez
                          move.w             #100,Noisevol
                          jsr                MakeSomeNoise
                          GETREGS

.notbeenshot:
                          move.b             #0,damagetaken(a0)
                          move.b             PLR1_energy+1,numlives(a0)

                          move.b             PLR1_StoodInTop,objInTop(a0)
 
                          move.w             (a1),12(a0)
                          move.w             (a1),d2
                          move.l             #zoneBrightTable,a1
                          move.l             (a1,d2.w*4),d2
                          tst.b              PLR1_StoodInTop
                          bne.s              .okinbott
                          swap               d2

.okinbott:
                          move.w             d2,2(a0)
 
                          move.l             p1_yoff,d0
                          move.l             p1_height,d1
                          asr.l              #1,d1
                          add.l              d1,d0
                          asr.l              #7,d0
                          move.w             d0,4(a0)

***********************************

                          move.l             PLR2_Obj,a0 
 
                          move.w             PLR2_angpos,d0
                          and.w              #8190,d0
                          move.w             d0,Facing(a0)
 
                          jsr                ViewpointToDraw
                          asl.w              #2,d0
                          moveq              #0,d1
                          move.b             p2_bobble,d1
                          not.b              d1
                          lsr.b              #3,d1
                          and.b              #$3,d1
                          add.w              d1,d0
                          move.w             d0,10(a0)
                          move.w             #10,8(a0)
 
                          move.l             ObjectPoints,a1
                          move.l             #ObjRotated,a2
                          move.w             (a0),d0
                          move.l             PLR2_xoff,(a1,d0.w*8)
                          move.l             PLR2_zoff,4(a1,d0.w*8)
                          move.l             PLR2_Roompt,a1

                          moveq              #0,d2
                          move.b             damagetaken(a0),d2
                          beq.b              .notbeenshot2
                          sub.w              d2,PLR2_energy

.notbeenshot2:
                          move.b             #0,damagetaken(a0)
                          move.b             PLR2_energy+1,numlives(a0)

                          move.b             PLR2_StoodInTop,objInTop(a0)
 
                          move.w             (a1),12(a0)
                          move.w             (a1),d2
                          move.l             #zoneBrightTable,a1
                          move.l             (a1,d2.w*4),d2
                          tst.b              PLR2_StoodInTop
                          bne.s              .okinbott2
                          swap               d2

.okinbott2:
                          move.w             d2,2(a0)
 
                          move.l             p2_yoff,d0
                          move.l             p2_height,d1
                          asr.l              #1,d1
                          add.l              d1,d0
                          asr.l              #7,d0
                          move.w             d0,4(a0)

**********************************

                          move.l             PLR1_Obj,a0
                          move.w             #-1,12+128(a0)

                          rts

*********************************************************************************************

DrawInGun:
; d0 = GunSelected
; d1 = GunFrame

                          move.l             #Objects+9*16,a0
                          move.l             4(a0),a5                                           ; ptr
                          move.l             8(a0),a2                                           ; frames
                          move.l             12(a0),a4                                          ; pal
                          move.l             (a0),a0                                            ; wad
 
                          move.l             #GunAnims,a1
                          move.l             (a1,d0.w*8),a1
                          move.w             (a1,d1.w*2),d5                                     ; frame of anim
 
                          move.l             #GUNYOFFS,a1
                          move.w             (a1,d0.w*2),d7                                     ; yoff

                          asl.w              #2,d0
                          add.w              d5,d0                                              ; frame
                          move.w             (a2,d0.w*4),d1                                     ; xoff

                          lea                (a5,d1.w),a5                                       ; right ptr
  
; width: 3*32 = 96 pix
; Height: 80 - d7 = y pix

*******************************************************************

                          include            "OSDrawGun.s"  

*********************************************************************************************
*********************************************************************************************

USEPLR2:

                          move.l             PLR2_Obj,a0 
                          move.l             ObjectPoints,a1
                          move.l             #ObjRotated,a2
                          move.w             (a0),d0
                          move.l             PLR2_xoff,(a1,d0.w*8)
                          move.l             PLR2_zoff,4(a1,d0.w*8)
                          move.l             PLR2_Roompt,a1

                          moveq              #0,d2
                          move.b             damagetaken(a0),d2
                          beq.b              .notbeenshot

                          move.w             #$f00,hitcol
                          move.w             #$f00,hitcol2
                          sub.w              d2,PLR2_energy

                          SAVEREGS
                          move.w             #19,Samplenum
                          clr.b              notifplaying
                          move.b             #$fb,IDNUM
                          move.w             #0,Noisex
                          move.w             #0,Noisez
                          move.w             #100,Noisevol
                          jsr                MakeSomeNoise
                          GETREGS
                          
.notbeenshot:
                          move.b             #0,damagetaken(a0)
                          move.b             PLR2_energy+1,numlives(a0)

                          move.b             PLR2_StoodInTop,objInTop(a0)
 
                          move.w             (a1),12(a0)
                          move.w             (a1),d2
                          move.l             #zoneBrightTable,a1
                          move.l             (a1,d2.w*4),d2
                          tst.b              PLR2_StoodInTop
                          bne.s              .okinbott
                          swap               d2

.okinbott:
                          move.w             d2,2(a0)
 
                          move.l             PLR2_yoff,d0
                          move.l             p2_height,d1
                          asr.l              #1,d1
                          add.l              d1,d0
                          asr.l              #7,d0
                          move.w             d0,4(a0)

****************************************************************

                          move.l             PLR1_Obj,a0 

                          move.w             PLR1_angpos,d0
                          and.w              #8190,d0
                          move.w             d0,Facing(a0)
 
                          jsr                ViewpointToDraw
                          asl.w              #2,d0
                          moveq              #0,d1
                          move.b             p1_bobble,d1
                          not.b              d1
                          lsr.b              #3,d1
                          and.b              #$3,d1
                          add.w              d1,d0
                          move.w             d0,10(a0)
                          move.w             #10,8(a0)

                          move.l             ObjectPoints,a1
                          move.l             #ObjRotated,a2
                          move.w             (a0),d0
                          move.l             PLR1_xoff,(a1,d0.w*8)
                          move.l             PLR1_zoff,4(a1,d0.w*8)
                          move.l             PLR1_Roompt,a1

                          moveq              #0,d2
                          move.b             damagetaken(a0),d2

                          IFEQ               UNLIMITEDHITS
                          beq.b              .notbeenshot2
                          sub.w              d2,PLR1_energy
                          ENDC

.notbeenshot2:
                          move.b             #0,damagetaken(a0)
                          move.b             PLR1_energy+1,numlives(a0)
                          move.b             PLR1_StoodInTop,objInTop(a0)
 
                          move.w             (a1),12(a0)
                          move.w             (a1),d2
                          move.l             #zoneBrightTable,a1
                          move.l             (a1,d2.w*4),d2
                          tst.b              PLR1_StoodInTop
                          bne.s              .okinbott2
                          swap               d2

.okinbott2:
                          move.w             d2,2(a0)
 
                          move.l             PLR1_yoff,d0
                          move.l             p1_height,d1
                          asr.l              #1,d1
                          add.l              d1,d0
                          asr.l              #7,d0
                          move.w             d0,4(a0)

****************************************************************

                          move.l             PLR2_Obj,a0
                          move.w             #-1,12+64(a0)

                          rts

*********************************************************************************************

GunSelected:              dc.b               0
                          even

*********************************************************************************************

GunAnims:
                          dc.l               MachineAnim,3
                          dc.l               PlasmaAnim,5
                          dc.l               RocketAnim,5
                          dc.l               FlameThrowerAnim,5
                          dc.l               GrenadeAnim,12
                          dc.l               0,0
                          dc.l               0,0
                          dc.l               ShotGunAnim,12+19+11+20+1

*********************************************************************************************

MachineAnim:              dc.w               0,1,2,3
PlasmaAnim:               dc.w               0,1,2,3,3,3
RocketAnim:               dc.w               0,1,2,3,3,3
FlameThrowerAnim:         dc.w               0,1,2,3,3,3

GrenadeAnim:              dc.w               0,1,1,1,1
                          dc.w               2,2,2,2,3
                          dc.w               3,3,3

ShotGunAnim:              dc.w               0
                          dcb.w              12,2
                          dcb.w              19,1
                          dcb.w              11,2
                          dcb.w              20,0
                          dc.w               3

*********************************************************************************************

GunData:                  dc.l               0

*********************************************************************************************

PLR1_GunData:
; 0=Pistol 1=Big Gun
; ammoleft,ammopershot(b),gunnoise(b),ammoinclip(b)
; VISIBLE/INSTANT (0/FF)
; damage,gotgun(b)
; Delay (w), Lifetime of bullet (w)
; Click or hold down (0,1)
; BulSpd: (w)

*************************************************
; PlayerGun (*0)
                          dc.w               0                                                  ; 0: Ammoleft (0=Pistol / 1=Big gun)
                          dc.b               8                                                  ; 2: AmmoPerShot
                          dc.b               3                                                  ; 3: GunSampleNumber
                          dc.b               15                                                 ; 4: AmmoClip
                          dc.b               -1                                                 ; 5: PlrFireBullet
                          dc.b               4                                                  ; 6: ShotPower/BulletDamage

                          dc.b               $ff                                                ; 7: Visible/Instant (0/$ff) 

                          dc.w               5                                                  ; 8: TimeToShoot/Delay
                          dc.w               -1                                                 ; 10: Life time of bullet
                          dc.w               1                                                  ; 12: Click or hold down (0,1)

                          dc.w               0                                                  ; 14: Bullet speed
                          dc.w               0                                                  ; 16: Shot gravity
                          dc.w               0                                                  ; 18: Shot flags (Ammo type (?))

                          dc.w               0                                                  ; 20: Bullet speed?                         
                          dc.w               1                                                  ; 22: Plr1FireBullet / Hitting?
                          ds.w               4                                                  ; 24: ?
PLR1_GunDataEnd:

*************************************************
; PlasmaGun (*1)
                          dc.w               0
                          dc.b               8,1
                          dc.b               20
                          dc.b               0
                          dc.b               16,0
                          dc.w               10,-1,0,5
                          dc.w               0,0,0
                          dc.w               1
                          ds.w               4
 
 *************************************************
; RocketLauncher (*2)
                          dc.w               0
                          dc.b               8,9
                          dc.b               2
                          dc.b               0
                          dc.b               12,0
                          dc.w               30,-1,0,5
                          dc.w               0,0,0
                          dc.w               1
                          ds.w               4

*************************************************
; FlameThrower (*3)
                          dc.w               90*8
                          dc.b               1,22
                          dc.b               40
                          dc.b               0
                          dc.b               8,$0	
                          dc.w               5,50,1,4
                          dc.w               0,0,0
                          dc.w               1
                          ds.w               4

*************************************************
; Grenade launcher (*4)
                          dc.w               0
                          dc.b               8,9
                          dc.b               6
                          dc.b               0
                          dc.b               8,0
                          dc.w               50,100,1,5
                          dc.w               60,3,-1000
                          dc.w               1
                          ds.w               4

************************************************* 
; WORMGUN (*5) NotUsed
                          dc.w               0
                          dc.b               0,0
                          dc.b               0
                          dc.b               0                          
                          dc.b               0,0
                          dc.w               0,-1,0,5
                          dc.w               0,0,0
                          dc.w               1
                          ds.w               4

*************************************************
; ToughMarineGun (*6) NotUsed
                          dc.w               0
                          dc.b               0,0
                          dc.b               0
                          dc.b               0                          
                          dc.b               0,0
                          dc.w               0,-1,0,5
                          dc.w               0,0,0
                          dc.w               1
                          ds.w               4

*************************************************
; Shotgun (*7)
                          dc.w               0                                                  ; 0: Ammoleft 
                          dc.b               8                                                  ; 2: AmmoPerShot
                          dc.b               21                                                 ; 3: GunSampleNumber                          
                          dc.b               15                                                 ; 4: AmmoClip
                          dc.b               -1                                                 ; 5: PlrFireBullet -1
                          dc.b               4                                                  ; 6: ShotPower/BulletDamage

                          dc.b               0                                                  ; 7: Visible/Instant (0/$ff)

                          dc.w               50                                                 ; 8: TimeToShoot/Delay
                          dc.w               -1                                                 ; 10: Life time of bullet
                          dc.w               1                                                  ; 12: Click or hold down (0,1)

                          dc.w               0                                                  ; 14: Bullet speed
                          dc.w               0                                                  ; 16: Shot gravity
                          dc.w               0                                                  ; 18: Shot flags (Ammo type (?))

                          dc.w               0                                                  ; 20: Bullet speed? 
                          dc.w               7                                                  ; 22: Plr1FireBullet / Hitting? 7
                          ds.w               4                                                  ; 24: ?

*********************************************************************************************

PLR2_GunData:
; 0=Pistol 1=Big Gun
; ammoleft,ammopershot(b),gunnoise(b),ammoinclip(b)
; VISIBLE/INSTANT (0/FF)
; damage,gotgun(b)
; Delay (w)

*************************************************
; PlayerGun (*0)
                          dc.w               0
                          dc.b               8,3
                          dc.b               15
                          dc.b               -1
                          dc.b               4,$ff
                          dc.w               5,-1,1,0
                          dc.w               0,0,0
                          dc.w               1
                          ds.w               4

*************************************************
; PlasmaGun (*1)
                          dc.w               0
                          dc.b               8,1
                          dc.b               20
                          dc.b               0
                          dc.b               16,0
                          dc.w               10,-1,0,5
                          dc.w               0,0,0
                          dc.w               1
                          ds.w               4

*************************************************
; RocketLauncher (*2)
                          dc.w               0
                          dc.b               8,9
                          dc.b               2
                          dc.b               0
                          dc.b               12,0
                          dc.w               30,-1,0,5
                          dc.w               0,0,0
                          dc.w               1
                          ds.w               4

*************************************************
; FlameThrower (*3)
                          dc.w               90*8
                          dc.b               1,22
                          dc.b               40
                          dc.b               0
                          dc.b               8,$0	
                          dc.w               5,50,1,4
                          dc.w               0,0,0
                          dc.w               1
                          ds.w               4

*************************************************
; Grenade launcher (*4)
                          dc.w               0
                          dc.b               8,9
                          dc.b               6
                          dc.b               0
                          dc.b               8,0
                          dc.w               50,100,1,5
                          dc.w               60,3
                          dc.w               -1000
                          dc.w               1
                          ds.w               4

*************************************************
; WORMGUN (*5)
                          dc.w               0
                          dc.b               0,0
                          dc.b               0
                          dc.b               0
                          dc.b               0,0
                          dc.w               0,-1,0,5
                          dc.w               0,0
                          dc.w               0
                          dc.w               1
                          ds.w               4

*************************************************
; ToughMarineGun (*6)
                          dc.w               0
                          dc.b               0,0
                          dc.b               0
                          dc.b               0
                          dc.b               0,0
                          dc.w               0,-1,0,5
                          dc.w               0,0
                          dc.w               0
                          dc.w               1
                          ds.w               4

*************************************************
; Shotgun (*7)
                          dc.w               0
                          dc.b               8,21
                          dc.b               15
                          dc.b               -1
                          dc.b               4,0
                          dc.w               50,-1,1,0
                          dc.w               0,0,0
                          dc.w               7
                          ds.w               4

*********************************************************************************************

                          even

*********************************************************************************************
; Path

                          IFNE               ENABLEPATH
Path:                     incbin             "data/misc/testpath"
endpath:
pathpt:                   dc.l               Path
                          ENDC
                          even

*********************************************************************************************

PLR1KEYS:                 dc.b               0
PLR1PATH:                 dc.b               0
PLR1MOUSE:                dc.b               -1
PLR1MOUSEKBD:             dc.b               0
PLR1JOY:                  dc.b               0

PLR2KEYS:                 dc.b               0
PLR2PATH:                 dc.b               0
PLR2MOUSE:                dc.b               -1
PLR2MOUSEKBD:             dc.b               0
PLR2JOY:                  dc.b               0
                          even

*********************************************************************************************

PLR1_bobble:              dc.w               0
PLR2_bobble:              dc.w               0

xwobble:                  dc.l               0
xwobxoff:                 dc.w               0
xwobzoff:                 dc.w               0

*********************************************************************************************

PLR1_Control:
; Take a snapshot of everything.

                          move.l             PLR1_xoff,d2
                          move.l             d2,PLR1_oldxoff
                          move.l             d2,oldx
                          move.l             PLR1_zoff,d3
                          move.l             d3,PLR1_oldzoff
                          move.l             d3,oldz
                          move.l             p1_xoff,d0
                          move.l             d0,PLR1_xoff
                          move.l             d0,newx
                          move.l             p1_zoff,d1
                          move.l             d1,newz
                          move.l             d1,PLR1_zoff

                          move.l             p1_height,PLR1_height
 
                          sub.l              d2,d0
                          sub.l              d3,d1
                          move.l             d0,xdiff
                          move.l             d1,zdiff
                          move.w             p1_angpos,d0
                          move.w             d0,PLR1_angpos
 
                          move.l             #SineTable,a1
                          move.w             (a1,d0.w),PLR1_sinval
                          add.w              #2048,d0
                          and.w              #8190,d0
                          move.w             (a1,d0.w),PLR1_cosval

                          move.l             p1_yoff,d0
                          move.w             p1_bobble,d1
                          move.w             (a1,d1.w),d1
                          move.w             d1,d3
                          ble.s              notnegative
                          neg.w              d1

notnegative:
                          add.w              #16384,d1
                          asr.w              #4,d1

                          tst.b              PLR1_Ducked
                          bne.s              .notdouble
                          add.w              d1,d1

.notdouble:
                          ext.l              d1
                          move.l             PLR1_height,d4
                          sub.l              d1,d4
                          add.l              d1,d0
 
                          cmp.b              #'s',mors
                          beq.s              .otherwob

                          asr.w              #6,d3
                          ext.l              d3
                          move.l             d3,xwobble
                          move.w             PLR1_sinval,d1
                          muls               d3,d1
                          move.w             PLR1_cosval,d2
                          muls               d3,d2
                          swap               d1
                          swap               d2
                          asr.w              #7,d1
                          move.w             d1,xwobxoff
                          asr.w              #7,d2
                          neg.w              d2
                          move.w             d2,xwobzoff

.otherwob:
                          move.l             d0,PLR1_yoff
                          move.l             d0,newy
                          move.l             d0,oldy
 
                          move.l             d4,thingheight
                          move.l             #40*256,StepUpVal
                          tst.b              PLR1_Ducked
                          beq.s              .okbigstep
                          move.l             #10*256,StepUpVal

.okbigstep:
                          move.l             #$1000000,StepDownVal
 
                          move.l             PLR1_Roompt,a0
                          move.w             ToTelZone(a0),d0
                          blt                .noteleport
 
*********************************************************************************************

                          move.w             ToTelX(a0),newx
                          move.w             ToTelZ(a0),newz
                          move.w             #-1,CollId
                          move.l             #%111111111111111111,CollideFlags
                          bsr                Collision

                          tst.b              hitwall
                          beq.s              .teleport
 
                          move.w             PLR1_xoff,newx
                          move.w             PLR1_zoff,newz
                          bra                .noteleport
 
.teleport:

*********************************************************************************************

                          move.l             PLR1_Roompt,a0
                          move.w             ToTelZone(a0),d0
                          move.w             ToTelX(a0),PLR1_xoff
                          move.w             ToTelZ(a0),PLR1_zoff
                          move.l             PLR1_yoff,d1
                          sub.l              ToZoneFloor(a0),d1
                          
                          move.l             zoneAdds,a0
                          move.l             (a0,d0.w*4),a0
                          add.l              LEVELDATA,a0
                          move.l             a0,PLR1_Roompt

                          add.l              ToZoneFloor(a0),d1
                          move.l             d1,PLR1s_yoff
                          move.l             d1,PLR1_yoff
                          move.l             d1,PLR1s_tyoff
                          move.l             PLR1_xoff,PLR1s_xoff
                          move.l             PLR1_zoff,PLR1s_zoff
 
                          SAVEREGS
                          move.w             #0,Noisex
                          move.w             #0,Noisez
                          move.w             #26,Samplenum
                          move.w             #100,Noisevol
                          move.b             #$fa,IDNUM
                          jsr                MakeSomeNoise
                          GETREGS
 
                          bra                .cantmove
 
*********************************************************************************************

.noteleport:
 
                          move.l             PLR1_Roompt,objroom
                          move.w             #%100000000,wallflags
                          move.b             PLR1_StoodInTop,StoodInTop
                          move.l             #%1011111110111000001,CollideFlags
                          move.w             #-1,CollId
                          bsr                Collision

                          tst.b              hitwall
                          beq.s              .nothitanything

                          move.w             oldx,PLR1_xoff
                          move.w             oldz,PLR1_zoff
                          move.l             PLR1_xoff,PLR1s_xoff
                          move.l             PLR1_zoff,PLR1s_zoff
                          bra                .cantmove

.nothitanything:

*********************************************************************************************

                          move.w             #40,extlen
                          move.b             #0,awayfromwall

                          clr.b              exitfirst
                          clr.b              wallbounce
                          bsr                MoveObject

                          move.b             StoodInTop,PLR1_StoodInTop
                          move.l             objroom,PLR1_Roompt
                          move.w             newx,PLR1_xoff
                          move.w             newz,PLR1_zoff
                          move.l             PLR1_xoff,PLR1s_xoff
                          move.l             PLR1_zoff,PLR1s_zoff
 
*********************************************************************************************

.cantmove:
                          move.l             PLR1_Roompt,a0
                          move.l             ToZoneFloor(a0),d0
                          tst.b              PLR1_StoodInTop
                          beq.s              notintop
                          move.l             ToUpperFloor(a0),d0

notintop:
                          adda.w             #ToZonePts,a0
                          sub.l              PLR1_height,d0
                          move.l             d0,PLR1s_tyoff
                          move.w             p1_angpos,tmpAngPos
                          
                          move.w             (a0)+,d1
                          ext.l              d1
                          add.l              PLR1_Roompt,d1
                          move.l             d1,PLR1_PointsToRotatePtr
                          
                          tst.w              (a0)+
                          sne                DRAWNGRAPHTOP
                          beq.s              noBackGraphicsPlr1

                          cmp.b              #'s',mors
                          beq.s              noBackGraphicsPlr1
                          
                          move.l             a0,-(a7)
                          jsr                PutInBackDrop
                          move.l             (a7)+,a0

noBackGraphicsPlr1:
                          adda.w             #10,a0
                          move.l             a0,PLR1_ListOfGraphRooms

                          rts

*********************************************************************************************

DRAWNGRAPHTOP:
tstzone:                  dc.l               0
CollId:                   dc.w               0

*********************************************************************************************

PLR2_Control:
; Take a snapshot of everything.

                          move.l             PLR2_xoff,d2
                          move.l             d2,PLR2_oldxoff
                          move.l             d2,oldx
                          move.l             PLR2_zoff,d3
                          move.l             d3,PLR2_oldzoff
                          move.l             d3,oldz
                          move.l             p2_xoff,d0
                          move.l             d0,PLR2_xoff
                          move.l             d0,newx
                          move.l             p2_zoff,d1
                          move.l             d1,newz
                          move.l             d1,PLR2_zoff

                          move.l             p2_height,PLR2_height
 
                          sub.l              d2,d0
                          sub.l              d3,d1
                          move.l             d0,xdiff
                          move.l             d1,zdiff
                          move.w             p2_angpos,d0
                          move.w             d0,PLR2_angpos
 
                          move.l             #SineTable,a1
                          move.w             (a1,d0.w),PLR2_sinval
                          add.w              #2048,d0
                          and.w              #8190,d0
                          move.w             (a1,d0.w),PLR2_cosval
 
                          move.l             p2_yoff,d0
                          move.w             p2_bobble,d1
                          move.w             (a1,d1.w),d1
                          move.w             d1,d3
                          ble.s              .notnegative
                          neg.w              d1

.notnegative:
                          add.w              #16384,d1
                          asr.w              #4,d1
                          add.w              d1,d1
                          ext.l              d1
                          move.l             PLR2_height,d4
                          sub.l              d1,d4
                          add.l              d1,d0
 
                          cmp.b              #'s',mors
                          bne.s              .otherwob

                          asr.w              #6,d3
                          ext.l              d3
                          move.l             d3,xwobble
                          move.w             PLR2_sinval,d1
                          muls               d3,d1
                          move.w             PLR2_cosval,d2
                          muls               d3,d2
                          swap               d1
                          swap               d2
                          asr.w              #7,d1
                          move.w             d1,xwobxoff
                          asr.w              #7,d2
                          neg.w              d2
                          move.w             d2,xwobzoff

.otherwob:
                          move.l             d0,PLR2_yoff
                          move.l             d0,newy
                          move.l             d0,oldy
 
                          move.l             d4,thingheight
                          move.l             #40*256,StepUpVal
                          tst.b              PLR2_Ducked
                          beq.s              .okbigstep
                          move.l             #10*256,StepUpVal

.okbigstep:
                          move.l             #$1000000,StepDownVal

                          move.l             PLR2_Roompt,a0
                          move.w             ToTelZone(a0),d0
                          blt                .noteleport
 
                          move.w             ToTelX(a0),newx
                          move.w             ToTelZ(a0),newz
                          move.w             #-1,CollId
                          move.l             #%111111111111111111,CollideFlags
                          bsr                Collision

                          tst.b              hitwall
                          beq.s              .teleport
 
                          move.w             PLR2_xoff,newx
                          move.w             PLR2_zoff,newz
                          bra                .noteleport
 
.teleport:
                          move.l             PLR2_Roompt,a0
                          move.w             ToTelZone(a0),d0
                          move.w             ToTelX(a0),PLR2_xoff
                          move.w             ToTelZ(a0),PLR2_zoff
                          move.l             PLR2_yoff,d1
                          sub.l              ToZoneFloor(a0),d1

                          move.l             zoneAdds,a0
                          move.l             (a0,d0.w*4),a0
                          add.l              LEVELDATA,a0
                          move.l             a0,PLR2_Roompt
                          
                          add.l              ToZoneFloor(a0),d1
                          move.l             d1,PLR2s_yoff
                          move.l             d1,PLR2_yoff
                          move.l             d1,PLR2s_tyoff
                          move.l             PLR2_xoff,PLR2s_xoff
                          move.l             PLR2_zoff,PLR2s_zoff
 
                          SAVEREGS
                          move.w             #0,Noisex
                          move.w             #0,Noisez
                          move.w             #26,Samplenum
                          move.w             #100,Noisevol
                          move.b             #$fa,IDNUM
                          jsr                MakeSomeNoise
                          GETREGS
 
                          bra                .cantmove
 
.noteleport:
                          move.l             PLR2_Roompt,objroom
                          move.w             #%100000000000,wallflags
                          move.b             PLR2_StoodInTop,StoodInTop

                          move.l             #%1011111010111100001,CollideFlags
                          move.w             #-1,CollId

                          bsr                Collision
                          tst.b              hitwall
                          beq.s              .nothitanything
                          move.w             oldx,PLR2_xoff
                          move.w             oldz,PLR2_zoff
                          move.l             PLR2_xoff,PLR2s_xoff
                          move.l             PLR2_zoff,PLR2s_zoff
                          bra.b              .cantmove

.nothitanything:
                          move.w             #40,extlen
                          move.b             #0,awayfromwall

                          clr.b              exitfirst
                          clr.b              wallbounce
                          bsr                MoveObject
                          move.b             StoodInTop,PLR2_StoodInTop
                          move.l             objroom,PLR2_Roompt
                          move.w             newx,PLR2_xoff
                          move.w             newz,PLR2_zoff
                          move.l             PLR2_xoff,PLR2s_xoff
                          move.l             PLR2_zoff,PLR2s_zoff
 
.cantmove:
                          move.l             PLR2_Roompt,a0
 
                          move.l             ToZoneFloor(a0),d0
                          tst.b              PLR2_StoodInTop
                          beq.s              .notintop
                          move.l             ToUpperFloor(a0),d0

.notintop:
                          adda.w             #ToZonePts,a0
                          sub.l              PLR2_height,d0
                          move.l             d0,PLR2s_tyoff
                          move.w             p2_angpos,tmpAngPos

                        ; move.l (a0),a0		; jump to viewpoint list

                        ; A0 is pointing at a pointer to list of points to rotate

                          move.w             (a0)+,d1
                          ext.l              d1
                          add.l              PLR2_Roompt,d1
                          move.l             d1,PLR2_PointsToRotatePtr

                          tst.w              (a0)+
                          beq.s              noBackGraphicsPlr2

                          cmp.b              #'s',mors
                          bne.s              noBackGraphicsPlr2

                          move.l             a0,-(a7)
                          jsr                PutInBackDrop
                          move.l             (a7)+,a0

noBackGraphicsPlr2:
                          adda.w             #10,a0
                          move.l             a0,PLR2_ListOfGraphRooms

                          rts

*********************************************************************************************
                          cnop               0,32  
KeyMap:                   dcb.b              256,0                                       
; Table of pressed keys

*********************************************************************************************

                          cnop               0,32 
fillScrnWater:            dc.w               0                                                  ; really .b
DONTDOGUN:                dc.w               0                                                  ; really .b
 
*********************************************************************************************

DrawDisplay:

********************************************************
; Setup

                          clr.b              fillScrnWater

********************************************************
; Sin & cos
                          move.l             #SineTable,a0
                          move.w             angpos,d0
                          move.w             (a0,d0.w),d6
                          adda.w             #2048,a0
                          move.w             (a0,d0.w),d7
                          move.w             d6,sinval
                          move.w             d7,cosval

********************************************************
; Handle special keys

                          move.l             #KeyMap,a5

********************************************************
; Look back?
                          moveq              #0,d5
                          move.b             look_behind_key,d5
                          tst.b              (a5,d5.w)
                          sne                DONTDOGUN
                          beq.s              .noLookBack

                          neg.w              cosval
                          neg.w              sinval

.noLookBack:

********************************************************
; Look left?

                          moveq              #0,d5
                          move.b             look_left_key,d5
                          tst.b              (a5,d5.w)
                          beq.s              .noLookLeft
                          sne                DONTDOGUN

                          move.l             #SineTable,a0
                          move.w             angpos,d0
                          sub.w              #1534,d0
                          and.w              #8190,d0
                          move.w             (a0,d0.w),d6
                          adda.w             #2048,a0
                          move.w             (a0,d0.w),d7
                          move.w             d6,sinval
                          move.w             d7,cosval                          

.noLookLeft:

********************************************************
; Look right?

                          moveq              #0,d5
                          move.b             look_right_key,d5
                          tst.b              (a5,d5.w)
                          beq.s              .noLookRight
                          sne                DONTDOGUN

                          move.l             #SineTable,a0
                          move.w             angpos,d0
                          add.w              #1534,d0
                          and.w              #8190,d0
                          move.w             (a0,d0.w),d6
                          adda.w             #2048,a0
                          move.w             (a0,d0.w),d7
                          move.w             d6,sinval
                          move.w             d7,cosval                          

.noLookRight:

********************************************************
; Calculate y offsets

                          move.l             yoff,d0
                          asr.l              #8,d0                                              ; / 256
                          move.w             d0,d1

                          add.w              #256-32,d1
                          and.w              #255,d1
                          move.w             d1,wallYOff

                          asl.w              #2,d0                                              ; * 4
                          move.w             d0,flooryoff

                          bsr                RotateLevelPts
                          bsr                RotateObjectPts

                          bsr                CalcPLR1InLine
 
********************************************************
; Multiplayer

                          cmp.b              #'n',mors
                          bne.s              doplr2too

                          move.l             PLR2_Obj,a0
                          move.w             #-1,12(a0)
                          move.w             #-1,GraphicRoom(a0)
                          bra.b              noplr2either

doplr2too:
                          bsr                CalcPLR2InLine

noplr2either:

********************************************************

                          move.l             endOfList,a0

subroomloop:
                          move.w             -(a0),d7
                          blt                jumpoutofrooms

                          move.l             a0,-(a7)
 
                          move.l             zoneAdds,a0
                          move.l             (a0,d7.w*4),a0
                          add.l              LEVELDATA,a0
                          move.l             ToZoneRoof(a0),SplitHeight
                          move.l             a0,ROOMBACK
 
                          move.l             ZoneGraphAdds,a0
                          move.l             4(a0,d7.w*8),a2
                          move.l             (a0,d7.w*8),a0
 
                          add.l              LEVELGRAPHICS,a0
                          add.l              LEVELGRAPHICS,a2
                          move.l             a2,ThisRoomToDraw+4
                          move.l             a0,ThisRoomToDraw

****************************************************************
; Loop rooms

                          move.l             ListOfGraphRooms,a1
 
finditit:
                          tst.w              (a1)
                          blt                nomoretodoatall
                          
                          cmp.w              (a1),d7
                          beq.b              outoffind

                          adda.w             #8,a1
                          bra.b              finditit

****************************************************************
; Handle clips

outoffind:
                          move.l             a1,-(a7)

                          move.w             #0,leftclip
                          move.w             #RTGScrWidth,rightclip

                          moveq              #0,d7
                          move.w             2(a1),d7
                          blt.s              outofrcliplop

                          move.l             LEVELCLIPS,a0
                          lea                (a0,d7.l*2),a0
                          tst.w              (a0)
                          blt.b              outoflcliplop
 
                          bsr                NEWsetlclip
 
intolcliplop:           ; clips
                          tst.w              (a0)
                          blt.b              outoflcliplop
 
                          bsr                NEWsetlclip
                          bra.b              intolcliplop

****************************************************************

outoflcliplop:
                          addq               #2,a0

                          tst.w              (a0)
                          blt.b              outofrcliplop
 
                          bsr                NEWsetrclip
 
intorcliplop:           ; clips
                          tst.w              (a0)
                          blt.b              outofrcliplop
 
                          bsr                NEWsetrclip 
                          bra.b              intorcliplop

****************************************************************

outofrcliplop:
                          move.w             leftclip,d0
                          cmp.w              #RTGScrWidth,d0 
                          bge                dontbothercantseeit

                          move.w             rightclip,d1
                          blt                dontbothercantseeit

                          cmp.w              d1,d0
                          bge                dontbothercantseeit
 
 ****************************************************************

                          move.l             yoff,d0
                          cmp.l              SplitHeight,d0
                          blt                botfirst
 
                          move.l             ThisRoomToDraw+4,a0
                          cmp.l              LEVELGRAPHICS,a0
                          beq.s              noupperroom

                          st                 DOUPPER
 
                          move.l             ROOMBACK,a1
                          move.l             ToUpperRoof(a1),TOPOFROOM
                          move.l             ToUpperFloor(a1),BOTOFROOM
 
                          move.l             #currentPointBrights+2,pointBrightsPtr
                          bsr                DoThisRoom

****************************************************************

noupperroom:
                          move.l             ThisRoomToDraw,a0
                          clr.b              DOUPPER
                          move.l             #currentPointBrights,pointBrightsPtr

                          move.l             ROOMBACK,a1
                          move.l             ToZoneRoof(a1),d0
                          move.l             d0,TOPOFROOM

                          move.l             ToZoneFloor(a1),d1
                          move.l             d1,BOTOFROOM

                          move.l             ToZoneWater(a1),d2
                          cmp.l              yoff,d2
                          blt.s              .abovefirst

                          move.l             d2,BEFOREWATTOP
                          move.l             d1,BEFOREWATBOT
                          move.l             d2,AFTERWATBOT
                          move.l             d0,AFTERWATTOP

                          bra.s              .belowfirst

****************************************************************

.abovefirst:
                          move.l             d0,BEFOREWATTOP
                          move.l             d2,BEFOREWATBOT
                          move.l             d1,AFTERWATBOT
                          move.l             d2,AFTERWATTOP

.belowfirst:
                          bsr                DoThisRoom 
                          bra                dontbothercantseeit

****************************************************************

botfirst:
                          move.l             ThisRoomToDraw,a0
                          clr.b              DOUPPER
                          move.l             #currentPointBrights,pointBrightsPtr

                          move.l             ROOMBACK,a1
                          move.l             ToZoneRoof(a1),d0
                          move.l             d0,TOPOFROOM
                          move.l             ToZoneFloor(a1),d1
                          move.l             d1,BOTOFROOM

                          move.l             ToZoneWater(a1),d2
                          cmp.l              yoff,d2
                          blt.s              .abovefirst
                          
                          move.l             d2,BEFOREWATTOP
                          move.l             d1,BEFOREWATBOT
                          move.l             d2,AFTERWATBOT
                          move.l             d0,AFTERWATTOP

                          bra.s              .belowfirst

****************************************************************

.abovefirst:
                          move.l             d0,BEFOREWATTOP
                          move.l             d2,BEFOREWATBOT
                          move.l             d1,AFTERWATBOT
                          move.l             d2,AFTERWATTOP

.belowfirst:
                          bsr                DoThisRoom

****************************************************************

                          move.l             ThisRoomToDraw+4,a0
                          cmp.l              LEVELGRAPHICS,a0
                          beq.s              noupperroom2

                          move.l             #currentPointBrights+2,pointBrightsPtr

                          move.l             ROOMBACK,a1
                          move.l             ToUpperRoof(a1),TOPOFROOM
                          move.l             ToUpperFloor(a1),BOTOFROOM

                          st                 DOUPPER
                          bsr                DoThisRoom

****************************************************************

noupperroom2:
dontbothercantseeit:
pastemp:
                          move.l             (a7)+,a1
                          move.l             ThisRoomToDraw,a0
                          move.w             (a0),d7
 
                          adda.w             #8,a1
                          bra                finditit

****************************************************************

nomoretodoatall:
                          move.l             (a7)+,a0
                          bra                subroomloop

****************************************************************

jumpoutofrooms:
                          tst.b              DONTDOGUN
                          bne.b              noGunLook

                          cmp.b              #'s',mors
                          beq.s              drawSlaveGun

****************************************************************

                          moveq              #0,d0
                          move.b             PLR1_GunSelected,d0
                          moveq              #0,d1
                          move.b             PLR1_GunFrame,d1
                          bsr                DrawInGun
                          bra.b              drawnPlr1Gun

****************************************************************

drawSlaveGun:
                          moveq              #0,d0
                          move.b             PLR2_GunSelected,d0
                          moveq              #0,d1
                          move.b             PLR2_GunFrame,d1
                          bsr                DrawInGun

****************************************************************

drawnPlr1Gun:
noGunLook:

****************************************************************

                          moveq              #0,d1
                          move.b             PLR1_GunFrame,d1
                          sub.w              TempFrames,d1
                          bgt.s              .continuePlr1GunFrame
                          moveq              #0,d1

.continuePlr1GunFrame:
                          move.b             d1,PLR1_GunFrame
                          ble.s              .doneFirePlr1

                          subq.b             #1,PLR1_GunFrame

.doneFirePlr1:

****************************************************************

                          moveq              #0,d1
                          move.b             PLR2_GunFrame,d1
                          sub.w              TempFrames,d1
                          bgt.s              .continuePlr2GunFrame
                          moveq              #0,d1

.continuePlr2GunFrame:
                          move.b             d1,PLR2_GunFrame
                          ble.s              .doneFirePlr2

                          subq.b             #1,PLR2_GunFrame

.doneFirePlr2:

*********************************************************************************************
; Inline include 

                          include            "OSDrawWater.s"  

*********************************************************************************************

DOUPPER:                  dc.w               0

*********************************************************************************************
; Draw wall, floor and objects

DoThisRoom:
; a0 = ThisRoomToDraw+n

                          move.w             (a0)+,d0
                          move.w             d0,currzone
                          lea                zoneBrightTable,a1
                          move.l             (a1,d0.w*4),d1
                          tst.b              DOUPPER
                          bne.s              .okbot
                          swap               d1

.okbot:
                          move.w             d1,ZoneBright

polyloop:
                          move.w             (a0)+,d0
                          blt                jumpoutofloop
                          beq                itsawall

                          cmp.w              #3,d0
                          beq                itsasetclip
                          blt                itsafloor

                          cmp.w              #4,d0
                          beq.b              itsanobject

                          cmp.w              #5,d0
                          beq.b              itsanarc

                          cmp.w              #6,d0
                          beq.b              itsalightbeam

                          cmp.w              #7,d0
                          beq.s              itswater

                          cmp.w              #9,d0
                          ble                itsachunkyfloor

                          cmp.w              #11,d0
                          ble.b              itsabumpyfloor

                          cmp.w              #12,d0
                          beq.s              itsbackdrop

                          cmp.w              #13,d0
                          beq.s              itsaseewall
 
                          bra.b              polyloop

********************************************************

itsaseewall:
                          st                 seethru
                          jsr                itsaWallDraw
                          bra.b              polyloop

********************************************************

itsbackdrop:
                          jsr                PutInBackDrop
                          bra.b              polyloop

********************************************************

itswater:
                          move.w             #3,d0
                          clr.b              useGouraud
                          move.l             #FloorLine,LineRoutineToUse
                          st                 useWater
                          clr.b              useBumpmap
                          jsr                itsafloordraw
                          bra                polyloop
 
********************************************************

itsanarc:
                          jsr                CurveDraw
                          bra                polyloop

********************************************************

itsanobject:
                          jsr                ObjDraw
                          bra                polyloop

********************************************************

itsalightbeam:
                          jsr                LightDraw
                          bra                polyloop

********************************************************

itsabumpyfloor:
                          sub.w              #9,d0
                          st                 useBumpmap
                          st                 useSmoothBumpmap
                          clr.b              useWater
                          move.l             #BumpLine,LineRoutineToUse
                          jsr                itsafloordraw
                          bra                polyloop

********************************************************

itsachunkyfloor:
                          subq.w             #7,d0
                          st                 useBumpmap
                          sub.w              #12,topclip
                        ; add.w #10,botclip
                          clr.b              useSmoothBumpmap
                          clr.b              useWater
                          move.l             #BumpLine,LineRoutineToUse
                          jsr                itsafloordraw
                          add.w              #12,topclip
                        ; sub.w #10,botclip
                          bra                polyloop 

********************************************************

itsafloor:
                          move.l             TheFloorLineRoutine,LineRoutineToUse               ; 1,2 = floor/roof
                          clr.b              useWater
                          clr.b              useBumpmap
                          move.b             selectGouraud,useGouraud	
                          jsr                itsafloordraw

                          bra                polyloop

********************************************************

itsasetclip:
                          bra                polyloop

********************************************************

itsawall:
                          clr.b              seethru
                          ; move.l #stripbuffer,a1
                          jsr                itsaWallDraw
                          bra                polyloop

********************************************************

jumpoutofloop:
                          rts

*********************************************************************************************

ThisRoomToDraw:           dc.l               0,0
SplitHeight:              dc.l               0

*********************************************************************************************

                          include            "OrderZones.s"

*********************************************************************************************

ReadMouse:

                          clr.l              d0
                          clr.l              d1

                          move.b             Mouse0Y,d0 

                          ext.l              d0
                          move.w             d0,d3
                          move.w             oldmy,d2
                          sub.w              d2,d0

                          cmp.w              #127,d0
                          blt.b              nonegy

                          move.w             #255,d1
                          sub.w              d0,d1
                          move.w             d1,d0
                          neg.w              d0

nonegy:
                          cmp.w              #-127,d0
                          bge.b              nonegy2

                          move.w             #255,d1
                          add.w              d0,d1
                          move.w             d1,d0

nonegy2:
                          add.b              d0,d2
                          add.w              d0,oldy2
                          move.w             d2,oldmy
                          move.w             d2,d0

                          move.w             oldy2,d0
                          move.w             d0,ymouse

                          clr.l              d0
                          clr.l              d1

                          move.b             Mouse0X,d0

                          ext.w              d0
                          ext.l              d0
                          move.w             d0,d3
                          move.w             oldmx,d2
                          sub.w              d2,d0

                          cmp.w              #127,d0
                          blt.b              nonegx

                          move.w             #255,d1
                          sub.w              d0,d1
                          move.w             d1,d0
                          neg.w              d0

nonegx:
                          cmp.w              #-127,d0
                          bge.b              nonegx2
                          
                          move.w             #255,d1
                          add.w              d0,d1
                          move.w             d1,d0

nonegx2:
                          add.b              d0,d2
                          move.w             d0,d1
                          move.w             d2,oldmx

                          add.w              d0,oldx2
                          move.w             oldx2,d0
                          and.w              #2047,d0
                          move.w             d0,oldx2
 
                          move.w             sensitivity,d2
                          asl.w              d2,d0              

                          sub.w              prevx,d0
                          add.w              d0,prevx
                          add.w              d0,angpos
                          move.w             #0,lrs
                          rts

noturn:
                        ; got to move lr instead. 
                        ; d1 = speed moved l/r
                          move.w             d1,lrs

                          rts

*********************************************************************************************
; Setup mouse sensitivity
; 2 = slow = 's', 3 = medium = 'm', 4 = fast = 'f', 5 = boost = 'b'

SetupMouseSensitivity:

                          cmp.b              #'b',Prefsfile+4
                          bne.s              .notBoost

                          move.w             #5,sensitivity
                          bra.b              .doneSensitivity

.notBoost:
                          cmp.b              #'f',Prefsfile+4
                          bne.s              .notFast

                          move.w             #4,sensitivity
                          bra.b              .doneSensitivity

.notFast:
                          cmp.b              #'m',Prefsfile+4
                          bne.s              .notMedium

                          move.w             #3,sensitivity
                          bra.b              .doneSensitivity

.notMedium:
                          cmp.b              #'s',Prefsfile+4
                          bne.s              .notSlow

                          move.w             #2,sensitivity
                          bra.b              .doneSensitivity

.notSlow:
                          move.w             #3,sensitivity

.doneSensitivity:
                          rts

*********************************************************************************************

sensitivity:              dc.w               3

lrs:                      dc.w               0
prevx:                    dc.w               0
 
angpos:                   dc.w               0
mang:                     dc.w               0
oldymouse:                dc.w               0
xmouse:                   dc.w               0
ymouse:                   dc.w               0
oldx2:                    dc.w               0
oldmx:                    dc.w               0
oldmy:                    dc.w               0
oldy2:                    dc.w               0

*********************************************************************************************
*********************************************************************************************

RTGScrWidthROTATE   EQU RTGScrWidth

RotateXAsl          EQU 7                                                                       ; (7) * 128
RotateZAsl          EQU 2                                                                       ; (2) * 4

*********************************************************************************************

RotateLevelPts:

                          move.w             sinval,d6
                          swap               d6
                          move.w             cosval,d6

                          move.l             PointsToRotatePtr,a0
                          move.l             Points,a3
                          lea                Rotated,a1
                          lea                OnScreen,a2
                          move.w             xoff,d4
                          move.w             zoff,d5
 
pointrotlop:
                          move.w             (a0)+,d7                                           ; point index
                          blt.s              outOfPointRot

**************************************************************

                          move.w             (a3,d7*4),d0                                       ; x
                          sub.w              d4,d0
                          move.w             d0,d2                                              ; x-offset = d2 

**************************************************************

                          move.w             2(a3,d7*4),d1                                      ; z
                          sub.w              d5,d1                                              ; z-offset = d1  

**************************************************************

                          muls               d6,d2                                              ; d6.w = Cos*x
                          swap               d6                                                 ; to sin
                          move.w             d1,d3
                          muls               d6,d3                                              ; d6.w = Sin*z
                          sub.l              d3,d2
                          add.l              d2,d2
                          swap               d2
                          ext.l              d2
                          asl.l              #RotateXAsl,d2                                     ; * 128
                          add.l              xwobble,d2
                          move.l             d2,(a1,d7*8)                                       ; -> Rotated (x)

**************************************************************

                          muls               d6,d0                                              ; d0 = x*sin
                          swap               d6                                                 ; To cos  
                          muls               d6,d1
                          add.l              d0,d1
                          asl.l              #RotateZAsl,d1                                     ; 2 (* 4) 
                          swap               d1
                          move.l             d1,4(a1,d7*8)                                      ; -> Rotated (z)  

**************************************************************

                          tst.w              d1
                          bgt.s              ptNotbehind

**************************************************************
; On left
                          tst.w              d2
                          bgt.s              onRightSomeWhere

                          move.w             #0,d2
                          bra.b              putIn

**************************************************************
; On right

onRightSomeWhere:
                          move.w             #RTGScrWidthROTATE,d2                              ; width 
                          bra.b              putIn

**************************************************************
; On limits

ptNotbehind:
                          divs               d1,d2                                              ; x/z
                          add.w              #(RTGScrWidthROTATE/2)-1,d2                        ; (x/z)+(width/2)-1

**************************************************************

putIn:
                          move.w             d2,(a2,d7*2)                                       ; -> X OnScreen (projection)
 
                          bra.b              pointrotlop

**************************************************************

outOfPointRot:
                          rts

*********************************************************************************************
*********************************************************************************************

PLR1_ObjDists:            ds.w               RTGMult*250
PLR2_ObjDists:            ds.w               RTGMult*250

*********************************************************************************************

CalcPLR1InLine:

                          move.w             PLR1_sinval,d5
                          move.w             PLR1_cosval,d6
                          move.l             ObjectData,a4
                          move.l             ObjectPoints,a0
                          move.w             NumObjectPoints,d7
                          move.l             #PLR1_ObsInLine,a2
                          move.l             #PLR1_ObjDists,a3

.objpointrotlop:
                          move.w             (a0),d0                                            ; X
                          sub.w              PLR1_xoff,d0
                          move.w             4(a0),d1                                           ; Y
                          addq               #8,a0
 
                          tst.w              objZone(a4)
                          blt.b              .noworkout
 
                          moveq              #0,d2
                          move.b             objNumber(a4),d2
                          lea                ColBoxTable,a6
                          lea                (a6,d2.w*8),a6
 
                          sub.w              PLR1_zoff,d1
                          move.w             d0,d2
                          muls               d6,d2
                          move.w             d1,d3
                          muls               d5,d3
                          sub.l              d3,d2
                          add.l              d2,d2
 
                          bgt.s              .okh
                          neg.l              d2

.okh:
                          swap               d2
 
                          muls               d5,d0
                          muls               d6,d1
                          add.l              d0,d1
                          asl.l              #RotateZAsl,d1
                          swap               d1
                          moveq              #0,d3
 
                          tst.w              d1
                          ble.s              .notinline

                          asr.w              #1,d2
                          cmp.w              (a6),d2
                          bgt.s              .notinline
 
                          st                 d3

.notinline:
                          move.b             d3,(a2)+                                           ; x
                          move.w             d1,(a3)+                                           ; y
                          lea                ObjectSize(a4),a4
                          dbra               d7,.objpointrotlop
                          rts
 
**************************************************************

.noworkout:
                          move.b             #0,(a2)+                                           ; x
                          move.w             #0,(a3)+                                           ; y
                          lea                ObjectSize(a4),a4
                          dbra               d7,.objpointrotlop
                          rts

*********************************************************************************************

CalcPLR2InLine:
                          move.w             PLR2_sinval,d5
                          move.w             PLR2_cosval,d6
                          move.l             ObjectData,a4
                          move.l             ObjectPoints,a0
                          move.w             NumObjectPoints,d7
                          move.l             #PLR2_ObsInLine,a2
                          move.l             #PLR2_ObjDists,a3

.objpointrotlop:
                          move.w             (a0),d0                                            ; x
                          sub.w              PLR2_xoff,d0
                          move.w             4(a0),d1                                           ; y
                          addq               #8,a0
 
                          tst.w              objZone(a4)
                          blt.b              .noworkout
 
                          moveq              #0,d2
                          move.b             objNumber(a4),d2
                          lea                ColBoxTable,a6
                          lea                (a6,d2.w*8),a6
 
                          sub.w              PLR2_zoff,d1
                          move.w             d0,d2
                          muls               d6,d2
                          move.w             d1,d3
                          muls               d5,d3
                          sub.l              d3,d2
                          add.l              d2,d2

                          bgt.s              .okh
                          neg.l              d2

.okh:
                          swap               d2

                          muls               d5,d0
                          muls               d6,d1
                          add.l              d0,d1
                          asl.l              #RotateZAsl,d1
                          swap               d1
                          moveq              #0,d3

                          tst.w              d1
                          ble.s              .notinline

                          asr.w              #1,d2
                          cmp.w              (a6),d2
                          bgt.s              .notinline
 
                          st                 d3

.notinline:
                          move.b             d3,(a2)+
                          move.w             d1,(a3)+
                          lea                ObjectSize(a4),a4
                          dbra               d7,.objpointrotlop
                          rts
 
 **************************************************************

.noworkout:
                          move.w             #0,(a3)+
                          move.b             #0,(a2)+
                          lea                ObjectSize(a4),a4
                          dbra               d7,.objpointrotlop
                          rts
 
*********************************************************************************************
*********************************************************************************************

RotateObjectPts:
                          move.w             sinval,d5
                          move.w             cosval,d6

                          move.l             ObjectData,a4
                          move.l             ObjectPoints,a0
                          move.w             NumObjectPoints,d7
                          move.l             #ObjRotated,a1
 
.objpointrotlop:
                          move.w             (a0),d0                                            ; x
                          sub.w              xoff,d0

                          move.w             4(a0),d1                                           ; z
                          addq               #8,a0
 
                          tst.w              12(a4)
                          blt.b              .noWorkOut
 
                          sub.w              zoff,d1

                          move.w             d0,d2                                              ; x -> d2
                          muls               d6,d2                                              ; cos*x

                          move.w             d1,d3                                              ; z -> d3  
                          muls               d5,d3                                              ; (sin*z)

                          sub.l              d3,d2                                              ; (cos*x)-(sin*z) 
 
                          add.l              d2,d2                                              ; ((cos*x)-(sin*z))*2
                          swap               d2
                          move.w             d2,(a1)+                                           ; -> Object z 
 
                          muls               d5,d0                                              ; sin*x
                          muls               d6,d1                                              ; cos*z  
                          add.l              d0,d1                                              ; (sin*x)+(cos*z)
                          asl.l              #RotateZAsl,d1                                     ; ((sin*x)+(cos*z)*4) (2)
                          swap               d1
                          moveq              #0,d3
                          move.w             d1,(a1)+                                           ; -> Object y

                          ext.l              d2
                          asl.l              #RotateXAsl,d2                                     ; 7 (* 128)
                          add.l              xwobble,d2
                          move.l             d2,(a1)+                                           ; -> Object x
                          sub.l              xwobble,d2

                          lea                ObjectSize(a4),a4
                          dbra               d7,.objpointrotlop
                          rts
 
 **************************************************************

.noWorkOut:
                          move.l             #0,(a1)+
                          move.l             #0,(a1)+
                          lea                ObjectSize(a4),a4
                          dbra               d7,.objpointrotlop
                          rts

*********************************************************************************************
*********************************************************************************************
; Draw light effect

                          include            "OSDrawLight.s"  

*********************************************************************************************
*********************************************************************************************
; Energy & ammo values

Energy:                   dc.w               191
OldEnergy:                dc.w               191

Ammo:                     dc.w               63
OldAmmo:                  dc.w               63

*********************************************************************************************
; Energy & ammo visual

FullEnergy:
                          move.w             #PlayerMaxEnergy,Energy
                          move.w             #PlayerMaxEnergy,OldEnergy

                          move.l             #health,a0
                          move.l             #borders,a1
                          lea                25*8*2+6(a1),a1
                          lea                2592(a1),a2
                          move.w             #PlayerMaxEnergy,d0

PutInFull:
                          move.b             (a0)+,(a1)
                          move.b             (a0)+,8(a1)
                          lea                16(a1),a1
                          move.b             (a0)+,(a2)
                          move.b             (a0)+,8(a2)
                          lea                16(a2),a2
                          dbra               d0,PutInFull
 
                          rts

*********************************************************************************************
; Energy

EnergyBar:
; Draw the energy bar

                          move.w             Energy,d0
                          bgt.s              .noeneg
                          move.w             #0,d0

.noeneg:
                          move.w             d0,Energy
 
                          cmp.w              OldEnergy,d0
                          bne.s              gottochange
 
NoEnergyChange:
                          rts

*************************************************************

gottochange:  
                          blt.b              LessEnergy

                          cmp.w              #PlayerMaxEnergy,Energy
                          blt.s              NotMax

                          move.w             #PlayerMaxEnergy,Energy

NotMax:
                          move.w             Energy,d0
                          move.w             OldEnergy,d2
                          sub.w              d0,d2
                          beq.s              NoEnergyChange	
                          neg.w              d2
 
                          move.w             #PlayerMaxEnergy,d3
                          sub.w              d0,d3
 
                          move.l             #health,a0
                          lea                (a0,d3.w*4),a0

                          move.l             #borders+25*16+6,a1
                          lsl.w              #4,d3
                          add.w              d3,a1
                          lea                2592(a1),a2
 
EnergyRise:
                          move.b             (a0)+,(a1)
                          move.b             (a0)+,8(a1)
                          lea                16(a1),a1
                          move.b             (a0)+,(a2)
                          move.b             (a0)+,8(a2)
                          lea                16(a2),a2
                          subq               #1,d2
                          bgt.s              EnergyRise

                          move.w             Energy,OldEnergy
                          rts 

*************************************************************

LessEnergy: 
                          move.w             OldEnergy,d2
                          sub.w              d0,d2
 
                          move.w             #PlayerMaxEnergy,d3
                          sub.w              OldEnergy,d3
 
                          move.l             #borders+25*16+6,a1
                          asl.w              #4,d3
                          add.w              d3,a1
                          lea                2592(a1),a2

EnergyDrain:
                          move.b             #0,(a1)
                          move.b             #0,8(a1)
                          move.b             #0,(a2)
                          move.b             #0,8(a2)
                          lea                16(a1),a1
                          lea                16(a2),a2
                          subq               #1,d2
                          bgt.s              EnergyDrain

                          move.w             Energy,OldEnergy

                          rts 

*********************************************************************************************
; Ammo

AmmoBar:
; Draw ammo the ammo bar

                          move.w             Ammo,d0
                          cmp.w              OldAmmo,d0
                          bne.s              gotToChange
 
NoAmmoChange:
                          rts

*********************************************************

gotToChange:  
                          blt.b              LessAmmo
                          cmp.w              #63,Ammo
                          blt.s              .NotMax
                          move.w             #63,Ammo

.NotMax:
                          move.w             Ammo,d0
                          move.w             OldAmmo,d2
                          sub.w              d0,d2
                          beq.s              NoAmmoChange
                          neg.w              d2
 
                          move.w             #63,d3
                          sub.w              d0,d3
 
                          move.l             #Ammunition,a0
                          lea                (a0,d3.w*8),a0

                          move.l             #borders+5184+25*16+1,a1
                          lsl.w              #5,d3
                          add.w              d3,a1
                          lea                2592(a1),a2

AmmoRise:
                          move.b             (a0)+,(a1)
                          move.b             (a0)+,8(a1)
                          lea                16(a1),a1
                          move.b             (a0)+,(a2)
                          move.b             (a0)+,8(a2)
                          lea                16(a2),a2
                          move.b             (a0)+,(a1)
                          move.b             (a0)+,8(a1)
                          lea                16(a1),a1
                          move.b             (a0)+,(a2)
                          move.b             (a0)+,8(a2)
                          lea                16(a2),a2
                          subq               #1,d2
                          bgt.s              AmmoRise

                          move.w             Ammo,OldAmmo

                          rts 

*********************************************************

LessAmmo: 
                          move.w             OldAmmo,d2
                          sub.w              d0,d2
 
                          move.w             #63,d3
                          sub.w              OldAmmo,d3
 
                          move.l             #borders+5184+25*16+1,a1
                          asl.w              #5,d3
                          add.w              d3,a1
                          lea                2592(a1),a2

AmmoDrain:
                          move.b             #0,(a1)
                          move.b             #0,8(a1)
                          move.b             #0,(a2)
                          move.b             #0,8(a2)
                          lea                16(a1),a1
                          lea                16(a2),a2
                          move.b             #0,(a1)
                          move.b             #0,8(a1)
                          move.b             #0,(a2)
                          move.b             #0,8(a2)
                          lea                16(a1),a1
                          lea                16(a2),a2
                          subq               #1,d2
                          bgt.s              AmmoDrain

                          move.w             Ammo,OldAmmo

                          rts 

*********************************************************************************************

doAnything:               dc.w               0

*********************************************************************************************

quitGame:

********************************************************************

                          clr.b              doAnything

********************************************************************

                          move.w             PLR1_energy,Energy

                          cmp.b              #'s',mors
                          bne.s              .notsl

                          move.w             PLR2_energy,Energy

.notsl:
                          bsr                EnergyBar
 
 ********************************************************************

                          lea                $dff000,a6  

                          IFEQ               ENABLEBGMUSIC
                          cmp.b              #'b',Prefsfile+3
                          bne.s              .noBack
                          ENDC
                          jsr                mt_end

.noBack:

********************************************************************
; Won or lost

                          tst.w              Energy
                          bgt.s              weveWon

********************************************************************
; Lost
                          st                 UseAllChannels
                          clr.b              reachedend
                          move.l             #gameOver,mt_data
                          jsr                mt_init

playGameOver:
                          WAITFORVERTBREQ
                          move.l             GraphicsBase,a6
                          jsr                _LVOWaitTOF(a6)

                          jsr                mt_music

                          tst.b              reachedend
                          beq.s              playGameOver

                          bra.b              weveLost
 
********************************************************************
; Won

weveWon:
                          cmp.b              #'n',mors
                          bne.s              .noNextLev

                          addq.w             #1,MAXLEVEL
                          st                 FINISHEDLEVEL

.noNextLev:
                          st                 UseAllChannels
                          clr.b              reachedend
                          move.l             #welldone,mt_data
                          jsr                mt_init

playWellDone:
                          WAITFORVERTBREQ
                          move.l             GraphicsBase,a6
                          jsr                _LVOWaitTOF(a6)

                          jsr                mt_music

                          tst.b              reachedend
                          beq.s              playWellDone
 
                          cmp.w              #16,MAXLEVEL
                          bne.b              noEndGame

********************************************************************
; End scroll

testEndScroll:            
                          move.w             #15,MAXLEVEL
                          bsr                CleanupForMainMenu 
                          bsr                EndGameScroll
                          rts

********************************************************************
; Return to menu

noEndGame:
weveLost:
                          bsr                CleanupForMainMenu 
                          rts

*********************************************************************************************

exitToMainMenu:

                          clr.b              doAnything

                          IFEQ               ENABLEBGMUSIC
                          cmp.b              #'b',Prefsfile+3
                          bne.s              .noBack
                          ENDC

                          jsr                mt_end

.noBack:

****************************************************************
                        ; cmp.b #'n',mors
                        ; bne.s .nonextlev
                        ; cmp.w #15,MAXLEVEL
                        ; bge.s .nonextlev
                        ; add.w #1,MAXLEVEL
                        ; st FINISHEDLEVEL
                        ;.nonextlev:
****************************************************************

                          bsr                CleanupForMainMenu
                          rts

*********************************************************************************************

                          include            "EndScroll.s"

*********************************************************************************************
; Joystick handling

                          include            "CD32Joy.s"

*********************************************************************************************
; Heading to main menu

CleanupForMainMenu:

                          jsr                mt_end

*******************************************************************

                          lea                $dff000,a6

                          move.l             #NullCop,d0                                        ; Dummy placeholder copper
                          move.w             d0,ocl
                          swap               d0
                          move.w             d0,och

*******************************************************************

                          move.w             #$f,dmacon(a6)                                     ; Audio disabled
 
 *******************************************************************

                          clr.w              aud0vol(a6) 
                          clr.w              aud1vol(a6)
                          clr.w              aud2vol(a6)
                          clr.w              aud3vol(a6)

*******************************************************************

                          jsr                ReleaseLevelData                                   
                          jsr                ReleaseLevelMemory                                 

*******************************************************************
                          
                          clr.b              SLAVEPAUSE                                         ; agi: added
                          clr.b              MASTERPAUSE
                          clr.b              MASTERQUITTING                                     ; agi: added
                          clr.b              SLAVEQUITTING

*******************************************************************
  
                          clr.b              doAnything

*******************************************************************

                          move.l             #0,d0
                          rts

*********************************************************************************************

do32:
; Fill color to copper
; a1 = screen 1
; a3 = screen 2
; 32*4 = 128 bytes
                          move.w             #31,d7
                          move.w             #$180,d1                                           ; Color 0

across:
                          move.w             d1,(a1)+  
                          move.w             d1,(a3)+  
                          move.w             #0,(a1)+  
                          move.w             #0,(a3)+
                          addq.w             #2,d1
                          dbra               d7,across
                          rts

*********************************************************************************************
*********************************************************************************************
; Set left and right clip values

NEWsetlclip:

                          move.l             #OnScreen,a1
                          move.l             #Rotated,a2
                          move.l             CONNECT_TABLE,a3
 
                          move.w             (a0),d0
                          bge.s              .notignoreleft
 
                          bra.b              .leftnotoktoclip

.notignoreleft:
                          move.w             6(a2,d0*8),d3                                      ; left z val
                          bgt.s              .leftclipinfront
                          
                          addq               #2,a0
                          rts

                          tst.w              6(a2,d0*8)
                          bgt.s              .leftnotoktoclip

.ignoreboth:
                          move.w             #0,leftclip
                          move.w             #RTGScrWidth,rightclip
                          addq               #8,a6
                          addq               #2,a0
                          rts

.leftclipinfront:
                          move.w             (a1,d0*2),d1                                       ; left x on screen
                          move.w             (a0),d2
                          move.w             2(a3,d2.w*4),d2
                          move.w             (a1,d2.w*2),d2
                          cmp.w              d1,d2
                          bgt.s              .leftnotoktoclip

                          cmp.w              leftclip,d1
                          ble.s              .leftnotoktoclip
                          move.w             d1,leftclip

.leftnotoktoclip:
                          addq               #2,a0

                          rts

*********************************************************************************************

NEWsetrclip:
                          move.l             #OnScreen,a1
                          move.l             #Rotated,a2
                          move.l             CONNECT_TABLE,a3
                          move.w             (a0),d0
                          bge.s              .notignoreright

                          move.w             #0,d4
                          bra.b              .rightnotoktoclip

.notignoreright:
                          move.w             6(a2,d0*8),d4                                      ; right z val
                          bgt.s              .rightclipinfront

                          bra.s              .rightnotoktoclip

.rightclipinfront:
                          move.w             (a1,d0*2),d1                                       ; right x on screen
                          move.w             (a0),d2
                          move.w             (a3,d2.w*4),d2
                          move.w             (a1,d2.w*2),d2
                          cmp.w              d1,d2
                          blt.s              .rightnotoktoclip

                          cmp.w              rightclip,d1
                          bge.s              .rightnotoktoclip

                          addq               #1,d1
                          move.w             d1,rightclip

.rightnotoktoclip:
                          addq               #8,a6
                          addq               #2,a0
                          rts

FIRSTsetlrclip:
                          move.l             #OnScreen,a1
                          move.l             #Rotated,a2
 
                          move.w             (a0)+,d0
                          bge.s              .notignoreleft
                          bra.b              .leftnotoktoclip

.notignoreleft:
                          move.w             6(a2,d0*8),d3                                      ; left z val
                          bgt.s              .leftclipinfront

                          move.w             (a0),d0
                          blt.s              .ignoreboth

                          tst.w              6(a2,d0*8)
                          bgt.s              .leftnotoktoclip

.ignoreboth:
                          move.w             #RTGScrWidth,rightclip
                          move.w             #0,leftclip
                          addq               #2,a0
                          rts

.leftclipinfront:
                          move.w             (a1,d0*2),d1                                       ; left x on screen
                          cmp.w              leftclip,d1
                          ble.s              .leftnotoktoclip
                          move.w             d1,leftclip

.leftnotoktoclip:
                          move.w             (a0)+,d0
                          bge.s              .notignoreright
                          move.w             #0,d4
                          bra.b              .rightnotoktoclip

.notignoreright:
                          move.w             6(a2,d0*8),d4                                      ; right z val
                          ble.s              .rightnotoktoclip

.rightclipinfront:
                          move.w             (a1,d0*2),d1                                       ; right x on screen
                          addq               #1,d1
                          cmp.w              rightclip,d1
                          bge.s              .rightnotoktoclip
                          
                          move.w             d1,rightclip

.rightnotoktoclip:
                          rts

*********************************************************************************************

leftclip2:                dc.w               0
rightclip2:               dc.w               0
ZoneBright:               dc.w               0
 
npolys:                   dc.w               0

PLR1_fire:                dc.b               0
PLR2_fire:                dc.b               0

*********************************************************************************************

                          include            "ObjectMove.s"
                          include            "Anims.s"

*********************************************************************************************

rotanimpt:                dc.w               0
xradd:                    dc.w               5
yradd:                    dc.w               8
xrpos:                    dc.w               320
yrpos:                    dc.w               320

*********************************************************************************************

rotanim:                  rts

*********************************************************************************************

option:                   dc.l               0,0

*********************************************************************************************
*********************************************************************************************

                          include            "OSDrawWall.s"

*********************************************************************************************
*********************************************************************************************

                          include            "OSDrawFloorAndCeiling.s"

*********************************************************************************************
*********************************************************************************************

                          include            "OSDrawObject.s"

*********************************************************************************************
*********************************************************************************************

numframes:                dc.w               0
alframe:                  dc.l               0

*********************************************************************************************

alan:                     dcb.l              8,0
                          dcb.l              8,1
                          dcb.l              8,2
                          dcb.l              8,3
endalan:

alanptr:                  dc.l               alan

*********************************************************************************************

Time2:                    dc.l               0
dispco:                   dc.w               0

*********************************************************************************************

key_interrupt:
                          SAVEREGS

                        ;	move.w	intreqr,d0
                        ;	btst	#3,d0
                        ;	beq	.not_key

                          move.b             $bfdd00,d0
                          btst               #0,d0
                          bne.b              .key_cont

                        ;	move.b	$bfed01,d0
                        ;	btst	#0,d0
                        ;	bne	.key_cont
                        
                        ;	btst	#3,d0
                        ;	beq	.key_cont

                          move.b             $bfec01,d0
                          clr.b              $bfec01

                          tst.b              d0
                          beq.b              .key_cont

                        ;	bset	#6,$bfee01
                        ;	move.b	#$f0,$bfe401
                        ;	move.b	#$00,$bfe501
                        ;	bset	#0,$bfee01

                          not.b              d0
                          ror.b              #1,d0
                          lea.l              KeyMap,a0
                          tst.b              d0
                          bmi.b              .key_up
                          and.w              #$7f,d0
                ;	add.w	#1,d0
                          move.b             #$ff,(a0,d0.w)
                          move.b             d0,lastpressed

                          bra.b              .key_cont2

.key_up:
                          and.w              #$7f,d0
                        ;	add.w	#1,d0
                          move.b             #$00,(a0,d0.w)

.key_cont2:
                        ;	btst	#0,$bfed01
                        ;	beq	.key_cont2
                        ;	move.b	#%00000000,$bfee01
                        ;	move.b	#%10001000,$bfed01

; alt keys should not be independent so overlay ralt on lalt

.key_cont:
                        ; move.w	#$0008,intreq

.not_key:	
                        ; lea.l	$dff000,a5

                        ; lea.l	_keypressed(pc),a0
                        ; move.b	101(a0),d0	;read LALT
                        ; or.b	102(a0),d0	;blend it with RALT
                        ; move.b	d0,127(a0)	;save in combined position

                          GETREGS
                          rts

*********************************************************************************************

lastpressed:              dc.b               0
KInt_CCode:               ds.b               1
KInt_Askey:               ds.b               1
KInt_OCode:               ds.w               1

*********************************************************************************************
 
OldSpace:                 dc.b               0
SpaceTapped:              dc.b               0
PLR1_SPCTAP:              dc.b               0
PLR2_SPCTAP:              dc.b               0
PLR1_Ducked:              dc.b               0
PLR2_Ducked:              dc.b               0
                          even

*********************************************************************************************

                          include            "Plr1Control.s"
                          include            "Plr2Control.s"
                          include            "Fall.s"
                          cnop               0,4

*********************************************************************************************

cop_interrupt:

***********************************************************************
; VBlank request indicator

                          move.l             d0,-(a7)  
                          move.w             reqVBlank,d0
                          add.b              #1,d0
                          and.w              #1,d0
                          move.w             d0,reqVBlank
                          move.l             (a7)+,d0

***********************************************************************

                          FILTER

***********************************************************************

                          tst.b              doAnything
                          bne.s              doSomething

***********************************************************************

                          moveq              #0,d0
                          rts

*********************************************************************************************

reqVBlank:                dc.w               0

*********************************************************************************************

doSomething:
                          SAVEREGS

***********************************************************************
; Frame counter

                          addq.w             #1,FramesToDraw

***********************************************************************
; Music

                          IFEQ               ENABLEBGMUSIC
                          cmp.b              #'b',Prefsfile+3
                          bne.s              .noback
                          ENDC
                          
                          jsr                mt_music

.noback:

***********************************************************************
; Timer

                          IFNE               ENABLETIMER
                          jsr                TimerInterruptHandler
                          ENDC

***********************************************************************
; ?

                          move.l             alanptr,a0
                          move.l             (a0)+,alframe
                          cmp.l              #endalan,a0
                          blt.s              nostartalan
                          move.l             #alan,a0

nostartalan:
                          move.l             a0,alanptr
 
***********************************************************************

                          tst.b              READCONTROLS
                          beq                nocontrols

***********************************************************************

                          cmp.b              #'s',mors
                          beq.s              control2

***********************************************************************
; Master and single controls

                          tst.b              PLR1MOUSE
                          beq.s              PLR1_nomouse
                          bsr                PLR1_mouse_control

PLR1_nomouse:

***********************************************************************

                          tst.b              PLR1MOUSEKBD
                          beq.s              PLR1_nomousekbd
                          bsr                PLR1_mousekbd_control

PLR1_nomousekbd:

***********************************************************************

                          tst.b              PLR1KEYS
                          beq.s              PLR1_nokeys
                          bsr                PLR1_keyboard_control

PLR1_nokeys:

***********************************************************************
; Path

                          IFNE               ENABLEPATH
                          tst.b              PLR1PATH
                          beq.s              PLR1_nopath
                          bsr                PLR1_follow_path

PLR1_nopath:
                          ENDC

***********************************************************************

                          tst.b              PLR1JOY
                          beq.s              PLR1_nojoy
                          bsr                PLR1_JoyStick_control

PLR1_nojoy: 
                          bra.s              nocontrols

***********************************************************************
; Slave controls

control2:
                          tst.b              PLR2MOUSE
                          beq.s              PLR2_nomouse
                          bsr                PLR2_mouse_control

PLR2_nomouse:

***********************************************************************

                          tst.b              PLR2MOUSEKBD
                          beq.s              PLR2_nomousekbd
                          bsr                PLR2_mousekbd_control

PLR2_nomousekbd:

***********************************************************************

                          tst.b              PLR2KEYS
                          beq.s              PLR2_nokeys
                          bsr                PLR2_keyboard_control

PLR2_nokeys:

***********************************************************************
; Path

                          IFNE               ENABLEPATH
                          tst.b              PLR2PATH
                          beq.s              PLR2_nopath
                          bsr                PLR1_follow_path

PLR2_nopath:
                          ENDC

***********************************************************************

                          tst.b              PLR2JOY
                          beq.s              PLR2_nojoy
                          bsr                PLR2_JoyStick_control

PLR2_nojoy: 

***********************************************************************

nocontrols:
                          lea                $dff000,a6

                          cmp.b              #'4',Prefsfile+1
                          bne.s              nomuckabout
 
                          move.w             #$0,d0 
                          tst.b              NoiseMade0LEFT
                          beq.s              noturnoff0
                          move.w             #1,d0

noturnoff0:
                          tst.b              NoiseMade0RIGHT
                          beq.s              noturnoff1
                          or.w               #2,d0

noturnoff1:
                          tst.b              NoiseMade1RIGHT
                          beq.s              noturnoff2
                          or.w               #4,d0

noturnoff2:
                          tst.b              NoiseMade1LEFT
                          beq.s              noturnoff3
                          or.w               #8,d0

noturnoff3:
                          move.w             d0,dmacon(a6)
 
nomuckabout:
                        ; tst.b PLR2_fire
                        ; beq.s firenotpressed2
                        ; fire was pressed last time. 
                        ; btst #7,$bfe001 ; LMB port 2
                        ; bne.s firenownotpressed2
                        ; fire is still pressed this time.
                        ; st PLR2_fire
                        ; bra dointer
 
firenownotpressed2:
                        ; fire has been released.
                        ; clr.b PLR2_fire
                        ; bra dointer
                                
firenotpressed2:
                        ; fire was not pressed last frame...

                        ; btst #7,$bfe001 ; LMB port 2
                        ; if it has still not been pressed, go back above
                        ; bne.s firenownotpressed2
                        ; fire was not pressed last time, and was this time, so has
                        ; been clicked.
                        ; st PLR2_clicked
                        ; st PLR2_fire

**************************************************************************
; Play sound

dointer:
                          cmp.b              #'4',Prefsfile+1
                          beq                fourchannel
 
                          lea                $dff000,a6
                          btst               #1,intreqr(a6)                                     ; 1 = AUDIO1
                          bne.s              newSampBitl

                          GETREGS

                          IFNE               ENABLETIMER
                          jsr                StartCounting
                          ENDC
                         
                          moveq              #0,d0
                          rts

*********************************************************************************************
; Sound player

                          include            "SoundPlayer.s"

*********************************************************************************************

                          include            "WallChunk.s"

*********************************************************************************************

                          include            "LoadFromDisk.s"

*********************************************************************************************                          

                          include            "ControlLoop.s"

*********************************************************************************************
; Sound player

pretab:
val                       SET                0
                          REPT               128
                          dc.b               val
val                       SET                val+1
                          ENDR
val                       SET                -128
                          REPT               128
                          dc.b               val
val                       SET                val+1
                          ENDR 

*********************************************************************************************
; Sound player

tab:                      ds.b               256*65
                          even

*********************************************************************************************
; Copper screen

fromPt:                   dc.l               0                                                  ; Copper chunky

*********************************************************************************************

SineTable:                incbin             "data/math/bigsine"
                          even

*********************************************************************************************

angspd:                   dc.w               0
flooryoff:                dc.w               0
xoff:                     dc.l               0
yoff:                     dc.l               0
yvel:                     dc.l               0
zoff:                     dc.l               0
tyoff:                    dc.l               0
xspdval:                  dc.l               0
zspdval:                  dc.l               0
Zone:                     dc.w               0

*****************************************************

OLDX1:                    dc.l               0
OLDX2:                    dc.l               0
OLDZ1:                    dc.l               0
OLDZ2:                    dc.l               0

XDIFF1:                   dc.l               0
ZDIFF1:                   dc.l               0
XDIFF2:                   dc.l               0
ZDIFF2:                   dc.l               0

*****************************************************
; Player 1 variables

PLR1:                     dc.b               $ff
                          even
PLR1_energy:              dc.w               191
PLR1_GunSelected:         dc.w               0
PLR1_cosval:              dc.w               0
PLR1_sinval:              dc.w               0
PLR1_angpos:              dc.w               0
PLR1_angspd:              dc.w               0
PLR1_xoff:                dc.l               0
PLR1_yoff:                dc.l               0
PLR1_yvel:                dc.l               0
PLR1_zoff:                dc.l               0
PLR1_tyoff:               dc.l               0
PLR1_xspdval:             dc.l               0
PLR1_zspdval:             dc.l               0
PLR1_Zone:                dc.w               0
PLR1_Roompt:              dc.l               0
PLR1_OldRoompt:           dc.l               0
PLR1_PointsToRotatePtr:   dc.l               0
PLR1_ListOfGraphRooms:    dc.l               0
PLR1_oldxoff:             dc.l               0
PLR1_oldzoff:             dc.l               0
PLR1_StoodInTop:          dc.b               0
                          even
PLR1_height:              dc.l               0

                          ds.w               4

PLR1s_cosval:             dc.w               0
PLR1s_sinval:             dc.w               0
PLR1s_angpos:             dc.w               0
PLR1s_angspd:             dc.w               0
PLR1s_xoff:               dc.l               0
PLR1s_yoff:               dc.l               0
PLR1s_yvel:               dc.l               0
PLR1s_zoff:               dc.l               0
PLR1s_tyoff:              dc.l               0
PLR1s_xspdval:            dc.l               0
PLR1s_zspdval:            dc.l               0
PLR1s_Zone:               dc.w               0
PLR1s_Roompt:             dc.l               0
PLR1s_OldRoompt:          dc.l               0
PLR1s_PointsToRotatePtr:  dc.l               0
PLR1s_ListOfGraphRooms:   dc.l               0
PLR1s_oldxoff:            dc.l               0
PLR1s_oldzoff:            dc.l               0
PLR1s_height:             dc.l               0
PLR1s_targheight:         dc.l               0

;                          ds.w               4

p1_xoff:                  dc.l               0
p1_zoff:                  dc.l               0
p1_yoff:                  dc.l               0
p1_height:                dc.l               0
p1_angpos:                dc.w               0
p1_bobble:                dc.w               0
p1_clicked:               dc.b               0
p1_spctap:                dc.b               0
p1_ducked:                dc.b               0
p1_gunselected:           dc.b               0
p1_fire:                  dc.b               0
                          even
p1_holddown:              dc.w               0

                          ds.w               4

;p1_nastyState:            dc.l               0                                                                    ; from NastyShotData

*****************************************************
; Player 2 variables

PLR2:                     dc.b               $ff
                          even
PLR2_GunSelected:         dc.w               0
PLR2_energy:              dc.w               191
PLR2_cosval:              dc.w               0
PLR2_sinval:              dc.w               0
PLR2_angpos:              dc.w               0
PLR2_angspd:              dc.w               0
PLR2_xoff:                dc.l               0
PLR2_yoff:                dc.l               0
PLR2_yvel:                dc.l               0
PLR2_zoff:                dc.l               0
PLR2_tyoff:               dc.l               0
PLR2_xspdval:             dc.l               0
PLR2_zspdval:             dc.l               0
PLR2_Zone:                dc.w               0
PLR2_Roompt:              dc.l               0
PLR2_OldRoompt:           dc.l               0
PLR2_PointsToRotatePtr:   dc.l               0
PLR2_ListOfGraphRooms:    dc.l               0
PLR2_oldxoff:             dc.l               0
PLR2_oldzoff:             dc.l               0
PLR2_StoodInTop:          dc.b               0
                          even
PLR2_height:              dc.l               0

                          ds.w               4

PLR2s_cosval:             dc.w               0
PLR2s_sinval:             dc.w               0
PLR2s_angpos:             dc.w               0
PLR2s_angspd:             dc.w               0
PLR2s_xoff:               dc.l               0
PLR2s_yoff:               dc.l               0
PLR2s_yvel:               dc.l               0
PLR2s_zoff:               dc.l               0
PLR2s_tyoff:              dc.l               0
PLR2s_xspdval:            dc.l               0
PLR2s_zspdval:            dc.l               0
PLR2s_Zone:               dc.w               0
PLR2s_Roompt:             dc.l               0
PLR2s_OldRoompt:          dc.l               0
PLR2s_PointsToRotatePtr:  dc.l               0
PLR2s_ListOfGraphRooms:   dc.l               0
PLR2s_oldxoff:            dc.l               0
PLR2s_oldzoff:            dc.l               0
PLR2s_height:             dc.l               0
PLR2s_targheight:         dc.l               0

                          ds.w               4

p2_xoff:                  dc.l               0
p2_zoff:                  dc.l               0
p2_yoff:                  dc.l               0
p2_height:                dc.l               0
p2_angpos:                dc.w               0
p2_bobble:                dc.w               0
p2_clicked:               dc.b               0
p2_spctap:                dc.b               0
p2_ducked:                dc.b               0
p2_gunselected:           dc.b               0
p2_fire:                  dc.b               0
                          even
p2_holddown:              dc.w               0

;                          ds.w               4

;p2_nastyState:            ds.l               0                                                                    ; from NastyShotData

*********************************************************************************************
; Glassball
; Used: objDraw3.ChipRam.s, GlassballTest.s

glassballData:            incbin             "data/helper/glassball"
endOfGlassballData:  
                          even

glassballPtr:             dc.l               glassballData

*********************************************************************************************

brightanimtab:
                          dcb.w              200,20
                          dc.w               5
                          dc.w               10,20
                          dc.w               5
                          dcb.w              30,20
                          dc.w               7,10,10,5,10,0,5,6,5,6,5,6,5,6,0
                          dcb.w              40,0
                          dc.w               1,2,3,2,3,2,3,2,3,2,3,2,3,0
                          dcb.w              300,0
                          dc.w               1,0,1,0,2,2,2,5,5,5,5,5,5,5,5,5,6,10
                          dc.w               -1

*********************************************************************************************

Roompt:                   dc.l               0
OldRoompt:                dc.l               0

*********************************************************************************************

wallpt:                   dc.l               0
floorpt:                  dc.l               0

*********************************************************************************************

Rotated:                  ds.l               RTGMult*800                                        ; 800
ObjRotated:               ds.l               RTGMult*500                                        ; 500

*********************************************************************************************

OnScreen:                 ds.l               RTGMult*800                                        ; 800

*********************************************************************************************

startwait:                dc.w               0
endwait:                  dc.w               0

*********************************************************************************************

WorkSpace:                ds.l               RTGMult*8192                                       ; 8192
                          cnop               0,8

*********************************************************************************************

darkentab:                incbin             "data/pal/darkenedcols"
                          even

brightenTab:              include            "data/rtg/helper/OldBrightenFileHiColor.s"
                          even

brightenTabWater:         include            "data/rtg/helper/OldBrightenFileWaterHiColor.s"
                          even

*********************************************************************************************
*********************************************************************************************

                          SECTION            LevelCode,CODE_F

*********************************************************************************************

AllocTextScrn:

                          move.l             #MEMF_FAST|MEMF_CLEAR,d1	
                          move.l             #TextScrSize,d0                                    ; *2 => EndScroll *4
                          move.l             4.w,a6
                          jsr                _LVOAllocMem(a6)
                          move.l             d0,TEXTSCRN

                          rts

*********************************************************************************************

ReleaseTextScrn:

                          move.l             TEXTSCRN,d1
                          beq                SkipTextScr

                          move.l             d1,a1
                          move.l             #TextScrSize,d0
                          move.l             4.w,a6
                          jsr                _LVOFreeMem(a6)
                          move.l             #0,TEXTSCRN

SkipTextScr:
                          rts

*********************************************************************************************

scrnTab:                  
                          ds.b               16
val                       SET                32
                          REPT               96
                          dc.b               val,val,val
val                       SET                val+1
                          ENDR
                          ds.b               16

*********************************************************************************************

smallScrnTab:
val                       SET                32
                          REPT               96
                          dc.b               val,val
val                       SET                val+1
                          ENDR
                          cnop               0,64

*********************************************************************************************
*********************************************************************************************

                          SECTION            CheatDataFast,DATA_F

*********************************************************************************************
; Cheat with player energy 

CHEATFRAME:               dc.b               26,20,33,27,17,12                                  ; J,A,C,K,I,E
ENDCHEAT:
                          even

CHEATPTR:                 dc.l               CHEATFRAME-200000
CHEATNUM:                 dc.l               0

*********************************************************************************************
*********************************************************************************************

                          SECTION            LevelCode,CODE_F

*********************************************************************************************
; Level

                          include            "LevelData2.s"
                          even

*********************************************************************************************
*********************************************************************************************

                          SECTION            SerialTransferCode,CODE_F

*********************************************************************************************
; Multi player

                          include            "SerialNightmare.s"
                          even
                          include            "SerialDataTransfer.s"
                          even

*********************************************************************************************
*********************************************************************************************

                          SECTION            MtPlayerCode,CODE_F

*********************************************************************************************
; Music player

                          include            "MtPlayer.s"

*********************************************************************************************
*********************************************************************************************
; Test codes (own sections) 

**********************************************************************
; Glassball test

                          IFNE               ENABLEGLASSBALL
                          include            "OSGlassballTest.s"
                          ENDC

**********************************************************************
; Faces test

                          IFNE               ENABLEFACES
                          include            "FaceTest.s"
                          ENDC

**********************************************************************
; Timer test

                          IFNE               ENABLETIMER
                          include            "TimerTest.s"
                          ENDC

*********************************************************************************************
*********************************************************************************************

                          SECTION            GraphicsDataFast,DATA_F

*********************************************************************************************

                          cnop               0,8
nullSpr:                  dc.l               0

*********************************************************************************************

                          cnop               0,8
borders:                  
borderLeft:               incbin             "data/gfx/newleftbord"
borderRight:              incbin             "data/gfx/newrightbord"
                          even
                          
*********************************************************************************************

                          cnop               0,8
health:                   incbin             "data/gfx/healthstrip"
                          even
                          
*********************************************************************************************

                          cnop               0,8
Ammunition:               incbin             "data/gfx/ammostrip"
                          even

*********************************************************************************************

                          cnop               0,8
HealthPal:                incbin             "data/pal/HealthPal"                               ; 160 bytes
                          even

*********************************************************************************************

                          cnop               0,8
PanelKeys:                incbin             "data/gfx/greenkey"                                ; 1056 bytes 
                          incbin             "data/gfx/redkey"                                  ; 1056 bytes 
                          incbin             "data/gfx/yellowkey"                               ; 1056 bytes 
                          incbin             "data/gfx/bluekey"                                 ; 1056 bytes 
                          even

*********************************************************************************************

TEXTSCRN:                 dc.l               0

*********************************************************************************************

Panel:                    dc.l               0

*********************************************************************************************
; Null bitplane (640 pix)

nullLine:                 ds.b               80	
                          even

*********************************************************************************************
                          
scrn:

                          dcb.l              8,$33333333
                          dc.l               0
                          dc.l               0
 
                          dcb.l              8,$0f0f0f0f
                          dc.l               0
                          dc.l               0

                          dcb.l              8,$00ff00ff
                          dc.l               0
                          dc.l               0
 
                          dcb.l              8,$0000ffff
                          dc.l               0
                          dc.l               0
 
                          dc.l               0,-1,0,-1,0,-1,0,-1
                          dc.l               0
                          dc.l               0
 
                          dc.l               -1,-1,0,0,-1,-1,0,0
                          dc.l               0
                          dc.l               0
 
                          dc.l               0,0,-1,-1,-1,-1,-1,-1
                          dc.l               0
                          dc.l               0

*********************************************************************************************
*********************************************************************************************

                          SECTION            CopperListsFast,DATA_F

*********************************************************************************************
; Copper lists

;                        include            "BlurbFieldCop.s"

*********************************************************************************************

                          include            "TitleCop.s"

*********************************************************************************************

                          include            "BigFieldCop.s"

*********************************************************************************************

                          include            "TextCop.s"

*********************************************************************************************

                          include            "NullCop.s"

*********************************************************************************************
*********************************************************************************************

                          SECTION            SoundData,DATA_C

*********************************************************************************************

null:                     ds.w               500
null2:                    ds.w               500
null3:                    ds.w               500
null4:                    ds.w               500

*********************************************************************************************
*********************************************************************************************

                          SECTION            MtPlayerMusicDataChip,DATA_C

*********************************************************************************************
; Music

inGame:                   incbin             "sounds/mt/InGame.mt" 
gameOver:                 incbin             "sounds/mt/GameOver.mt"
welldone:                 incbin             "sounds/mt/WellDone.mt"
endGame:                  incbin             "sounds/mt/EndGame.mt" 

*********************************************************************************************
*********************************************************************************************

                          SECTION            OSDataFast,DATA_F

*********************************************************************************************                          

                          include            "OSData.s"

*********************************************************************************************
