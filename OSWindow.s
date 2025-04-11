*********************************************************************************************

                          opt         P=68020

*********************************************************************************************
; Picasso 96 RTG PiP
RTGCanvasWidth     EQU 640
RTGCanvasHeight    EQU 256
RTGCanvasDepth     EQU 16

RTGWinWidth  EQU (RTGCanvasWidth/3)*4
RTGWinHeight EQU (RTGCanvasHeight/3)*4

*********************************************************************************************

OpenP96RTGWindow:
; Open pip window

                          STOREREGS

                          move.l      IntuiBase,d0
                          beq         .leaveWindow
                          move.l      d0,a6
                          
                          move.l      #0,a0
                          jsr         _LVOLockPubScreen(a6)
                          tst         d0
                          beq         .leaveWindow

                          move.l      d0,pipPublicScreen
                          move.l      d0,a1
                          
                          moveq       #0,d1
                          move.l      #RTGWinWidth,d2    
                          move.l      d2,pipWidth
                          move.w      sc_Width(a1),d1
                          sub.w       d2,d1
                          asr.w       #1,d1
                          move.l      d1,pipLeft    

                          moveq       #0,d1
                          move.l      #RTGWinHeight,d2    
                          move.l      d2,pipHeight
                          move.w      sc_Height(a1),d1
                          sub.w       d2,d1
                          asr.w       #1,d1
                          move.l      d1,pipTop    

                          move.l      #0,a0
                          jsr         _LVOUnlockPubScreen(a6)
                          tst         d0

                          move.l      P96Base,d0
                          beq         .leaveWindow
                          move.l      d0,a6
                                      
                          lea         PipTags(pc),a0
                          jsr         _LVOp96PIP_OpenTagList(a6)
                          move.l      d0,PipBase
                          beq         .leaveWindow

*********************************************************************
                            
                          move.l      d0,a0
                          lea         PipTagItems,a1
                          jsr         _LVOp96PIP_GetTagList(a6)
                          tst.l       d0
                          beq         .leaveWindow

*********************************************************************

                          move.l      PipBase,a0
                          move.l      wd_UserPort(a0),PipPort  

*********************************************************************

                          move.l       #0,d0  
                          RESTOREREGS
                          rts

*********************************************************************

.leaveWindow:                 
                          jsr         CloseP96RTGWindow

                          move.l       #-1,d0                              
                          RESTOREREGS
                          rts

*********************************************************************************************
*********************************************************************************************

CloseP96RTGWindow:
; OS - Close RTG window

                          SAVEREGS

                          move.l      P96Base,d0
                          beq         .leaveClose
                          move.l      d0,a6

                          move.l      PipBase,d0
                          beq.s       .leaveClose

                          move.l      d0,a0
                          jsr         _LVOp96PIP_Close(a6)
                          clr.l       PipBase

.leaveClose:
                          GETREGS
                          rts

*********************************************************************************************
*********************************************************************************************

GetP96RTGWindowMouseXY:
; d0.l MouseY - relative top top-left corner
; d1.l MouseX - relative top top-left corner

                          movem.l     d2-d7/a0-a6,-(a7)

                          clr.l       d0
                          clr.l       d1

                          move.l      PipBase,d2
                          beq         .leaveMouse
                          move.l      d2,a0

                          move.w      wd_MouseX(a0),d0
                          move.w      wd_MouseY(a0),d1

.leaveMouse:
                          movem.l     (a7)+,d2-d7/a0-a6
                          rts

*********************************************************************************************   
*********************************************************************************************   

ClearP96RTGWindowPointer:

                          SAVEREGS

                          move.l      PipBase,d0
                          beq         .leavePointer
                          move.l      d0,a0

                          lea         nullPointer,a1
                          move.l      #1,d0  
                          move.l      #1,d1
                          move.l      #0,d2
                          move.l      #0,d3
                          move.l      IntuiBase,a6
                          jsr         _LVOSetPointer(a6)

.leavePointer:
                          GETREGS
                          rts

*********************************************************************************************
*********************************************************************************************   

ResetP96RTGWindowPointer:

                          SAVEREGS

                          move.l      PipBase,d0
                          beq         .leaveClear
                          move.l      d0,a0

                          move.l      IntuiBase,a6
                          jsr         _LVOClearPointer(a6)   

.leaveClear:                        
                          GETREGS
                          rts

*********************************************************************************************
*********************************************************************************************

ScrRP:                    dc.l        0

*********************************************************************************************
*********************************************************************************************

PipTagItems:
                          dc.l        P96PIP_SourceRPort
                          dc.l        ScrRP
                          dc.l        TAG_END,TAG_END                             

*********************************************************************************************

PipTags:
                          dc.l        P96PIP_SourceFormat, RGBFB_R5G5B5                                    ; HiColor15 (5 bit each), format: 0rrrrrgggggbbbbb
                          dc.l        P96PIP_SourceWidth, RTGCanvasWidth
                          dc.l        P96PIP_SourceHeight, RTGCanvasHeight
                          dc.l        WA_Title, PipTitle
                          dc.l        WA_Width
pipWidth:                 dc.l        0
                          dc.l        WA_Height
pipHeight:                dc.l        0
                          dc.l        WA_Left
pipLeft:                  dc.l        0
                          dc.l        WA_Top
pipTop:                   dc.l        0
                          dc.l        WA_Activate, 1
                          dc.l        WA_RMBTrap, 1
                          dc.l        WA_DragBar, 1
                          dc.l        WA_DepthGadget, 1
                          dc.l        WA_SimpleRefresh, 1
                          dc.l        WA_SizeGadget, 1
                          dc.l        WA_CloseGadget, 0
                          dc.l        WA_IDCMP, IDCMP_INACTIVEWINDOW!IDCMP_ACTIVEWINDOW
                          dc.l        WA_GimmeZeroZero, 1
                          dc.l        WA_ReportMouse, 1
                          dc.l        WA_PubScreen
pipPublicScreen:          dc.l        0
                          dc.l        TAG_DONE,TAG_END                                

*********************************************************************************************

PipTitle:                 dc.b        "Alien Breed 3D I - P96 RTG - HiColor15 (16bit) PiP - Experiment - v"
                          dc.l        AB3DVERSION
                          dc.b        "-"
                          dc.l        AB3DLABEL
                          dc.b        0
                          even

*********************************************************************************************

PipPublicScreenName:      dc.b        "Workbench",0
                          even

*********************************************************************************************

PipBase:                  dc.l        0
PipPort:                  dc.l        0

*********************************************************************************************                   