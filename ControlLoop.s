*********************************************************************************************
; Main control loop.
; This is the very outer loop of the program.
;
; What needs to be done and when?
;
; Black screen start.
; Load title music
; Load title screen
; Fade up title screen
; Select options
; Play game.
;
; Playing the game involves allocating screen and
; level memory, loading the level, loading the
; samples, loading the wall graphics, playing the
; level, deallocating the screen memory....
;
; Control part should therefore:
;
; 1. Load Title Music
; 2. Load title screen
; 3. Fade up title screen.
; 4. Add 'loading' message
; 5. Load samples and walls
; 6: LOOP START
; 7. Option select screens
; 8. Free music mem, allocate level mem.
; 9. Load level
;10. Play level with options selected
;11. Reload title music
;12. Reload title screen
;13. goto 6
;
*********************************************************************************************

                          opt                P=68020

*********************************************************************************************

                          incdir             "includes"
                          include            "AB3DI.i"
                          include            "macros.i"
                          include            "defs.i"

                          include            "exec/memory.i"

*********************************************************************************************

INTROTUNEADDR:            dc.l               0
INTROTUNENAME:            dc.b               'disk/sounds/abreed3d.med',0
                          even

*********************************************************************************************

TITLESCRNADDR:            dc.l               0
TITLESCRNNAME:            dc.b               'disk/includes/titlescrnraw',0
                          even
TITLESCRNNAME2:           dc.b               'dick/includes/titlescrnraw',0
                          even

*********************************************************************************************

OPTSPRADDR:               dc.l               0

*********************************************************************************************
; Keyboard to ascii conversion table

KVALTOASC:
                          dc.b               " `  "," 1  "," 2  "," 3  "
                          dc.b               " 4  "," 5  "," 6  "," 7  "
                          dc.b               " 8  "," 9  "
                          dc.b               " 0  "," -  "," +  "," \  "
                          dc.b               '    ','    '," Q  "," W  "
                          dc.b               " E  "," R  "
                          dc.b               " T  "," Y  "," U  "," I  "
                          dc.b               " O  "," P  "," [  "," ]  "
                          dc.b               '    ','KP1 '
                          dc.b               'KP2 ','KP3 '," A  "," S  "
                          dc.b               " D  "," F  "," G  "," H  "
                          dc.b               " J  "," K  "
                          dc.b               " L  "," ;  "," #  ",'    '
                          dc.b               '    ','KP4 ','KP5 ','KP6 '
                          dc.b               '    '," Z  "
                          dc.b               " X  "," C  "," V  "," B  "
                          dc.b               " N  "," M  "," ,  "," .  "
                          dc.b               " /  ",'    '
                          dc.b               '    ','KP7 ','KP8 ','KP9 '
                          dc.b               'SPC ','<-- ','TAB ','ENT '
                          dc.b               'RTN ','ESC '
                          dc.b               'DEL ','    ','    ','    '
                          dc.b               'KP- ','    ','UCK ','DCK '
                          dc.b               'RCK ','LCK '
                          dc.b               'FK1 ','FK2 ','FK3 ','FK4 '
                          dc.b               'FK5 ','FK6 ','FK7 ','FK8 '
                          dc.b               'FK9 ','FK0 '
                          dc.b               'KP( ','KP) ','KP/ ','KP* '
                          dc.b               'KP+ '
                          dc.b               'HLP ','LSH ','RSH '
                          dc.b               'CPL ','CTL '
                          dc.b               'LAL ','RAL ','LAM ','RAM '
                          dc.b               '    ','    ','    ','    '
                          dc.b               '    ','    '
                          dc.b               '    ','    ','    ','    '
                          dc.b               '    ','    ','    ','    '
                          dc.b               '    ','    '
                          even

*********************************************************************************************

FINISHEDLEVEL:            dc.w               STARTLEVEL

*********************************************************************************************
; mors (multi or single): m = master, s = slave, n = single, q = quit/exit

PlayGame:
                          move.b             #'n',mors

*********************************************************************************************
; TAKE OUT WHEN PLAYING MODULE AGAIN

                          jsr                ClearTitlePalette

                          move.w             #$7201,titleplanes
                          ;DEL: move.w             #$20,$dff1dc                                  ; PAL
                          ;DEL: move.l             #titlecop,$dff080

                          ;DEL:lea                $dff000,a6
                          ;DEL:move.w             #%1000000110100000,dmacon(a6)                 ; $87c0 5=SPREN,6=BTLEN,7=COPPER,8=BITPLANE,9=MASTER,10=NASTY

                          bsr                AllocTitleMemory
                          bsr                ClrOptScrn
                          bsr                SetupTitleScrn
                          bsr                LoadTitleScrn

 *********************************************************************************************
 
                          move.w             #0,FADEVAL
                          move.w             #63,FADEAMOUNT
                          bsr                FadeUpTitle

*********************************************************************************************
; Start music

                          IFNE               ENABLETITLEMUSIC
                          jsr                _InitPlayer

                          move.l             #INTROTUNENAME,a0
                          jsr                _LoadModule
                          move.l             d0,INTROTUNEADDR

                          move.l             d0,a0
                          jsr                _InitModule
                    
                          move.l             INTROTUNEADDR,a0
                          jsr                _PlayModule
                          ENDC
                     
*********************************************************************************************

                          jsr                LoadWalls
                          jsr                LoadFloor
                          jsr                LoadObjects

*********************************************************************************************

                          move.w             #31,FADEAMOUNT
                          bsr                FadeDownTitle

*********************************************************************************************

                          jsr                LoadSFX

*********************************************************************************************

                          bsr                SetupDefaultGame
                                               
*********************************************************************************************

BACKTOMENU:

***************************************************************
; RTG changes

                          jsr                ClearPiPWindow
                          jsr                ResetP96RTGWindowPointer
                          move.w             #0,TrapMouse

; End of RTG change                          
***************************************************************

                          cmp.b              #'s',mors
                          beq.s              BACKTOSLAVE
                     
                          cmp.b              #'m',mors
                          beq.s              BACKTOMASTER
                     
                          bsr                ReadMainMenu
                     
***************************************************************

                          cmp.b              #'q',mors                                     ; Exit game
                          bne                DoNotExitGame

                          IFNE               ENABLETITLEMUSIC
                          jsr                _StopPlayer
                          jsr                _RemPlayer

                          move.l             INTROTUNEADDR,a0
                          jsr                _UnLoadModule
                          ENDC

                          rts

DoNotExitGame:     

***************************************************************

                          bra                doneMenu

BACKTOMASTER:
                          bsr                MasterMenu
                          bra                doneMenu

BACKTOSLAVE:
                          bsr                SlaveMenu

doneMenu:
                          bsr                WaitRelease

*********************************************************************************************
; Stop music

                          IFNE               ENABLETITLEMUSIC
                          jsr                _StopPlayer
                          jsr                _RemPlayer

                          move.l             INTROTUNEADDR,a0
                          jsr                _UnLoadModule
                          ENDC

*********************************************************************************************
; Clear titlescreen option sprites 

                          bsr                ClrSprites
 
*********************************************************************************************

                          move.w             #31,FADEAMOUNT
                          bsr                FadeUpTitle
                          move.w             #63,FADEAMOUNT
                          bsr                FadeDownTitle

*********************************************************************************************

                          move.w             #$0201,titleplanes
                          bsr                ReleaseTitleMemory
  
*********************************************************************************************
; Load key panel picture

                          jsr                LoadPanel

*********************************************************************************************
; Return when dead or level ends

                          clr.b              FINISHEDLEVEL
                          clr.b              NASTY

                          move.w             #0,PLR1_angpos
                          move.w             #0,PLR2_angpos
                          move.b             #0,PLR1_GunSelected
                          move.b             #0,PLR2_GunSelected

                          jsr                PlayTheGame

*********************************************************************************************
; Free key panel picture

                          bsr                ReleasePanelMemory      
 
*********************************************************************************************
;

                          tst.b              FINISHEDLEVEL
                          beq                dontusestats
                          bsr                CalcPassword
dontusestats:

*********************************************************************************************

                          bsr                PassLineToGame
                          bsr                GetStats
 
*********************************************************************************************
; Setup title screen

                          bsr                AllocTitleMemory
                          bsr                ClrOptScrn
                          bsr                SetupTitleScrn
                          bsr                LoadTitleScrn

                          move.w             #$7201,titleplanes

                          ;DEL:lea                $dff000,a6
                          ;DEL:move.w             #$20,beamcon0(a6)                             ; 5 = PAL
                          ;DEL:move.l             #titlecop,cop1lch(a6)
                          ;DEL:move.w             #%1000000110100000,dmacon(a6)                 ; $87c0
                                             
                          move.w             #0,FADEVAL
                          move.w             #63,FADEAMOUNT
                          bsr                FadeUpTitle

                          move.w             #31,FADEAMOUNT
                          bsr                FadeDownTitle 

*********************************************************************************************
; Start music

                          IFNE               ENABLETITLEMUSIC
                          jsr                _InitPlayer

                          move.l             #INTROTUNENAME,a0
                          jsr                _LoadModule
                          move.l             d0,INTROTUNEADDR

                          move.l             d0,a0
                          jsr                _InitModule
                    
                          move.l             INTROTUNEADDR,a0
                          jsr                _PlayModule
                          ENDC

*********************************************************************************************

                          move.b             #'n',mors
                          bra                BACKTOMENU

*********************************************************************************************
; KEY OPTIONS:

CONTROLBUFFER:

; ------------------------------------------------------
; * Original

turn_left_key:            dc.b               $4f                                           ; Cursor Left
turn_right_key:           dc.b               $4e                                           ; Cursor Right
forward_key:              dc.b               $4c                                           ; Cursor Up
backward_key:             dc.b               $4d                                           ; Cursor Down

fire_key:                 dc.b               $65                                           ; Right Alt
operate_key:              dc.b               $40                                           ; Space

run_key:                  dc.b               $61                                           ; Right Shift

force_sidestep_key:       dc.b               $67                                           ; Right Amiga
sidestep_left_key:        dc.b               $39                                           ; . >
sidestep_right_key:       dc.b               $3a                                           ; / ?

duck_key:                 dc.b               $22                                           ; D

look_behind_key:          dc.b               $28                                           ; L

look_left_key:            dc.b               $10                                           ; Q
look_right_key:           dc.b               $12                                           ; E

; ------------------------------------------------------
; Custom (better :)

