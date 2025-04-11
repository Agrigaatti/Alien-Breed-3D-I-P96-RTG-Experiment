*********************************************************************************************

                          opt              P=68020

*********************************************************************************************

                          incdir           "includes"
                          include          "macros.i"
                          include          "AB3DI.i"
                          include          "AB3DIRTG.i"

*********************************************************************************************
; AB3d

AB3dWidth         EQU scrWidth
AB3dHeight        EQU scrHeight

AB3dOffsetX       EQU (RTGCanvasWidth-AB3dWidth)/2
AB3dOffsetY       EQU (RTGCanvasHeight-AB3dHeight)/4

AB3dDblWidth      EQU AB3dWidth*2
AB3dDblHeight     EQU AB3dHeight*2
AB3dDblOffsetX    EQU (RTGCanvasWidth-(AB3dDblWidth))/2
AB3dDblOffsetY    EQU (0)

*********************************************************************************************
*********************************************************************************************

DirectDrawAB3DChunky:
; Draw rtg window directly from the copper chunky (fromPt)
; HiColor15 (5 bit each), format: 0rrrrrgggggbbbbb

                          SAVEREGS

                          move.l           #AB3dDblOffsetX,d0                           
                          move.l           #1,d1  
                          move.l           fromPt,a0

                          move.w           #2,d3                                           ; Copy repeat

DCpyRepeat1:
                          move.w           #31,d4

DCpyRepeat2:
                          move.w           #3,d5
                          move.l           a0,a1

DCpyRepeat3:

val                       SET              0
                          REPT             20
                          INLINE                     

                          move.w           val(a1),d2                                      ; color

                          C12BITTOHICOL

                          jsr              WriteAB3dChunkyPixel
                          movem.l          d0-d1,-(a7)
                          add.l            #1,d0
                          add.l            #1,d1
                          jsr              WriteAB3dChunkyPixel
                          movem.l          (a7)+,d0-d1

                          add.l            #2,d1
                          cmp.l            #(AB3dDblOffsetY+AB3dDblHeight)+1,d1
                          bne              .contDraw

                          move.l           #1,d1
                          add.l            #2,d0
                          
.contDraw:

                          EINLINE  
val                       SET              val+widthOffset
                          ENDR

                          adda.l           #widthOffset*20,a1
                          dbra             d5,DCpyRepeat3 

                          addq             #4,a0
                          dbra             d4,DCpyRepeat2 

                          addq             #4,a0
                          dbra             d3,DCpyRepeat1

                          GETREGS
                          rts

*********************************************************************************************

WriteAB3dChunkyPixel:
; d0 = x 
; d1 = y 
; d2 = 16bit chunky pixel

                          SAVEREGS

                          lea              AB3dChunkyRenderInfo,a0                         ; ri
                          lea              AB3dChunkyHiColor15Buffer,a1
                          move.w           d2,(a1)

                          move.l           a1,gri_Memory(a0)
                          move.w           #AB3dWidth*2,gri_BytesPerRow(a0)                ; Word
                          move.w           #0,gri_pad(a0)
                          move.l           #RGBFB_R5G5B5,gri_RGBFormat(a0)
                          
                          move.l           d0,d2                                           ; DestX
                          move.l           d1,d3                                           ; DestY

                          move.l           #0,d0                                           ; SrcX
                          move.l           #0,d1                                           ; SrcY
                          move.l           #1,d4                                           ; SizeX
                          move.l           #1,d5                                           ; SizeY

                          move.l           ScrRP,a1                                        ; rp
                          move.l           P96Base,a6
                          jsr              _LVOp96WritePixelArray(a6)
                            
                          GETREGS
                          rts

*********************************************************************************************
*********************************************************************************************

CopyAB3DChunkyToHiColorBuffer:
; Copy copper chunky to the color buffer 

                          SAVEREGS

                          move.l           fromPt,a0

                          lea              AB3dChunkyHiColor15Buffer,a2
                          move.l           a2,a3

                          move.l           #AB3dHeight,d4  

                          move.w           #2,d0

CpyRepeat1:
                          move.w           #31,d1

CpyRepeat2:
                          move.w           #3,d3
                          move.l           a0,a1

CpyRepeat3:

