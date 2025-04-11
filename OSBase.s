*********************************************************************************************

                          opt            P=68020

*********************************************************************************************

                          incdir         "includes"
                          include        "intuition/screens.i"
                          include        "intuition/intuitionbase.i"
                          include        "graphics/text.i"
                          include        "exec/types.i"
                          include        "exec/memory.i"
                          include        "devices/input.i"
                          include        "devices/inputevent.i"
                          include        "lvo/diskfont_lib.i"
                          include        "lvo/gadtools_lib.i"
                          include        "lvo/cia_lib.i"

                          include        "resources/misc.i"

                          incdir         "Picasso96Develop/include"
                          include        "lvo_p96.i"
                          include        "libraries/picasso96.i"

                          incdir         "includes"
                          include        "AB3DI.i"
                          include        "AB3DIRTG.i"
                          include        "macros.i"
                          include        "OSP96rtg.i"

*********************************************************************************************
*********************************************************************************************

WLOG                      MACRO
                          move.l         \1,logText
                          jsr            WriteLog
                          ENDM

*********************************************************************************************
*********************************************************************************************

InitOSBase: 
                          STOREREGS

                          move.l         4.w,a6
                          lea            P96LibName,a1
                          moveq          #0,d0
                          jsr            _LVOOpenLibrary(a6)
                          move.l         d0,P96Base

                          move.l         4.w,a6
                          lea            IntuiLibName,a1
                          moveq          #0,d0
                          jsr            _LVOOpenLibrary(a6)
                          move.l         d0,IntuiBase

                          move.l         4.w,a6
                          lea            GTLibName,a1
                          moveq          #0,d0
                          jsr            _LVOOpenLibrary(a6)
                          move.l         d0,GTBase
  
                          move.l         4.w,a6
                          lea            GraphicsLibName,a1
                          moveq          #0,d0
                          jsr            _LVOOpenLibrary(a6)
                          move.l         d0,GraphicsBase

                          move.l         4.w,a6
                          lea            DiskfontLibName,a1
                          moveq          #0,d0
                          jsr            _LVOOpenLibrary(a6)
                          move.l         d0,DiskfontBase

                          move.l         4.w,a6
                          lea            LocaleLibName,a1
                          moveq          #0,d0
                          jsr            _LVOOpenLibrary(a6)
                          move.l         d0,LocaleBase

                          move.l         4.w,a6
                          lea            DosLibName,a1
                          moveq          #0,d0
                          jsr            _LVOOpenLibrary(a6)
                          move.l         d0,DosBase

                          RESTOREREGS
                          rts

*********************************************************************************************
*********************************************************************************************

CleanupOSBase:
                          STOREREGS

                          move.l         IntuiBase,a1
                          tst.l          a1
                          beq.b          .SkipIntui

                          move.l         4.w,a6
                          jsr            _LVOCloseLibrary(a6)

.SkipIntui:
                          move.l         GraphicsBase,a1
                          tst.l          a1
                          beq.b          .SkipGraphics

                          move.l         4.w,a6
                          jsr            _LVOCloseLibrary(a6)

.SkipGraphics:
                          move.l         P96Base,a1
                          tst.l          a1
                          beq.b          .SkipP96

                          move.l         4.w,a6
                          jsr            _LVOCloseLibrary(a6)

.SkipP96:

                          move.l         GTBase,a1
                          tst.l          a1
                          beq.b          .skipGT

                          move.l         4.w,a6
                          jsr            _LVOCloseLibrary(a6)

.skipGT:
                          move.l         DiskfontBase,a1
                          tst.l          a1
                          beq.b          .skipDF

                          move.l         4.w,a6
                          jsr            _LVOCloseLibrary(a6)

.skipDF:
                          move.l         LocaleBase,a1
                          tst.l          a1
                          beq.b          .skipL

                          move.l         4.w,a6
                          jsr            _LVOCloseLibrary(a6)

.skipL:
                          move.l         DosBase,a1
                          tst.l          a1
                          beq.b          .skipD

                          move.l         4.w,a6
                          jsr            _LVOCloseLibrary(a6)

.skipD:
                          RESTOREREGS
                          rts

*********************************************************************************************
*********************************************************************************************

P96LibName:               dc.b           'Picasso96API.library',0
                          cnop           0,32

P96Base:                  dc.l           0

*********************************************************************

IntuiLibName:             dc.b           'intuition.library',0
                          cnop           0,32

IntuiBase:                dc.l           0

*********************************************************************

GraphicsLibName:          dc.b           'graphics.library',0
                          cnop           0,32

GraphicsBase:             dc.l           0

*********************************************************************

GTLibName:                dc.b           'gadtools.library',0
                          cnop           0,32

GTBase:                   dc.l           0

*********************************************************************************************

DiskfontLibName:          dc.b           'diskfont.library',0
                          cnop           0,32

DiskfontBase:             dc.l           0

*********************************************************************************************

LocaleLibName:            dc.b           'locale.library',0
                          cnop           0,32

LocaleBase:               dc.l           0

*********************************************************************************************

DosLibName:               dc.b           'dos.library',0
                          cnop           0,32

DosBase:                  dc.l           0

*********************************************************************************************
*********************************************************************************************

WriteMemToFile:
; memBegin = ptr
; memLength = length

                          SAVEREGS

                          tst.l          DosBase
                          beq            skipDump

                          move.l         #memFileName,d1
                          move.l         #MODE_NEWFILE,d2
v                         move.l         DosBase,a6
                          jsr            _LVOOpen(a6)
                          move.l         d0,memFileHandle

                          move.l         memFileHandle,d1
                          move.l         memBegin,d2
                          move.l         memLength,d3
                          move.l         DosBase,a6
                          jsr            _LVOWrite(a6)

                          move.l         memFileHandle,d1
                          move.l         DosBase,a6
                          jsr            _LVOClose(a6)
                          move.l         #0,memFileHandle  