; turn_left_key:       dc.b        $4f                                           ; Cursor Left
; turn_right_key:      dc.b        $4e                                           ; Cursor Right
; forward_key:         dc.b        $4c                                           ; Cursor Up
; backward_key:        dc.b        $4d                                           ; Cursor Down
; sidestep_left_key:   dc.b        $20                                           ; A
; sidestep_right_key:  dc.b        $22                                           ; D

; fire_key:            dc.b        $11                                           ; W
; look_behind_key:     dc.b        $10                                           ; Q 
; duck_key:            dc.b        $21                                           ; S

; operate_key:         dc.b        $40                                           ; Space

; run_key:             dc.b        $60                                           ; Left Shift

; force_sidestep_key:  dc.b        $67                                           ; Right Amiga

*********************************************************************************************

templeftkey:              dc.b               0
temprightkey:             dc.b               0
tempslkey:                dc.b               0 
tempsrkey:                dc.b               0
                          even 

*********************************************************************************************

GUNDATASIZE EQU (PLR1_GunDataEnd-PLR1_GunData)                                             ; 32

GetStats:
; CHANGE PASSWORD INTO RAW DATA

                          move.b             PASSBUFFER,d0
                          and.w              #$7f,d0
                          move.w             d0,PLR1_energy                

                          move.b             PASSBUFFER+1,d0
                          btst               #7,d0
                          sne                PLR1_GunData+GUNDATASIZE+7                    ; 7: Visible/Instant (0/$ff)
                          btst               #6,d0
                          sne                PLR1_GunData+GUNDATASIZE*2+7
                          btst               #5,d0
                          sne                PLR1_GunData+GUNDATASIZE*4+7
                          btst               #4,d0
                          sne                PLR1_GunData+GUNDATASIZE*7+7

                          and.w              #%1111,d0
                          move.w             d0,MAXLEVEL                   

                          move.b             PASSBUFFER+2,d0
                          and.w              #$7f,d0
                          lsl.w              #3,d0
                          move.w             d0,PLR1_GunData                               ; 0: Ammo left

                          move.b             PASSBUFFER+3,d0
                          and.w              #$7f,d0
                          lsl.w              #3,d0
                          move.w             d0,PLR1_GunData+GUNDATASIZE

                          move.b             PASSBUFFER+4,d0
                          and.w              #$7f,d0
                          lsl.w              #3,d0
                          move.w             d0,PLR1_GunData+GUNDATASIZE*2

                          move.b             PASSBUFFER+5,d0
                          and.w              #$7f,d0
                          lsl.w              #3,d0
                          move.w             d0,PLR1_GunData+GUNDATASIZE*4

                          move.b             PASSBUFFER+6,d0
                          and.w              #$7f,d0
                          lsl.w              #3,d0
                          move.w             d0,PLR1_GunData+GUNDATASIZE*7

                          rts

*********************************************************************************************

SetPlayers:
                          move.w             PLOPT,d0
                          add.b              #'a',d0
                          move.b             d0,LEVA
                          move.b             d0,LEVB
                          move.b             d0,LEVC

                          move.w             #$0111,TXTBGCOL
                          cmp.b              #'s',mors
                          beq                SLAVESETUP  

                          cmp.b              #'m',mors
                          beq                MASTERSETUP

                          st.b               NASTY                                         ; Allow enemies

                          move.w             #$0000,TXTBGCOL
                          rts

*********************************************************************************************

NASTY:                    dc.w               0

*********************************************************************************************
;  Multi player

MASTERSETUP:
                          SAVEREGS

                          cmp.w              #1,MPMode
                          bne.b              skipMasterCoop

                          bsr                SetupDefaultGame
                          st.b               NASTY                                         ; All enemies

                          clr.l              d0
                          move.w             MPMode,d0
                          swap               d0
                          move.w             PLOPT,d0

                          bra                continueMaster

skipMasterCoop:
                          bsr                SetupTwoPlayerGame
                          clr.b              NASTY                                         ; No enemies

                          clr.l              d0
                          move.w             PLOPT,d0

continueMaster:
                          IFNE               ENABLEADVSERIAL
                          jsr                INITSEND                                      ; Sync slave
                          jsr                SENDLONG
                          jsr                SENDLAST
                          ENDC

                          IFEQ               ENABLEADVSERIAL
                          jsr                SENDFIRST
                          ENDC

                          move.w             #$0000,TXTBGCOL
                          GETREGS
                          rts

*********************************************************************************************
;  Multi player

SLAVESETUP:
                          SAVEREGS

                          IFNE               ENABLEADVSERIAL
                          jsr                INITREC                                       ; Wait master
                          jsr                RECEIVE
                          move.l             BUFFER,d0
                          ENDC

                          IFEQ               ENABLEADVSERIAL
                          jsr                RECFIRST
                          ENDC

                          move.l             d0,d1
                          swap               d1
                          move.w             d1,MPMode

                          move.w             d0,PLOPT
                          add.b              #'a',d0
                          move.b             d0,LEVA
                          move.b             d0,LEVB
                          move.b             d0,LEVC

                          move.w             #$0000,TXTBGCOL

                          cmp.w              #1,MPMode
                          bne.b              skipSlaveCoop

                          bsr                SetupDefaultGame
                          st.b               NASTY                                         ; All enemies

                          bra.b              continueSlave

skipSlaveCoop:
                          bsr                SetupTwoPlayerGame
                          clr.b              NASTY                                         ; No enemies

continueSlave:

                          GETREGS
                          rts
 	
*********************************************************************************************

ASKFORDISK:

                          move.w             #3,OptScrn
                          bsr                DrawOptScrn

.wtrel:
                          btst               #7,$bfe001                                    ; LMB port 2
                          beq.s              .wtrel

wtclick:
                          btst               #6,$bfe001                                    ; LMB port 1
                          bne.s              wtclick
 
                          rts

*********************************************************************************************

ClrSprites: 
; Clear tilescreen option sprites

                          move.l             #nullSpr,d0
                          move.w             d0,tsp0l
                          move.w             d0,tsp1l
                          move.w             d0,tsp2l
                          move.w             d0,tsp3l
                          move.w             d0,tsp4l
                          move.w             d0,tsp5l
                          move.w             d0,tsp6l
                          move.w             d0,tsp7l
                          swap               d0
                          move.w             d0,tsp0h
                          move.w             d0,tsp1h
                          move.w             d0,tsp2h
                          move.w             d0,tsp3h
                          move.w             d0,tsp4h
                          move.w             d0,tsp5h
                          move.w             d0,tsp6h
                          move.w             d0,tsp7h 

                          rts

*********************************************************************************************

ReadMainMenu:
; Stay here until 'play game' is selected.

                          move.b             #'n',mors

                          move.w             MAXLEVEL,d0
 
                          move.l             #CURRENTLEVELLINE,a1
                          muls               #40,d0
                          move.l             #LEVEL_OPTS,a0
                          add.l              d0,a0
                          bsr                PutInLine

                          move.w             #0,OptScrn
                          bsr                DrawOptScrn

                          move.w             #1,OPTNUM
                          bsr                HighLight

                          bsr                WaitRelease

************************************************************

rdlop1:
                          bsr                CheckMenu
                          tst.w              d0
                          blt.s              rdlop1
                          bne                noOpt1
                          bra                MasterMenu

noOpt1:

************************************************************
; Exit


                          cmp.w              #$ff,d0                                       ; agi: Exit game 
                          bne                .noExit
                          move.b             #'q',mors
                          rts
                     
.noExit:

************************************************************
; Level change

                          cmp.w              #$fe,d0                                       ; agi: Exit game 
                          bne                .noLevelChange

                          SAVEREGS

                          move.l             #PasswordStorage,a1
                          move.l             a1,a2

                          move.l             PasswordIndex,d2
                          move.l             d2,d1
                          muls.l             #17,d1
                          add.l              d1,a2
                          cmp.b              #32,(a2)
                          bne                .skip
                          move.l             #0,d1
                          move.l             #1,d2
                          bra                .continueLevels

.skip:
                          add.l              d1,a1

                          add.l              #1,d2   
                          cmp.l              #16,d2
                          bne                .continueLevels
                          move.l             #0,d2

.continueLevels: 
                          move.l             d2,PasswordIndex

                          move.l             #PASSWORDLINE+12,a0
                          move.l             #15,d0

.cpyLoop:                                   
                          move.b             (a1)+,(a0)+
                          dbra               d0,.cpyLoop

                          GETREGS

                          move.l             #PASSWORDLINE+12,a0
                          move.w             #15,d1
                          bra                .drawPassWord

.noLevelChange:

************************************************************

                          cmp.w              #1,d0
                          beq                readyToPlay1

************************************************************

                          cmp.w              #2,d0
                          bne                .nocontrol

                          bsr                ChangeControls

                          move.w             #0,OptScrn
                          bsr                DrawOptScrn

                          move.w             #1,OPTNUM
                          bsr                HighLight

                          bsr                WaitRelease

                          bra                rdlop1
 
.nocontrol:

************************************************************
 
                          cmp.w              #3,d0
                          bne                .nocred

                          bsr                SHOWCREDITS

                          move.w             #0,OptScrn
                          bsr                DrawOptScrn

                          move.w             #1,OPTNUM
                          bsr                HighLight

                          bsr                WaitRelease
                          bra                rdlop1
 
.nocred:

************************************************************
 
                          cmp.w              #4,d0
                          bne                readyToPlay1
                          bsr                WaitRelease

************************************************************
; Password handling

                          move.l             #PASSWORDLINE+12,a0
                          moveq              #15,d2

.clrline:
                          move.b             #32,(a0)+
                          dbra               d2,.clrline 

                          move.w             #0,OptScrn
                          bsr                DrawOptScrn

                          clr.b              lastpressed
                          move.l             #PASSWORDLINE+12,a0
                          move.w             #0,d1

.ENTERPASS:
                          tst.b              lastpressed
                          beq                .ENTERPASS

                          move.b             lastpressed,d2
                          move.b             #0,lastpressed
                          move.l             #KVALTOASC,a1

                          cmp.l              #'<-- ',(a1,d2.w*4)
                          bne                .nodel

                          tst.b              d1
                          beq                .nodel

                          subq               #1,d1
                          move.b             #32,-(a0)
                          SAVEREGS
                          bsr                JustDrawIt
                          GETREGS
                          bra                .ENTERPASS