val                       SET              0
                          REPT             20
                          inline                     
                          move.w           val(a1),d2
                          move.w           #0,val(a1) 

                          C12BITTOHICOL                                             

                          move.w           d2,(a2)                                         ; 16bit value
                          move.w           d2,((AB3dDblWidth*2)+2)(a2)                     ; Double size

                          add.l            #(AB3dDblWidth*4),a2                            ; word

                          sub.l            #1,d4
                          bne              .CpySkipXStep
                          move.l           #AB3dHeight,d4

                          add.l            #4,a3                                           ; word
                          move.l           a3,a2

.CpySkipXStep:
                          einline  
val                       SET              val+widthOffset
                          ENDR

                          adda.l           #widthOffset*20,a1
                          dbra             d3,CpyRepeat3

                          addq             #4,a0
                          dbra             d1,CpyRepeat2

                          addq             #4,a0
                          dbra             d0,CpyRepeat1

                          GETREGS
                          rts

********************************************************************************************

DrawAB3dHiColorBuffer:
; Draw color buffer to rtg window.

                          SAVEREGS

                          lea              AB3dChunkyRenderInfo,a0                         ; ri
                          lea              AB3dChunkyHiColor15Buffer,a1
                          move.l           a1,gri_Memory(a0)
                          move.w           #AB3dDblWidth*2,gri_BytesPerRow(a0)             ; Word
                          move.w           #0,gri_pad(a0)
                          move.l           #RGBFB_R5G5B5,gri_RGBFormat(a0)

                          move.l           #1,d0                                           ; SrcX
                          move.l           #1,d1                                           ; SrcX
                          move.l           #AB3dDblOffsetX,d2                              ; DestX
                          move.l           #AB3dDblOffsetY,d3                              ; DestY
                          move.l           #AB3dDblWidth,d4                                ; SizeX
                          move.l           #AB3dDblHeight,d5                               ; SizeY

                          move.l           ScrRP,a1                                        ; rp
                          move.l           P96Base,a6
                          jsr              _LVOp96WritePixelArray(a6)
                            
                          GETREGS
                          RTS

*********************************************************************************************

ClearAB3dHiColorBuffer:

                          SAVEREGS

                          lea              AB3dChunkyHiColor15Buffer,a0
                          move.l           #((640*256*2)/4)-1,d0
.clearLoop
                          move.l           #0,(a0)+
                          dbra             d0,.clearLoop

                          GETREGS  
                          rts

*********************************************************************************************
*********************************************************************************************

ClearAB3dChunkyBuffer:

                          SAVEREGS

                          lea              AB3dChunkyBuffer,a0
                          move.l           #((320*256*2)/4)-1,d0
.clearLoop:
                          move.l           #0,(a0)+
                          dbra             d0,.clearLoop

                          GETREGS  
                          rts

*********************************************************************************************
*********************************************************************************************

DrawScaledAB3dChunkyBuffer:
; 96*80 -> 2x2 = 192*160

                          SAVEREGS

                          lea              AB3dChunkyBuffer,a0
                          lea              AB3dScaledChunkyBuffer,a1

                          move.l           #scrHeight-1,d0

.scaleYLoop
                          move.l           #scrWidth-1,d1

.scaleXloop:
                          ;move.w      (a1),d2
                          ;cmp.w       #0,d2
                          ;bne         .skipPixel         

                          move.w           (a0),(a1)
                          move.w           (a0),(scrWidth*4)+2(a1)

.skipPixel:

                          add.l            #2,a0
                          add.l            #4,a1

                          dbra             d1,.scaleXloop

                          add.l            #(scrWidth*4),a1

                          dbra             d0,.scaleYLoop

*******************************************************

                          lea              AB3dChunkyRenderInfo,a0                         ; ri
                          lea              AB3dScaledChunkyBuffer,a1
                          move.l           a1,gri_Memory(a0)
                          move.w           #AB3dWidth*2*2,gri_BytesPerRow(a0)                ; Word
                          move.w           #0,gri_pad(a0)
                          move.l           #RGBFB_R5G5B5,gri_RGBFormat(a0)

                          move.l           #1,d0                                           ; SrcX
                          move.l           #1,d1                                           ; SrcX
                          move.l           #(RTGCanvasWidth-AB3dWidth*2)/2,d2              ; DestX
                          move.l           #0,d3    ; DestY
                          move.l           #AB3dWidth*2,d4                                   ; SizeX
                          move.l           #AB3dHeight*2,d5                                  ; SizeY

                          move.l           ScrRP,a1                                        ; rp
                          move.l           P96Base,a6
                          jsr              _LVOp96WritePixelArray(a6)

                          GETREGS  
                          rts

