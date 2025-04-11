*********************************************************************************************
; LevelPack-2

LDname:                   dc.b               'disk/levels_test/level_'
LEVA:                     dc.b               'a/twolev.bin',0
                          cnop               0,32

LDhandle:                 dc.l               0
LGname:                   dc.b               'disk/levels_test/level_'
LEVB:                     dc.b               'a/twolev.graph.bin',0
                          cnop               0,32

LGhandle:                 dc.l               0
LCname:                   dc.b               'disk/levels_test/level_'
LEVC:                     dc.b               'a/twolev.clips',0
                          cnop               0,32

*********************************************************************************************