.nodel:
                          cmp.l              #'RTN ',(a1,d2.w*4)
                          beq                .FORGETIT

                          cmp.l              #'ESC ',(a1,d2.w*4)
                          beq                .FORGETIT

                          move.b             1(a1,d2.w*4),d2
                          cmp.b              #65,d2
                          blt                .ENTERPASS

                          cmp.b              #'Z',d2
                          bgt                .ENTERPASS

                          move.b             d2,(a0)+

.drawPassWord:
                          move.w             #0,OptScrn
                          SAVEREGS
                          bsr                JustDrawIt
                          GETREGS

                          add.w              #1,d1
                          cmp.w              #16,d1
                          blt                .ENTERPASS

                          bsr                PassLineToGame
                          tst.w              d0
                          bne                .FORGETIT
 
                          bsr                GetStats
                          move.w             MAXLEVEL,d0
                          move.l             #CURRENTLEVELLINE,a1
                          muls               #40,d0
                          move.l             #LEVEL_OPTS,a0
                          add.l              d0,a0
                          bsr                PutInLine

.FORGETIT:

*********************************************************************************************

                          bsr                WaitRelease
                          bsr                CalcPassword

                          move.w             #0,OptScrn
                          bsr                DrawOptScrn

                          move.w             #1,OPTNUM
                          bsr                HighLight

                          bra                rdlop1
 
readyToPlay1:
                          move.w             MAXLEVEL,PLOPT
                          rts

*********************************************************************************************

LEVELSELECTED:            dc.w               0

*********************************************************************************************
*********************************************************************************************

MasterMenu:

                          move.b             #'m',mors

                          move.w             MAXLEVEL,d0
                          move.w             d0,LEVELSELECTED

************************************************************
; Reset level line

                          lea                CURRENTLEVELLINEM,a1
                          muls               #40,d0
                          lea                LEVEL_OPTS,a0
                          add.l              d0,a0
                          bsr                PutInLine

************************************************************
; Update mode line

                          lea                CURRENTMPMODELINE,a1
                          clr.l              d0
                          move.w             MPMode,d0
                          muls.l             #40,d0
                          lea                MPMODE_OPTS,a0
                          add.l              d0,a0
                          bsr                PutInLine

                          move.w             MPMode,d0
                          lea                MPMODE_HIGHLIGHT_OPTS,a0
                          lea                MASTERPLAYERMENU_OPTS,a1
                          bsr                UpdateHLSettings

************************************************************
; Stay here until 'play game' is selected.

                          move.w             #4,OptScrn
                          bsr                DrawOptScrn

                          move.w             #1,OPTNUM
                          bsr                HighLight

                          bsr                WaitRelease

************************************************************

rdlop2:
                          bsr                CheckMenu
                          tst.w              d0
                          blt.s              rdlop2
                          bsr                WaitRelease

************************************************************
; Master level change

                          cmp.w              #$fe,d0                                       ; TAB
                          beq.b              .masterNextLevel

                          cmp.w              #1,d0
                          bne.s              .nonextlev
 
.masterNextLevel:
                          movem.l            d1-d7/a0-a6,-(a7)

                          move.l             #PasswordStorage,a0
                          move.w             LEVELSELECTED,d0
                          add.w              #1,d0 
                          move.w             d0,d1
                          muls.w             #17,d1
                          add.w              d1,a0
                          cmp.b              #32,(a0)
                          bne                .masterSkip

                          move.w             #0,d0
                          bra                .masterContinueLevels

.masterSkip:
                          cmp.w              #16,d0
                          bne                .masterContinueLevels

                          move.w             #0,d0

.masterContinueLevels: 
                          move.w             d0,LEVELSELECTED

                          movem.l            (a7)+,d1-d7/a0-a6

                          lea                CURRENTLEVELLINEM,a1
                          muls               #40,d0
                          lea                LEVEL_OPTS,a0
                          add.l              d0,a0
                          bsr                PutInLine

                          bsr                JustDrawIt
                          bra                rdlop2

.nonextlev:

************************************************************

                          cmp.w              #2,d0
                          beq                readyToPlay2
 
 ************************************************************

                          cmp.w              #$ff,d0                                       ; ESC
                          beq.b              .masterToSlaveMenu

                          cmp.w              #0,d0
                          bne                noOpt2
 
                          cmp.w              #1,MPMode
                          bne                changeMPMode
                     
                          move.w             #0,MPMode

.masterToSlaveMenu:
                          bra                SlaveMenu

************************************************************

changeMPMode:
                          lea                CURRENTMPMODELINE,a1
                          clr.l              d0
                          move.w             MPMode,d0
                          add.w              #1,d0
                          move.w             d0,MPMode
                          mulu.l             #40,d0
                          lea                MPMODE_OPTS,a0
                          add.l              d0,a0
                          bsr                PutInLine

                          move.w             MPMode,d0
                          lea                MPMODE_HIGHLIGHT_OPTS,a0
                          lea                MASTERPLAYERMENU_OPTS,a1
                          bsr                UpdateHLSettings

                          move.w             #4,OptScrn
                          bsr                DrawOptScrn

                          move.w             #2,OPTNUM
                          bsr                HighLight

                          bsr                WaitRelease
                     
                          bra                rdlop2

************************************************************

noOpt2:
                          cmp.w              #3,d0
                          bne                .nocontrol
 
                          bsr                ChangeControls

                          move.w             #4,OptScrn
                          bsr                DrawOptScrn
                          move.w             #0,OPTNUM

                          bsr                HighLight

                          bsr                WaitRelease
                          bra                rdlop2
 
.nocontrol:

************************************************************

readyToPlay2:
                          move.w             LEVELSELECTED,PLOPT
                          rts

*********************************************************************************************
*********************************************************************************************

SlaveMenu:

                          move.b             #'s',mors

; Stay here until 'play game' is selected.

                          move.w             #5,OptScrn
                          bsr                DrawOptScrn
                          move.w             #1,OPTNUM

                          bsr                HighLight
                          bsr                WaitRelease

************************************************************

rdlop3:
                          bsr                CheckMenu
                          tst.w              d0
                          blt.s              rdlop3
                          bsr                WaitRelease

************************************************************

                          cmp.w              #$fe,d0                                       ; TAB
                          beq.b              rdlop3

                          cmp.w              #1,d0
                          beq                readyToPlay3


                          cmp.w              #$ff,d0                                       ; ESC
                          beq.b              .slaveToMainMenu

                          cmp.w              #0,d0
                          bne                noOpt3
 
.slaveToMainMenu:
                          bra                ReadMainMenu
 
noOpt3:
                          cmp.w              #2,d0
                          bne                .nocontrol
 
                          bsr                ChangeControls

                          move.w             #0,OptScrn
                          bsr                DrawOptScrn
                          move.w             #0,OPTNUM

                          bsr                HighLight

                          bsr                WaitRelease
                          bra                rdlop3
 
.nocontrol:
readyToPlay3:
                          rts

*********************************************************************************************
*********************************************************************************************

SetupTwoPlayerGame:

                          move.w             #0,OldEnergy
                          move.w             #PlayerMaxEnergy,Energy
                          jsr                EnergyBar
 
                          move.w             #63,OldAmmo
                          move.w             #0,Ammo
                          jsr                AmmoBar
                          move.w             #0,OldAmmo
 
                          move.w             #PlayerMaxEnergy,PLR1_energy
                          move.w             #PlayerMaxEnergy,PLR2_energy 


                          st                 PLR1_GunData+7                                ; 7: Visible/Instant (0/$ff)
                          move.w             #160,PLR1_GunData                             ; 0: Ammo (10 shots pistol)

                          st.b               PLR1_GunData+GUNDATASIZE+7
                          move.w             #80*4,PLR1_GunData+GUNDATASIZE
 
                          st.b               PLR1_GunData+GUNDATASIZE*2+7
                          move.w             #80*4,PLR1_GunData+GUNDATASIZE*2
 
                          st.b               PLR1_GunData+GUNDATASIZE*3+7
                          move.w             #80*4,PLR1_GunData+GUNDATASIZE*3
 
                          st.b               PLR1_GunData+GUNDATASIZE*4+7
                          move.w             #80*4,PLR1_GunData+GUNDATASIZE*4
 
                          st.b               PLR1_GunData+GUNDATASIZE*7+7
                          move.w             #80*4,PLR1_GunData+GUNDATASIZE*7
 
                          move.b             #0,PLR1_GunSelected


                          st                 PLR2_GunData+7 
                          move.w             #160,PLR2_GunData                             ; 10 shots pistol

                          st.b               PLR2_GunData+GUNDATASIZE+7
                          move.w             #80*4,PLR2_GunData+GUNDATASIZE
 
                          st.b               PLR2_GunData+GUNDATASIZE*2+7
                          move.w             #80*4,PLR2_GunData+GUNDATASIZE*2
 
                          st.b               PLR2_GunData+GUNDATASIZE*3+7
                          move.w             #80*4,PLR2_GunData+GUNDATASIZE*3
 
                          st.b               PLR2_GunData+GUNDATASIZE*4+7
                          move.w             #80*4,PLR2_GunData+GUNDATASIZE*4
 
                          st.b               PLR2_GunData+GUNDATASIZE*7+7
                          move.w             #80*4,PLR2_GunData+GUNDATASIZE*7

                          move.b             #0,PLR2_GunSelected
                     
                          rts

*********************************************************************************************

