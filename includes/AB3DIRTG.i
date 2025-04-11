*********************************************************************************************

                          IFND      AB3DIRTG_i
AB3DIRTG_i EQU 1

*********************************************************************************************
; Macros

C12BITTOHICOL             MACRO
; d2.w (12bit) => d2.w (0rrrrrgggggbbbbb)
; 0R:GB => 0rrrrrgg:gggbbbbb
; HiColor15 (5 bit each), format: 0rrrrrgggggbbbbb

                          movem.l          d3-d4,-(a7)

                          move.w           d2,d3
                          and.w            #$0fff,d3                                 ; 12bit = 0000rrrr ggggbbbb
                          
                          moveq            #0,d2                                     ; 15bit = 0rrrrrgg gggbbbbb 

                          move.w           d3,d4
                          and.l            #%0000111100000000,d4                     ; R
                          rol.l            #3,d4                                     ; 
                          or.l             d4,d2

                          move.w           d3,d4
                          and.l            #%0000000011110000,d4                     ; G
                          rol.l            #2,d4
                          or.l             d4,d2

                          move.w           d3,d4
                          and.l            #%0000000000001111,d4                     ; B
                          rol.l            #1,d4
                          or.l             d4,d2

                          movem.l          (a7)+,d3-d4
                          ENDM

*********************************************************************************************

CHICOLTO12BIT             MACRO
; d2.w (0rrrrrgggggbbbbb) => d2.w (12bit)
; 0rrrrrgg:gggbbbbb => 0R:GB
; HiColor15 (5 bit each), format: 0rrrrrgggggbbbbb

                          movem.l          d3-d4,-(a7)

                          move.w           d2,d3
                          and.w            #$7fff,d3                                 ; 15bit = 0rrrrrgg gggbbbbb 
                          
                          moveq            #0,d2                                     ; 12bit = 0000rrrr ggggbbbb

                          move.w           d3,d4
                          and.l            #%0111100000000000,d4                     ; R
                          ror.l            #3,d4                                     ; 
                          or.l             d4,d2

                          move.w           d3,d4
                          and.l            #%0000001111000000,d4                     ; G
                          ror.l            #2,d4
                          or.l             d4,d2

                          move.w           d3,d4
                          and.l            #%0000000000011110,d4                     ; B
                          rol.l            #1,d4
                          or.l             d4,d2

                          movem.l          (a7)+,d3-d4
                          ENDM

*********************************************************************************************

C24BITTOHICOL             MACRO
; d1.w (12bit HI)
; d2.w (12bit LO) 
; => ds.w (0rrrrrgg:gggbbbbb)
; 0R:GB Hi + 0R:GB Lo => 0rrrrrgg:gggbbbbb
;
; 182:0011 HI -> 0000 0000 0001 0001
; 182:07ED LO -> 0000 0111 1110 1101
; => 0000 0000  0000 0111  0001 1110  0001 1101
; => 00 07 1E 1D => FF 07 1E 1D

                          movem.l          d1,-(a7)
                          movem.l          d3-d6,-(a7)

                          move.w           d2,d5
                          and.w            #$0fff,d5                                 ; LO
                          move.w           d1,d3
                          and.w            #$0fff,d3                                 ; HI

                          moveq            #0,d2                                     ; 0rrrrrgg gggbbbbb

                          move.w           d3,d4                                     ; HI
                          and.l            #$0f00,d4                                 ; R
                          ror.l            #7,d4
                          or.l             d4,d2

                          move.w           d5,d6                                     ; LO
                          and.l            #$0800,d6
                          ror.l            #8,d6
                          ror.l            #3,d6
                          or.l             d6,d2

                          rol.l            #5,d2

*********************************************************************
                          move.w           d3,d4                                     ; HI
                          and.l            #$00f0,d4                                 ; G
                          ror.l            #3,d4
                          or.l             d4,d2

                          move.w           d5,d6                                     ; LO
                          and.l            #$0080,d6
                          ror.l            #7,d6
                          or.l             d6,d2

                          rol.l            #5,d2

*********************************************************************
                          move.w           d3,d4                                     ; HI    
                          and.l            #$000f,d4                                 ; B
                          rol.l            #1,d4
                          or.l             d4,d2

                          move.w           d5,d6                                     ; LO
                          and.l            #$0008,d6
                          ror.l            #3,d6
                          or.l             d6,d2

*********************************************************************
                          movem.l          (a7)+,d3-d6
                          movem.l          (a7)+,d1

                          ENDM
                          
*********************************************************************************************

                          ENDC  
                          
*********************************************************************************************                          