*********************************************************************************************
*********************************************************************************************

DrawAB3dChunkyBuffer:
; Draw color buffer to rtg window.

                          SAVEREGS

                          lea              AB3dChunkyRenderInfo,a0                         ; ri
                          lea              AB3dChunkyBuffer,a1
                          move.l           a1,gri_Memory(a0)
                          move.w           #RTGScrWidthByteOffset,gri_BytesPerRow(a0)      ; Word
                          move.w           #0,gri_pad(a0)
                          move.l           #RGBFB_R5G5B5,gri_RGBFormat(a0)

                          move.l           #1,d0                                           ; SrcX
                          move.l           #1,d1                                           ; SrcY
                          move.l           #(RTGCanvasWidth-RTGScrWidth)/2,d2              ; DestX
                          move.l           #(((RTGCanvasHeight/3)*2)-RTGScrHeight)/2,d3    ; DestY
                          move.l           #RTGScrWidth,d4                                 ; SizeX
                          move.l           #RTGScrHeight,d5                                ; SizeY

                          move.l           ScrRP,a1                                        ; rp
                          move.l           P96Base,a6
                          jsr              _LVOp96WritePixelArray(a6)

                          GETREGS
                          RTS

*********************************************************************************************

                          cnop             0,32
AB3dChunkyRenderInfo:     
                          dcb.b            gri_SIZEOF,0

*********************************************************************************************
*********************************************************************************************

BplBufferByteSize EQU (640/8)*256*2

CopySpriteToColorBuffer:
; StaColBufPtr = Color register buffer
; StaColBufHeightPtr = Color register buffer height value
; StaSprPtr = Sprite pointer
; StaColRegBase = Color register base, default colors:
;                   Spr 0-1 : 16-19
;                   Spr 2-3 : 20-23
;                   Spr 4-5 : 24-27
;                   Spr 6-7 : 28-31 
;                 With attached sprites (Set only for the second sprite): 16-32 
; (StaSprHeight = Sprite height)
;
; Result:
; StaSprWidth = Sprite width (64 pix - default)
; StaSprHeight = Sprite height
;

                          SAVEREGS

                          move.l           StaSprPtr,a0  

                          clr.l            d0  
                          move.w           (a0),d0                                         ; VSTART, HSTART
                          add.l            #8,a0                                           ; 64bit

                          clr.l            d1 
                          move.w           (a0),d1                                         ; VSTOP, control bits
                          add.l            #8,a0                                           ; 64bit

                          move.w           d1,d0                                           ; # Handle attached
                          and.w            #$80,d0                                                        
                          beq              notAttachedSpr    
                          move.w           #1,StaSprAttach
                          bra              spr_NoCleanup

notAttachedSpr:
                          move.w           #0,StaSprAttach

***************************************************************
; Cleanup buffer
; $3448 VSTART, HSTART
                          move.l           #BplBufferByteSize/(4*4),d0
                          move.l           StaColBufPtr,a6

spr_Clean:  
                          move.l           #0,(a6)+
                          move.l           #0,(a6)+
                          move.l           #0,(a6)+
                          move.l           #0,(a6)+
                          dbra             d0,spr_Clean    

***************************************************************

spr_NoCleanup:

                          move.l           StaSprHeight,d0
                          beq              setHeight

                          move.l           StaSprHeight,d1
                          bra              heightOk

setHeight:

***************************************************************
; Bits 15-8          The low eight bits of VSTOP
; Bit  7             (Used in attachment)
; Bits 6-3           Unused (make zero)
; Bit  2             The VSTART high bit
; Bit  1             The VSTOP high bit
; Bit  0             The HSTART low bit

                          clr.l            d0 
                          move.w           d1,d0                                           ; # Handle height & width
                          ror.w            #8,d1                                                          
                          and.l            #%11111111,d1
                          and.l            #%00000010,d0
                          ror.l            #7,d0
                          or.l             d0,d1

                          cmp.l            #257,d1
                          bmi              heightOk
                          move.l           #256,d1  

***************************************************************

heightOk:
                          move.l           d1,d6
                          move.l           d1,StaSprHeight 

                          move.l           #64,StaSprWidth

                          move.l           a0,a1
                          add.l            #8,a1                                           ; 2 * 64bit lines

                          move.l           StaColBufPtr,a6

sprDataLoop:
                          move.l           #4,d1                                           ; 4 * 16bit -> 64bit wide