SetupDefaultGame:

                          move.w             #STARTLEVEL,MAXLEVEL
 
                          move.w             #0,OldEnergy
                          move.w             #PlayerMaxEnergy,Energy
                          jsr                EnergyBar
 
                          move.w             #63,OldAmmo
                          move.w             #0,Ammo
                          jsr                AmmoBar
                          move.w             #0,OldAmmo
 
                          move.w             #PlayerMaxEnergy,PLR1_energy
                          move.w             #PlayerMaxEnergy,PLR2_energy 


                          move.w             #160,PLR1_GunData                             ; 10 shots pistol

                          st                 PLR1_GunData+7

                          clr.b              PLR1_GunData+GUNDATASIZE+7
                          clr.w              PLR1_GunData+GUNDATASIZE

                          clr.b              PLR1_GunData+GUNDATASIZE*2+7
                          clr.w              PLR1_GunData+GUNDATASIZE*2

                          clr.b              PLR1_GunData+GUNDATASIZE*3+7
                          clr.w              PLR1_GunData+GUNDATASIZE*3

                          clr.b              PLR1_GunData+GUNDATASIZE*4+7
                          clr.w              PLR1_GunData+GUNDATASIZE*4

                          clr.b              PLR1_GunData+GUNDATASIZE*7+7
                          clr.w              PLR1_GunData+GUNDATASIZE*7

                          move.b             #0,PLR1_GunSelected


                          move.w             #160,PLR2_GunData                             ; 10 shots pistol
                     
                          st                 PLR2_GunData+7

                          clr.b              PLR2_GunData+GUNDATASIZE+7
                          clr.w              PLR2_GunData+GUNDATASIZE

                          clr.b              PLR2_GunData+GUNDATASIZE*2+7
                          clr.w              PLR2_GunData+GUNDATASIZE*2

                          clr.b              PLR2_GunData+GUNDATASIZE*3+7
                          clr.w              PLR2_GunData+GUNDATASIZE*3

                          clr.b              PLR2_GunData+GUNDATASIZE*4+7
                          clr.w              PLR2_GunData+GUNDATASIZE*4

                          clr.b              PLR2_GunData+GUNDATASIZE*7+7
                          clr.w              PLR2_GunData+GUNDATASIZE*7

                          move.b             #0,PLR2_GunSelected
 

                          bsr                CalcPassword
 
                          rts

*********************************************************************************************
*********************************************************************************************

GetParity:

                          move.w             #6,d3

.calcparity:
                          btst               d3,d0
                          beq.s              .nochange
                          bchg               #7,d0

.nochange:
                          dbra               d3,.calcparity
                          rts

*********************************************************************************************

CheckParity:

                          move.w             #6,d3
                          move.b             #$0,d2

.calcparity:
                          btst               d3,d0
                          beq.s              .nochange
                          bchg               #7,d2

.nochange:
                          dbra               d3,.calcparity
                          move.b             d0,d1
                          and.b              #$80,d1
                          eor.b              d1,d2
                          sne                d5
                          rts

*********************************************************************************************
; Create level password

CalcPassword:

                          move.b             PLR1_energy+1,d0
                          bsr                GetParity
                          move.b             d0,PASSBUFFER

                          moveq              #0,d0
                          tst.b              PLR1_GunData+GUNDATASIZE+7
                          sne                d0
                          lsl.w              #1,d0
                          tst.b              PLR1_GunData+GUNDATASIZE*2+7
                          sne                d0
                          lsl.w              #1,d0
                          tst.b              PLR1_GunData+GUNDATASIZE*4+7
                          sne                d0
                          lsl.w              #1,d0
                          tst.b              PLR1_GunData+GUNDATASIZE*7+7
                          sne                d0
                          lsr.w              #3,d0
                          and.b              #%11110000,d0
                          or.b               MAXLEVEL+1,d0
                          move.b             d0,PASSBUFFER+1

                          eor.b              #%10110101,d0
                          neg.b              d0
                          add.b              #50,d0
                          move.b             d0,PASSBUFFER+7
 
                          move.w             PLR1_GunData,d0
                          lsr.w              #3,d0
                          bsr                GetParity
                          move.b             d0,PASSBUFFER+2

                          move.w             PLR1_GunData+GUNDATASIZE,d0
                          lsr.w              #3,d0
                          bsr                GetParity
                          move.b             d0,PASSBUFFER+3

                          move.w             PLR1_GunData+GUNDATASIZE*2,d0
                          lsr.w              #3,d0
                          bsr                GetParity
                          move.b             d0,PASSBUFFER+4

                          move.w             PLR1_GunData+GUNDATASIZE*4,d0
                          lsr.w              #3,d0
                          bsr                GetParity
                          move.b             d0,PASSBUFFER+5

                          move.w             PLR1_GunData+GUNDATASIZE*7,d0
                          lsr.w              #3,d0
                          bsr                GetParity
                          move.b             d0,PASSBUFFER+6

                          move.w             #3,d0
                          move.l             #PASSBUFFER,a0
                          move.l             #PASSBUFFER+8,a1
                          move.l             #PASS,a2
                          moveq              #0,d4

mixemup:
                          move.b             (a0)+,d1
                          move.b             -(a1),d2
                          not.b              d2
                          moveq              #0,d3
                          lsr.b              #1,d1
                          addx.w             d3,d3
                          lsr.b              #1,d2
                          addx.w             d3,d3
                          lsr.b              #1,d1
                          addx.w             d3,d3
                          lsr.b              #1,d2
                          addx.w             d3,d3
                          lsr.b              #1,d1
                          addx.w             d3,d3
                          lsr.b              #1,d2
                          addx.w             d3,d3
                          lsr.b              #1,d1
                          addx.w             d3,d3
                          lsr.b              #1,d2
                          addx.w             d3,d3
                          lsr.b              #1,d1
                          addx.w             d3,d3
                          lsr.b              #1,d2
                          addx.w             d3,d3
                          lsr.b              #1,d1
                          addx.w             d3,d3
                          lsr.b              #1,d2
                          addx.w             d3,d3
                          lsr.b              #1,d1
                          addx.w             d3,d3
                          lsr.b              #1,d2
                          addx.w             d3,d3
                          lsr.b              #1,d1
                          addx.w             d3,d3
                          lsr.b              #1,d2
                          addx.w             d3,d3
                          move.w             d3,(a2)+

                          dbra               d0,mixemup
 
                          move.l             #PASSWORDLINE+12,a0
                          move.l             #PASS,a1
                          move.w             #7,d0

putinpassline:
                          move.b             (a1),d1
                          and.b              #%1111,d1
                          add.b              #65,d1
                          move.b             d1,(a0)+
                          move.b             (a1)+,d1
                          lsr.b              #4,d1
                          and.b              #%1111,d1
                          add.b              #65,d1
                          move.b             d1,(a0)+
                          move.b             d1,(a2)+
                          dbra               d0,putinpassline

 ; Save to passstorage

                          move.l             #PasswordStorage,a1
                          clr.l              d0
                          move.w             MAXLEVEL,d0
                          muls.l             #17,d0
                          add.l              d0,a1

                          move.l             #PASSWORDLINE+12,a0
                          move.l             #15,d0

.cpyLoop1:
                          move.b             (a0)+,(a1)+
                          dbra               d0,.cpyLoop1

                          rts

*********************************************************************************************

PassLineToGame:

                          move.l             #PASSWORDLINE+12,a0
                          move.l             #PASS,a1
                          move.w             #7,d0

getbuff:
                          move.b             (a0)+,d1
                          move.b             (a0)+,d2
                          sub.b              #65,d1
                          sub.b              #65,d2
                          and.b              #%1111,d1
                          and.b              #%1111,d2
                          lsl.b              #4,d2
                          or.b               d2,d1
                          move.b             d1,(a1)+
                          dbra               d0,getbuff
 
                          move.l             #PASS,a0
                          move.l             #PASSBUFFER,a1
                          move.l             #PASSBUFFER+8,a2
                          move.w             #3,d0
                          moveq              #0,d4

unmix:
                          move.w             (a0)+,d1
                          moveq              #0,d2
                          moveq              #0,d3
                          lsr.w              #1,d1
                          addx.w             d3,d3
                          lsr.w              #1,d1
                          addx.w             d2,d2
                          lsr.w              #1,d1
                          addx.w             d3,d3
                          lsr.w              #1,d1
                          addx.w             d2,d2
                          lsr.w              #1,d1
                          addx.w             d3,d3
                          lsr.w              #1,d1
                          addx.w             d2,d2
                          lsr.w              #1,d1
                          addx.w             d3,d3
                          lsr.w              #1,d1
                          addx.w             d2,d2
                          lsr.w              #1,d1
                          addx.w             d3,d3
                          lsr.w              #1,d1
                          addx.w             d2,d2
                          lsr.w              #1,d1
                          addx.w             d3,d3
                          lsr.w              #1,d1
                          addx.w             d2,d2
                          lsr.w              #1,d1
                          addx.w             d3,d3
                          lsr.w              #1,d1
                          addx.w             d2,d2
                          lsr.w              #1,d1
                          addx.w             d3,d3
                          lsr.w              #1,d1
                          addx.w             d2,d2
                          not.b              d3
                          move.b             d3,-(a2)
                          move.b             d2,(a1)+
                          dbra               d0,unmix
 
                          move.b             PASSBUFFER,d0
                          bsr                CheckParity
                          tst.b              d5
                          bne                illega
                          move.b             PASSBUFFER+2,d0
                          bsr                CheckParity
                          tst.b              d5
                          bne                illega
                          move.b             PASSBUFFER+3,d0
                          bsr                CheckParity
                          tst.b              d5
                          bne                illega
                          move.b             PASSBUFFER+4,d0
                          bsr                CheckParity
                          tst.b              d5
                          bne                illega
                          move.b             PASSBUFFER+5,d0
                          bsr                CheckParity
                          tst.b              d5
                          bne                illega
                          move.b             PASSBUFFER+6,d0
                          bsr                CheckParity
                          tst.b              d5
                          bne                illega
 
                          move.b             PASSBUFFER+1,d0
                          eor.b              #%10110101,d0
                          neg.b              d0
                          add.b              #50,d0
                          cmp.b              PASSBUFFER+7,d0
                          bne                illega
 
                          move.w             #0,d0
                          rts
 
illega:
                          move.w             #-1,d0
                          rts

*********************************************************************************************

PASSBUFFER:               ds.b               8
CHECKBUFFER:              ds.b               8
PASS:                     ds.b               16

*********************************************************************************************

ChangeControls:

                          move.w             #6,OptScrn
                          bsr                DrawOptScrn
                          move.w             #0,OPTNUM
                          bsr                HighLight
                          bsr                WaitRelease
 
.rdlop4:
                          bsr                CheckMenu
                          tst.w              d0
                          blt.s              .rdlop4

                          cmp.w              #12,d0
                          beq                .backtomain

                          move.l             #KEY_LINES,a0
                          move.w             d0,d1
                          muls               #40,d1
                          add.l              d1,a0
                          add.w              #32,a0
                          move.l             #$20202020,(a0)
                          movem.l            d0/a0,-(a7)
                          bsr                JustDrawIt
                          movem.l            (a7)+,d0/a0 

                          clr.b              lastpressed

