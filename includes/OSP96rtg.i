*********************************************************************************************

                          incdir       "includes"
                          include      "exec\types.i"

*********************************************************************************************
; Palette param
                          STRUCTURE    PaletteBuffer,0
                          STRUCT       pb_Palette,256*4               ; 256 colors
                          LABEL        PaletteBuffer_SIZEOF

*********************************************************************
; Color buffer param
                          STRUCTURE    ColorBuffer,0
                          ULONG        cb_Width
                          ULONG        cb_Height
                          APTR         cb_BufferPtr
                          LABEL        ColorBuffer_SIZEOF

*********************************************************************************************
; Copy bpl to color buffer
                          STRUCTURE    CopyBplToColorBuffer,0
                          ULONG        btcb_BplCount
                          ULONG        btcb_BplModulo
                          ULONG        btcb_BplWidth
                          ULONG        btcb_BplHeight
                          ULONG        btcb_BplSize

                          APTR         btcb_PalettePtr
                          APTR         btcb_BplPtr

                          ULONG        btcb_RtgX
                          ULONG        btcb_RtgY
                          LABEL        CopyBplToColorBuffer_SIZEOF

*********************************************************************************************
; Draw color buffer params

                          STRUCTURE    DrawColorBuffer,0
                          ; in
                          APTR         dcb_BplColBufPtr
                          APTR         dcb_PalettePtr
                          ULONG        dcb_Width
                          ULONG        dcb_Height
                          ULONG        dcb_RtgX
                          ULONG        dcb_RtgY

                          ; out
                          ULONG        dcb_RtgRight
                          ULONG        dcb_RtgBottom
                          LABEL        DrawColorBuffer_SIZEOF

*********************************************************************************************
; Game and input control states

                          STRUCTURE    AB3DStateRegistry,0
                          UWORD        asr_IsActive                   ; Window activ?
                          UWORD        asr_TrapMouse                  ; Grab mouse?
                          UBYTE        asr_Buttons:                   ; 2 = Mouse0Middle, 1 = Mouse0Right, 0 = Mouse0Left (0=Fire)
                                                                      ; 5 = Mouse1Middle, 4 = Mouse1Right, 3 = Mouse1Left
                          UBYTE        asr_JoyMove                    ; 0 = Joy0UP, 1 = Joy0DOWN, 2=Joy0LEFT, 3=Joy0RIGHT
                                                                      ; 4 = Joy1UP, 5 = Joy1DOWN, 6=Joy1LEFT, 7=Joy1RIGHT
                          UBYTE        asr_Mouse0X                    ; Delta value
                          UBYTE        asr_Mouse0Y                    ; Delta value
                          UWORD        asr_RawKey                     ; Raw key value
                          UWORD        asr_RawMouse                   ; Raw mouse value
                          LABEL        AB3DStateRegistry_SIZEOF

*********************************************************************************************                          