wideLoop:
                          clr.l            d2 
                          clr.l            d3 
                          move.w           (a0)+,d2                                        ; high word of data, line 1
                          move.w           (a1)+,d3                                        ; low word of data, line 1 

                          move.l           #16,d5

***************************************************************
; Loop 16 pixels

sprBitLoop:                            
                          sub.l            #1,d5 
                          clr.l            d4   

*********************************************
; Bits
                          btst             d5,d2                                           ; high word of data, line 1 - Bit 0 refers to the least-significant bit.
                          beq              sprNotHigh  
                          bset             #0,d4 

sprNotHigh:                          
                          btst             d5,d3                                           ; low word of data, line 1 
                          beq              sprNotLow  
                          bset             #1,d4 

sprNotLow:

*********************************************

                          tst.w            StaSprAttach
                          beq              skipAttach

                          rol.w            #2,d4                                           ; d4 = Color 3-2 bits

                          clr.l            d0
                          move.w           (a6),d0                                         ; d0 = Color 1-0 bits
                          
                          or.w             d0,d4                                           ; d4 = Color 3-0 bits   

skipAttach:   
                          tst.w            d4  
                          beq              sprSkipColBase

                          clr.l            d0                                           
                          move.w           StaColRegBase,d0                                ; Add offset to the real color register
                          add.w            d0,d4                                           ; Note: bplcon4 gives the four highest bits for color register value (defalut %0001)
                                                                                ; eg. %00010000 = color 16 => transparent, %00010001 = color 17, etc 
sprSkipColBase:                          
                          move.w           d4,(a6)+
                            
                          tst              d5
                          bne              sprBitLoop

***************************************************************

                          sub.l            #1,d1
                          bne              wideLoop    

                          add.l            #8,a0                                           ; Skip already handled lines  
                          add.l            #8,a1                                                          

                          sub.l            #1,d6
                          bne              sprDataLoop    

                          move.l           StaColBufHeightPtr,a0 
                          move.l           StaSprHeight,(a0)

                          GETREGS

                          rts

*********************************************************************************************

; in
StaColRegBase:            dc.w             0  
StaColBufPtr:             dc.l             0
StaColBufHeightPtr:       dc.l             0  
StaSprPtr:                dc.l             0
StaSprHeight:             dc.l             0  

; out
StaSprWidth:              dc.l             0  
StaSprAttach:             dc.w             0                                               ; 0/1

*********************************************************************************************
*********************************************************************************************
; Draw converted buffer

DrawSpriteColorBuffer:
; DscbColBuf = Sprite color buffer
; DscbPalettePtr = Palette pointer
; DscbHeight = Sprite height
; DscForce = force draw
;
; DscbRtgX = X coordinate on rtg window
; DscbRtgY = Y coordinate on rtg window
;
; DscbCopEffectCol = Color for copper bar effect
; DscbCopEffectColBufPtr = Color bar colors (traversed by y coordinate)

                          SAVEREGS

                          lea              AB3dSprHiColor15Buffer,a4

                          move.l           DscbRtgX,d0
                          add.l            #64,d0
                          move.l           d0,DscbRtgRight

                          move.l           DscbRtgY,d0
                          add.l            DscbHeight,d0
                          move.l           d0,DscbRtgBottom

                          move.l           DscbColBuf,a0  
                          move.l           DscbPalettePtr,a5

                          move.l           P96Base,a6
                          move.l           ScrRP,a1

                          move.l           DscbRtgY,d1                                     ; y
                          
spr_YLoop:
                          move.l           DscbRtgX,d0                                     ; x

spr_XLoop:
                          clr.l            d2
                          move.w           (a0)+,d2                                        ; Color register

                          move.l           DscForce,d5
                          tst              d5
                          bne              spr_Force      

                          tst              d2
                          beq              spa_SkipDraw
                          
spr_Force:
                          move.w           DscbCopEffectCol,d5
                          cmp.w            d2,d5
                          bne              skipCopEffect  

                          move.l           DscbCopEffectColBufPtr,a2
                          move.w           (a2,d1*2),d2
                          bra              copEffectOk  

skipCopEffect:  
                          move.w           (a5,d2*2),d2                                    ; Palette color (word)

copEffectOk:
                          jsr              WriteAB3dChunkyPixel