.wtkey:
                          tst.b              lastpressed
                          beq                .wtkey
 
                          move.l             #CONTROLBUFFER,a1
                          moveq              #0,d1
                          move.b             lastpressed,d1
                          move.b             d1,(a1,d0.w)
                          move.l             #KVALTOASC,a1
                          move.l             (a1,d1.w*4),(a0)
                          bsr                JustDrawIt
                          bsr                WaitRelease
                          bra                .rdlop4

.backtomain:
                          rts

*********************************************************************************************
 
MAXLEVEL:                 dc.w               STARTLEVEL

*********************************************************************************************

SHOWCREDITS:

                          move.w             #2,OptScrn
                          bsr                DrawOptScrn

                          bsr                WaitRelease

.rdlop5:
                          bsr                CheckMenu
                          tst.w              d0
                          blt.s              .rdlop5
 
                          move.w             #8,OptScrn
                          bsr                DrawOptScrn

                          bsr                WaitRelease                     

.rdlop6:
                          bsr                CheckMenu
                          tst.w              d0
                          blt.s              .rdlop6

                          rts
 
*********************************************************************************************

HELDDOWN:                 dc.w               0

*********************************************************************************************

WaitRelease:
                         
*********************************************************************************************
; RTG Change:

                          SAVEREGS

************************************************************
; Get title picture
                        ;   lea                TitleSrnCop,a5
                        ;   lea                Title24bitPalette,a6
                        ;   move.l             #128,pp24ColorCount
                        ;   move.l             #0,pp24ColorOffset
                        ;   jsr                Parse24bitPalette

                        ;   lea                OptScrnCop,a5
                        ;   lea                Title24bitPalette,a6
                        ;   move.l             #64,pp12ColorCount
                        ;   move.l             #128,pp12ColorOffset
                        ;   jsr                Parse12bitPalette

                        ;   move.l             #Title24bitPalette,PtaPalettePtr
                        ;   move.l             TITLESCRNADDR,PtaBplPtr
                        ;   move.l             #PlaneBuffer1,PtaBplColBufPtr
                        ;   move.l             #320,PtaBplWidth
                        ;   move.l             #256,PtaBplHeight
                        ;   move.l             #7,PtaBplCount
                        ;   move.l             #0,PtaBplModulo
                        ;   move.l             #(320/8)*256,PtaBplOffsetInBytes
                        ;   jsr                CopyPlaneToColorBuffer

                          move.l             #RTGTitle,bplHiColBufPtr
                          move.l             #(RTGCanvasWidth/4)+1,bplHiColRtgX
                          move.l             #1,bplHiColRtgY
                          jsr                DrawAB3dHiColor15BufferToWindow

************************************************************
; Sprite 0
                          move.l             OPTSPRADDR,d0
                          move.l             d0,StaSprPtr
                          lea                SprColorBuffer0,a0
                          move.l             a0,StaColBufPtr
                          lea                SprColorBufferHeight0,a0
                          move.l             a0,StaColBufHeightPtr
                          move.w             #32*4,StaColRegBase
                          move.l             #0,StaSprHeight
                          jsr                CopySpriteToColorBuffer

; Sprite 1
                          move.l             OPTSPRADDR,d0
                          add.l              #258*16,d0
                          move.l             d0,StaSprPtr
                          lea                SprColorBuffer1,a0
                          move.l             a0,StaColBufPtr
                          lea                SprColorBufferHeight1,a0
                          move.l             a0,StaColBufHeightPtr
                          move.w             #32*4,StaColRegBase
                          move.l             #0,StaSprHeight
                          jsr                CopySpriteToColorBuffer

; Sprite 2
                          move.l             OPTSPRADDR,d0
                          add.l              #258*16*2,d0
                          move.l             d0,StaSprPtr
                          lea                SprColorBuffer2,a0
                          move.l             a0,StaColBufPtr
                          lea                SprColorBufferHeight2,a0
                          move.l             a0,StaColBufHeightPtr
                          move.w             #32*4,StaColRegBase
                          move.l             #0,StaSprHeight
                          jsr                CopySpriteToColorBuffer

; Sprite 3
                          move.l             OPTSPRADDR,d0
                          add.l              #258*16*3,d0
                          move.l             d0,StaSprPtr
                          lea                SprColorBuffer3,a0
                          move.l             a0,StaColBufPtr
                          lea                SprColorBufferHeight3,a0
                          move.l             a0,StaColBufHeightPtr
                          move.w             #32*4,StaColRegBase
                          move.l             #0,StaSprHeight
                          jsr                CopySpriteToColorBuffer

; Sprite 4
                          move.l             OPTSPRADDR,d0
                          add.l              #258*16*4,d0
                          move.l             d0,StaSprPtr
                          lea                SprColorBuffer4,a0
                          move.l             a0,StaColBufPtr
                          lea                SprColorBufferHeight4,a0
                          move.l             a0,StaColBufHeightPtr
                          move.w             #32*4,StaColRegBase
                          move.l             #0,StaSprHeight
                          jsr                CopySpriteToColorBuffer

************************************************************
; Draw title text

                          lea                SprColorBuffer0,a0
                          move.l             a0,DscbColBuf
                          move.l             SprColorBufferHeight0,DscbHeight
                          lea                Title24bitPalette,a0
                          move.l             a0,DscbPalettePtr
                          move.l             #(RTGCanvasWidth/4)+1,DscbRtgX
                          move.l             #1,DscbRtgY
                          move.l             #0,DscForce
                          move.l             #-1,DscbCopEffectCol
                          move.l             #0,DscbCopEffectColBufPtr                          
                          jsr                DrawSpriteColorBuffer

                          lea                SprColorBuffer1,a0
                          move.l             a0,DscbColBuf
                          move.l             SprColorBufferHeight1,DscbHeight
                          lea                Title24bitPalette,a0
                          move.l             a0,DscbPalettePtr
                          move.l             #(RTGCanvasWidth/4)+64,DscbRtgX
                          move.l             #1,DscbRtgY
                          move.l             #0,DscForce
                          move.l             #-1,DscbCopEffectCol
                          move.l             #0,DscbCopEffectColBufPtr                          
                          jsr                DrawSpriteColorBuffer

                          lea                SprColorBuffer2,a0
                          move.l             a0,DscbColBuf
                          move.l             SprColorBufferHeight2,DscbHeight
                          lea                Title24bitPalette,a0
                          move.l             a0,DscbPalettePtr
                          move.l             #(RTGCanvasWidth/4)+128,DscbRtgX
                          move.l             #1,DscbRtgY
                          move.l             #0,DscForce
                          move.l             #-1,DscbCopEffectCol
                          move.l             #0,DscbCopEffectColBufPtr                          
                          jsr                DrawSpriteColorBuffer

                          lea                SprColorBuffer3,a0
                          move.l             a0,DscbColBuf
                          move.l             SprColorBufferHeight3,DscbHeight
                          lea                Title24bitPalette,a0
                          move.l             a0,DscbPalettePtr
                          move.l             #(RTGCanvasWidth/4)+192,DscbRtgX
                          move.l             #1,DscbRtgY
                          move.l             #0,DscForce
                          move.l             #-1,DscbCopEffectCol
                          move.l             #0,DscbCopEffectColBufPtr                          
                          jsr                DrawSpriteColorBuffer

                          lea                SprColorBuffer4,a0
                          move.l             a0,DscbColBuf
                          move.l             SprColorBufferHeight4,DscbHeight
                          lea                Title24bitPalette,a0
                          move.l             a0,DscbPalettePtr
                          move.l             #(RTGCanvasWidth/4)+256,DscbRtgX
                          move.l             #1,DscbRtgY
                          move.l             #0,DscForce
                          move.l             #-1,DscbCopEffectCol
                          move.l             #0,DscbCopEffectColBufPtr                          
                          jsr                DrawSpriteColorBuffer

                          GETREGS

; End of RTG changes
*********************************************************************************************

                          movem.l            d0/d1/d2/d3,-(a7)
                          move.l             #KeyMap,a5

waitRelLoop:

************************************************************************
; Rtg change - Handle keyboard

                          jsr                HandleP96RTGWindowInputs

; End of RTG change
************************************************************************

                          btst               #7,$bfe001                                    ; LMB port 2
                          beq.s              waitRelLoop

                          tst.b              $40(a5)                                       ; Space bar
                          bne.s              waitRelLoop

                          tst.b              $44(a5)                                       ; Return
                          bne.s              waitRelLoop

                          tst.b              $4c(a5)                                       ; Up arrow
                          bne.s              waitRelLoop

                          tst.b              $4d(a5)                                       ; Down arrow
                          bne.s              waitRelLoop

                          tst.b              $45(a5)                                       ; Esc
                          bne.s              waitRelLoop

                          tst.b              $42(a5)                                       ; Tab
                          bne.s              waitRelLoop

                          btst               #1,$dff00c
                          sne                d0
                          btst               #1,$dff00d
                          sne                d1
                          btst               #0,$dff00c
                          sne                d2
                          btst               #0,$dff00d
                          sne                d3
 
                          eor.b              d0,d2
                          eor.b              d1,d3
                          tst.b              d2
                          bne.s              waitRelLoop
                          tst.b              d3
                          bne.s              waitRelLoop

                          movem.l            (a7)+,d0/d1/d2/d3
                          rts

*********************************************************************************************

PutInLine:
; line = 40 chars
; a0 = source line
; a1 = destination line

                          moveq              #39,d0

loopChars:
                          move.b             (a0)+,(a1)+
                          dbra               d0,loopChars
                          rts

*********************************************************************************************

CheckMenu:

************************************************************************
; Rtg change - Handle keyboard

                          jsr                HandleP96RTGWindowInputs

; End of RTG change
************************************************************************

                          btst               #1,$dff00c
                          sne                d0
                          btst               #1,$dff00d
                          sne                d1
                          btst               #0,$dff00c
                          sne                d2
                          btst               #0,$dff00d
                          sne                d3
 
                          eor.b              d0,d2
                          eor.b              d1,d3
 
                          move.l             #KeyMap,a5

                          tst.b              $45(a5)                                       ; ESC
                          beq                NotESCKey 
                          bsr                WaitRelease
                          move.w             #$ff,d0
                          bra                noselect

NotESCKey:
                          tst.b              $42(a5)                                       ; TAB
                          beq                NotTABKey
                          bsr                WaitRelease
                          move.w             #$fe,d0
                          bra                noselect

