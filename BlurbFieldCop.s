*********************************************************************************************

                          opt       P=68020

*********************************************************************************************

                          incdir    "includes"

*********************************************************************************************

BlurbFieldCop:

                          dc.w      bpl1ptl
bl1l:                     dc.w      0
                          dc.w      bpl1pth
bl1h:                     dc.w      0

                          dc.w      diwstrt,$2c81
                          dc.w      diwstop,$1cc1
                          dc.w      ddfstrt,$38
                          dc.w      ddfstop,$b8
                          dc.w      bplcon0,$9201
                          dc.w      bplcon1,0
                          dc.w      bplcon3,$c40
       
blcols:
                          dc.w      color00,$0000
                          dc.w      color00,$0fff

                          dc.w      bpl1mod,0
                          dc.w      bpl2mod,0

                          dc.w      $ffff,$fffe

*********************************************************************************************