spa_SkipDraw:
                          move.w           d2,(a4)+                                        ; word

                          add.l            #1,d0
                          cmp.l            DscbRtgRight,d0
                          bmi              spr_XLoop

                          add.l            #1,d1
                          cmp.l            DscbRtgBottom,d1
                          bmi              spr_YLoop                            

                          GETREGS
                          rts

*********************************************************************************************

DscbColBuf:               dc.l             0
DscbPalettePtr:           dc.l             0  
DscbHeight:               dc.l             0
DscForce:                 dc.l             0

DscbRtgX:                 dc.l             0
DscbRtgY:                 dc.l             0
DscbRtgRight:             dc.l             0  
DscbRtgBottom:            dc.l             0  

DscbCopEffectCol:         dc.w             -1
DscbCopEffectColBufPtr:   dc.l             0

*********************************************************************************************
*********************************************************************************************

CopyPlaneToColorBuffer:
; PtaPalettePtr = Palette pointer
; PtaBplColBufPtr = Color buffer pointer
; PtaBplPtr = Pointer to first bitplane 
; PtaBplCount = Bitplanes count
; PtaBplModulo = Bitplanes modulo in bytes
; PtaBplOffsetInBytes = Offset for next bpl
; PtaBplWidth = Bitplane width in pixels
; PtaBplHeight = Bitplane height in pixels
;
; -----------------------------------------------------
; Color 15 - HealthPal
; PanelPal copper inst
; Panel - 320*200 - modulo : 40 bytes - 8bpl
; P2ARGB - Function with color
; -----------------------------------------------------

                          SAVEREGS

*********************************************************************
; Handle bitplanes

                          move.l           PtaPalettePtr,a5 
                          move.l           PtaBplColBufPtr,a4
                          move.l           PtaBplWidth,(a4)+
                          move.l           PtaBplHeight,(a4)+

                          move.l           PtaBplWidth,d0
                          divu.l           #8,d0
                          move.l           d0,PtaBplWidthInBytes

                          tst.l            PtaBplOffsetInBytes
                          bne              skipDefaultOffset
                          move.l           PtaBplWidthInBytes,PtaBplOffsetInBytes

skipDefaultOffset:
                          move.l           d0,d4
                          move.l           PtaBplCount,d5

                          move.l           PtaBplHeight,d6
                          mulu.l           d4,d6  
                          move.l           d6,PtaBplSize

                          move.l           PtaBplPtr,a6   

*********************************************************************

nextByte:
                          sub.l            #1,d4                                                          
                          move.l           #8,d0                                           ; 8 pixels

*********************************************************************

loopByteBits:
                          sub.l            #1,d0                                           ; Next pixel
                          move.l           a6,a1                                           ; (a6) Make new copy of bpl pointer

                          move.l           #0,d1                                           ; Bitplane number
                          move.l           #0,d3                                           ; Color register value

*********************************************************************
; Loop through bitplanes 

loopBitplanes:
                          move.l           #0,d2                                           ; Tmp buffer
                          move.b           (a1),d2                                         ; Get bpl byte

                          btst             d0,d2                                           ; Is n pixel of bitplane set?
                          beq              doNotSetBit

                          bset             d1,d3                                           ; Set bit by bpl number

doNotSetBit:
                          add.l            PtaBplOffsetInBytes,a1                          ; Add offset to next plane
                          add.l            #1,d1                                           ; Next plane

                          cmp.l            PtaBplCount,d1                                  ; Check plane count
                          bne              loopBitplanes                                                  

*********************************************************************
; d3 = Color register value from bitplanes

                          and.w            #$ff,d3  
                          move.w           (a5,d3*2),d3                                    ; 16bit palette color
                          move.w           d3,(a4)+                                        ; Store 16bit chunky color value

*********************************************************************
; Loop trough 8 pixels

                          tst              d0                                              ; 8 pixels
                          bne              loopByteBits

*********************************************************************
; Loop trough one bitplane

                          add.l            #1,a6

                          tst              d4
                          bne              doNotAddBplMod
                          add.l            PtaBplModulo,a6
                          move.l           PtaBplWidthInBytes,d4

doNotAddBplMod:                          
                          dbra             d6,nextByte

                          GETREGS
                          rts

*********************************************************************************************

; in
PtaPalettePtr:            dc.l             0  
PtaBplColBufPtr:          dc.l             0
PtaBplPtr:                dc.l             0
PtaBplCount:              dc.l             0
PtaBplModulo:             dc.l             0
PtaBplOffsetInBytes:      dc.l             0
PtaBplWidth:              dc.l             0
PtaBplHeight:             dc.l             0
PtaBplSize:               dc.l             0