NotTABKey:
                          move.b             $4c(a5),d0                                    ; Up arrow
                          move.b             $4d(a5),d1                                    ; Down arrow
                          or.b               d1,d3
                          or.b               d0,d2

                          move.w             OptScrn,d0
                          move.l             #MENUDATA,a0
                          move.l             4(a0,d0.w*8),a0                               ; opt data

                          move.w             OPTNUM,d0

                          tst.b              d2
                          beq.s              NOPREV
 
 
                          sub.w              #1,d0
                          bge.s              NOPREV
 
                          move.w             #0,d0 

NOPREV:
                          tst.b              d3
                          beq.s              NONEXT
 
                          bsr                WaitRelease
 
                          add.w              #1,d0
                          tst.w              (a0,d0.w*8)
                          bge.s              NONEXT
 
                          subq               #1,d0
 
NONEXT:
                          cmp.w              OPTNUM,d0
                          beq.s              .nochange

                          bsr                HighLight
                          move.w             d0,OPTNUM
                          bsr                HighLight
                          bsr                WaitRelease
 
.nochange:
                          move.w             #-1,d0
 
                          btst               #7,$bfe001                                    ; LMB port 2
                          beq.s              select
                          move.b             $40(a5),d1                                    ; Space bar
                          or.b               $44(a5),d1                                    ; Return
                          tst.b              d1
                          beq.s              noselect
 
select:
                          bsr                WaitRelease
                          move.w             OPTNUM,d0

noselect:
                          rts

*********************************************************************************************

UpdateHLSettings:
; d0=line
; a0=from
; a1=to

                          mulu.l             #8,d0
                          add.l              d0,a0
                          move.l             #3,d0

cpyHLSettings:
                          move.w             (a0)+,(a1)+
                          dbeq               d0,cpyHLSettings

                          rts

*********************************************************************************************

HighLight:
; Highlight menu line
                          SAVEREGS

                          lea                MENUDATA,a0

                          move.w             OptScrn,d0
                          move.l             4(a0,d0.w*8),a0

                          move.w             OPTNUM,d0
                          lea                (a0,d0.w*8),a0

                          move.w             (a0)+,d0                                      ; left
                          move.w             (a0)+,d1                                      ; top
                          move.w             (a0)+,d2                                      ; width

                          muls               #16*8,d1
                          move.l             OPTSPRADDR,a1
                          add.w              d1,a1
                          add.w              #8+16,a1
                          move.l             #SCRTOSPR2,a5
                          adda.w             d0,a5
                          adda.w             d0,a5
 
NOTLOP:
                          move.w             (a5)+,d3
                          lea                (a1,d3.w),a2
                          not.b              (a2)
                          not.b              16(a2)
                          not.b              32(a2)
                          not.b              48(a2)
                          not.b              64(a2)
                          not.b              80(a2)
                          not.b              96(a2)
                          not.b              112(a2)
                          not.b              128(a2)
                          subq               #1,d2
                          bgt.s              NOTLOP
 
                          GETREGS
                          rts

*********************************************************************************************

SCRTOSPR2:
val                       SET                0
                          REPT               6
                          dc.w               val+0
                          dc.w               val+1
                          dc.w               val+2
                          dc.w               val+3
                          dc.w               val+4
                          dc.w               val+5
                          dc.w               val+6
                          dc.w               val+7
val                       SET                val+258*16
                          ENDR

*********************************************************************************************

ClrOptScrn:
; Five sprites for the menu text 
; One sprite 1430 bytes

                          move.l             OPTSPRADDR,a0
                          lea                16(a0),a1                                     ; spr0 ptr (Skip control words (2*8 bytes -> 64bit))
                          lea                16+(258*16)(a0),a2                            ; spr1 ptr
                          lea                16+(258*16*2)(a0),a3                          ; spr2 ptr
                          lea                16+(258*16*3)(a0),a4                          ; spr3 ptr
                          lea                258*16(a4),a0                                 ; spr4 ptr
 
                          move.w             #256,d0
                          moveq              #0,d1

CLRLOP:
                          move.l             d1,(a0)+
                          move.l             d1,(a0)+
                          move.l             d1,(a0)+
                          move.l             d1,(a0)+

                          move.l             d1,(a1)+
                          move.l             d1,(a1)+
                          move.l             d1,(a1)+
                          move.l             d1,(a1)+

                          move.l             d1,(a2)+
                          move.l             d1,(a2)+
                          move.l             d1,(a2)+
                          move.l             d1,(a2)+

                          move.l             d1,(a3)+
                          move.l             d1,(a3)+
                          move.l             d1,(a3)+
                          move.l             d1,(a3)+

                          move.l             d1,(a4)+
                          move.l             d1,(a4)+
                          move.l             d1,(a4)+
                          move.l             d1,(a4)+

                          dbra               d0,CLRLOP

************************************************************
; Setup spr control words 64bit * 2
; spr = 258 * 16 bytes -> 2 * 8 bytes + 4112 bytes
; $1020 = 4128 bytes

                          move.l             OPTSPRADDR,a0
                          move.w             #44*256+64,(a0)                               ; $2c40
                          move.w             #44*256+2,8(a0)                               ; $2c02 
                          add.l              #258*16,a0

                          move.w             #44*256+96,(a0)                               ; $2c60
                          move.w             #44*256+2,8(a0)                               ; $2c02
                          add.l              #258*16,a0

                          move.w             #44*256+128,(a0)
                          move.w             #44*256+2,8(a0)
                          add.l              #258*16,a0

                          move.w             #44*256+160,(a0)
                          move.w             #44*256+2,8(a0)
                          add.l              #258*16,a0

                          move.w             #44*256+192,(a0)
                          move.w             #44*256+2,8(a0)

                          rts

*********************************************************************************************

DrawOptScrn:

                          bsr                ClrOptScrn

*********************************************************************************************

JustDrawIt:

                          lea                font,a0
                          lea                MENUDATA,a1
                          move.w             OptScrn,d0
                          move.l             (a1,d0.w*8),a1
 
                          move.l             OPTSPRADDR,a3
                          add.l              #16,a3                                        ; Skip spr control bytes
                          moveq              #0,d2
 
                          move.w             #31,d0
linelop:
                          move.w             #39,d1
                          lea                SCRTOSPR,a4
                          move.l             a3,a2
charlop:
                          move.b             (a1)+,d2
                          lea                (a0,d2.w*8),a5
                          move.b             (a5)+,(a2)
                          move.b             (a5)+,16(a2)
                          move.b             (a5)+,32(a2)
                          move.b             (a5)+,48(a2)
                          move.b             (a5)+,64(a2)
                          move.b             (a5)+,80(a2)
                          move.b             (a5)+,96(a2)
                          move.b             (a5),112(a2)
                          add.w              (a4)+,a2
                          dbra               d1,charlop
                          add.w              #16*8,a3
                          dbra               d0,linelop

                          rts

*********************************************************************************************

SCRTOSPR:
                          dc.w               1,1,1,1,1,1,1,258*16-7
                          dc.w               1,1,1,1,1,1,1,258*16-7
                          dc.w               1,1,1,1,1,1,1,258*16-7
                          dc.w               1,1,1,1,1,1,1,258*16-7
                          dc.w               1,1,1,1,1,1,1,258*16-7
                          dc.w               1,1,1,1,1,1,1,258*16-7

*********************************************************************************************

OPTNUM:                   dc.w               0
OptScrn::                 dc.w               0

*********************************************************************************************

; Selected level
PLOPT:                    dc.w               0
; Note: Mode 1 = CO-OP - Only the master (plr1) can pickup a key (etc) in the coop mode 
MPMode:                   dc.w               0 

*********************************************************************************************

MENUDATA:
;0
                          dc.l               ONEPLAYERMENU_TXT
                          dc.l               ONEPLAYERMENU_OPTS
;1
                          dc.l               INSTRUCTIONS_TXT
                          dc.l               INSTRUCTIONS_OPTS
;2
                          dc.l               CREDITMENU_TXT
                          dc.l               CREDITMENU_OPTS
;3
                          dc.l               INSTRUCTIONS_TXT                              ; ASKFORDISK_TXT
                          dc.l               INSTRUCTIONS_OPTS                             ; ASKFORDISK_OPTS
;4
                          dc.l               MASTERPLAYERMENU_TXT
                          dc.l               MASTERPLAYERMENU_OPTS
;5
                          dc.l               SLAVEPLAYERMENU_TXT
                          dc.l               SLAVEPLAYERMENU_OPTS
;6
                          dc.l               CONTROL_TXT
                          dc.l               CONTROL_OPTS
;7
                          dc.l               INSTRUCTIONS_TXT                              ; PROTMENU_TXT
                          dc.l               INSTRUCTIONS_OPTS                             ; CONTROL_OPTS
;8
                          dc.l               CREDITMENUPART2_TXT
                          dc.l               CREDITMENU_OPTS

*********************************************************************************************
 
ONEPLAYERMENU_TXT:
;                                             0123456789012345678901234567890123456789
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1
                          dc.b               '                                        '    ;2
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;4
                          dc.b               '                                        '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;0
CURRENTLEVELLINE:
                          dc.b               '           LEVEL 1 : THE GATE           '    ;1 
                          dc.b               '                                        '    ;2
                          dc.b               '                1 PLAYER                '    ;3
                          dc.b               '                                        '    ;4
                          dc.b               '               PLAY  GAME               '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '            CONTROL  OPTIONS            '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '              GAME CREDITS              '    ;9
                          dc.b               '                                        '    ;0
                          dc.b               '                PASSWORD                '    ;1
                          dc.b               '                                        '    ;2
PASSWORDLINE:
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;4
                          dc.b               '                                        '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1

ONEPLAYERMENU_OPTS:
                          dc.w               16,13,8,1
                          dc.w               15,15,10,1
                          dc.w               12,17,16,1
                          dc.w               14,19,12,1
                          dc.w               12,23,16,1
                          dc.w               -1

*********************************************************************************************

MASTERPLAYERMENU_TXT:
;                                             0123456789012345678901234567890123456789
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1
                          dc.b               '                                        '    ;2
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;4
                          dc.b               '                                        '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1
CURRENTMPMODELINE:        dc.b               '            2 PLAYER  MASTER            '    ;2
                          dc.b               '                                        '    ;3
CURRENTLEVELLINEM:        dc.b               '           LEVEL 1 : THE GATE           '    ;4 
                          dc.b               '                                        '    ;5
                          dc.b               '               PLAY  GAME               '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '            CONTROL  OPTIONS            '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1
                          dc.b               '                                        '    ;2
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;4
                          dc.b               '                                        '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1
                          even
                     