skipDump:
                          GETREGS
                          rts

*********************************************************************************************

memFileHandle:            dc.l           0
memFileName:              dc.b           "dump.raw",0
                          even

*********************************************************************************************

memBegin:                 dc.l           0
memLength:                dc.l           0

*********************************************************************************************
*********************************************************************************************

Convert12BitColorAndWriteToDisk:
; a0 = source
; d0 = length
                           SAVEREGS

                           move.l a0,memBegin
                           move.l d0,memLength

                           move.l a0,a1
                           add.l  d0,a1   

convert12bitLoop:
                           move.w (a0),d2
                           C12BITTOHICOL
                           move.w d2,(a0)+

                           cmp.l a1,a0
                           bne   convert12bitLoop

                           jsr    WriteMemToFile

                           GETREGS
                           rts

*********************************************************************************************
*********************************************************************************************

OpenConsole:
                          SAVEREGS

                          move.l         #conFileName,d1
                          move.l         #MODE_NEWFILE,d2
                          move.l         DosBase,a6
                          jsr            _LVOOpen(a6)
                          move.l         d0,conFileHanlde

                          GETREGS
                          rts

*********************************************************************************************

CloseConsole:
                          SAVEREGS

                          move.l         conFileHanlde,d1
                          move.l         DosBase,a6
                          jsr            _LVOClose(a6)
                          move.l         #0,conFileHanlde  

                          GETREGS
                          rts

*****************************************************************************
*****************************************************************************

DBUGPRINT                 MACRO
; DBUGPRINT "2","Plr1Zone: %lx",l,#10

                          movem.l        d0-d7/a0-a6,-(a7)
                          lea            .\@text,a0
                          lea            .\@data,a1
                          move.\3        \4,(a1)    
                          jsr            WriteToConsole
                          bra            .\@exit

.\@text:                  dc.b           $1B,$9B,\1,$3B,"1H",\2,10,0
                          even      
.\@data:                  dc.l           0

.\@exit:                   
                          movem.l        (a7)+,d0-d7/a0-a6
                                                    
                          ENDM

*********************************************************************************************

WriteToConsole:
; a0 = inputText
; a1 = data
; ----------------------
; conIntTxt, conIntDat.l : long as hex

                          SAVEREGS 
                       
                          lea            conStuffChar,a2
                          lea            contFmtOutput,a3                                    ;Get the output string pointer
                          move.l         $4,a6
                          jsr            _LVORawDoFmt(a6)

                          move.l         conFileHanlde,d1
                          move.l         #contFmtOutput,d2
                          move.l         #conEndOfLayout-conLayoutTxt,d3
                          move.l         DosBase,a6
                          jsr            _LVOWrite(a6)
                          
                          GETREGS
                          rts

*********************************************************************************************

conStuffChar:
                          move.b         d0,(a3)+                                            ;Put data to output string
                          rts

*********************************************************************************************

contFmtOutput:            dcb.b          512,0

*********************************************************************************************
; Print layout

conLayoutTxt: 
                          dc.b           $1B,$9B,"1",$3B,"1H","PLR1_xoff: %x     "
                          dc.b           $1B,$9B,"1",$3B,"23H","PLR1_key: %x     "

                          dc.b           $1B,$9B,"2",$3B,"1H","PLR1_yoff: %x     "
                          dc.b           $1B,$9B,"2",$3B,"23H","PLR1_Mouse0X: %x     "
                          
                          dc.b           $1B,$9B,"3",$3B,"1H","PLR1_zoff: %x     "
                          dc.b           $1B,$9B,"3",$3B,"23H","PLR1_Mouse0Y: %x     "

                          dc.b           $1B,$9B,"4",$3B,"1H","PLR1_angspd: %x     "
                          dc.b           $1B,$9B,"4",$3B,"23H","PLR1_angpos: %x     "

                          dc.b           $1B,$9B,"5",$3B,"1H","PLR1_GunSelected: %x     "
                          dc.b           $1B,$9B,"5",$3B,"23H","PLR1_Zone: %x     "

                          dc.b           $1B,$9B,"7",$3B,"1H","DebugDec1: %ld     "
                          dc.b           $1B,$9B,"7",$3B,"23H","DebugHex1: %lx     "

                          dc.b           $1B,$9B,"8",$3B,"1H","DebugDec2: %ld     "
                          dc.b           $1B,$9B,"8",$3B,"23H","DebugHex2: %lx     "

                          dc.b           $1B,$9B,"9",$3B,"1H"
conEndOfLayout:           dc.b           0
                          cnop           0,32  

conLayoutData:            
                          dc.w           0                                                   ; PLR1_xoff
                          dc.w           0                                                   ; PLR1_key
                          dc.w           0                                                   ; PLR1_yoff
                          dc.w           0                                                   ; PLR1_Mouse0X
                          dc.w           0                                                   ; PLR1_zoff 
                          dc.w           0                                                   ; PLR1_Mouse0Y 
                          dc.w           0                                                   ; PLR1_angspd
                          dc.w           0                                                   ; PLR1_angpos
                          dc.w           0                                                   ; PLR1_GunSelected
                          dc.w           0                                                   ; PLR1_Zone 

conDebugDec1:             dc.l           0 
conDebugHex1:             dc.l           0 

conDebugDec2:             dc.l           0 
conDebugHex2:             dc.l           0 

*********************************************************************************************

conFileHanlde:            dc.l           0

conFileName:              dc.b           "CON:16/16/400/200/Debug",0
                          cnop           0,32

*********************************************************************************************
*********************************************************************************************