; out
PtaBplWidthInBytes:       dc.l             0  

*********************************************************************************************
*********************************************************************************************

CopyAB3dHiColor15BufferToWindow:
; In: 
; bplHiColBufPtr = HiColor15 picture buffer
; bplHiColRtgX = Destination X
; bplHiColRtgY = Destination Y
; bplHiColSrcX = Source x
; bplHiColSrcY = Source y
; bplHiColSizeX = Size x
; bplHiColSizeY = Size y
;
; Result:
;     dcb_RtgRight(a6).l = End of rtg x
;     dcb_RtgBottom(a6).l = End of rtg x
;
; Uses _LVOp96WritePixelArray() function.

                          SAVEREGS
                          move.l           bplHiColBufPtr,a6
                          lea              bplHiColRenderInfo,a0                           ; ri
                          lea              8(a6),a1
                          move.l           a1,gri_Memory(a0)
                          move.l           (a6),d0
                          mulu.l           #2,d0                                           ; Word per pixel
                          move.w           d0,gri_BytesPerRow(a0)

                          move.w           #0,gri_pad(a0)
                          move.l           #RGBFB_R5G5B5,gri_RGBFormat(a0)

                          move.l           bplHiColSrcX,d0                                 ; SrcX
                          move.l           bplHiColSrcY,d1                                 ; SrcY

                          move.l           bplHiColRtgX,d2                                 ; DestX
                          move.l           bplHiColRtgY,d3                                 ; DestY

                          move.l           bplHiColSizeX,d4                                ; SizeX
                          move.l           bplHiColSizeY,d5                                ; SizeY

                          move.l           ScrRP,a1                                        ; rp
                          move.l           P96Base,a6
                          jsr              _LVOp96WritePixelArray(a6)
                            
                          GETREGS
                          RTS

*********************************************************************************************

DrawAB3dHiColor15BufferToWindow:
; In: 
; bplHiColBufPtr = HiColor15 picture buffer
; bplHiColRtgX = Destination X
; bplHiColRtgY = Destination Y
;
; Result:
;     dcb_RtgRight(a6).l = End of rtg x
;     dcb_RtgBottom(a6).l = End of rtg x
;
; Uses _LVOp96WritePixelArray() function.

                          SAVEREGS
                          move.l           bplHiColBufPtr,a6
                          lea              bplHiColRenderInfo,a0                           ; ri
                          lea              8(a6),a1
                          move.l           a1,gri_Memory(a0)
                          move.l           (a6),d0
                          mulu.l           #2,d0                                           ; Word per pixel
                          move.w           d0,gri_BytesPerRow(a0)

                          move.w           #0,gri_pad(a0)
                          move.l           #RGBFB_R5G5B5,gri_RGBFormat(a0)

                          move.l           #0,d0                                           ; SrcX
                          move.l           #0,d1                                           ; SrcY

                          move.l           bplHiColRtgX,d2                                 ; DestX
                          move.l           bplHiColRtgY,d3                                 ; DestY

                          move.l           (a6),d4                                         ; SizeX
                          move.l           4(a6),d5                                        ; SizeY

                          move.l           ScrRP,a1                                        ; rp
                          move.l           P96Base,a6
                          jsr              _LVOp96WritePixelArray(a6)
                            
                          GETREGS
                          RTS

*********************************************************************************************

WriteAB3dPixel:
; d0 = x 
; d1 = y 
; d2 = 16bit pixel
; Use PlaneBuffer0
; Uses _LVOp96WritePixelArray() function.

                          SAVEREGS

                          lea              bplHiColRenderInfo,a0                           ; ri
                          lea              PlaneBuffer0,a1
                          move.w           d2,(a1)

                          move.l           a1,gri_Memory(a0)
                          move.w           #AB3dWidth*2,gri_BytesPerRow(a0)                ; Word
                          move.w           #0,gri_pad(a0)
                          move.l           #RGBFB_R5G5B5,gri_RGBFormat(a0)
                          
                          move.l           d0,d2                                           ; DestX
                          move.l           d1,d3                                           ; DestY

                          move.l           #0,d0                                           ; SrcX
                          move.l           #0,d1                                           ; SrcY
                          move.l           #1,d4                                           ; SizeX
                          move.l           #1,d5                                           ; SizeY

                          move.l           ScrRP,a1                                        ; rp
                          move.l           P96Base,a6
                          jsr              _LVOp96WritePixelArray(a6)
                            
                          GETREGS
                          RTS