MPMODE_OPTS:            
;                                             0123456789012345678901234567890123456789
                          dc.b               '            2 PLAYER  MASTER            '    ;2
                          dc.b               '        2 PLAYER  MASTER (CO-OP)        '    ;2
                          even

MPMODE_HIGHLIGHT_OPTS:
                          dc.w               12,12,16,1
                          dc.w               8,12,24,1

MASTERPLAYERMENU_OPTS:
                          dc.w               12,12,16,1
                          dc.w               6,14,28,1
                          dc.w               15,16,10,1
                          dc.w               12,18,16,1
                          dc.w               -1

*********************************************************************************************

SLAVEPLAYERMENU_TXT:
;                                             0123456789012345678901234567890123456789
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1
                          dc.b               '                                        '    ;2
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;4
                          dc.b               '                                        '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;1
                          dc.b               '             2 PLAYER SLAVE             '    ;4
                          dc.b               '                                        '    ;3
                          dc.b               '               PLAY  GAME               '    ;2
                          dc.b               '                                        '    ;5
                          dc.b               '            CONTROL  OPTIONS            '    ;0
                          dc.b               '                                        '    ;1
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;4
                          dc.b               '                                        '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;9

*********************************************************************************************

SLAVEPLAYERMENU_OPTS:
                          dc.w               13,12,14,1
                          dc.w               15,14,10,1
                          dc.w               12,16,16,1
                          dc.w               -1

*********************************************************************************************

PLAYER_OPTS:
;                                             0123456789012345678901234567890123456789
                          dc.b               '                 1 PLAYER               '
                          dc.b               '             2  PLAYER MASTER           '
                          dc.b               '              2 PLAYER SLAVE            '
 
LEVEL_OPTS:
;                                             0123456789012345678901234567890123456789
                          dc.b               '      LEVEL  1 :          THE GATE      '
                          dc.b               '      LEVEL  2 :       STORAGE BAY      '
                          dc.b               '      LEVEL  3 :     SEWER NETWORK      '
                          dc.b               '      LEVEL  4 :     THE COURTYARD      '
                          dc.b               '      LEVEL  5 :      SYSTEM PURGE      '
                          dc.b               '      LEVEL  6 :         THE MINES      '
                          dc.b               '      LEVEL  7 :       THE FURNACE      '
                          dc.b               '      LEVEL  8 :  TEST ARENA GAMMA      '
                          dc.b               '      LEVEL  9 :      SURFACE ZONE      '
                          dc.b               '      LEVEL 10 :     TRAINING AREA      '
                          dc.b               '      LEVEL 11 :       ADMIN BLOCK      '
                          dc.b               '      LEVEL 12 :           THE PIT      '
                          dc.b               '      LEVEL 13 :            STRATA      '
                          dc.b               '      LEVEL 14 :      REACTOR CORE      '
                          dc.b               '      LEVEL 15 :     COOLING TOWER      '
                          dc.b               '      LEVEL 16 :    COMMAND CENTRE      '

CONTROL_TXT:
;                                             0123456789012345678901234567890123456789
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1
                          dc.b               '                                        '    ;2
                          dc.b               '                                        '    ;3
                          dc.b               '            DEFINE  CONTROLS            '    ;4
                          dc.b               '                                        '    ;5
KEY_LINES:
                          dc.b               '     TURN LEFT                  LCK     '    ;6
                          dc.b               '     TURN RIGHT                 RCK     '    ;7
                          dc.b               '     FORWARDS                   UCK     '    ;8
                          dc.b               '     BACKWARDS                  DCK     '    ;9
                          dc.b               '     FIRE                       RAL     '    ;0
                          dc.b               '     OPERATE DOOR/LIFT/SWITCH   SPC     '    ;1
                          dc.b               '     RUN                        RSH     '    ;2
                          dc.b               '     FORCE SIDESTEP             RAM     '    ;3
                          dc.b               '     SIDESTEP LEFT               .      '    ;4
                          dc.b               '     SIDESTEP RIGHT              /      '    ;5
                          dc.b               '     DUCK                        D      '    ;6
                          dc.b               '     LOOK BEHIND                 L      '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '             OTHER CONTROLS             '    ;9
                          dc.b               '                                        '    ;0
                          dc.b               ' PULSE RIFLE      1  PAUSE            P '    ;1
                          dc.b               ' SHOTGUN          2  QUIT           ESC '    ;2
                          dc.b               ' PLASMA GUN       3  MOUSE CONTROL    M '    ;3
                          dc.b               ' GRENADE LAUNCHER 4  JOYSTICK CONTROL J '    ;4
                          dc.b               ' ROCKET LAUNCHER  5  KEYBOARD CONTROL K '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '               MAIN  MENU               '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1

CONTROL_OPTS:
                          dc.w               5,6,30,1
                          dc.w               5,7,30,1
                          dc.w               5,8,30,1
                          dc.w               5,9,30,1
                          dc.w               5,10,30,1
                          dc.w               5,11,30,1
                          dc.w               5,12,30,1
                          dc.w               5,13,30,1
                          dc.w               5,14,30,1
                          dc.w               5,15,30,1
                          dc.w               5,16,30,1
                          dc.w               5,17,30,1
                          dc.w               15,27,10,1
                          dc.w               -1

*********************************************************************************************

INSTRUCTIONS_TXT:
;                                             0123456789012345678901234567890123456789
                          dc.b               'Main controls:                          '    ;1
                          dc.b               '                                        '    ;2
                          dc.b               'Curs Keys = Forward / Backward          '    ;3
                          dc.b               '            Turn left / right           '    ;4
                          dc.b               '          Right Alt = Fire              '    ;5
                          dc.b               '        Right Shift = Run               '    ;6
                          dc.b               '                  > = Slide Left        '    ;7
                          dc.b               '                  ? = Slide Right       '    ;8
                          dc.b               '              SPACE = Operate Door/Lift '    ;9
                          dc.b               '                  D = Duck              '    ;0
                          dc.b               '                  J = Joystick Control  '    ;1
                          dc.b               '                  K = Keyboard Control  '    ;2
                          dc.b               '                                        '    ;3
                          dc.b               '              1,2,3 = Select weapon     '    ;4
                          dc.b               '              ENTER = Toggle screen size'    ;5
                          dc.b               '                ESC = Quit              '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               'The one player game has no objective and'    ;9
                          dc.b               'the only way to finish is to die or quit'    ;0
                          dc.b               '                                        '    ;1
                          dc.b               'The two-player game is supposed to be a '    ;2
                          dc.b               'fight to the death but will probably be '    ;3
                          dc.b               'a fight-till-we-find-the-rocket-launcher'    ;4
                          dc.b               'then-blow-ourselves-up type game.       '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               'LOOK OUT FOR TELEPORTERS: They usually  '    ;7
                          dc.b               'have glowing red walls and overhead     '    ;8
                          dc.b               'lights. Useful for getting behind your  '    ;9
                          dc.b               ' opponent!                              '    ;0
                          dc.b               '  Just a taster of what is to come....  '    ;1
                          dc.b               '                                        '    ;0

INSTRUCTIONS_OPTS:
                          dc.w               0,0,0,1
                          dc.w               -1

*********************************************************************************************

CREDITMENU_TXT:
;                                             0123456789012345678901234567890123456789
                          dc.b               '    Programming, Game Code, Graphics    '    ;0
                          dc.b               '         Game Design and Manual         '    ;1
                          dc.b               '            Andrew Clitheroe            '    ;2
                          dc.b               '                                        '    ;3
                          dc.b               '             Alien Graphics             '    ;4
                          dc.b               '             Michael  Green             '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '           3D Object Designer           '    ;7
                          dc.b               '            Charles Blessing            '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '              Level Design              '    ;0
                          dc.b               'Michael Green  Ben Chanter   Jackie Lang'    ;1
                          dc.b               '     Kai Barrett Charles Blessing       '    ;2
                          dc.b               '                                        '    ;3
                          dc.b               '           Creative  Director           '    ;4
                          dc.b               '              Martyn Brown              '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '       Project Manager and Manual       '    ;7
                          dc.b               "            Martin O'Donnell            "    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '              Music + SFX               '    ;0
                          dc.b               '              Bjorn Lynne               '    ;1
                          dc.b               '                                        '    ;2
                          dc.b               '      Cover Illustration and Logo       '    ;3
                          dc.b               '             Kevin Jenkins              '    ;4
                          dc.b               '                                        '    ;5
                          dc.b               '      Packaging and Manual Design       '    ;6
                          dc.b               '               Paul Sharp               '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '             QA and Playtest            '    ;9
                          dc.b               '           Phil and The Wolves          '    ;0
                          dc.b               '                                        '    ;1
 
CREDITMENUPART2_TXT:
;                                             0123456789012345678901234567890123456789
                          dc.b               '    Serial Link and 3D Object Editor:   '    ;4
                          dc.b               '                   by                   '    ;5
                          dc.b               '            Charles Blessing            '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '                Graphics:               '    ;8
                          dc.b               '                   by                   '    ;9
                          dc.b               '              Mike  Oakley              '    ;0
                          dc.b               '                                        '    ;1
                          dc.b               '             Title  Picture             '    ;2
                          dc.b               '                   by                   '    ;3
                          dc.b               '               Mike Green               '    ;4
                          dc.b               '                                        '    ;5
                          dc.b               ' Inspiration, incentive, moral support, '    ;6
                          dc.b               '     level design and plenty of tea     '    ;7
                          dc.b               '         generously supplied by         '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '              Jackie  Lang              '    ;0
                          dc.b               '                                        '    ;1
                          dc.b               '    Music for the last demo composed    '    ;2
                          dc.b               '       by the inexpressibly evil:       '    ;3
                          dc.b               '                                        '    ;8
                          dc.b               '            *BAD* BEN CHANTER           '    ;9
                          dc.b               '                                        '    ;0
                          dc.b               '    Sadly no room for music this time   '    ;1
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;8                     
                          dc.b               '               v'
                          dc.l               AB3DVERSION
                          dc.b               '-'
                          dc.l               AB3DLABEL
                          dc.b               '               '                             ;9

CREDITMENU_OPTS:
                          dc.w               0,0,1,1
                          dc.w               -1

*********************************************************************************************

