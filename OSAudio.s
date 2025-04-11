*********************************************************************************************

                          opt         P=68020

*********************************************************************************************

                          incdir      "includes"
                          include     "macros.i"

                          include     "exec/ports.i"
                          include     "exec/memory.i"
                          include     "exec/types.i"
                          include     "exec/io.i"
                          include     "devices/audio.i"

*********************************************************************************************

OpenAudioIO:
; d0 = error code, 0 = ok
; Allocate 8-channels
            
                          STOREREGS

                          move.l      $4,a6
                          jsr         _LVOCreateMsgPort(a6)
                          move.l      d0,audioPort

                          move.l      d0,a0
                          move.l      #ioa_SIZEOF,d0
                          move.l      $4,a6
                          jsr         _LVOCreateIORequest(a6)
                          move.l      d0,audioRequest

                          move.l      d0,a0
                          move.w      #ADCMD_ALLOCATE,IO_COMMAND(a0)
                          move.b      #ADIOF_NOWAIT,IO_FLAGS(a0)

                          move.w      #0,ioa_AllocKey(a0)
                          lea         channels,a1                       ; allocate channels
                          move.l      a1,ioa_Data(a0)
                          move.l      #4,ioa_Length(a0)                          

                          move.l      d0,a1
                          lea         audioDeviceName,a0
                          move.l      #0,d0
                          move.l      #0,d1
                          move.l      $4,a6
                          jsr         _LVOOpenDevice(a6)
                          
                          RESTOREREGS
                          rts

*********************************************************************************************
*********************************************************************************************

CloseAudioIO:
; Deallocate 8-channels

                          STOREREGS

                          move.l      audioRequest,a1
                          move.l      $4,a6
                          jsr         _LVOCloseDevice(a6)

                          move.l      audioRequest,a0
                          move.l      $4,a6
                          jsr         _LVODeleteIORequest(a6)

                          move.l      audioPort,a0
                          move.l      $4,a6
                          jsr         _LVODeleteMsgPort(a6)

                          moveq       #0,d0
                          RESTOREREGS
                          rts

*********************************************************************************************
*********************************************************************************************

audioCode:                dc.w        0

*********************************************************************************************

audioPort:                dc.l        0
audioRequest:             dc.l        0

audioDeviceName:          dc.b        "audio.device",0
                          cnop        0,32

*********************************************************************************************

channels:                 dc.b        1,2,4,8

*********************************************************************************************