*********************************************************************************************

; in
bplHiColBufPtr:           dc.l             0  

bplHiColRtgX:             dc.l             0
bplHiColRtgY:             dc.l             0

bplHiColSrcX:             dc.l             0
bplHiColSrcY:             dc.l             0

bplHiColSizeX:            dc.l             0
bplHiColSizeY:            dc.l             0

*********************************************************************************************

                          cnop             0,32
bplHiColRenderInfo:       dcb.b            gri_SIZEOF,0

*********************************************************************************************
*********************************************************************************************

ClearPiPWindow:
; Clear with bg color black
; Uses _LVOp96WritePixelArray() function.

                          SAVEREGS

                          lea              AB3dHiColClearRenderInfo,a0                     ; ri
                          lea              AB3dHiColClearBuffer,a1
                          move.l           a1,gri_Memory(a0)
                          move.w           #AB3dWidth*2,gri_BytesPerRow(a0)
                          move.w           #0,gri_pad(a0)
                          move.l           #RGBFB_R5G5B5,gri_RGBFormat(a0)

                          move.l           #1,d0                                           ; SrcX
                          move.l           #1,d1                                           ; SrcX
                          move.l           #0,d2                                           ; DestX
                          move.l           #0,d3                                           ; DestY
                          move.l           #RTGCanvasWidth,d4                              ; SizeX
                          move.l           #RTGCanvasHeight,d5                             ; SizeY

                          move.l           ScrRP,a1                                        ; rp
                          move.l           P96Base,a6
                          jsr              _LVOp96WritePixelArray(a6)
                            
                          GETREGS
                          RTS

*********************************************************************************************

                          cnop             0,32
AB3dHiColClearRenderInfo:  dcb.b       gri_SIZEOF,0

*********************************************************************************************
*********************************************************************************************

Get12bitColors:
; a5 = 12bit colors
; a6 = 16bit palette values
; gp12ColorCount = Color count

                          SAVEREGS

                          move.l           a5,a0
                          move.l           a6,a1
                          move.l           gc12ColorCount,d0

gc12Loop:                   
                          clr.l            d2

                          move.w           (a0)+,d2                                        ; color value
                          C12BITTOHICOL
                          move.w           d2,(a1)+

                          sub.l            #1,d0
                          tst              d0
                          bne              gc12Loop

                          GETREGS
                          rts

*********************************************************************************************

gc12ColorCount:           dc.l             256

*********************************************************************************************
*********************************************************************************************

Parse12bitPalette:
; a5 = 12bit copper palette 
; a6 = 16bit palette values
; gp12ColorCount = Color register count

                          SAVEREGS

                          move.l           a5,a0

                          move.l           pp12ColorOffset,d0
                          mulu.l           #2,d0
                          add.l            d0,a6 
                          move.l           a6,a1

                          move.l           pp12ColorCount,d0

pp12Loop:                   
                          clr.l            d1      
                          clr.l            d2

                          move.w           (a0)+,d1                                        ; custom register
                          move.w           (a0)+,d2                                        ; value

                          cmp.w            #$0106,d1
                          beq              pp12Loop

                          C12BITTOHICOL

                          move.w           d2,(a1)+

                          sub.l            #1,d0
                          tst              d0
                          bne              pp12Loop

                          GETREGS
                          rts

*********************************************************************************************

pp12ColorCount:           dc.l             256
pp12ColorOffset:          dc.l             0

*********************************************************************************************
*********************************************************************************************

Parse24bitPalette:
; a5.l = 24bit copper palette with all 256 color registers.
;      Copper list begins with e.g. $0106,$0002  
; a6.l = 16bit palette
; pp24ColorCount.l = How many colors to convert
; pp24ColorOffset.l = Start from color register
;

                          SAVEREGS

*********************************************************************
; Setup
                          move.l           a5,a0

                          move.l           pp24ColorOffset,d0
                          mulu.l           #2,d0
                          add.l            d0,a6    
                          move.l           a6,a1

                          move.l           pp24ColorCount,d7

*********************************************************************
; Get values

ppLoop:                   
                          clr.l            d1      
                          clr.l            d2

                          move.w           (a0)+,d1                                        ; custom register
                          move.w           (a0)+,d2                                        ; value