;                                             0123456789012345678901234567890123456789
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1
                          dc.b               '                                        '    ;2
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;4
                          dc.b               '                                        '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1
                          dc.b               '                                        '    ;2
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;4
                          dc.b               '                                        '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1
                          dc.b               '                                        '    ;2
                          dc.b               '                                        '    ;3
                          dc.b               '                                        '    ;4
                          dc.b               '                                        '    ;5
                          dc.b               '                                        '    ;6
                          dc.b               '                                        '    ;7
                          dc.b               '                                        '    ;8
                          dc.b               '                                        '    ;9
                          dc.b               '                                        '    ;0
                          dc.b               '                                        '    ;1
                          even
                 
*********************************************************************************************
 
PUTIN32:

                          move.w             #31,d2
p32loop:
                          moveq              #0,d5
                          move.l             (a0)+,d3
                          move.w             d3,d4
                          swap               d3
                          move.b             d4,d5
                          lsr.w              #8,d4

                          muls               d0,d3
                          muls               d0,d4
                          muls               d0,d5
                          lsr.l              #8,d3
                          lsr.l              #8,d4
                          lsr.l              #8,d5
                          move.w             d3,d6
                          swap               d3
                          move.w             d6,d3
                          move.w             d4,d6
                          swap               d4
                          move.w             d6,d4
                          move.w             d5,d6
                          swap               d5
                          move.w             d6,d5
                          and.w              #%11110000,d3
                          and.w              #%11110000,d4
                          and.w              #%11110000,d5
                          lsl.w              #4,d3
                          add.w              d4,d3
                          lsr.w              #4,d5
                          add.w              d5,d3
                          move.w             d3,2(a1)
                          swap               d3
                          swap               d4
                          swap               d5
                          and.w              #%1111,d3
                          and.w              #%1111,d4
                          and.w              #%1111,d5
                          lsl.w              #8,d3
                          lsl.w              #4,d4
                          add.w              d4,d3
                          add.w              d5,d3
                          move.w             d3,2+(132*4)(a1)
                          addq               #4,a1
                          dbra               d2,p32loop

                          rts

*********************************************************************************************

FADEAMOUNT:               dc.w               0
FADEVAL:                  dc.w               0

*********************************************************************************************

FadeUpTitle:

                          move.w             FADEVAL,d0
                          move.w             FADEAMOUNT,d1
fadeuploop:

                          lea                TITLEPAL,a0
                          lea                TITLEPALCOP,a1

                          lea                $dff000,a6
                          WAITFORVERTBREQ

                          bsr                PUTIN32
                          add.w              #4,a1
                          bsr                PUTIN32
                          add.w              #4,a1
                          bsr                PUTIN32
                          add.w              #4,a1
                          bsr                PUTIN32

                          addq.w             #4,d0
                          dbra               d1,fadeuploop

                          subq               #4,d0
                          move.w             d0,FADEVAL

                          rts

*********************************************************************************************

ClearTitlePalette:

                          lea                TITLEPALCOP,a0
                          move.w             #7,d1
clrpal:
                          move.w             #31,d0
clr32
                          move.w             #0,2(a0)
                          addq               #4,a0
                          dbra               d0,clr32
                          addq               #4,a0
                          dbra               d1,clrpal

                          rts

*********************************************************************************************

FadeDownTitle:

                          move.w             FADEVAL,d0
                          move.w             FADEAMOUNT,d1
fadedownloop:

                          lea                TITLEPAL,a0
                          lea                TITLEPALCOP,a1

                          lea                $dff000,a6
                          WAITFORVERTBREQ

                          bsr                PUTIN32
                          add.w              #4,a1
                          bsr                PUTIN32
                          add.w              #4,a1
                          bsr                PUTIN32
                          add.w              #4,a1
                          bsr                PUTIN32

                          subq.w             #4,d0
                          dbra               d1,fadedownloop

                          addq               #4,d0
                          move.w             d0,FADEVAL

                          rts

*********************************************************************************************

AllocTitleMemory:

                          move.l             #MEMF_FAST|MEMF_CLEAR,d1
                          move.l             #TitleScrAddrSize,d0
                          move.l             4.w,a6
                          jsr                _LVOAllocMem(a6)
                          move.l             d0,TITLESCRNADDR
 
                          move.l             #MEMF_FAST|MEMF_CLEAR,d1
                          move.l             #OptSprAddrSize,d0
                          move.l             4.w,a6
                          jsr                _LVOAllocMem(a6)
                          move.l             d0,OPTSPRADDR
 
                          rts
 
*********************************************************************************************

ReleaseTitleMemory:

                          move.l             TITLESCRNADDR,d1
                          beq                SkipTitleScr

                          move.l             d1,a1
                          move.l             #TitleScrAddrSize,d0
                          move.l             4.w,a6
                          jsr                _LVOFreeMem(a6)
                          move.l             #0,TITLESCRNADDR

SkipTitleScr:
                          move.l             OPTSPRADDR,d1
                          beq                SkipOptScr

                          move.l             d1,a1
                          move.l             #OptSprAddrSize,d0
                          move.l             4.w,a6
                          jsr                _LVOFreeMem(a6)
                          move.l             #0,OPTSPRADDR

SkipOptScr:
                          rts
 
*********************************************************************************************

LoadTitleScrn2:
 
                          move.l             #TITLESCRNNAME2,d1
                          move.l             #1005,d2
                          move.l             doslib,a6
                          jsr                _LVOOpen(a6)
                          move.l             d0,fileHandle
                          beq                ScrName2FileNotFound

                          move.l             d0,d1
                          move.l             doslib,a6
                          move.l             TITLESCRNADDR,d2
                          move.l             #TitleScrAddrSize,d3
                          jsr                _LVORead(a6)

                          move.l             doslib,a6
                          move.l             fileHandle,d1
                          jsr                _LVOClose(a6)

ScrName2FileNotFound:
                          rts

*********************************************************************************************

LoadTitleScrn:
 
                          move.l             #TITLESCRNNAME,d1
                          move.l             #1005,d2
                          move.l             doslib,a6
                          jsr                _LVOOpen(a6)
                          move.l             d0,fileHandle
                          beq                ScrNamefileNotFound

                          move.l             d0,d1
                          move.l             doslib,a6
                          move.l             TITLESCRNADDR,d2
                          move.l             #TitleScrAddrSize,d3
                          jsr                _LVORead(a6)

                          move.l             doslib,a6
                          move.l             fileHandle,d1
                          jsr                _LVOClose(a6)

ScrNamefileNotFound:
                          rts

*********************************************************************************************

SetupTitleScrn:
                          move.l             #OPTCOP,a0
                          move.l             #rain,a1
                          move.w             #255,d0

putinrain:
                          move.w             (a1)+,d1
                          move.w             d1,6(a0)
                          move.w             d1,6+4(a0)
                          move.w             d1,6+8(a0)
                          move.w             d1,6+12(a0)
                          add.w              #4*14,a0

                          dbra               d0,putinrain

*****************************************************************
; Sprites for menu 
; There is 5 sprites side by side and the text is divided horizontallya with them.

                          move.l             OPTSPRADDR,d0                                 ; Put addr into copper.
                          move.w             d0,tsp0l
                          swap               d0
                          move.w             d0,tsp0h
                          swap               d0
                          add.l              #258*16,d0
                          move.w             d0,tsp1l
                          swap               d0
                          move.w             d0,tsp1h
                          swap               d0
                          add.l              #258*16,d0
                          move.w             d0,tsp2l
                          swap               d0
                          move.w             d0,tsp2h
                          swap               d0
                          add.l              #258*16,d0
                          move.w             d0,tsp3l
                          swap               d0
                          move.w             d0,tsp3h
                          swap               d0
                          add.l              #258*16,d0
                          move.w             d0,tsp4l
                          swap               d0
                          move.w             d0,tsp4h
 
 *****************************************************************

                          move.l             #nullSpr,d0
                          move.w             d0,tsp5l
                          move.w             d0,tsp6l
                          move.w             d0,tsp7l
                          swap               d0
                          move.w             d0,tsp5h
                          move.w             d0,tsp6h
                          move.w             d0,tsp7h 

*****************************************************************

                          move.l             TITLESCRNADDR,d0
                          move.w             d0,ts1l
                          swap               d0
                          move.w             d0,ts1h
                          swap               d0
                          add.l              #10240,d0
                          move.w             d0,ts2l
                          swap               d0
                          move.w             d0,ts2h
                          swap               d0
                          add.l              #10240,d0
                          move.w             d0,ts3l
                          swap               d0
                          move.w             d0,ts3h
                          swap               d0
                          add.l              #10240,d0
                          move.w             d0,ts4l
                          swap               d0
                          move.w             d0,ts4h
                          swap               d0
                          add.l              #10240,d0
                          move.w             d0,ts5l
                          swap               d0
                          move.w             d0,ts5h
                          swap               d0
                          add.l              #10240,d0
                          move.w             d0,ts6l
                          swap               d0
                          move.w             d0,ts6h
                          swap               d0
                          add.l              #10240,d0
                          move.w             d0,ts7l
                          swap               d0
                          move.w             d0,ts7h
                          rts 

*********************************************************************************************

                          include            "LevelBlurb.s"
                          even

*********************************************************************************************

font:                     incbin             "data/fonts/OptFont"
                          even

rain:                     incbin             "data/copper/optcop"
                          even

*********************************************************************************************
; MED-Player

                          IFNE               ENABLETITLEMUSIC
                          include            "ProPlayer.s"
                          even
                     
                          include            "LoadMod.s"
                          even
                          ENDC

*********************************************************************************************
; 17*16 'OAMMBGELDHMNFFFF',0
; LF = 10 (Unix)
; CR = 13

PasswordStorage:          dc.b               "KLLKFFFFNFFNFFFF "                           ; 1
                          dc.b               "                 "                           ; 2
                          dc.b               "                 "                           ; 3
                          dc.b               "                 "                           ; 4
                          dc.b               "                 "                           ; 5
                          dc.b               "                 "                           ; 6
                          dc.b               "                 "                           ; 7
                          dc.b               "                 "                           ; 8
                          dc.b               "                 "                           ; 9
                          dc.b               "                 "                           ; 10
                          dc.b               "                 "                           ; 11
                          dc.b               "                 "                           ; 12
                          dc.b               "                 "                           ; 13
                          dc.b               "                 "                           ; 14
                          dc.b               "                 "                           ; 15
                          dc.b               "                 "                           ; 16
                          cnop               0,32

PasswordIndex:            dc.l               1

*********************************************************************************************