*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

                          incdir     "includes"
                          include    "macros.i"

*********************************************************************************************
; FPS chunky buffers

                          cnop       0,64
AB3dChunkyHiColor15Buffer:      
                          dcb.w      640*256,0                                              ; HiColor15 (5 bit each), format: 0rrrrrgggggbbbbb

                          cnop       0,64
AB3dChunkyBuffer:         dcb.w      320*256,0

                          cnop       0,64
AB3dScaledChunkyBuffer:   dcb.w      320*256,0

*********************************************************************************************
; Bitplane buffers

                          cnop       0,64
PlaneBuffer0:
PlaneColorBufferWidth0:   
                          dc.l       0
PlaneColorBufferHeight0:  
                          dc.l       0
PlaneColorBuffer0:
                          dcb.w      640*256,0

*****************************************************

                          cnop       0,64
PlaneBuffer1:
PlaneColorBufferWidth1:   
                          dc.l       0
PlaneColorBufferHeight1:  
                          dc.l       0
PlaneColorBuffer1:        
                          dcb.w      640*256,0

*****************************************************
; Bitplane HiColor buffer for clear

                          cnop       0,64
AB3dHiColClearBuffer:     dcb.w      640*256,0                                              ; HiColor15 (5 bit each), format: 0rrrrrgggggbbbbb


*********************************************************************************************
; Sprite buffers


********************************************
; Panel (borders):
                          cnop       0,64
PanelSprColorBufferHeight0:    
                          dc.l       0
PanelSprColorBuffer0:     
                          dcb.b      BplBufferByteSize,0                                    ; Color register values

PanelSprColorBufferHeight1:    
                          dc.l       0
PanelSprColorBuffer1:     
                          dcb.b      BplBufferByteSize,0                                    ; Color register values


********************************************
; Menu:
                          cnop       0,64
SprColorBufferHeight0:    
                          dc.l       0
SprColorBuffer0:          
                          dcb.b      BplBufferByteSize,0                                    ; Color register values

SprColorBufferHeight1:    
                          dc.l       0
SprColorBuffer1:          
                          dcb.b      BplBufferByteSize,0                                    ; Color register values

SprColorBufferHeight2:    
                          dc.l       0
SprColorBuffer2:          
                          dcb.b      BplBufferByteSize,0                                    ; Color register values

SprColorBufferHeight3:    
                          dc.l       0
SprColorBuffer3:          
                          dcb.b      BplBufferByteSize,0                                    ; Color register values

SprColorBufferHeight4:    
                          dc.l       0
SprColorBuffer4:          
                          dcb.b      BplBufferByteSize,0                                    ; Color register values


********************************************
; Sprite chunky buffer
                          cnop       0,64
AB3dSprHiColor15Buffer:
                          dcb.w      640*256,0                                              ; 16 bit color buffer (HiColor15)

*********************************************************************************************
; Palette buffers

                          cnop       0,64
Border24bitPalette:       include    "data\rtg\pal\borders_256_24_16_HiColor15.s"

                          cnop       0,64
Panel24bitPalette:        include    "data\rtg\pal\panel_256_24_16_HiColor15.s"

                          cnop       0,64
Text24bitPalette:         
                          dc.w       $0000                                                  ; Col0 : $0
                          dc.w       $3B8E                                                  ; Col1 : $07E7 = %000 0111 1110 0111 (12bit) =>  %0 01110 11100 01110 (16bit) = $3B8E (Level text)
                          dc.w       $0000                                                  ; Col2 : $0
                          dc.w       $739C                                                  ; Col3 : $0fff + $0000 = $00f0f0f0 (24bit) => %0111001110011100 (16bit) = $739C
                          dcb.w      256-4,$0000

*******************************************************

                          cnop       0,64
Title24bitPalette:        incbin     "data\rtg\pal\title_256_24_16_HiColor15.raw"

                          cnop       0,64
Healt12bitPalette:        include    "data\rtg\pal\health_80_12_16_HiColor15.s"             ; Col15 : ($19e)

                          cnop       0,64
Faces12bitPalette:        include    "data\rtg\pal\faces_32_12_16_HiColor15.s"

*********************************************************************************************
; Title images
                          cnop       0,64
RTGTitle:                 
                          dc.l       320                                                    ; Width
                          dc.l       256                                                    ; Height
                          incbin     "data\rtg\gfx\title_320x256x16_HiColor15.raw"

*********************************************************************************************
; Panel images

                          cnop       0,64
RTGPanelLeft:
                          dc.l       64                                                     ; Width
                          dc.l       160                                                    ; Height
                          incbin     "data\rtg\gfx\panel_left_64x160x16_HiColor15.raw"

                          cnop       0,64
RTGPanelRight:
                          dc.l       64                                                     ; Width
                          dc.l       160                                                    ; Height
                          incbin     "data\rtg\gfx\panel_right_64x160x16_HiColor15.raw"

                          cnop       0,64
RTGPanelBottom:
                          dc.l       320                                                    ; Width
                          dc.l       96                                                     ; Height
                          incbin     "data\rtg\gfx\panel_bottom_320x96x16_HiColor15.raw"

*********************************************************************************************