*********************************************************************
; Check control bits

                          cmp.w            #$0106,d1
                          bne              ppColor

                          clr.l            d3
                          move.w           d2,d3
                          and.l            #%1110000000000000,d3                           ; LOTC bit
                          ror.l            #8,d3
                          ror.l            #5,d3
                          mulu.l           #32*2,d3                                        ; Offset to the bank start
                          move.l           d3,ppOffsetToBank  

; LOTC = 0 => we fill in R7-R4,G7-G4,B7-B4
; LOTC = 1 => we fill in R3-R0,G3-G0,B3-B0. 
                          clr.l            d3
                          move.w           d2,d3    
                          and.l            #%0000001000000000,d3                           ; LOTC bit
                          ror.l            #8,d3
                          ror.l            #1,d3
                          move.w           d3,ppLowBits                              

                          bra              ppLoop

*********************************************************************
; Parse colors

ppColor:
                          clr.l            d3  
                          move.w           d1,d3
                          sub.l            #$180,d3                                        ; Note: already *2
                          
                          move.l           ppOffsetToBank,d0
                          add.l            d3,d0

                          move.l           a6,a1    
                          add.l            d0,a1  

******************************************

                          clr.l            d0    
                          move.w           ppLowBits,d0
                          bne              low
                          
                          move.w           d2,(a1)  
                          bra              ppLoop  

low:
                          clr.l            d1    
                          move.w           (a1),d1
                          C24BITTOHICOL
                          move.w           d2,(a1)

                          sub.l            #1,d7
                          bne              ppLoop

                          GETREGS
                          rts

*********************************************************************************************

pp24ColorCount:           dc.l             256
pp24ColorOffset:          dc.l             0

ppOffsetToBank:           dc.l             0
ppLowBits:                dc.w             0

*********************************************************************************************
*********************************************************************************************

DrawPalette:
; a5 = Palette pointer

                          SAVEREGS

                          move.l           P96Base,a6
                          move.l           ScrRP,a1

                          move.l           #RTGCanvasHeight-6,d1                           ; y
                          
dp_YLoop:
                          move.l           #1,d0                                           ; x

dp_XLoop:
                          move.w           (a5)+,d2                                        ; 16bit palette color
                          jsr              WriteAB3dPixel

                          add.l            #1,d0
                          cmp.l            #RTGCanvasWidth,d0
                          bmi              dp_XLoop

                          add.l            #1,d1
                          cmp.l            #RTGCanvasHeight-6,d1
                          bmi              dp_YLoop                            

                          GETREGS
                          rts

*********************************************************************************************
*********************************************************************************************

ClearPiPPointer:
                          SAVEREGS

                          move.l           PipBase,a0
                          move.l           IntuiBase,a6 
                          jsr              _LVOClearPointer(a6)
                         
                          GETREGS
                          rts

*********************************************************************************************
*********************************************************************************************

DebugPrint:
; a0 = inputText
; a1 = data

                          SAVEREGS
                          lea              txtClr,a0
                          move.l           a0,debugText  
                          move.l           #10,d0
                          lea              intuiTextStruct,a1
                          move.l           ScrRP,a0 
                          move.l           IntuiBase,a6 
                          jsr              _LVOPrintIText(a6)                          
                          GETREGS
                          
                          SAVEREGS
                          lea              stuffChar,a2
                          lea              fmtOutput,a3                                    ;Get the output string pointer
                          move.l           $4,a6
                          jsr              _LVORawDoFmt(a6)
                          GETREGS  

                          SAVEREGS
                          move.l           #fmtOutput,debugText  
                          move.l           #10,d0
                          lea              intuiTextStruct,a1
                          move.l           ScrRP,a0 
                          move.l           IntuiBase,a6 
                          jsr              _LVOPrintIText(a6)
                          GETREGS

                          rts

*********************************************************************

stuffChar:
                          move.b           d0,(a3)+                                        ;Put data to output string
                          rts

*********************************************************************

fmtOutput:                dcb.b            256,0

*********************************************************************

intuiTextStruct:
                          dc.b             1
                          dc.b             0
                          dc.b             RP_JAM2
                          dc.b             0
                          dc.w             0
                          dc.w             0
                          dc.l             0
debugText:                dc.l             txtClr
                          dc.l             0

*********************************************************************

txtClr:                   dc.b             "                  ",0
                          cnop             0,32

*********************************************************************************************