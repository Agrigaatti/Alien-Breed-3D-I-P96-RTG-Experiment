;============================================================================
;   proplayer.a
;   ~~~~~~~~~~~
; $VER: proplayer 6.0 (08.03.1995)
;
; The music player routine for MMD0/MMD1/MMD2 MED/OctaMED
; four-channel modules.
;
; Copyright � 1995 Teijo Kinnunen and RBF Software.
;
; Written by Teijo Kinnunen.
; Comments/questions/bug reports can be sent to:
;   Teijo Kinnunen
;   Oksantie 19
;   FIN-86300  OULAINEN
;   FINLAND
;   email: kinnunen@stekt.oulu.fi
;
; See OctaMED docs for conditions about using these routines.
; Comments/questions about distribution and usage conditions
; should be directed to RBF Software. (Email: rbfsoft@cix.compulink.co.uk)
;
;============================================================================

;****** Feature control ******
;
MIDI            EQU 0                                                                                              ;1 = include MIDI code
AUDDEV          EQU 0                                                                                              ;1 = allocate channels using audio.device
SYNTH           EQU 1                                                                                              ;1 = include synth-sound handler
CHECK           EQU 1                                                                                              ;1 = do range checkings (track, sample in mem etc.)
RELVOL          EQU 1                                                                                              ;1 = include relative volume handling code
IFFMOCT         EQU 1                                                                                              ;1 = play IFF multi-octave samples/ExtSamples correctly
HOLD            EQU 1                                                                                              ;1 = handle hold/decay
PLAYMMD0        EQU 1                                                                                              ;1 = play old MMD0 modules
AURA            EQU 0                                                                                              ;1 = support the Aura sampler
;
; The less features you include, the faster and shorter the play-routine
; will be.
;
; NOTE: Using the Aura will cause Enforcer hits (LONG-READ/WRITE at addr $70).
; This is normal, and can't be avoided.

;****** Timing control ******
;
VBLANK          EQU 0                                                                                              ;1 = use VBlank interrupt (when absolutely necessary)
CIAB            EQU 1                                                                                              ;1 = use CIA timers (default)
;
; Please use CIAB whenever possible to avoid problems with variable
; VBlank speeds and to allow the use of command F01 - FF0 (set tempo)
; If both are set to 0, the timing is left for you (never set both to 1!!),
; then you just call _IntHandler for each timing pulse.

;============================================================================

;If you are making a demo/game with only a single tune you'd like to
;incorporate in the code (like "easyplayer.a" of MED V3), set the following
;flag to 1. This requires an assembler with INCBIN (or equivalent) directive.
;You have to insert the module name to the INCBIN statement (located near the
;end of this file, on line 2052).

EASY            EQU 0

;Call _startmusic to play the music, and _endmusic to stop it (before
;exiting). Note: don't call _startmusic twice!! This would cause the module
;to be relocated twice (= Guru). If you need to stop and continue playing,
;don't use the EASY routines, use PlayModule/StopPlayer... instead.

;============================================================================

; The MMD structure offsets
mmd_id          EQU 0
mmd_modlen      EQU 4
;mmd_songinfo    EQU 8
; these two for MMD2s only!
mmd_psecnum     EQU 12
mmd_pseq        EQU 14
;
;mmd_blockarr    EQU 16
mmd_smplarr     EQU 24
;mmd_expdata EQU 32
mmd_pstate      EQU 40                                                                                             ; <0 = play song, 0 = don't play, >0 = play block
mmd_pblock      EQU 42
mmd_pline       EQU 44
mmd_pseqnum     EQU 46
mmd_counter     EQU 50
;mmd_songsleft   EQU 51

; The Song structure
; Instrument data here (504 bytes = 63 * 8)
;msng_numblocks  EQU 504
msng_songlen    EQU 506
msng_playseq    EQU 508
msng_deftempo   EQU 764
msng_playtransp EQU 766
msng_flags      EQU 767
msng_flags2     EQU 768
msng_tempo2     EQU 769
; msng_trkvol applies to MMD0/MMD1 only.
msng_trkvol     EQU 770
msng_mastervol  EQU 786
;msng_numsamples EQU 787
; Fields below apply to MMD2 modules only.
;msng_pseqs  EQU 508
msng_sections   EQU 512
msng_trkvoltbl  EQU 516
msng_numtracks  EQU 520
msng_numpseqs   EQU 522

; Instrument data
inst_repeat     EQU 0
inst_replen     EQU 2
inst_midich     EQU 4
inst_midipreset EQU 5
inst_svol       EQU 6
inst_strans     EQU 7

; Audio hardware offsets
;ac_ptr          EQU $00
;ac_len          EQU $04
;ac_per          EQU $06
;ac_vol          EQU $08

; Trackdata sizes
T03SZ           EQU 106
T415SZ          EQU 22
;offset of trk_audioaddr
TAAOFFS         EQU 24
TTMPVOLOFFS     EQU 102

; Maximum number of tracks allowed. If you don't need this much tracks,
; you can decrease the number to save some space. (Be sure that the
; song really has no more than MAX_NUMTRACKS tracks. Minimum allowed
; value = 4.)
MAX_NUMTRACKS   EQU 64

; This value is used for MMD0/1 conversion. If MAX_NUMTRACKS <= 16,
; this should be the same. If MAX_NUMTRACKS > 16, this should be 16.
MAX_MMD1_TRACKS EQU 16

; Aura output handling routines
                          IFNE        AURA
; also includes the SECTION cmd...
                          INCLUDE     "aura.a"
                          ENDC
                          IFEQ        AURA
                          SECTION     "text",CODE
                          ENDC

                          IFNE        EASY

                          XDEF        _startmusic,_endmusic

_startmusic               lea         easymod,a2
                          bsr.s       _RelocModule
                          bsr.w       _InitPlayer
                          lea         easymod,a0
                          bra.w       _PlayModule

_endmusic                 bra.w       _RemPlayer
; ***** The relocation routine *****
reloci                    move.l      24(a2),d0
                          beq.s       xloci
                          movea.l     d0,a0
                          moveq       #0,d0
                          move.b      msng_numsamples(a1),d0
                          subq.b      #1,d0
relocs                    bsr.s       relocentr
                          move.l      -4(a0),d3
                          beq.s       nosyn
                          move.l      d3,a3
                          tst.w       4(a3)
                          bpl.s       nosyn
                          move.w      20(a3),d2
                          lea         278(a3),a3
                          subq.w      #1,d2
relsyn                    add.l       d3,(a3)+
                          dbf         d2,relsyn
nosyn                     dbf         d0,relocs
xloci                     rts
norel                     addq.l      #4,a0
                          rts
relocentr                 tst.l       (a0)
                          beq.s       norel
                          add.l       d1,(a0)+
                          rts

;============================================================================

_RelocModule              movem.l     a2-a4/d2-d4,-(sp)
                          move.l      a2,d1
                          bsr.s       relocp
                          movea.l     mmd_songinfo(a2),a1
                          bsr.s       reloci
                          move.b      mmd_songsleft(a2),d4
rel_lp                    bsr.s       relocb
                          cmp.b       #'2',3(a2)
                          bne.s       norelmmd2
                          bsr.w       relocmmd2sng
norelmmd2                 move.l      mmd_expdata(a2),d0
                          beq.s       rel_ex
                          move.l      d0,a0
                          bsr.s       relocentr
                          bsr.s       relocentr
                          addq.l      #4,a0
                          bsr.s       relocentr
                          addq.l      #4,a0
                          bsr.s       relocentr
                          addq.l      #8,a0
                          bsr.s       relocentr
                          addq.l      #4,a0
                          bsr.s       relocentr
                          bsr.s       relocentr
                          addq.l      #4,a0
                          bsr.s       relocentr
                          bsr.s       relocmdd
                          subq.b      #1,d4
                          bcs.s       rel_ex
                          move.l      d0,a0
                          move.l      (a0),d0
                          beq.s       rel_ex
                          move.l      d0,a2
                          bsr.s       relocp
                          movea.l     8(a2),a1
                          bra.s       rel_lp
rel_ex                    movem.l     (sp)+,d2-d4/a2-a4
                          rts

;============================================================================

relocp                    lea         mmd_songinfo(a2),a0
                          bsr.s       relocentr
                          addq.l      #4,a0
                          bsr.s       relocentr
                          addq.l      #4,a0
                          bsr.s       relocentr
                          addq.l      #4,a0
                          bra.s       relocentr
relocb                    move.l      mmd_blockarr(a2),d0
                          beq.s       xlocb
                          movea.l     d0,a0
                          move.w      msng_numblocks(a1),d0
                          subq.b      #1,d0
rebl                      bsr         relocentr
                          dbf         d0,rebl
                          cmp.b       #'T',3(a2)
                          beq.s       xlocb
                          cmp.b       #'1',3(a2)
                          bge.s       relocbi
xlocb                     rts

;============================================================================

relocmdd                  move.l      d0,-(sp)
                          tst.l       -(a0)
                          beq.s       xlocmdd
                          movea.l     (a0),a0
                          move.w      (a0),d0
                          addq.l      #8,a0
mddloop                   beq.s       xlocmdd
                          bsr         relocentr
                          bsr.s       relocdmp
                          subq.w      #1,d0
                          bra.s       mddloop
xlocmdd                   move.l      (sp)+,d0
                          rts
relocdmp                  move.l      -4(a0),d3
                          beq.s       xlocdmp
                          exg.l       a0,d3
                          addq.l      #4,a0
                          bsr         relocentr
                          move.l      d3,a0
xlocdmp                   rts

;============================================================================

relocbi                   move.w      msng_numblocks(a1),d0
                          move.l      a0,a3
biloop                    subq.w      #1,d0
                          bmi.s       xlocdmp
                          move.l      -(a3),a0
                          addq.l      #4,a0
                          bsr         relocentr
                          tst.l       -(a0)
                          beq.s       biloop
                          move.l      (a0),a0
                          bsr         relocentr
                          bsr         relocentr
                          addq.l      #4,a0
                          bsr         relocentr
                          tst.l       -(a0)
                          bne.s       relocpgtbl
                          bra.s       biloop
relocmmd2sng              move.l      mmd_songinfo(a2),a0
                          lea         msng_pseqs(a0),a0
                          bsr         relocentr
                          bsr         relocentr
                          bsr         relocentr
                          move.w      2(a0),d0
                          move.l      -12(a0),a0
                          subq.w      #1,d0
psqtblloop                bsr         relocentr
                          dbf         d0,psqtblloop
                          rts

;============================================================================

relocpgtbl                movea.l     (a0),a4
                          move.w      (a4),d2
                          subq.w      #1,d2
                          lea         4(a4),a0
pgtblloop                 bsr         relocentr
                          dbf         d2,pgtblloop
                          bra         biloop
                          ENDC

; -------- _ChannelOff: Turn off a channel -------------------------------
_ChannelOff:    ;d0 = channel #
                          lea         DB,a0
                          lea         trackdataptrs-DB(a0),a1
                          lsl.w       #2,d0
                          adda.w      d0,a1
                          lsr.w       #2,d0
                          movea.l     (a1),a1
                          move.b      trk_outputdev(a1),d1
                          IFNE        AURA
                          beq.s       choff_outstd
                          subq.b      #1,d1
                          bne.s       notamigatrk                                                                  ;unknown type... do nothing
                          jmp         _StopAura(pc)                                                                ;AURA off
choff_outstd
                          ENDC
                          IFEQ        AURA
                          bne.s       notamigatrk
                          ENDC
                          IFNE        MIDI
                          move.b      trk_prevmidin(a1),d1                                                         ;first: is it MIDI??
                          beq.s       notcomidi                                                                    ;not a midi note
; -------- TURN OFF MIDI TRACK -------------------------------------------
                          lea         noteondata-DB(a0),a0
choff_midi:               clr.b       trk_prevmidin(a1)
                          move.b      d1,1(a0)
                          bmi.s       notamigatrk
                          move.b      trk_prevmidich(a1),(a0)                                                      ;prev midi channel
                          clr.b       2(a0)
                          or.b        #$90,(a0)                                                                    ;note off
                          moveq       #3,d0
                          bra.w       _AddMIDIData
                          ENDC
notcomidi:                cmp.b       #4,d0
                          bge.s       notamigatrk
; -------- TURN OFF AMIGA-CHANNEL ----------------------------------------
                          IFNE        SYNTH
                          clr.l       trk_synthptr(a1)
                          clr.b       trk_synthtype(a1)
                          ENDC
                          clr.w       trk_soffset(a1)
                          moveq       #1,d1
                          lsl.w       d0,d1
                          move.w      d1,$dff096
notamigatrk:              rts

;============================================================================
; -------- SoundOff: Turn off all channels -------------------------------

SoundOff:                 move.l      d2,-(sp)
                          moveq       #MAX_NUMTRACKS-1,d2
SO_loop0                  move.l      d2,d0
                          bsr.s       _ChannelOff
                          dbf         d2,SO_loop0
                          clr.l       _module                                                                      ;play nothing
                          move.l      (sp)+,d2
SO_rts                    rts

;============================================================================
; -------- _PlayNote: The note playing routine ---------------------------

_PlayNote:  ;d7(w) = trk #, d1 = note #, d3(w) = instr # a3 = addr of instr
; -------- CHECK INSTRUMENT (existence, type) ----------------------------
                          move.l      a3,d4
                          beq.s       SO_rts
                          moveq       #0,d4
                          bset        d7,d4                                                                        ;d4 is mask for this channel
                          movea.l     mmd_smplarr(a2),a0
                          add.w       d3,d3                                                                        ;d3 = instr.num << 2
                          add.w       d3,d3
                          move.l      0(a0,d3.w),d5                                                                ;get address of instrument
                          IFNE        MIDI
                          bne.s       inmem
                          tst.b       inst_midich(a3)                                                              ;is MIDI channel set?
                          ENDC
                          IFNE        CHECK
                          beq.w       pnote_rts                                                                    ; NO!!!
                          ENDC
; -------- ADD TRANSPOSE -------------------------------------------------
inmem                     add.b       msng_playtransp(a4),d1                                                       ;add play transpose
                          add.b       inst_strans(a3),d1                                                           ;and instr. transpose
                          IFNE        AURA
                          cmp.w       #3,d7
                          bne.s       pn_norelch3
                          tst.b       playing_aura-DB(a6)
                          bne.s       pn_offaura
pn_norelch3
                          ENDC
                          move.b      trk_outputdev(a5),d3
                          beq.s       pn_offami
                          IFNE        AURA
                          subq.b      #1,d3
                          bne.s       noprevmidi
pn_offaura                jsr         _StopAura(pc)
                          ENDC
                          bra.s       noprevmidi                                                                   ;dunno.. unsupported type
    
; -------- TURN OFF CHANNEL DMA, IF REQUIRED -----------------------------
pn_offami                 cmp.b       #4,d7
                          bge.s       nodmaoff                                                                     ;track #�>= 4: not an Amiga channel
                          move.l      d5,a1
                          IFNE        SYNTH
                          tst.l       d5
                          beq.s       stpdma
                          tst.b       trk_synthtype(a5)
                          ble.s       stpdma                                                                       ;prev. type = sample/hybrid
                          cmp.w       #-1,4(a1)                                                                    ;type == SYNTHETIC??
                          beq.s       nostpdma
                          ENDC
stpdma:                   move.w      d4,$dff096                                                                   ;stop this channel (dmacon)
nostpdma:
                          IFNE        SYNTH
                          clr.l       trk_synthptr(a5)
                          ENDC
nodmaoff:                 subq.b      #1,d1
                          IFNE        MIDI
; -------- KILL PREVIOUS MIDI NOTE ---------------------------------------
                          move.b      trk_prevmidin(a5),d3                                                         ;get prev. midi note
                          beq.s       noprevmidi
                          clr.b       trk_prevmidin(a5)
                          lea         noteondata+2-DB(a6),a0
                          clr.b       (a0)
                          move.b      d3,-(a0)
                          bmi.s       noprevmidi
                          move.b      trk_prevmidich(a5),-(a0)                                                     ;prev midi channel
                          or.b        #$90,(a0)                                                                    ;note off
                          move.w      d1,-(sp)
                          moveq       #3,d0
                          bsr.w       _AddMIDId
                          move.w      (sp)+,d1
noprevmidi
; -------- IF MIDI NOTE, CALL MIDI NOTE ROUTINE --------------------------
                          tst.b       inst_midich(a3)
                          bne.w       handleMIDInote
                          ENDC
; -------- TEST OUTPUT DEVICE AND BRANCH IF NOT STD ----------------------
                          IFEQ        MIDI
noprevmidi
                          ENDC
                          tst.b       trk_outputdev(a5)
                          bne.w       handlenonstdout
; -------- SET SOME AMIGA-CHANNEL PARAMETERS -----------------------------
                          IFNE        CHECK
                          cmp.w       #4,d7                                                                        ;track > 3???
                          bge.w       pnote_rts                                                                    ;no Amiga instruments here!!!
                          ENDC
; handle decay (for tracks 0 - 3 only!!)
                          IFNE        HOLD
                          clr.b       trk_fadespd(a5)                                                              ;no fade yet..
                          move.b      trk_initdecay(a5),trk_decay(a5)                                              ;set decay
                          ENDC
                          clr.w       trk_vibroffs(a5)                                                             ;clr vibrato/tremolo offset
                          or.w        d4,dmaonmsk-DB(a6)
                          move.l      d5,a0
                          IFNE        SYNTH
; -------- IF SYNTH NOTE, CALL SYNTH ROUTINE -----------------------------
                          tst.w       4(a0)
                          bmi.w       handleSynthnote
                          clr.b       trk_synthtype(a5)
                          ENDC
; -------- CHECK NOTE RANGE ----------------------------------------------
tlwtst0                   tst.b       d1
                          bpl.s       notenot2low
                          add.b       #12,d1                                                                       ;note was too low, octave up
                          bra.s       tlwtst0
notenot2low               cmp.b       #62,d1
                          ble.s       endpttest
                          sub.b       #12,d1                                                                       ;note was too high, octave down
endpttest
                          moveq       #0,d2
                          moveq       #0,d3
                          moveq       #6,d4                                                                        ;skip (stereo+hdr) offset
                          lea         _periodtable+32-DB(a6),a1
                          move.b      trk_finetune(a5),d2                                                          ;finetune value
                          add.b       d2,d2
                          add.b       d2,d2                                                                        ;multiply by 4...
                          ext.w       d2                                                                           ;extend
                          movea.l     0(a1,d2.w),a1                                                                ;period table address
                          move.w      4(a0),d0                                                                     ;(Instr hdr in a0)
                          btst        #5,d0
                          beq.s       gid_nostereo
                          move.b      d7,d5
                          and.b       #3,d5
                          beq.s       gid_nostereo                                                                 ;ch 0/4 = play left (norm.)
                          cmp.b       #3,d5
                          beq.s       gid_nostereo                                                                 ;also for ch 3/7
                          add.l       (a0),d4                                                                      ;play right channel
gid_nostereo
                          IFNE        IFFMOCT
                          and.w       #$F,d0
                          bne.s       gid_notnormal                                                                ;note # in d1 (0 - ...)
                          ENDC
gid_cont_ext              move.l      a1,trk_periodtbl(a5)
                          add.b       d1,d1
                          move.w      0(a1,d1.w),d5                                                                ;put period to d5
                          move.l      a0,d0
                          move.l      (a0),d1                                                                      ;length
                          add.l       d4,d0                                                                        ;skip hdr and stereo
                          add.l       d0,d1                                                                        ;sample end pointer
                          move.w      inst_repeat(a3),d2
                          move.w      inst_replen(a3),d3
                          IFNE        IFFMOCT
                          bra         gid_setrept
gid_addtable              dc.b        0,6,12,18,24,30
gid_divtable              dc.b        31,7,3,15,63,127
gid_notnormal             cmp.w       #7,d0
                          blt.s       gid_not_ext
                          suba.w      #48,a1
                          bra.s       gid_cont_ext
gid_not_ext               move.l      d7,-(sp)
                          moveq       #0,d7
                          move.w      d1,d7
                          divu        #12,d7                                                                       ;octave #
                          move.l      d7,d5
                          cmp.w       #6,d7                                                                        ;if oct > 5, oct = 5
                          blt.s       nohioct
                          moveq       #5,d7
nohioct                   swap        d5                                                                           ;note number in this oct (0-11) is in d5
                          move.l      (a0),d1
                          cmp.w       #6,d0
                          ble.s       nounrecit
                          moveq       #6,d0
nounrecit                 add.b       gid_addtable-1(pc,d0.w),d7
                          move.b      gid_divtable-1(pc,d0.w),d0
                          divu        d0,d1                                                                        ;get length of the highest octave
                          swap        d1
                          clr.w       d1
                          swap        d1
                          move.l      d1,d0                                                                        ;d0 and d1 = length of the 1st oct
                          move.w      inst_repeat(a3),d2
                          move.w      inst_replen(a3),d3
                          moveq       #0,d6
                          move.b      shiftcnt(pc,d7.w),d6
                          lsl.w       d6,d2
                          lsl.w       d6,d3
                          lsl.w       d6,d1
                          move.b      mullencnt(pc,d7.w),d6
                          mulu        d6,d0                                                                        ;offset of this oct from 1st oct
                          add.l       a0,d0                                                                        ;add base address to offset
                          add.l       d4,d0                                                                        ;skip header + stereo
                          add.l       d0,d1
                          move.l      a1,trk_periodtbl(a5)
                          add.b       octstart(pc,d7.w),d5
                          add.b       d5,d5
                          move.w      0(a1,d5.w),d5
                          move.l      (sp)+,d7
                          bra.s       gid_setrept
shiftcnt:                 dc.b        4,3,2,1,1,0,2,2,1,1,0,0,1,1,0,0,0,0
                          dc.b        3,3,2,2,1,0,5,4,3,2,1,0,6,5,4,3,2,1
mullencnt:                dc.b        15,7,3,1,1,0,3,3,1,1,0,0,1,1,0,0,0,0
                          dc.b        7,7,3,3,1,0,31,15,7,3,1,0,63,31,15,7,3,1
octstart:                 dc.b        12,12,12,12,24,24,0,12,12,24,24,36,0,12,12,24,36,36
                          dc.b        0,12,12,24,24,24,12,12,12,12,12,12,12,12,12,12,12,12
                          ENDC
gid_setrept               add.l       d2,d2
                          add.l       d0,d2                                                                        ;rep. start pointer
                          cmp.w       #1,d3
                          bhi.s       gid_noreplen2
                          moveq       #0,d3                                                                        ;no repeat
                          bra.s       gid_cont
gid_noreplen2             add.l       d3,d3
                          add.l       d2,d3                                                                        ;rep. end pointer

; -------- CALCULATE START/END ADDRESSES ---------------------------------
gid_cont                  moveq       #0,d4
                          move.w      trk_soffset(a5),d4
                          add.l       d4,d0
                          cmp.l       d0,d1
                          bhi.s       pn_nooffsovf
                          sub.l       d4,d0
pn_nooffsovf              movea.l     trk_audioaddr(a5),a1                                                         ;base of this channel's regs
                          move.l      d0,(a1)+                                                                     ;push ac_ptr
                          moveq       #0,d4
                          move.b      trk_previnstr(a5),d4
                          lea         flags-DB(a6),a0
                          btst        #0,0(a0,d4.w)                                                                ;test flags.SSFLG_LOOP
                          bne.s       repeat
        
                          move.l      #_chipzero,trk_sampleptr(a5)                                                 ;pointer of zero word
                          move.w      #1,trk_samplelen(a5)                                                         ;length: 1 word
                          sub.l       d0,d1
                          lsr.l       #1,d1                                                                        ;shift length right
                          move.w      d1,(a1)+                                                                     ;and push to ac_len
                          bra.s       retsn1

repeat                    move.l      d2,trk_sampleptr(a5)
                          move.l      d3,d1
                          sub.l       d0,d1
                          lsr.l       #1,d1
                          move.w      d1,(a1)+                                                                     ;ac_len
                          sub.l       d2,d3
                          lsr.l       #1,d3
                          move.w      d3,trk_samplelen(a5)
                
retsn1                    move.w      d5,trk_prevper(a5)
                          IFNE        SYNTH
                          tst.b       trk_synthtype(a5)
                          bne.w       hSn2
                          ENDC
pnote_rts                 rts

;============================================================================

handlenonstdout
                          IFNE        AURA
                          move.b      trk_outputdev(a5),d0
                          subq.b      #1,d0
                          bne.s       hnso_notaura
; -------- AURA NOTE PLAYER ROUTINE --------------------------------------
;   a0 = sample pointer, already set
                          moveq       #0,d0
                          move.w      trk_soffset(a5),d0
                          lea         _periodtable+32-DB(a6),a1
                          move.b      trk_finetune(a5),d2                                                          ;finetune value
                          add.b       d2,d2
                          add.b       d2,d2
                          ext.w       d2
                          movea.l     0(a1,d2.w),a1                                                                ;period table address
                          add.b       d1,d1
                          move.w      0(a1,d1.w),d1
                          moveq       #0,d2                                                                        ;end offset = 0
                          jsr         _PlayAura(pc)
hnso_notaura
                          ENDC
                          rts

;============================================================================

                          IFNE        MIDI
; -------- MIDI NOTE PLAYER ROUTINE --------------------------------------
handleMIDInote:
                          IFNE        PLAYMMD0
                          cmp.b       #'1',3(a2)
                          bge.s       plr_mmd1_3
                          add.b       #24,d1
plr_mmd1_3
                          ENDC
; -------- CHECK & SCALE VOLUME ------------------------------------------
                          move.b      trk_prevvol(a5),d2                                                           ;temporarily save the volume
                          IFNE        RELVOL
; -------- GetRelVol: Calculate track volume -----------------------------
                          ext.w       d2
                          mulu        trk_trackvol(a5),d2
                          lsr.w       #7,d2
                          ENDC
                          IFEQ        RELVOL
                          lsl.b       #1,d2
                          ENDC
                          subq.b      #1,d2                                                                        ;if 128 => 127
                          bpl.s       hmn_notvolu0
                          moveq       #0,d2
hmn_notvolu0
                          moveq       #0,d5
; -------- CHECK MIDI CHANNEL --------------------------------------------
                          move.b      inst_midich(a3),d5                                                           ;get midi chan of this instrument
                          bpl.s       hmn_nosmof                                                                   ;bit 7 clear
                          clr.b       trk_prevmidin(a5)                                                            ;suppress note off!
                          bra.s       hmn_smof
hmn_nosmof                move.b      d1,trk_prevmidin(a5)
hmn_smof                  and.b       #$1F,d5                                                                      ;clear all flag bits etc...
                          subq.b      #1,d5                                                                        ;from 1-16 to 0-15
                          move.b      d5,trk_prevmidich(a5)                                                        ;save to prev midi channel

; -------- CHECK MIDI PRESET ---------------------------------------------
                          moveq       #0,d0
                          move.b      trk_previnstr(a5),d0
                          add.w       d0,d0
                          lea         ext_midipsets-DB(a6),a1
                          move.w      0(a1,d0.w),d0                                                                ;get preset #
                          beq.s       nochgpres                                                                    ;zero = no preset
                          lea         prevmidicpres-DB(a6),a1
                          adda.w      d5,a1
                          adda.w      d5,a1
                          cmp.w       (a1),d0                                                                      ;is this previous preset ??
                          beq.s       nochgpres                                                                    ;yes...no need to change
                          move.w      d0,(a1)                                                                      ;save preset to prevmidicpres
                          subq.w      #1,d0                                                                        ;sub 1 to get 0 - 127
                          btst        #6,inst_midich(a3)
                          bne.s       hmn_extpreset
; -------- PREPARE PRESET CHANGE COMMAND ---------------------------------
hmn_ordpreset             lea         preschgdata+1-DB(a6),a0
                          move.b      d0,(a0)                                                                      ;push the number to second byte
                          moveq       #2,d0
hmn_sendpreset            move.b      #$c0,-(a0)                                                                   ;command: $C
                          or.b        d5,(a0)                                                                      ;"or" midi channel
                          move.w      d1,-(sp)
                          bsr.w       _AddMIDId
                          move.w      (sp)+,d1
                          tst.b       d2
                          beq.s       hmn_suppress                                                                 ;vol = 0, don't send NOTE ON

; -------- PREPARE & SEND NOTE ON COMMAND --------------------------------
nochgpres                 lea         bytesinnotebuff-DB(a6),a0
                          movea.l     a0,a1
                          adda.w      (a0)+,a0
                          or.b        #$90,d5                                                                      ;MIDI: Note on
                          move.b      d5,(a0)+                                                                     ;MIDI msg Note on & channel
                          move.b      d1,(a0)+                                                                     ;MIDI msg note #
                          move.b      d2,(a0)                                                                      ;MIDI msg volume
                          beq.s       hmn_suppress                                                                 ;vol = 0 -> no note
                          addq.w      #3,(a1)
                          rts
hmn_suppress              st          trk_prevmidin(a5)
                          rts

;============================================================================
; -------- HANDLE EXTENDED PRESET ----------------------------------------

hmn_extpreset             cmp.w       #100,d0
                          blt.s       hmn_ordpreset
                          moveq       #99,d3
hmn_loop100               sub.w       #100,d0
                          addq.b      #1,d3
                          cmp.w       #100,d0
                          bge.s       hmn_loop100
                          lea         preschgdata+2-DB(a6),a0
                          move.b      d0,(a0)                                                                      ;push the <= 99 number
                          move.b      d3,-(a0)                                                                     ;push the >= 100 number
                          moveq       #3,d0
                          bra.s       hmn_sendpreset
                          ENDC

                          IFNE        SYNTH
; -------- TRIGGER SYNTH NOTE, CLEAR PARAMETERS --------------------------
handleSynthnote           move.b      d1,trk_prevnote2(a5)
                          move.l      a0,trk_synthptr(a5)
                          cmp.w       #-2,4(a0)                                                                    ;HYBRID??
                          bne.s       hSn_nossn
                          st          trk_synthtype(a5)
                          movea.l     278(a0),a0                                                                   ;yep, get the waveform pointer
                          bra.w       tlwtst0                                                                      ;go and play it
hSn_nossn:                move.b      #1,trk_synthtype(a5)
                          lea         _periodtable+32-DB(a6),a1
                          move.b      trk_finetune(a5),d0                                                          ;finetune value
                          add.b       d0,d0
                          add.b       d0,d0                                                                        ;multiple by 4...
                          ext.w       d0                                                                           ;extend
                          movea.l     0(a1,d0.w),a1                                                                ;period table address
                          suba.w      #48,a1
                          move.l      a1,trk_periodtbl(a5)                                                         ;save table ptr for synth periods
                          add.w       d1,d1
                          move.w      0(a1,d1.w),d1
                          move.w      d1,trk_prevper(a5)
                          clr.l       trk_sampleptr(a5)
hSn2:                     lea         trk_arpgoffs(a5),a1
                          clr.l       (a1)+
                          clr.l       (a1)+
                          btst        #0,trk_miscflags(a5)
                          bne.s       hSn_cmdE                                                                     ;cmd E given, don't clear trk_wfcmd!
                          clr.w       (a1)
hSn_cmdE                  addq.l      #2,a1
                          clr.w       (a1)+
                          clr.l       (a1)+
                          clr.l       (a1)+
                          clr.l       (a1)+
                          move.l      #sinetable,(a1)+
                          clr.w       (a1)+
                          movea.l     trk_synthptr(a5),a0
                          move.w      18(a0),(a1)+
                          clr.b       (a1)
                          moveq       #64,d4
                          rts

;============================================================================

synth_start               move.w      trk_prevper(a5),d5
synth_start2              move.l      a3,-(sp)                                                                     ;d0 = SynthPtr
                          move.l      d0,a0
                          movea.l     trk_audioaddr(a5),a3                                                         ;audio channel base address
; -------- SYNTHSOUND VOLUME SEQUENCE HANDLING ---------------------------
                          subq.b      #1,trk_volxcnt(a5)                                                           ;decrease execute counter..
                          bgt.w       synth_wftbl                                                                  ;not 0...go to waveform
                          move.b      trk_initvolxspd(a5),trk_volxcnt(a5)                                          ;reset counter
                          move.b      trk_volchgspd(a5),d0                                                         ;volume change??
                          beq.s       synth_nochgvol                                                               ;no.
                          add.b       trk_synvol(a5),d0                                                            ;add previous volume
                          bpl.s       synth_voln2l                                                                 ;not negative
                          moveq       #0,d0                                                                        ;was negative => 0
synth_voln2l              cmp.b       #$40,d0                                                                      ;too high??
                          ble.s       synth_voln2h                                                                 ;not 2 high.
                          moveq       #$40,d0                                                                      ;was 2 high => 64
synth_voln2h              move.b      d0,trk_synvol(a5)                                                            ;remember new...
synth_nochgvol            move.l      trk_envptr(a5),d1                                                            ;envelope pointer
                          beq.s       synth_novolenv
                          movea.l     d1,a1
                          move.b      (a1)+,d0
                          add.b       #128,d0
                          lsr.b       #2,d0
                          move.b      d0,trk_synvol(a5)
                          addq.b      #1,trk_envcount(a5)
                          bpl.s       synth_endenv
                          clr.b       trk_envcount(a5)
                          move.l      trk_envrestart(a5),a1
synth_endenv              move.l      a1,trk_envptr(a5)
synth_novolenv            move.w      trk_volcmd(a5),d0                                                            ;get table position ptr
                          tst.b       trk_volwait(a5)                                                              ;WAI(t) active
                          beq.s       synth_getvolcmd                                                              ;no
                          subq.b      #1,trk_volwait(a5)                                                           ;yep, decr wait ctr
                          ble.s       synth_getvolcmd                                                              ;0 => continue
                          bra.w       synth_wftbl                                                                  ;> 0 => still wait
synth_inccnt              addq.b      #1,d0
synth_getvolcmd           addq.b      #1,d0                                                                        ;advance pointer
                          move.b      21(a0,d0.w),d1                                                               ;get command
                          bmi.s       synth_cmd                                                                    ;negative = command
                          move.b      d1,trk_synvol(a5)                                                            ;set synthvol
                          bra.w       synth_endvol                                                                 ;end of volume executing
synth_cmd                 and.w       #$000f,d1
                          add.b       d1,d1
                          move.w      synth_vtbl(pc,d1.w),d1
                          jmp         syv(pc,d1.w)
synth_vtbl                dc.w        syv_f0-syv,syv_f1-syv,syv_f2-syv,syv_f3-syv
                          dc.w        syv_f4-syv,syv_f5-syv,syv_f6-syv
                          dc.w        synth_endvol-syv,synth_endvol-syv,synth_endvol-syv
                          dc.w        syv_fa-syv,syv_ff-syv,synth_endvol-syv
                          dc.w        synth_endvol-syv,syv_fe-syv,syv_ff-syv
; -------- VOLUME SEQUENCE COMMANDS --------------------------------------
syv
syv_fe                    move.b      22(a0,d0.w),d0                                                               ;JMP
                          bra.s       synth_getvolcmd
syv_f0                    move.b      22(a0,d0.w),trk_initvolxspd(a5)                                              ;change volume ex. speed
                          bra.s       synth_inccnt
syv_f1                    move.b      22(a0,d0.w),trk_volwait(a5)                                                  ;WAI(t)
                          addq.b      #1,d0
                          bra.s       synth_endvol
syv_f3                    move.b      22(a0,d0.w),trk_volchgspd(a5)                                                ;set volume slide up
                          bra.s       synth_inccnt
syv_f2                    move.b      22(a0,d0.w),d1
                          neg.b       d1
                          move.b      d1,trk_volchgspd(a5)                                                         ;set volume slide down
                          bra.s       synth_inccnt
syv_fa                    move.b      22(a0,d0.w),trk_wfcmd+1(a5)                                                  ;JWS (jump wform sequence)
                          clr.b       trk_wfwait(a5)
                          bra.s       synth_inccnt
syv_f4                    move.b      22(a0,d0.w),d1
                          bsr.s       synth_getwf
                          clr.l       trk_envrestart(a5)
syv_f4end                 move.l      a1,trk_envptr(a5)
                          clr.b       trk_envcount(a5)
                          bra.w       synth_inccnt
syv_f5                    move.b      22(a0,d0.w),d1
                          bsr.s       synth_getwf
                          move.l      a1,trk_envrestart(a5)
                          bra.s       syv_f4end
syv_f6                    clr.l       trk_envptr(a5)
                          bra.w       synth_getvolcmd
synth_getwf               ext.w       d1                                                                           ;d1 = wform number, returns ptr in a1
                          add.w       d1,d1                                                                        ;create index
                          add.w       d1,d1
                          lea         278(a0),a1
                          adda.w      d1,a1
                          movea.l     (a1),a1                                                                      ;get wform address
                          addq.l      #2,a1                                                                        ;skip length
                          rts

;============================================================================

syv_ff                    subq.b      #1,d0
synth_endvol              move.w      d0,trk_volcmd(a5)
synth_wftbl               move.b      trk_synvol(a5),trk_prevvol(a5)
                          adda.w      #158,a0
; -------- SYNTHSOUND WAVEFORM SEQUENCE HANDLING -------------------------
                          subq.b      #1,trk_wfxcnt(a5)                                                            ;decr. wf speed counter
                          bgt.w       synth_arpeggio                                                               ;not yet...
                          move.b      trk_initwfxspd(a5),trk_wfxcnt(a5)                                            ;restore speed counter
                          move.w      trk_wfcmd(a5),d0                                                             ;get table pos offset
                          move.w      trk_wfchgspd(a5),d1                                                          ;CHU/CHD ??
                          beq.s       synth_tstwfwai                                                               ;0 = no change
wytanwet                  add.w       trk_perchg(a5),d1                                                            ;add value to current change
                          move.w      d1,trk_perchg(a5)                                                            ;remember amount of change
synth_tstwfwai            tst.b       trk_wfwait(a5)                                                               ;WAI ??
                          beq.s       synth_getwfcmd                                                               ;not waiting...
                          subq.b      #1,trk_wfwait(a5)                                                            ;decr wait counter
                          beq.s       synth_getwfcmd                                                               ;waiting finished
                          bra.w       synth_arpeggio                                                               ;still sleep...
synth_incwfc              addq.b      #1,d0
synth_getwfcmd            addq.b      #1,d0                                                                        ;advance position counter
                          move.b      -9(a0,d0.w),d1                                                               ;get command
                          bmi.s       synth_wfcmd                                                                  ;negative = command
                          ext.w       d1
                          add.w       d1,d1
                          add.w       d1,d1
                          movea.l     120(a0,d1.w),a1
                          move.w      (a1)+,ac_len(a3)                                                             ;push waveform length
                          move.l      a1,ac_ptr(a3)                                                                ;and the new pointer
                          bra.w       synth_wfend                                                                  ;no new commands now...
synth_wfcmd               and.w       #$000f,d1                                                                    ;get the right nibble
                          add.b       d1,d1                                                                        ;* 2
                          move.w      synth_wfctbl(pc,d1.w),d1
                          jmp         syw(pc,d1.w)                                                                 ;jump to command
synth_wfctbl              dc.w        syw_f0-syw,syw_f1-syw,syw_f2-syw,syw_f3-syw,syw_f4-syw
                          dc.w        syw_f5-syw,syw_f6-syw,syw_f7-syw,synth_wfend-syw
                          dc.w        synth_wfend-syw,syw_fa-syw,syw_ff-syw
                          dc.w        syw_fc-syw,synth_getwfcmd-syw,syw_fe-syw,syw_ff-syw
; -------- WAVEFORM SEQUENCE COMMANDS ------------------------------------
syw
syw_f7                    move.b      -8(a0,d0.w),d1
                          ext.w       d1
                          add.w       d1,d1
                          add.w       d1,d1
                          movea.l     120(a0,d1.w),a1
                          addq.l      #2,a1
                          move.l      a1,trk_synvibwf(a5)
                          bra.s       synth_incwfc
syw_fe                    move.b      -8(a0,d0.w),d0                                                               ;jump (JMP)
                          bra.s       synth_getwfcmd
syw_fc                    move.w      d0,trk_arpsoffs(a5)                                                          ;new arpeggio begin
                          move.w      d0,trk_arpgoffs(a5)
synth_findare             addq.b      #1,d0
                          tst.b       -9(a0,d0.w)
                          bpl.s       synth_findare
                          bra.s       synth_getwfcmd
syw_f0                    move.b      -8(a0,d0.w),trk_initwfxspd(a5)                                               ;new waveform speed
                          bra         synth_incwfc
syw_f1                    move.b      -8(a0,d0.w),trk_wfwait(a5)                                                   ;wait waveform
                          addq.b      #1,d0
                          bra.s       synth_wfend
syw_f4                    move.b      -8(a0,d0.w),trk_synvibdep+1(a5)                                              ;set vibrato depth
                          bra.w       synth_incwfc
syw_f5                    move.b      -8(a0,d0.w),trk_synthvibspd+1(a5)                                            ;set vibrato speed
                          addq.b      #1,trk_synthvibspd+1(a5)
                          bra.w       synth_incwfc
syw_f2                    moveq       #0,d1                                                                        ;set slide down
                          move.b      -8(a0,d0.w),d1
synth_setsld              move.w      d1,trk_wfchgspd(a5)
                          bra.w       synth_incwfc
syw_f3                    move.b      -8(a0,d0.w),d1                                                               ;set slide up
                          neg.b       d1
                          ext.w       d1
                          bra.s       synth_setsld
syw_f6                    clr.w       trk_perchg(a5)                                                               ;reset period
                          move.w      trk_prevper(a5),d5
                          bra.w       synth_getwfcmd
syw_fa                    move.b      -8(a0,d0.w),trk_volcmd+1(a5)                                                 ;JVS (jump volume sequence)
                          clr.b       trk_volwait(a5)
                          bra.w       synth_incwfc
syw_ff                    subq.b      #1,d0                                                                        ;pointer = END - 1
synth_wfend               move.w      d0,trk_wfcmd(a5)
; -------- HANDLE SYNTHSOUND ARPEGGIO ------------------------------------
synth_arpeggio            move.w      trk_arpgoffs(a5),d0
                          beq.s       synth_vibrato
                          moveq       #0,d1
                          move.b      -8(a0,d0.w),d1
                          add.b       trk_prevnote2(a5),d1
                          movea.l     trk_periodtbl(a5),a1                                                         ;get period table
                          add.w       d1,d1
                          move.w      0(a1,d1.w),d5
                          addq.b      #1,d0
                          tst.b       -8(a0,d0.w)
                          bpl.s       synth_noarpres
                          move.w      trk_arpsoffs(a5),d0
synth_noarpres            move.w      d0,trk_arpgoffs(a5)
; -------- HANDLE SYNTHSOUND VIBRATO -------------------------------------
synth_vibrato             move.w      trk_synvibdep(a5),d1                                                         ;get vibrato depth
                          beq.s       synth_rts                                                                    ;0 => no vibrato
                          move.w      trk_synviboffs(a5),d0                                                        ;get offset
                          lsr.w       #4,d0                                                                        ;/ 16
                          and.w       #$1f,d0                                                                      ;sinetable offset (0-31)
                          movea.l     trk_synvibwf(a5),a0
                          move.b      0(a0,d0.w),d0                                                                ;get a byte
                          ext.w       d0                                                                           ;to word
                          muls        d1,d0                                                                        ;amplify (* depth)
                          asr.w       #8,d0                                                                        ;and divide by 64
                          add.w       d0,d5                                                                        ;add vibrato...
                          move.w      trk_synthvibspd(a5),d0                                                       ;vibrato speed
                          add.w       d0,trk_synviboffs(a5)                                                        ;add to offset
synth_rts                 add.w       trk_perchg(a5),d5
                          cmp.w       #113,d5                                                                      ;overflow??
                          bge.s       synth_pern2h
                          moveq       #113,d1
synth_pern2h              move.l      (sp)+,a3
                          rts
                          ENDC

sinetable                 dc.b        0,25,49,71,90,106,117,125,127,125,117,106,90,71,49
                          dc.b        25,0,-25,-49,-71,-90,-106,-117,-125,-127,-125,-117
                          dc.b        -106,-90,-71,-49,-25,0
                          even
                 
_IntHandler:              movem.l     d2-d7/a2-a6,-(sp)
                          IFNE        CIAB|VBLANK
                          movea.l     a1,a6                                                                        ;get data base address (int_Data)
                          ENDC
                          IFEQ        CIAB|VBLANK
                          lea         DB,a6                                                                        ;don't expect a1 to contain DB address
                          ENDC
                          tst.b       bpmcounter-DB(a6)
                          bmi.s       plr_nobpm
                          subq.b      #1,bpmcounter-DB(a6)
                          ble.s       plr_bpmcnt0
                          bra.w       plr_exit
plr_bpmcnt0               move.b      #4,bpmcounter-DB(a6)
plr_nobpm                 movea.l     _module-DB(a6),a2
                          move.l      a2,d0
                          beq.w       plr_exit
                          IFNE        MIDI
                          clr.b       lastcmdbyte-DB(a6)                                                           ;no MIDI optimization
                          ENDC
                          tst.w       mmd_pstate(a2)
                          beq.w       plr_exit
                          IFNE        MIDI
                          clr.l       dmaonmsk-DB(a6)
                          ENDC
                          IFEQ        MIDI
                          clr.w       dmaonmsk-DB(a6)
                          ENDC
                          movea.l     mmd_songinfo(a2),a4
                          moveq       #0,d3
                          move.b      mmd_counter(a2),d3
                          addq.b      #1,d3
                          cmp.b       msng_tempo2(a4),d3
                          bge.s       plr_pnewnote                                                                 ;play new note
                          move.b      d3,mmd_counter(a2)
                          bne.w       nonewnote                                                                    ;do just fx
; --- new note!!
plr_pnewnote:             clr.b       mmd_counter(a2)
                          tst.w       blkdelay-DB(a6)
                          beq.s       plr_noblkdelay
                          subq.w      #1,blkdelay-DB(a6)
                          bne.w       nonewnote
; --- now start to play it
; -------- GET ADDRESS OF NOTE DATA --------------------------------------
plr_noblkdelay            move.w      mmd_pblock(a2),d0
                          bsr.w       GetNoteDataAddr
                          moveq       #0,d7                                                                        ;number of track
                          moveq       #0,d4
                          IFNE        PLAYMMD0
                          cmp.b       #'1',3(a2)
                          sge         d5                                                                           ;d5 set -> >= MMD1
                          ENDC
                          lea         trackdataptrs-DB(a6),a1
; -------- TRACK LOOP (FOR EACH TRACK) -----------------------------------
plr_loop0:                movea.l     (a1)+,a5                                                                     ;get address of this track's struct
; ---------------- get the note numbers
                          moveq       #0,d3
                          IFNE        PLAYMMD0
                          tst.b       d5
                          bne.s       plr_mmd1_1
                          move.b      (a3)+,d0
                          move.b      (a3),d3
                          addq.l      #2,a3
                          lsr.b       #4,d3
                          bclr        #7,d0
                          beq.s       plr_bseti4
                          bset        #4,d3
plr_bseti4                bclr        #6,d0
                          beq.s       plr_bseti5
                          bset        #5,d3
plr_bseti5                move.b      d0,trk_currnote(a5)
                          beq.s       plr_nngok
                          move.b      d0,(a5)
                          bra.s       plr_nngok
plr_mmd1_1
                          ENDC
                          move.b      (a3)+,d0                                                                     ;get the number of this note
                          bpl.s       plr_nothinote
                          moveq       #0,d0
plr_nothinote             move.b      d0,trk_currnote(a5)
                          beq.s       plr_nosetprevn
                          move.b      d0,(a5)
plr_nosetprevn            move.b      (a3),d3                                                                      ;instrument number
                          addq.l      #3,a3                                                                        ;adv. to next track
; ---------------- check if there's an instrument number
plr_nngok                 and.w       #$3F,d3
                          beq.s       noinstnum
; ---------------- finally, save the number
                          subq.b      #1,d3
                          move.b      d3,trk_previnstr(a5)                                                         ;remember instr. number!
; ---------------- get the pointer of data's of this sample in Song-struct
                          move.w      d3,d0
                          asl.w       #3,d3
                          lea         0(a4,d3.w),a0                                                                ;a0 contains now address of it
                          move.l      a0,trk_previnstra(a5)
; ---------------- get volume
                          move.b      inst_svol(a0),trk_prevvol(a5)                                                ;vol of this instr
                          move.b      inst_strans(a0),trk_stransp(a5)
; ---------------- remember some values of this instrument
                          lea         holdvals-DB(a6),a0
                          adda.w      d0,a0
                          IFNE        HOLD
                          move.b      (a0),trk_inithold(a5)                                                        ;hold
                          move.b      63(a0),trk_initdecay(a5)                                                     ;decay
                          ENDC
                          move.b      2*63(a0),trk_finetune(a5)                                                    ;finetune
                          move.b      6*63(a0),trk_outputdev(a5)                                                   ;output dev
; ---------------- remember transpose
                          clr.w       trk_soffset(a5)                                                              ;sample offset
                          clr.b       trk_miscflags(a5)                                                            ;misc.
noinstnum                 addq.w      #1,d7
                          cmp.w       numtracks-DB(a6),d7
                          blt         plr_loop0
                          bsr.w       DoPreFXLoop
; -------- NOTE PLAYING LOOP ---------------------------------------------
                          moveq       #0,d7
                          lea         trackdataptrs-DB(a6),a1
plr_loop2                 movea.l     (a1)+,a5
                          tst.b       trk_fxtype(a5)
                          bne.s       plr_loop2_end
                          move.b      trk_currnote(a5),d1
                          beq.s       plr_loop2_end
; ---------------- play
                          move.l      a1,-(sp)
                          ext.w       d1
                          moveq       #0,d3
                          move.b      trk_previnstr(a5),d3                                                         ;instr #
                          movea.l     trk_previnstra(a5),a3                                                        ;instr data address
                          move.b      trk_inithold(a5),trk_noteoffcnt(a5)                                          ;initialize hold
                          bne.s       plr_nohold0                                                                  ;not 0 -> OK
                          st          trk_noteoffcnt(a5)                                                           ;0 -> hold = 0xff (-1)
; ---------------- and finally:
plr_nohold0               bsr         _PlayNote                                                                    ;play it
                          move.l      (sp)+,a1
plr_loop2_end             addq.w      #1,d7
                          cmp.w       numtracks-DB(a6),d7
                          blt.s       plr_loop2
; -------- THE REST... ---------------------------------------------------
                          bsr.s       AdvSngPtr
nonewnote                 bsr.w       DoFX
plr_endfx:                bsr         _StartDMA                                                                    ;turn on DMA
plr_exit:                 movem.l     (sp)+,d2-d7/a2-a6
                          IFNE        VBLANK
                          moveq       #0,d0
                          ENDC
                          rts

;============================================================================
; and advance song pointers

AdvSngPtr                 move.l      mmd_pblock(a2),fxplineblk-DB(a6)                                             ;store pline/block for fx
                          move.w      nextblockline-DB(a6),d1
                          beq.s       plr_advlinenum
                          clr.w       nextblockline-DB(a6)
                          subq.w      #1,d1
                          bra.s       plr_linenumset
plr_advlinenum            move.w      mmd_pline(a2),d1                                                             ;get current line #
                          addq.w      #1,d1                                                                        ;advance line number
plr_linenumset            cmp.w       numlines-DB(a6),d1                                                           ;advance block?
                          bhi.s       plr_chgblock                                                                 ;yes.
                          tst.b       nextblock-DB(a6)                                                             ;command F00/1Dxx?
                          beq.w       plr_nochgblock                                                               ;no, don't change block
; -------- CHANGE BLOCK? -------------------------------------------------
plr_chgblock              tst.b       nxtnoclrln-DB(a6)
                          bne.s       plr_noclrln
                          moveq       #0,d1                                                                        ;clear line number
plr_noclrln               tst.w       mmd_pstate(a2)                                                               ;play block or play song
                          bpl.w       plr_nonewseq                                                                 ;play block only...
                          cmp.b       #'2',3(a2)                                                                   ;MMD2?
                          bne.s       plr_noMMD2_0
; ********* BELOW CODE FOR MMD2 ONLY ************************************
; -------- CHANGE SEQUENCE -----------------------------------------------
plr_skipseq               move.w      mmd_pseq(a2),d0                                                              ;actually stored as << 2
                          movea.l     msng_pseqs(a4),a1                                                            ;ptr to playseqs
                          movea.l     0(a1,d0.w),a0                                                                ;a0 = ptr to curr PlaySeq
                          move.w      mmd_pseqnum(a2),d0                                                           ;get play sequence number
                          tst.b       nextblock-DB(a6)
                          bmi.s       plr_noadvseq                                                                 ;Bxx sets nextblock to -1
                          addq.w      #1,d0                                                                        ;advance sequence number
plr_noadvseq              cmp.w       40(a0),d0                                                                    ;is this the highest seq number??
                          blt.s       plr_notagain                                                                 ;no.
; -------- CHANGE SECTION ------------------------------------------------
                          move.w      mmd_psecnum(a2),d0                                                           ;get section number
                          addq.w      #1,d0                                                                        ;increase..
                          cmp.w       msng_songlen(a4),d0                                                          ;highest section?
                          blt.s       plr_nohisec
                          moveq       #0,d0                                                                        ;yes.
plr_nohisec               move.w      d0,mmd_psecnum(a2)                                                           ;push back.
                          add.w       d0,d0
                          movea.l     msng_sections(a4),a0                                                         ;section table
                          move.w      0(a0,d0.w),d0                                                                ;new playseqlist number
                          add.w       d0,d0
                          add.w       d0,d0
                          move.w      d0,mmd_pseq(a2)
                          movea.l     0(a1,d0.w),a0                                                                ;a0 = ptr to new PlaySeq
                          moveq       #0,d0                                                                        ;playseq OFFSET = 0
; -------- FETCH BLOCK NUMBER FROM SEQUENCE ------------------------------
plr_notagain              move.w      d0,mmd_pseqnum(a2)                                                           ;remember new playseq pos
                          add.w       d0,d0
                          move.w      42(a0,d0.w),d0                                                               ;get number of the block
                          bpl.s       plr_changeblk                                                                ;neg. values for future expansion
                          bra.s       plr_skipseq                                                                  ;(skip them)
; ********* BELOW CODE FOR MMD0/MMD1 ONLY *******************************
plr_noMMD2_0              move.w      mmd_pseqnum(a2),d0                                                           ;get play sequence number
                          tst.b       nextblock-DB(a6)
                          bmi.s       plr_noadvseq_b                                                               ;Bxx sets nextblock to -1
                          addq.w      #1,d0                                                                        ;advance sequence number
plr_noadvseq_b            cmp.w       msng_songlen(a4),d0                                                          ;is this the highest seq number??
                          blt.s       plr_notagain_b                                                               ;no.
                          moveq       #0,d0                                                                        ;yes: restart song
plr_notagain_b            move.b      d0,mmd_pseqnum+1(a2)                                                         ;remember new playseq-#
                          lea         msng_playseq(a4),a0                                                          ;offset of sequence table
                          move.b      0(a0,d0.w),d0                                                                ;get number of the block
; ********* BELOW CODE FOR BOTH FORMATS *********************************
plr_changeblk
                          IFNE        CHECK
                          cmp.w       msng_numblocks(a4),d0                                                        ;beyond last block??
                          blt.s       plr_nolstblk                                                                 ;no..
                          moveq       #0,d0                                                                        ;play block 0
                          ENDC
plr_nolstblk              move.w      d0,mmd_pblock(a2)                                                            ;store block number
plr_nonewseq              clr.w       nextblock-DB(a6)                                                             ;clear this if F00 set it
; ------------------------------------------------------------------------
plr_nochgblock            move.w      d1,mmd_pline(a2)                                                             ;set new line number

                          IFNE        HOLD
                          lea         trackdataptrs-DB(a6),a5
                          move.w      mmd_pblock(a2),d0                                                            ;pblock
                          bsr.w       GetBlockAddr
                          move.w      mmd_pline(a2),d0                                                             ;play line
                          move.b      msng_tempo2(a4),d3                                                           ;interrupts/note
                          IFNE        PLAYMMD0
                          cmp.b       #'1',3(a2)
                          bge.s       plr_mmd1_2
                          move.b      (a0),d7                                                                      ;# of tracks
                          move.w      d0,d1
                          add.w       d0,d0                                                                        ;d0 * 2
                          add.w       d1,d0                                                                        ;+ d0 = d0 * 3
                          mulu        d7,d0
                          lea         2(a0,d0.w),a3
                          subq.b      #1,d7
plr_chkholdb              movea.l     (a5)+,a1                                                                     ;track data
                          tst.b       trk_noteoffcnt(a1)                                                           ;hold??
                          bmi.s       plr_holdendb                                                                 ;no.
                          move.b      (a3),d1                                                                      ;get the 1st byte..
                          bne.s       plr_hold1b
                          move.b      1(a3),d1
                          and.b       #$f0,d1
                          beq.s       plr_holdendb                                                                 ;don't hold
                          bra.s       plr_hold2b
plr_hold1b                and.b       #$3f,d1                                                                      ;note??
                          beq.s       plr_hold2b                                                                   ;no, cont hold..
                          move.b      1(a3),d1
                          and.b       #$0f,d1                                                                      ;get cmd
                          subq.b      #3,d1                                                                        ;is there command 3 (slide)
                          bne.s       plr_holdendb                                                                 ;no -> end holding
plr_hold2b                add.b       d3,trk_noteoffcnt(a1)                                                        ;continue holding...
plr_holdendb              addq.l      #3,a3                                                                        ;next note
                          dbf         d7,plr_chkholdb
                          rts

;============================================================================

plr_mmd1_2
                          ENDC
                          move.w      (a0),d7                                                                      ;# of tracks
                          add.w       d0,d0
                          add.w       d0,d0                                                                        ;d0 = d0 * 4
                          mulu        d7,d0
                          lea         8(a0,d0.l),a3
                          subq.b      #1,d7
plr_chkhold               movea.l     (a5)+,a1                                                                     ;track data
                          tst.b       trk_noteoffcnt(a1)                                                           ;hold??
                          bmi.s       plr_holdend                                                                  ;no.
                          move.b      (a3),d1                                                                      ;get the 1st byte..
                          bne.s       plr_hold1
                          move.b      1(a3),d0
                          and.b       #$3F,d0
                          beq.s       plr_holdend                                                                  ;don't hold
                          bra.s       plr_hold2
plr_hold1                 and.b       #$7f,d1                                                                      ;note??
                          beq.s       plr_hold2                                                                    ;no, cont hold..
                          move.b      2(a3),d1
                          subq.b      #3,d1                                                                        ;is there command 3 (slide)
                          bne.s       plr_holdend                                                                  ;no -> end holding
plr_hold2                 add.b       d3,trk_noteoffcnt(a1)                                                        ;continue holding...
plr_holdend               addq.l      #4,a3                                                                        ;next note
                          dbf         d7,plr_chkhold
                          ENDC
                          rts

; *******************************************************************
; DoPreFXLoop:  Loop and call DoPreFX
; *******************************************************************
DoPreFXLoop:
; -------- PRE-FX COMMAND HANDLING LOOP ----------------------------------
                          moveq       #0,d5                                                                        ;command page count
plr_loop1                 move.w      mmd_pblock(a2),d0
                          bsr.w       GetBlockAddr
                          move.w      d5,d1
                          move.w      mmd_pline(a2),d2
                          bsr.w       GetCmdPointer
                          movea.l     a0,a3
                          moveq       #0,d7                                                                        ;clear track count
                          lea         trackdataptrs-DB(a6),a1
plr_loop1_1               movea.l     (a1)+,a5
                          clr.b       trk_fxtype(a5)
                          move.b      (a3),d0                                                                      ;command #
                          beq.s       plr_loop1_end
                          moveq       #0,d4
                          move.b      1(a3),d4                                                                     ;data byte
                          IFNE        PLAYMMD0
                          cmp.b       #3,d6                                                                        ;if adv == 3 -> MMD0
                          bne.s       doprefx_mmd12mask
                          and.w       #$0F,d0
                          bra.s       doprefx_mmd0maskd
doprefx_mmd12mask
                          ENDC
                          and.w       #$1F,d0
doprefx_mmd0maskd
                          bsr.s       DoPreFX
                          or.b        d0,trk_fxtype(a5)
plr_loop1_end             adda.w      d6,a3                                                                        ;next track...
                          addq.w      #1,d7
                          cmp.w       numtracks-DB(a6),d7
                          blt.s       plr_loop1_1
                          addq.w      #1,d5
                          cmp.w       numpages-DB(a6),d5
                          bls.s       plr_loop1
                          rts

; *******************************************************************
; DoPreFX: Perform effects that must be handled before note playing
; *******************************************************************
; args:     a6 = DB         d0 = command number (w)
;       a5 = track data     d5 = note number
;       a4 = song       d4 = data
;                   d7 = track #
; returns:  d0 = 0: play - d0 = 1: don't play

rtplay                    MACRO
                          moveq       #0,d0
                          rts
                          ENDM
rtnoplay                  MACRO
                          moveq       #1,d0
                          rts
                          ENDM

DoPreFX:                  add.b       d0,d0                                                                        ;* 2
                          move.w      f_table(pc,d0.w),d0
                          jmp         fst(pc,d0.w)
f_table                   dc.w        fx-fst,fx-fst,fx-fst,f_03-fst,fx-fst,fx-fst,fx-fst,fx-fst
                          dc.w        f_08-fst,f_09-fst,fx-fst,f_0b-fst,f_0c-fst,fx-fst,f_0e-fst,f_0f-fst
                          dc.w        fx-fst,fx-fst,fx-fst,fx-fst,fx-fst,f_15-fst,f_16-fst,fx-fst
                          dc.w        fx-fst,f_19-fst,fx-fst,fx-fst,f_1c-fst,f_1d-fst,f_1e-fst,f_1f-fst
fst
; ---------------- tempo (F)
f_0f                      tst.b       d4                                                                           ;test effect qual..
                          beq         fx0fchgblck                                                                  ;if effect qualifier (last 2 #'s)..
                          cmp.b       #$f0,d4                                                                      ;..is zero, go to next block
                          bhi.s       fx0fspecial                                                                  ;if it's F1-FF something special
; ---------------- just an ordinary "change tempo"-request
                          IFNE        CIAB
                          moveq       #0,d0                                                                        ;will happen!!!
                          move.b      d4,d0
                          bsr         _SetTempo                                                                    ;change The Tempo
                          ENDC
fx                        rtplay
; ---------------- no, it was FFx, something special will happen!!
fx0fspecial:              cmp.b       #$f2,d4
                          beq.s       f_1f
                          cmp.b       #$f4,d4
                          beq.s       f_1f
                          cmp.b       #$f5,d4
                          bne.s       isfxfe
; ---------------- FF2 (or 1Fxx)
f_1f
                          IFNE        HOLD
                          move.b      trk_inithold(a5),trk_noteoffcnt(a5)                                          ;initialize hold
                          bne.s       f_1frts                                                                      ;not 0 -> OK
                          st          trk_noteoffcnt(a5)                                                           ;0 -> hold = 0xff (-1)
                          ENDC
f_1frts                   rtnoplay
isfxfe:                   cmp.b       #$fe,d4
                          bne.s       notcmdfe
; ---------------- it was FFE, stop playing
                          clr.w       mmd_pstate(a2)
                          IFNE        CIAB
                          movea.l     craddr-DB(a6),a0
                          bclr        #0,(a0)
                          ENDC
                          bsr.w       SoundOff
                          IFNE        AURA
                          jsr         _RemAura(pc)
                          ENDC
                          adda.w      #8,sp                                                                        ;2 subroutine levels
                          bra.w       plr_exit
f_ffe_no8                 rtplay
notcmdfe:                 cmp.b       #$fd,d4                                                                      ;change period
                          bne.s       isfxff
; ---------------- FFD, change the period, don't replay the note
                          IFNE        CHECK
                          cmp.w       #4,d7                                                                        ;no tracks above 4, thank you!!
                          bge.s       f_ff_rts
                          ENDC
                          move.l      trk_periodtbl(a5),d1                                                         ;period table
                          beq.s       f_1frts
                          movea.l     d1,a0
                          move.b      trk_currnote(a5),d0
                          subq.b      #1,d0                                                                        ;sub 1 to make "real" note number
                          IFNE        CHECK
                          bmi.s       f_1frts
                          ENDC
                          add.b       msng_playtransp(a4),d0
                          add.b       trk_stransp(a5),d0
                          add.w       d0,d0
                          bmi.s       f_1frts
                          move.w      0(a0,d0.w),trk_prevper(a5)                                                   ;get & push the period
                          rtnoplay
isfxff:                   cmp.b       #$ff,d4                                                                      ;note off??
                          bne.s       f_ff_rts
                          move.w      d7,d0
                          move.l      a1,-(sp)
                          bsr.w       _ChannelOff
                          move.l      (sp)+,a1
f_ff_rts                  rtplay
; ---------------- F00, called Pattern Break in ST
fx0fchgblck:              move.b      #1,nextblock-DB(a6)                                                          ;next block????...YES!!!! (F00)
                          bra.s       f_ff_rts
; ---------------- was not Fxx, then it's something else!!
f_0e
                          IFNE        CHECK
                          cmp.b       #4,d7
                          bge.s       f_0e_rts
                          ENDC
                          bset        #0,trk_miscflags(a5)
                          move.b      d4,trk_wfcmd+1(a5)                                                           ;set waveform command position ptr
f_0e_rts                  rtplay
; ---------------- change volume
f_0c                      move.b      d4,d0
                          bpl.s       plr_nosetdefvol
                          and.b       #$7F,d0
                          IFNE        CHECK
                          cmp.b       #64,d0
                          bgt.s       go_nocmd
                          ENDC
                          moveq       #0,d1
                          move.b      trk_previnstr(a5),d1
                          asl.w       #3,d1
                          move.b      d0,inst_svol(a4,d1.w)                                                        ;set new svol
                          bra.s       plr_setvol
plr_nosetdefvol           btst        #4,msng_flags(a4)                                                            ;look at flags
                          bne.s       volhex
                          lsr.b       #4,d0                                                                        ;get number from left
                          mulu        #10,d0                                                                       ;number of tens
                          move.b      d4,d1                                                                        ;get again
                          and.b       #$0f,d1                                                                      ;this time don't get tens
                          add.b       d1,d0                                                                        ;add them
volhex:
                          IFNE        CHECK
                          cmp.b       #64,d0
                          bhi.s       go_nocmd
                          ENDC
plr_setvol                move.b      d0,trk_prevvol(a5)
go_nocmd                  rtplay
; ---------------- tempo2 change??
f_09
                          IFNE        CHECK
                          and.b       #$1F,d4
                          bne.s       fx9chk
                          moveq       #$20,d4
                          ENDC
fx9chk:                   move.b      d4,msng_tempo2(a4)
f_09_rts                  rtplay
; ---------------- block delay
f_1e                      tst.w       blkdelay-DB(a6)
                          bne.s       f_1e_rts
                          addq.w      #1,d4
                          move.w      d4,blkdelay-DB(a6)
f_1e_rts                  rtplay
; ---------------- finetune
f_15
                          IFNE        CHECK
                          cmp.b       #7,d4
                          bgt.s       f_15_rts
                          cmp.b       #-8,d4
                          blt.s       f_15_rts
                          ENDC
                          move.b      d4,trk_finetune(a5)
f_15_rts                  rtplay
; ---------------- repeat loop
f_16                      tst.b       d4
                          bne.s       plr_dorpt
                          move.w      mmd_pline(a2),rptline-DB(a6)
                          bra.s       f_16_rts
plr_dorpt                 tst.w       rptcounter-DB(a6)
                          beq.s       plr_newrpt
                          subq.w      #1,rptcounter-DB(a6)
                          beq.s       f_16_rts
                          bra.s       plr_setrptline
plr_newrpt                move.b      d4,rptcounter+1-DB(a6)
plr_setrptline            move.w      rptline-DB(a6),d0
                          addq.w      #1,d0
                          move.w      d0,nextblockline-DB(a6)
f_16_rts                  rtplay
; ---------------- preset change
f_1c                      cmp.b       #$80,d4
                          bhi.s       f_1c_rts
                          moveq       #0,d1
                          move.b      trk_previnstr(a5),d1
                          add.w       d1,d1
                          lea         ext_midipsets-DB(a6),a0
                          ext.w       d4
                          move.w      d4,0(a0,d1.w)                                                                ;set MIDI preset
f_1c_rts                  rtplay
; ---------------- note off time set??
f_08
                          IFNE        HOLD
                          move.b      d4,d0
                          lsr.b       #4,d4                                                                        ;extract left  nibble
                          and.b       #$0f,d0                                                                      ; "   "  right  "  "
                          move.b      d4,trk_initdecay(a5)                                                         ;left = decay
                          move.b      d0,trk_inithold(a5)                                                          ;right = hold
                          ENDC
                          rtplay
; ---------------- sample begin offset
f_19                      lsl.w       #8,d4
                          move.w      d4,trk_soffset(a5)
f_19_rts                  rtplay
; ---------------- cmd Bxx, "position jump"
f_0b
                          IFNE        CHECK
                          cmp.b       #'2',3(a2)
                          beq.s       chk0b_mmd2
                          cmp.w       msng_songlen(a4),d4
                          bhi.s       f_0b_rts
                          bra.s       chk0b_end
chk0b_mmd2                move.w      mmd_pseq(a2),d0                                                              ;get seq number
                          movea.l     msng_pseqs(a4),a0                                                            ;ptr to playseqs
                          movea.l     0(a0,d0.w),a0                                                                ;a0 = ptr to curr PlaySeq
                          cmp.w       40(a0),d4                                                                    ;test song length
                          bhi.s       f_0b_rts
chk0b_end
                          ENDC
                          move.w      d4,mmd_pseqnum(a2)
                          st          nextblock-DB(a6)                                                             ; = 1
f_0b_rts                  rtplay
; ---------------- cmd 1Dxx, jump to next seq, line # specified
f_1d                      move.w      #$1ff,nextblock-DB(a6)
                          addq.w      #1,d4
                          move.w      d4,nextblockline-DB(a6)
                          rtplay
; ---------------- try portamento (3)
f_03
                          IFNE        CHECK
                          cmp.w       #4,d7
                          bge.s       f_03_rts
                          ENDC
                          moveq       #0,d0
                          move.b      trk_currnote(a5),d0
                          subq.b      #1,d0                                                                        ;subtract note number
                          bmi.s       plr_setfx3spd                                                                ;0 -> set new speed
                          move.l      trk_periodtbl(a5),d1
                          beq.s       f_03_rts
                          movea.l     d1,a0
                          add.b       msng_playtransp(a4),d0                                                       ;play transpose
                          add.b       trk_stransp(a5),d0                                                           ;and instrument transpose
                          bmi.s       f_03_rts                                                                     ;again.. too low
                          add.w       d0,d0
                          move.w      0(a0,d0.w),trk_porttrgper(a5)                                                ;period of this note is the target
plr_setfx3spd:            tst.b       d4                                                                           ;qual??
                          beq.s       f_03_rts                                                                     ;0 -> do nothing
                          move.b      d4,trk_prevportspd(a5)                                                       ;store speed
f_03_rts                  rtnoplay

; *******************************************************************
; DoFX: Handle effects, hold/fade etc.
; *******************************************************************
DoFX                      moveq       #0,d3
                          move.b      mmd_counter(a2),d3
                          IFNE        HOLD
                          lea         trackdataptrs-DB(a6),a1
; Loop 1: Hold/Fade handling
                          moveq       #0,d7                                                                        ;clear track count
dofx_loop1                movea.l     (a1)+,a5
                          bsr.w       HoldAndFade
                          addq.w      #1,d7
                          cmp.w       numtracks-DB(a6),d7
                          blt.s       dofx_loop1
                          ENDC
; Loop 2: Track command handling
                          moveq       #0,d5                                                                        ;command page count
dofx_loop2                move.w      fxplineblk-DB(a6),d0
                          bsr.w       GetBlockAddr
                          movea.l     a0,a3
                          IFNE        PLAYMMD0
                          cmp.b       #'1',3(a2)
                          bge.s       dofx_sbd_nommd0
                          bsr.w       StoreBlkDimsMMD0
                          bra.s       dofx_sbd_mmd0
dofx_sbd_nommd0
                          ENDC
                          bsr.w       StoreBlockDims
dofx_sbd_mmd0             move.w      d5,d1
                          move.w      fxplineblk+2-DB(a6),d2
                          movea.l     a3,a0
                          bsr.s       GetCmdPointer
                          movea.l     a0,a3
                          moveq       #0,d7                                                                        ;clear track count
                          lea         trackdataptrs-DB(a6),a1
dofx_loop2_1              movea.l     (a1)+,a5
                          moveq       #0,d4
                          move.b      (a3),d0                                                                      ;command #
                          move.b      1(a3),d4                                                                     ;data byte
                          IFNE        PLAYMMD0
                          cmp.b       #3,d6                                                                        ;if adv == 3 -> MMD0
                          bne.s       dofx_mmd12mask
                          and.w       #$0F,d0
                          bra.s       dofx_mmd0maskd
dofx_mmd12mask
                          ENDC
                          and.w       #$1F,d0
dofx_mmd0maskd            tst.b       trk_fxtype(a5)
                          bgt.s       dofx_lend2_1                                                                 ;1 = skip
                          IFNE        MIDI
                          beq.s       dofx_chfx
                          bsr.w       MIDIFX
                          bra.s       dofx_lend2_1
                          ENDC
                          IFEQ        MIDI
                          bne.s       dofx_lend2_1
                          ENDC
dofx_chfx                 bsr.w       ChannelFX
dofx_lend2_1              adda.w      d6,a3                                                                        ;next track...
                          addq.w      #1,d7
                          cmp.w       numtracks-DB(a6),d7
                          blt.s       dofx_loop2_1
                          addq.w      #1,d5
                          cmp.w       numpages-DB(a6),d5
                          bls.s       dofx_loop2
; Loop 3: Updating audio hardware
                          moveq       #0,d7                                                                        ;clear track count
                          lea         trackdataptrs-DB(a6),a1
dofx_loop3                movea.l     (a1)+,a5
                          IFNE        HOLD
                          tst.b       trk_fxtype(a5)
                          bne.s       dofx_lend3                                                                   ;only in case 0 (norm)
                          ENDC
                          IFEQ        HOLD
                          cmp.w       #4,d7
                          bge.s       dofx_stopl3
                          ENDC
                          bsr.w       UpdatePerVol
dofx_lend3                addq.w      #1,d7
                          cmp.w       numtracks-DB(a6),d7
                          blt.s       dofx_loop3
dofx_stopl3               rts

; *******************************************************************
; GetCmdPointer: Return command pointer for track 0
; *******************************************************************
; args:     a0 = block pointer
;       d1 = page number
;       d2 = line number
;       a2 = module
; result:   a0 = command pointer (i.e. trk 0 note + 2)
;       d6 = track advance (bytes)
; scratches:    d0, d1, d2, a0
; Note: no num_pages check! If numpages > 0 it can be assumed that
; extra pages exist.

GetCmdPointer
                          IFNE        PLAYMMD0
                          cmp.b       #'1',3(a2)
                          blt.s       GetCmdPtrMMD0
                          ENDC
                          mulu        (a0),d2                                                                      ;d2 = line # * numtracks
                          add.l       d2,d2                                                                        ;d2 *= 2...
                          subq.w      #1,d1
                          bmi.s       gcp_page0
                          movea.l     4(a0),a0
                          movea.l     12(a0),a0
                          add.w       d1,d1
                          add.w       d1,d1
                          movea.l     4(a0,d1.w),a0                                                                ;command data
                          adda.l      d2,a0
                          moveq       #2,d6
                          rts
gcp_page0                 add.l       d2,d2                                                                        ;d2 *= 4
                          lea         10(a0,d2.l),a0                                                               ;offs: 4 = header, 2 = note
                          moveq       #4,d6                                                                        ;track advance (bytes)
                          rts
                          IFNE        PLAYMMD0
GetCmdPtrMMD0             moveq       #0,d0
                          move.b      (a0),d0                                                                      ;get numtracks
                          mulu        d0,d2                                                                        ;line # * numtracks
                          move.w      d2,d0
                          add.w       d2,d2
                          add.w       d0,d2                                                                        ; *= 3...
                          lea         3(a0,d2.l),a0                                                                ;offs: 2 = header, 1 = note
                          moveq       #3,d6
                          rts
                          ENDC

; *******************************************************************
; GetBlockAddr: Return pointer to block
; *******************************************************************
; args:     d0 = block number
; result:   a0 = block pointer
; scratches: d0, a0

GetBlockAddr              movea.l     mmd_blockarr(a2),a0
                          add.w       d0,d0
                          add.w       d0,d0
                          movea.l     0(a0,d0.w),a0
                          rts

; *******************************************************************
; GetNoteDataAddr: Check & return addr. of current note
; *******************************************************************
;args:      d0 = pblock     a6 = DB
;returns:   a3 = address
;scratches: d0, a0, d1

GetNoteDataAddr           bsr.w       GetBlockAddr
                          movea.l     a0,a3
                          IFNE        PLAYMMD0
                          cmp.b       #'1',3(a2)
                          blt.s       GetNDAddrMMD0
                          ENDC
                          bsr.w       StoreBlockDims
                          move.w      numlines-DB(a6),d1
                          move.w      mmd_pline(a2),d0
                          cmp.w       d1,d0                                                                        ;check if block end exceeded...
                          bls.s       plr_nolinex
                          move.w      d1,d0
plr_nolinex               add.w       d0,d0
                          add.w       d0,d0                                                                        ;d0 = d0 * 4
                          mulu        numtracks-DB(a6),d0
                          lea         8(a3,d0.l),a3                                                                ;address of current note
                          rts

                          IFNE        PLAYMMD0
GetNDAddrMMD0             bsr.w       StoreBlkDimsMMD0
                          move.w      numlines-DB(a6),d1
                          move.w      mmd_pline(a2),d0
                          cmp.w       d1,d0                                                                        ;check if block end exceeded...
                          bls.s       plr_nolinex2
                          move.w      d1,d0
plr_nolinex2              move.w      d0,d1
                          add.w       d0,d0
                          add.w       d1,d0                                                                        ;d0 = d0 * 3
                          mulu        numtracks-DB(a6),d0
                          lea         2(a3,d0.l),a3                                                                ;address of current note
                          rts
                          ENDC

; *******************************************************************
; StoreBlockDims: Store block dimensions
; *******************************************************************
; args:     a0 = block ptr, a6 = DB

StoreBlockDims            move.l      (a0)+,numtracks-DB(a6)                                                       ;numtracks & lines
                          tst.l       (a0)            :BlockInfo
                          beq.s       sbd_1page
                          movea.l     (a0),a0
                          move.l      12(a0),d0                                                                    ;BlockInfo.pagetable
                          beq.s       sbd_1page
                          movea.l     d0,a0
                          move.w      (a0),numpages-DB(a6)                                                         ;num_pages
                          rts
sbd_1page                 clr.w       numpages-DB(a6)
                          rts

                          IFNE        PLAYMMD0
StoreBlkDimsMMD0
                          clr.w       numpages-DB(a6)
                          moveq       #0,d0
                          move.b      (a0)+,d0                                                                     ;numtracks
                          move.w      d0,numtracks-DB(a6)
                          move.b      (a0),d0                                                                      ;numlines
                          move.w      d0,numlines-DB(a6)
                          rts
                          ENDC

; *******************************************************************
; HoldAndFade: Handle hold/fade
; *******************************************************************
; args:     a5 = track data
;       a6 = DB
;       d7 = track #
; scratches:    d0, d1, a0

                          IFNE        HOLD
HoldAndFade
                          IFNE        MIDI
                          tst.b       trk_prevmidin(a5)                                                            ;is it MIDI??
                          bne.w       plr_haf_midi
                          ENDC
                          IFNE        CHECK
                          cmp.w       #4,d7
                          bge.w       plr_haf_midi                                                                 ;no non-MIDI effects in tracks 4 - 15
                          ENDC
                          tst.b       trk_noteoffcnt(a5)
                          bmi.s       plr_haf_noholdexp
                          subq.b      #1,trk_noteoffcnt(a5)
                          bpl.s       plr_haf_noholdexp
                          IFNE        SYNTH
                          tst.b       trk_synthtype(a5)                                                            ;synth/hybrid??
                          beq.s       plr_nosyndec
                          move.b      trk_decay(a5),trk_volcmd+1(a5)                                               ;set volume command pointer
                          clr.b       trk_volwait(a5)                                                              ;abort WAI
                          bra.s       plr_haf_noholdexp
                          ENDC
plr_nosyndec              move.b      trk_decay(a5),trk_fadespd(a5)                                                ;set fade...
                          bne.s       plr_haf_noholdexp                                                            ;if > 0, don't stop sound
                          moveq       #0,d0
                          bset        d7,d0
                          move.w      d0,$dff096                                                                   ;shut DMA...
plr_haf_noholdexp
                          move.b      trk_fadespd(a5),d0                                                           ;fade??
                          beq.s       plr_haf_dofx                                                                 ;no.
                          sub.b       d0,trk_prevvol(a5)
                          bpl.s       plr_nofade2low
                          clr.b       trk_prevvol(a5)
                          clr.b       trk_fadespd(a5)                                                              ;fade no more
plr_nofade2low
plr_haf_dofx              clr.b       trk_fxtype(a5)
plr_haf_rts               rts
; MIDI version
plr_haf_midi
                          IFNE        MIDI
                          st          trk_fxtype(a5)
                          tst.b       trk_noteoffcnt(a5)
                          bmi.s       plr_haf_rts
                          subq.b      #1,trk_noteoffcnt(a5)
                          bpl.s       plr_haf_rts
                          move.b      trk_prevmidin(a5),d1
                          beq.s       plr_haf_rts
                          lea         noteondata-DB(a6),a0
                          exg.l       a5,a1
                          bsr.w       choff_midi
                          exg.l       a5,a1
                          ENDC
                          rts
;hold
                          ENDC

; *******************************************************************
; ChannelFX:    Do an effect on a channel
; *******************************************************************
;args:                  d3 = counter
;       a4 = song struct    d4 = command qual (long, byte used)
;       a5 = track data ptr 
;       a6 = DB         d0 = command (long, byte used)
;                   d7 = track (channel) number
;scratches: d0, d1, d4, a0

ChannelFX                 add.b       d0,d0                                                                        ;* 2
                          move.w      fx_table(pc,d0.w),d0
                          jmp         fxs(pc,d0.w)
fx_table                  dc.w        fx_00-fxs,fx_01-fxs,fx_02-fxs,fx_03-fxs,fx_04-fxs
                          dc.w        fx_05-fxs,fx_06-fxs,fx_07-fxs,fx_xx-fxs,fx_xx-fxs
                          dc.w        fx_0a-fxs,fx_xx-fxs,fx_0c-fxs,fx_0d-fxs,fx_xx-fxs
                          dc.w        fx_0f-fxs
                          dc.w        fx_10-fxs,fx_11-fxs,fx_12-fxs,fx_13-fxs,fx_14-fxs
                          dc.w        fx_xx-fxs,fx_xx-fxs,fx_xx-fxs,fx_18-fxs,fx_xx-fxs
                          dc.w        fx_1a-fxs,fx_1b-fxs,fx_xx-fxs,fx_xx-fxs,fx_xx-fxs
                          dc.w        fx_1f-fxs
fxs:
;   **************************************** Effect 01 ******
fx_01                     tst.b       d3
                          bne.s       fx_01nocnt0
                          btst        #5,msng_flags(a4)                                                            ;FLAG_STSLIDE??
                          bne.s       fx_01rts
fx_01nocnt0               move.w      trk_prevper(a5),d0
                          sub.w       d4,d0
                          cmp.w       #113,d0
                          bge.s       fx_01noovf
                          move.w      #113,d0
fx_01noovf                move.w      d0,trk_prevper(a5)
fx_xx       ;fx_xx is just a RTS
fx_01rts                  rts
;   **************************************** Effect 11 ******
fx_11                     tst.b       d3
                          bne.s       fx_11rts
                          sub.w       d4,trk_prevper(a5)
fx_11rts                  rts
;   **************************************** Effect 02 ******
fx_02                     tst.b       d3
                          bne.s       fx_02nocnt0
                          btst        #5,msng_flags(a4)
                          bne.s       fx_02rts
fx_02nocnt0               add.w       d4,trk_prevper(a5)
fx_02rts                  rts
;   **************************************** Effect 12 ******
fx_12                     tst.b       d3
                          bne.s       fx_12rts
                          add.w       d4,trk_prevper(a5)
fx_12rts                  rts
;   **************************************** Effect 00 ******
fx_00                     tst.b       d4                                                                           ;both fxqualifiers are 0s: no arpeggio
                          beq.s       fx_00rts
                          move.l      d3,d0
                          divu        #3,d0
                          swap        d0
                          subq.b      #1,d0
                          bgt.s       fx_arp2
                          blt.s       fx_arp0
                          and.b       #$0f,d4
                          bra.s       fx_doarp
fx_arp0                   lsr.b       #4,d4
                          bra.s       fx_doarp
fx_arp2                   moveq       #0,d4
fx_doarp:                 move.b      (a5),d0
                          subq.b      #1,d0                                                                        ;-1 to make it 0 - 127
                          add.b       msng_playtransp(a4),d0                                                       ;add play transpose
                          add.b       trk_stransp(a5),d0                                                           ;add instrument transpose
                          add.b       d0,d4
                          move.l      trk_periodtbl(a5),d1
                          beq.s       fx_00rts
                          movea.l     d1,a0
                          add.b       d0,d0
                          move.w      0(a0,d0.w),d0                                                                ;base note period
                          add.b       d4,d4
                          sub.w       0(a0,d4.w),d0                                                                ;calc difference from base note
                          move.w      d0,trk_arpadjust(a5)
fx_00rts                  rts
;   **************************************** Effect 04 ******
fx_14                     move.b      #6,trk_vibshift(a5)
                          bra.s       vib_cont
fx_04                     move.b      #5,trk_vibshift(a5)
vib_cont                  tst.b       d3
                          bne.s       nonvib
                          move.b      d4,d1
                          beq.s       nonvib
                          and.w       #$0f,d1
                          beq.s       plr_chgvibspd
                          move.w      d1,trk_vibrsz(a5)
plr_chgvibspd             and.b       #$f0,d4
                          beq.s       nonvib
                          lsr.b       #3,d4
                          and.b       #$3e,d4
                          move.b      d4,trk_vibrspd(a5)
nonvib                    move.b      trk_vibroffs(a5),d0
                          lsr.b       #2,d0
                          and.w       #$1f,d0
                          moveq       #0,d1
                          lea         sinetable(pc),a0
                          move.b      0(a0,d0.w),d0
                          ext.w       d0
                          muls        trk_vibrsz(a5),d0
                          move.b      trk_vibshift(a5),d1
                          asr.w       d1,d0
                          move.w      d0,trk_vibradjust(a5)
                          move.b      trk_vibrspd(a5),d0
                          add.b       d0,trk_vibroffs(a5)
fx_04rts                  rts
;   **************************************** Effect 06 ******
fx_06:                    tst.b       d3
                          bne.s       fx_06nocnt0
                          btst        #5,msng_flags(a4)
                          bne.s       fx_04rts
fx_06nocnt0               bsr.s       plr_volslide                                                                 ;Volume slide
                          bra.s       nonvib                                                                       ;+ Vibrato
;   **************************************** Effect 07 ******
fx_07                     tst.b       d3
                          bne.s       nontre
                          move.b      d4,d1
                          beq.s       nontre
                          and.w       #$0f,d1
                          beq.s       plr_chgtrespd
                          move.w      d1,trk_tremsz(a5)
plr_chgtrespd             and.b       #$f0,d4
                          beq.s       nontre
                          lsr.b       #2,d4
                          and.b       #$3e,d4
                          move.b      d4,trk_tremspd(a5)
nontre                    move.b      trk_tremoffs(a5),d0
                          lsr.b       #3,d0
                          and.w       #$1f,d0
                          lea         sinetable(pc),a0
                          move.b      0(a0,d0.w),d1
                          ext.w       d1
                          muls        trk_tremsz(a5),d1
                          asr.w       #7,d1
                          move.b      trk_tremspd(a5),d0
                          add.b       d0,trk_tremoffs(a5)
                          add.b       trk_prevvol(a5),d1
                          bpl.s       tre_pos
                          moveq       #0,d1
tre_pos                   cmp.b       #64,d1
                          ble.s       tre_no2hi
                          moveq       #64,d1
tre_no2hi                 move.b      d1,trk_tempvol(a5)
                          rts
;   ********* VOLUME SLIDE FUNCTION *************************
plr_volslide              move.b      d4,d0
                          moveq       #0,d1
                          move.b      trk_prevvol(a5),d1                                                           ;move previous vol to d1
                          and.b       #$f0,d0
                          bne.s       crescendo
                          sub.b       d4,d1                                                                        ;sub from prev. vol
voltest0                  bpl.s       novolover64
                          moveq       #0,d1                                                                        ;volumes under zero not accepted
                          bra.s       novolover64
crescendo:                lsr.b       #4,d0
                          add.b       d0,d1
voltest                   cmp.b       #64,d1
                          ble.s       novolover64
                          moveq       #64,d1
novolover64               move.b      d1,trk_prevvol(a5)
volsl_rts                 rts
;   **************************************** Effect 0D/0A ***
fx_0a:
fx_0d:                    tst.b       d3
                          bne.s       plr_volslide
                          btst        #5,msng_flags(a4)
                          beq.s       plr_volslide
                          rts
;   **************************************** Effect 05 ******
fx_05:                    tst.b       d3
                          bne.s       fx_05nocnt0
                          btst        #5,msng_flags(a4)
                          bne.s       fx_05rts
fx_05nocnt0               bsr.s       plr_volslide
                          bra.s       fx_03nocnt0
fx_05rts                  rts
;   **************************************** Effect 1A ******
fx_1a                     tst.b       d3
                          bne.s       volsl_rts
                          move.b      trk_prevvol(a5),d1
                          add.b       d4,d1
                          bra.s       voltest
;   **************************************** Effect 1B ******
fx_1b                     tst.b       d3
                          bne.s       volsl_rts
                          move.b      trk_prevvol(a5),d1
                          sub.b       d4,d1
                          bra.s       voltest0
;   **************************************** Effect 03 ******
fx_03                     tst.b       d3
                          bne.s       fx_03nocnt0
                          btst        #5,msng_flags(a4)
                          bne.s       fx_03rts
fx_03nocnt0               move.w      trk_porttrgper(a5),d0                                                        ;d0 = target period
                          beq.s       fx_03rts
                          move.w      trk_prevper(a5),d1                                                           ;d1 = curr. period
                          move.b      trk_prevportspd(a5),d4                                                       ;get prev. speed
                          cmp.w       d0,d1
                          bhi.s       subper                                                                       ;curr. period > target period
                          add.w       d4,d1                                                                        ;add the period
                          cmp.w       d0,d1
                          bge.s       targreached
                          bra.s       targnreach
subper:                   sub.w       d4,d1                                                                        ;subtract
                          cmp.w       d0,d1                                                                        ;compare current period to target period
                          bgt.s       targnreach
targreached:              move.w      trk_porttrgper(a5),d1                                                        ;eventually push target period
                          clr.w       trk_porttrgper(a5)                                                           ;now we can forget everything
targnreach:               move.w      d1,trk_prevper(a5)
fx_03rts                  rts
;   **************************************** Effect 13 ******
fx_13:                    cmp.b       #3,d3
                          bge.s       fx_13rts                                                                     ;if counter < 3
                          neg.w       d4
                          move.w      d4,trk_vibradjust(a5)                                                        ;subtract effect qual...
fx_13rts                  rts
;   *********************************************************
fx_0c:                    tst.b       d3
                          bne.s       fx_13rts
dvc_0                     move.b      trk_prevvol(a5),d1
                          rts
;   **************************************** Effect 10 ******
fx_10:
                          IFNE        MIDI
                          tst.b       d3
                          bne.s       fx_13rts
                          move.w      d4,d0
                          bra.w       _InitMIDIDump
                          ENDC
                          IFEQ        MIDI
                          rts
                          ENDC
;   **************************************** Effect 18 ******
fx_18                     cmp.b       d4,d3
                          bne.s       fx_18rts
                          clr.b       trk_prevvol(a5)
fx_18rts                  rts
;   **************************************** Effect 1F ******
fx_1f                     move.b      d4,d1
                          lsr.b       #4,d4                                                                        ;note delay
                          beq.s       nonotedelay
                          cmp.b       d4,d3                                                                        ;compare to counter
                          blt.s       fx_18rts                                                                     ;tick not reached
                          bne.s       nonotedelay
                          bra         playfxnote                                                                   ;trigger note
nonotedelay               and.w       #$0f,d1                                                                      ;retrig?
                          beq.s       fx_18rts
                          moveq       #0,d0
                          move.b      d3,d0
                          divu        d1,d0
                          swap        d0                                                                           ;get modulo of counter/tick
                          tst.w       d0
                          bne.s       fx_18rts
                          bra         playfxnote                                                                   ;retrigger
;   **************************************** Effect 0F ******
;   see below...
;   *********************************************************

; *******************************************************************
; UpdatePerVol: Update audio registers (period & volume) after FX
; *******************************************************************
; args:     a6 = DB         d7 = channel #
;       a5 = track data
; scratches:    d0, d1, a0, d5
UpdatePerVol              move.w      trk_prevper(a5),d5
                          IFNE        SYNTH
                          move.l      trk_synthptr(a5),d0
                          beq.s       plr_upv_nosynth
                          move.l      a1,-(sp)
                          bsr.w       synth_start
                          move.l      (sp)+,a1
                          ENDC
plr_upv_nosynth           add.w       trk_vibradjust(a5),d5
                          sub.w       trk_arpadjust(a5),d5
                          clr.l       trk_vibradjust(a5)                                                           ;clr both adjusts
                          movea.l     trk_audioaddr(a5),a0
                          move.w      d5,ac_per(a0)                                                                ;push period
                          moveq       #0,d0
                          move.b      trk_tempvol(a5),d0
                          bpl.s       plr_upv_setvol
                          move.b      trk_prevvol(a5),d0
plr_upv_setvol            st          trk_tempvol(a5)
; -------- GetRelVol: Calculate track volume -----------------------------
; track # = d7, note vol = d0, song = a4
                          IFNE        RELVOL
                          mulu        trk_trackvol(a5),d0                                                          ;d0 = master v. * track v. * volume
                          lsr.w       #8,d0
                          ENDC
                          move.b      d0,ac_vol+1(a0)
                          rts

; **** a separate routine for handling command 0F
fx_0f                     cmp.b       #$f1,d4
                          bne.s       no0ff1
                          cmp.b       #3,d3
                          beq.s       playfxnote
                          rts
no0ff1:                   cmp.b       #$f2,d4
                          bne.s       no0ff2
                          cmp.b       #3,d3
                          beq.s       playfxnote
                          rts
no0ff2:                   cmp.b       #$f3,d4
                          bne.s       no0ff3
                          move.b      d3,d0
                          beq.s       cF_rts
                          and.b       #1,d0                                                                        ;is 2 or 4
                          bne.s       cF_rts
playfxnote:               moveq       #0,d1
                          move.b      trk_currnote(a5),d1                                                          ;get note # of curr. note
                          beq.s       cF_rts
                          move.b      trk_noteoffcnt(a5),d0                                                        ;get hold counter
                          bmi.s       pfxn_nohold                                                                  ;no hold, or hold over
                          add.b       d3,d0                                                                        ;increase by counter val
                          bra.s       pfxn_hold
pfxn_nohold               move.b      trk_inithold(a5),d0                                                          ;get initial hold
                          bne.s       pfxn_hold
                          st          d0
pfxn_hold                 move.b      d0,trk_noteoffcnt(a5)
                          movem.l     a1/a3/d3/d6,-(sp)
                          moveq       #0,d3
                          move.b      trk_previnstr(a5),d3                                                         ;and prev. sample #
                          movea.l     trk_previnstra(a5),a3
                          bsr         _PlayNote
pndone_0ff                movem.l     (sp)+,a1/a3/d3/d6
cF_rts                    rts
no0ff3:                   cmp.b       #$f4,d4                                                                      ;triplet cmd 1
                          bne.s       no0ff4
                          moveq       #0,d0
                          move.b      msng_tempo2(a4),d0
                          divu        #3,d0
                          cmp.b       d0,d3
                          beq.s       playfxnote
                          rts
no0ff4                    cmp.b       #$f5,d4                                                                      ;triplet cmd 2
                          bne.s       no0ff5
                          moveq       #0,d0
                          move.b      msng_tempo2(a4),d0
                          divu        #3,d0
                          add.w       d0,d0
                          cmp.b       d0,d3
                          beq.s       playfxnote
                          rts
no0ff5                    cmp.b       #$f8,d4                                                                      ;f8 = filter off
                          beq.s       plr_filteroff
                          cmp.b       #$f9,d4                                                                      ;f9 = filter on
                          bne.s       cF_rts
                          bclr        #1,$bfe001
                          bset        #0,msng_flags(a4)
                          rts
plr_filteroff:            bset        #1,$bfe001
                          bclr        #0,msng_flags(a4)
                          rts

; -------- HANDLE DMA WAIT (PROCESSOR-INDEPENDENT) -----------------------
_Wait1line:               move.w      d0,-(sp)
wl0:                      move.b      $dff007,d0
wl1:                      cmp.b       $dff007,d0
                          beq.s       wl1
                          dbf         d1,wl0
                          move.w      (sp)+,d0
                          rts
pushnewvals:              movea.l     (a1)+,a5
                          lsr.b       #1,d0
                          bcc.s       rpnewv
                          move.l      trk_sampleptr(a5),d1
                          beq.s       rpnewv
                          movea.l     trk_audioaddr(a5),a0
                          move.l      d1,ac_ptr(a0)
                          move.w      trk_samplelen(a5),ac_len(a0)
rpnewv:                   rts

; -------- AUDIO DMA ROUTINE ---------------------------------------------
_StartDMA:  ;This small routine turns on audio DMA
                          move.w      dmaonmsk-DB(a6),d0                                                           ;dmaonmsk contains the mask of
                          beq.s       sdma_nodmaon                                                                 ;the channels that must be turned on
                          bset        #15,d0                                                                       ;DMAF_SETCLR: set these bits in dmacon
                          moveq       #80,d1
; The following line makes the playroutine one scanline slower. If your
; song works well without the following instruction, you can leave it out.
                          IFNE        SYNTH
                          add.w       d1,d1                                                                        ;sometimes double wait time is required
                          ENDC
                          bsr.s       _Wait1line
                          move.w      d0,$dff096                                                                   ;do that!!!
                          moveq       #80,d1
                          bsr.s       _Wait1line
                          lea         trackdataptrs-DB(a6),a1
                          bsr.s       pushnewvals
                          bsr.s       pushnewvals
                          bsr.s       pushnewvals
                          IFNE        MIDI
                          bsr.s       pushnewvals
                          ENDC
                          IFEQ        MIDI
                          bra.s       pushnewvals
                          ENDC
sdma_nodmaon
                          IFNE        MIDI
                          lea         bytesinnotebuff-DB(a6),a0
                          move.w      (a0)+,d0
                          beq.s       rpnewv
                          bra.w       _AddMIDId
                          ENDC
                          rts

_SetTempo:
                          IFNE        CIAB
                          move.l      _module-DB(a6),d1
                          beq.s       ST_x
                          move.l      d1,a0
                          movea.l     mmd_songinfo(a0),a0
                          btst        #5,msng_flags2(a0)
                          bne.s       ST_bpm
                          cmp.w       #10,d0                                                                       ;If tempo <= 10, use SoundTracker tempo
                          bhi.s       calctempo
                          subq.b      #1,d0
                          add.w       d0,d0
                          move.w      sttempo+2(pc,d0.w),d1
                          bra.s       pushtempo
calctempo:                move.l      timerdiv-DB(a6),d1
                          divu        d0,d1
pushtempo:                movea.l     craddr+4-DB(a6),a0
                          move.b      d1,(a0)                                                                      ;and set the CIA timer
                          lsr.w       #8,d1
                          movea.l     craddr+8-DB(a6),a0
                          move.b      d1,(a0)
                          ENDC
ST_x                      rts                                                                                      ;   vv-- These values are the SoundTracker tempos (approx.)
sttempo:                  dc.w        $0f00
                          IFNE        CIAB
                          dc.w        2417,4833,7250,9666,12083,14500,16916,19332,21436,24163
ST_bpm                    move.b      msng_flags2(a0),d1
                          and.w       #$1F,d1
                          addq.b      #1,d1
                          mulu        d1,d0
                          move.l      bpmdiv-DB(a6),d1
                          divu        d0,d1
                          bra.s       pushtempo
                          ENDC

                          IFNE        MIDI
MIDIFX                    add.b       d0,d0                                                                        ;* 2
                          move.w      midicmd_table(pc,d0.w),d0
                          jmp         midifx(pc,d0.w)
midicmd_table             dc.w        mfx_00-midifx,mfx_01-midifx,mfx_02-midifx,mfx_03-midifx,mfx_04-midifx
                          dc.w        mfx_05-midifx,mfx_rts-midifx,mfx_rts-midifx,mfx_rts-midifx,mfx_rts-midifx
                          dc.w        mfx_0a-midifx,mfx_rts-midifx,mfx_rts-midifx,mfx_0d-midifx,mfx_0e-midifx
                          dc.w        mfx_0f-midifx
                          dc.w        mfx_10-midifx,mfx_rts-midifx,mfx_rts-midifx,mfx_13-midifx
                          dc.w        mfx_rts-midifx,mfx_rts-midifx,mfx_rts-midifx,mfx_17-midifx
                          dc.w        mfx_rts-midifx,mfx_rts-midifx,mfx_rts-midifx,mfx_rts-midifx
                          dc.w        mfx_rts-midifx,mfx_rts-midifx,mfx_rts-midifx,mfx_1f-midifx
midifx      
mfx_01                    lea         prevmidipbend-DB(a6),a0
                          moveq       #0,d1
                          move.b      trk_prevmidich(a5),d1                                                        ;get previous midi channel
                          add.b       d1,d1                                                                        ;UWORD index
                          tst.b       d4                                                                           ;x100??
                          beq.s       resetpbend
                          move.w      0(a0,d1.w),d0                                                                ;get previous pitch bend
                          lsl.w       #3,d4                                                                        ;multiply bend value by 8
                          add.w       d4,d0
                          cmp.w       #$3fff,d0
                          bls.s       bendpitch
                          move.w      #$3fff,d0
bendpitch:                move.w      d0,0(a0,d1.w)                                                                ;save current pitch bend
                          lsr.b       #1,d1                                                                        ;back to UBYTE
                          or.b        #$e0,d1
                          lea         noteondata-DB(a6),a0
                          move.b      d1,(a0)                                                                      ;midi command & channel
                          move.b      d0,1(a0)                                                                     ;lower value
                          and.b       #$7f,1(a0)                                                                   ;clear bit 7
                          lsr.w       #7,d0
                          and.b       #$7f,d0                                                                      ;clr bit 7
                          move.b      d0,2(a0)                                                                     ;higher 7 bits
                          moveq       #3,d0
                          bra.w       _AddMIDId

mfx_02                    lea         prevmidipbend-DB(a6),a0
                          moveq       #0,d1
                          move.b      trk_prevmidich(a5),d1
                          add.b       d1,d1
                          tst.b       d4
                          beq.s       resetpbend                                                                   ;x200??
                          move.w      0(a0,d1.w),d0
                          lsl.w       #3,d4
                          sub.w       d4,d0
                          bpl.s       bendpitch                                                                    ;not under 0
                          moveq       #0,d0
                          bra.s       bendpitch
resetpbend:               tst.b       d3                                                                           ;d3 = counter (remember??)
                          bne.s       mfx_rts
                          move.w      #$2000,d0
                          bra.s       bendpitch
mfx_rts                   rts
mfx_13
mfx_03                    tst.b       d3
                          bne.s       mfx_rts
                          lea         prevmidipbend-DB(a6),a0
                          moveq       #0,d1
                          move.b      trk_prevmidich(a5),d1
                          add.b       d1,d1
                          move.b      d4,d0
                          add.b       #128,d0
                          lsl.w       #6,d0
                          bra.s       bendpitch

mfx_0d                    tst.b       d3
                          bne.s       mfx_rts
                          lea         noteondata+1-DB(a6),a0                                                       ;CHANNEL AFTERTOUCH
                          move.b      d4,(a0)                                                                      ;value
                          bmi.s       mfx_rts
                          move.b      trk_prevmidich(a5),-(a0)
                          or.b        #$d0,(a0)
                          moveq       #2,d0
                          bra.w       _AddMIDId

mfx_0a                    tst.b       d3
                          bne.s       mfx_rts
                          lea         noteondata+2-DB(a6),a0                                                       ;POLYPHONIC AFTERTOUCH
                          and.b       #$7f,d4
                          move.b      d4,(a0)
                          move.b      trk_prevmidin(a5),-(a0)
                          ble.s       mfx_rts
                          move.b      trk_prevmidich(a5),-(a0)
                          or.b        #$A0,(a0)
                          moveq       #3,d0
                          bra.w       _AddMIDId

mfx_17                    moveq       #$07,d0                                                                      ;07 = VOLUME
                          bra.s       pushctrldata

mfx_04                    moveq       #$01,d0                                                                      ;01 = MODULATION WHEEL
                          bra.s       pushctrldata

mfx_0e                    moveq       #$0a,d0
pushctrldata              tst.b       d3                                                                           ;do it only once in a note
                          bne.s       mfx_rts2                                                                     ;(when counter = 0)
                          lea         noteondata+2-DB(a6),a0                                                       ;push "control change" data,
                          move.b      d4,(a0)                                                                      ;second databyte
                          bmi.s       mfx_rts2                                                                     ;$0 - $7F only
                          move.b      d0,-(a0)                                                                     ;1st databyte
                          move.b      trk_prevmidich(a5),-(a0)                                                     ;MIDI channel
                          or.b        #$b0,(a0)                                                                    ;command (B)
                          moveq       #3,d0
                          bra.w       _AddMIDId

mfx_05                    and.b       #$7f,d4                                                                      ;set contr. value of curr. MIDI ch.
                          move.b      trk_prevmidich(a5),d6
                          lea         midicontrnum-DB(a6),a0
                          adda.w      d6,a0
                          move.b      d4,(a0)
mfx_rts2                  rts

mfx_0f                    cmp.b       #$fa,d4                                                                      ;hold pedal ON
                          bne.s       nomffa
                          moveq       #$40,d0
                          moveq       #$7f,d4
                          bra.s       pushctrldata
nomffa                    cmp.b       #$fb,d4                                                                      ;hold pedal OFF
                          bne.w       fx_0f
                          moveq       #$40,d0
                          moveq       #$00,d4
                          bra.s       pushctrldata

mfx_00                    tst.b       d4
                          beq.s       mfx_rts2
                          and.b       #$7f,d4
                          move.b      trk_prevmidich(a5),d6
                          lea         midicontrnum-DB(a6),a0
                          move.b      0(a0,d6.w),d0
                          bra.s       pushctrldata

mfx_10                    tst.b       d3
                          bne.s       mfx_rts3
                          move.w      d4,d0
                          bra.w       _InitMIDIDump

mfx_1f                    move.b      d4,d1
                          lsr.b       #4,d4                                                                        ;note delay
                          beq.s       nonotedelay_m
                          cmp.b       d4,d3                                                                        ;compare to counter
                          blt.s       mfx_rts3                                                                     ;tick not reached
                          bne.s       nonotedelay_m
                          bsr         playfxnote                                                                   ;trigger note
nonotedelay_m             and.w       #$0f,d1                                                                      ;retrig?
                          beq.s       mfx_rts3
                          moveq       #0,d0
                          move.b      d3,d0
                          divu        d1,d0
                          swap        d0                                                                           ;get modulo of counter/tick
                          tst.w       d0
                          beq         playfxnote
mfx_rts3                  rts

_ResetMIDI:               movem.l     d2/a2/a6,-(sp)
                          movea.l     4.w,a6                                                                       ;ExecBase
                          jsr         _LVODisable(a6)                                                              ;Disable()
                          lea         DB,a6
; Clear preset memory
                          lea         prevmidicpres-DB(a6),a0
                          moveq       #7,d2
RM_loop0                  clr.l       (a0)+                                                                        ;force presets to be set again
                          dbf         d2,RM_loop0
                          clr.b       lastcmdbyte
; Reset pitchbenders & modulation wheels
                          lea         midiresd-DB(a6),a2
                          move.b      #$e0,(a2)
                          move.b      #$b0,3(a2)
                          moveq       #15,d2
respbendl:                movea.l     a2,a0
                          moveq       #6,d0
                          bsr.w       _AddMIDId
                          addq.b      #1,(a2)
                          addq.b      #1,3(a2)
                          dbf         d2,respbendl
                          lea         prevmidipbend-DB(a6),a2
                          moveq       #15,d2
resprevpbends:            move.w      #$2000,(a2)+
                          dbf         d2,resprevpbends
; Clear dump variables
                          clr.b       sysx-DB(a6)
                          lea         dumpqueue-DB(a6),a0
                          move.l      a0,dqreadptr-DB(a6)
                          move.l      a0,dqwriteptr-DB(a6)
                          clr.w       dqentries-DB(a6)
; Enable & exit
                          movea.l     4.w,a6
                          jsr         _LVOEnable(a6)                                                               ;Enable()
                          movem.l     (sp)+,d2/a2/a6
                          rts
                          ENDC

; *************************************************************************
; *************************************************************************
; ***********          P U B L I C   F U N C T I O N S          ***********
; *************************************************************************
; *************************************************************************

                          IFEQ        EASY
                          XDEF        _InitModule,_PlayModule
                          XDEF        _InitPlayer,_RemPlayer,_StopPlayer
                          XDEF        _ContModule
                          ENDC

; *************************************************************************
; InitModule(a0 = module) -- extract expansion data etc.. from V3.xx module
; *************************************************************************

_InitModule:              movem.l     a2-a3/d2,-(sp)
                          move.l      a0,-(sp)
                          beq         IM_exit                                                                      ;0 => xit
                          IFNE        RELVOL	
                          movea.l     mmd_songinfo(a0),a1                                                          ;MMD0song
                          move.b      msng_mastervol(a1),d0                                                        ;d0 = mastervol
                          ext.w       d0
                          lea         trackdataptrs,a2
                          cmp.b       #'2',3(a0)                                                                   ;MMD2?
                          bne.s       IM_mmd01
                          move.w      msng_numtracks(a1),d1
                          subq.w      #1,d1
                          movea.l     msng_trkvoltbl(a1),a1
                          bra.s       IM_loop0
IM_mmd01                  lea         msng_trkvol(a1),a1                                                           ;a1 = trkvol
                          moveq       #MAX_MMD1_TRACKS-1,d1
IM_loop0                  move.b      (a1)+,d2                                                                     ;get vol...
                          ext.w       d2
                          move.l      (a2)+,a3                                                                     ;pointer to track data
                          mulu        d0,d2                                                                        ;mastervol * trackvol
                          lsr.w       #4,d2
                          move.w      d2,trk_trackvol(a3)
                          dbf         d1,IM_loop0
                          ENDC
                          IFNE        SYNTH
                          lea         trackdataptrs,a2
                          moveq       #3,d1
IM_loop1                  move.l      (a2)+,a3
                          clr.l       trk_synthptr(a3)
                          clr.b       trk_synthtype(a3)
                          dbf         d1,IM_loop1
                          ENDC
                          lea         holdvals,a2
                          movea.l     a0,a3
                          move.l      mmd_expdata(a0),d0                                                           ;expdata...
                          IFEQ        MIDI
                          beq.s       IM_clrhlddec                                                                 ;none here
                          ENDC
                          IFNE        MIDI
                          beq.w       IM_clrhlddec
                          ENDC
                          move.l      d0,a1
                          move.l      4(a1),d0                                                                     ;exp_smp
                          IFEQ        MIDI
                          beq.s       IM_clrhlddec                                                                 ;again.. nothing
                          ENDC
                          IFNE        MIDI
                          beq.w       IM_clrhlddec
                          ENDC
                          move.l      d0,a0                                                                        ;InstrExt...
                          move.w      8(a1),d2                                                                     ;# of entries
                          IFEQ        MIDI
                          beq.s       IM_clrhlddec
                          ENDC
                          IFNE        MIDI
                          beq.w       IM_clrhlddec
                          ENDC
                          subq.w      #1,d2                                                                        ;-1 (for dbf)
                          move.w      10(a1),d0                                                                    ;entry size
                          movea.l     mmd_songinfo(a3),a3                                                          ;MMD0song
                          IFNE        MIDI
                          lea         4*63(a2),a1                                                                  ;pointer to ext_midipsets...
                          ENDC
IM_loop2                  clr.b       2*63(a2)                                                                     ;clear finetune
                          cmp.w       #3,d0
                          ble.s       IM_noftune
                          move.b      3(a0),126(a2)                                                                ;InstrExt.finetune -> finetune
IM_noftune                clr.b       3*63(a2)                                                                     ;clear flags
                          cmp.w       #6,d0
                          blt.s       IM_noflags
                          move.b      5(a0),3*63(a2)                                                               ;InstrExt.flags -> flags
                          bra.s       IM_gotflags
IM_noflags                cmp.w       #1,inst_replen(a3)
                          bls.s       IM_gotflags
                          bset        #0,3*63(a2)
IM_gotflags               clr.b       6*63(a2)                                                                     ;Initally OUTPUT_STD
                          cmp.w       #9,d0
                          blt.s       IM_noopdev
                          move.b      8(a0),6*63(a2)                                                               ;get InstrExt.output_device
                          IFNE        AURA
                          cmp.b       #1,8(a0)                                                                     ;is it OUTPUT_AURA?
                          bne.s       IM_noopdev
; does no harm to call several times...
                          jsr         _InitAura(pc)
                          ENDC
IM_noopdev
                          IFNE        MIDI
                          cmp.w       #2,d0
                          ble.s       IM_nsmnoff
                          tst.b       2(a0)                                                                        ;suppress MIDI note off?
                          beq.s       IM_nsmnoff
                          bset        #7,inst_midich(a3)
IM_nsmnoff                move.b      inst_midipreset(a3),d1
                          ext.w       d1
                          move.w      d1,(a1)
                          cmp.w       #8,d0
                          ble.s       IM_nolongpset
                          move.w      6(a0),(a1)                                                                   ;-> ext_midipsets
                          btst        #1,5(a0)
                          beq.s       IM_nolongpset
                          bset        #6,inst_midich(a3)
IM_nolongpset             addq.l      #2,a1
                          ENDC
                          move.b      1(a0),63(a2)                                                                 ;InstrExt.decay -> decay
                          move.b      (a0),(a2)+                                                                   ;InstrExt.hold -> holdvals
                          adda.w      d0,a0                                                                        ;ptr to next InstrExt
                          addq.l      #8,a3                                                                        ;next instrument...
                          dbf         d2,IM_loop2
                          bra.s       IM_exit
IM_clrhlddec              move.w      #3*63-1,d0                                                                   ;no InstrExt => clear holdvals/decays
IM_loop3                  clr.w       (a2)+                                                                        ;..and finetunes/flags/ext_psets
                          dbf         d0,IM_loop3
                          movea.l     (sp),a0
; -------- For (very old) MMDs, with no InstrExt, set flags/SSFLG_LOOP,
; -------- also copy inst_midipreset to ext_midipsets.
                          movea.l     mmd_songinfo(a0),a3
                          lea         flags,a2
                          IFNE        MIDI
                          lea         ext_midipsets,a1
                          ENDC
                          moveq       #62,d0
IM_loop4                  cmp.w       #1,inst_replen(a3)
                          bls.s       IM_noreptflg
                          bset        #0,(a2)
IM_noreptflg              addq.l      #1,a2
                          IFNE        MIDI
                          move.b      inst_midipreset(a3),d1
                          ext.w       d1
                          move.w      d1,(a1)+
                          ENDC
                          addq.l      #8,a3                                                                        ;next inst
                          dbf         d0,IM_loop4
IM_exit                   addq.l      #4,sp
                          movem.l     (sp)+,a2-a3/d2
                          rts
; *************************************************************************
; InitPlayer() -- allocate interrupt, audio, serial port etc...
; *************************************************************************
_InitPlayer:
                          IFNE        MIDI
                          bsr.w       _GetSerial
                          tst.l       d0
                          bne.s       IP_error
                          ENDC
                          bsr.w       _AudioInit
                          tst.l       d0
                          bne.s       IP_error
                          rts
IP_error                  bsr.s       _RemPlayer
                          moveq       #-1,d0
                          rts
; *************************************************************************
; RemPlayer() -- free interrupt, audio, serial port etc..
; *************************************************************************
_RemPlayer:
                          move.b      _timeropen,d0
                          beq.s       RP_notimer                                                                   ;timer is not ours
                          bsr.s       _StopPlayer
RP_notimer:
                          bsr.w       _AudioRem
                          IFNE        MIDI
                          bra.w       _FreeSerial
                          ELSEIF
                          rts
                          ENDC
; *************************************************************************
; StopPlayer() -- stop the music
; *************************************************************************
_StopPlayer:              lea         DB,a1
                          move.b      _timeropen-DB(a1),d0
                          beq.s       SP_end                                                                       ;res. alloc fail.
                          IFNE        CIAB
                          movea.l     craddr-DB(a1),a0
                          bclr        #0,(a0)                                                                      ;stop timer
                          ENDC
                          IFNE        AURA
                          jsr         _RemAura(pc)
                          ENDC
                          move.l      _module-DB(a1),d0
                          beq.s       SP_nomod
                          move.l      d0,a0
                          clr.w       mmd_pstate(a0)
                          clr.l       _module-DB(a1)
SP_nomod
                          IFNE        MIDI
                          clr.b       lastcmdbyte-DB(a1)
                          ENDC
                          bra.w       SoundOff
SP_end                    rts


_ContModule               tst.b       _timeropen
                          beq.s       SP_end
                          movea.l     craddr,a1
                          bclr        #0,(a1)
                          move.l      a0,-(sp)
                          bsr.w       SoundOff
                          move.l      (sp)+,a0
                          moveq       #0,d0
                          bra.s       contpoint
; *************************************************************************
; PlayModule(a0 = module)  -- initialize & play it!
; *************************************************************************
_PlayModule:              st          d0
contpoint                 movem.l     a0/d0,-(sp)
                          bsr         _InitModule
                          movem.l     (sp)+,a0/d0
                          move.l      a6,-(sp)
                          lea         DB,a6
                          tst.b       _timeropen-DB(a6)
                          beq         PM_end                                                                       ;resource allocation failure
                          move.l      a0,d1
                          beq         PM_end                                                                       ;module failure
                          IFNE        CIAB
                          movea.l     craddr-DB(a6),a1
                          bclr        #0,(a1)                                                                      ;stop timer...
                          ENDC
                          clr.l       _module-DB(a6)
                          IFNE        MIDI
                          clr.b       lastcmdbyte-DB(a6)
                          ENDC
                          move.w      _modnum,d1
                          beq.s       PM_modfound
PM_nextmod                tst.l       mmd_expdata(a0)
                          beq.s       PM_modfound
                          move.l      mmd_expdata(a0),a1
                          tst.l       (a1)
                          beq.s       PM_modfound                                                                  ;no more modules here!
                          move.l      (a1),a0
                          subq.w      #1,d1
                          bgt.s       PM_nextmod
PM_modfound               cmp.b       #'T',3(a0)
                          bne.s       PM_nomodT
                          move.b      #'0',3(a0)                                                                   ;change MCNT to MCN0
PM_nomodT                 movea.l     mmd_songinfo(a0),a1                                                          ;song
                          move.b      msng_tempo2(a1),mmd_counter(a0)                                              ;init counter
                          btst        #0,msng_flags(a1)
                          bne.s       PM_filon
                          bset        #1,$bfe001
                          bra.s       PM_filset
PM_filon                  bclr        #1,$bfe001
PM_filset                 tst.b       d0
                          beq.s       PM_noclr
                          clr.l       mmd_pline(a0)
                          clr.l       rptline-DB(a6)
                          clr.w       blkdelay-DB(a6)
; ---------- Set 'pblock' and 'pseq' to correct values...
PM_noclr                  cmp.b       #'2',3(a0)
                          bne.s       PM_oldpbset
                          move.w      mmd_psecnum(a0),d1
                          move.l      a2,-(sp)                                                                     ;need extra register
                          movea.l     msng_sections(a1),a2
                          add.w       d1,d1
                          move.w      0(a2,d1.w),d1                                                                ;get sequence number
                          add.w       d1,d1
                          add.w       d1,d1
                          move.w      d1,mmd_pseq(a0)
                          movea.l     msng_pseqs(a1),a2
                          movea.l     0(a2,d1.w),a2                                                                ;PlaySeq...
                          move.w      mmd_pseqnum(a0),d1
                          add.w       d1,d1
                          move.w      42(a2,d1.w),d1                                                               ;and the correct block..
                          move.l      (sp)+,a2
                          bra.s       PM_setblk
PM_oldpbset               move.w      mmd_pseqnum(a0),d1
                          add.w       #msng_playseq,d1
                          move.b      0(a1,d1.w),d1                                                                ;get first playseq entry
                          ext.w       d1
PM_setblk                 move.w      d1,mmd_pblock(a0)
                          move.w      #-1,mmd_pstate(a0)
                          move.l      a0,_module-DB(a6)
                          btst        #5,msng_flags2(a1)                                                           ;BPM?
                          seq         bpmcounter-DB(a6)
                          IFNE        CIAB
                          move.w      msng_deftempo(a1),d0                                                         ;get default tempo
                          movea.l     craddr-DB(a6),a1
                          bsr.w       _SetTempo                                                                    ;set default tempo
                          bset        #0,(a1)                                                                      ;start timer => PLAY!!
                          ENDC
PM_end                    move.l      (sp)+,a6
                          rts
; *************************************************************************

_AudioInit:               movem.l     a4/a6/d2-d3,-(sp)
                          lea         DB,a4
                          moveq       #0,d2
                          movea.l     4.w,a6

;   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ alloc signal bit
                          IFNE        AUDDEV
                          moveq       #1,d2
                          moveq       #-1,d0
                          jsr         _LVOAllocSignal(a6)                                                          ;AllocSignal()
                          tst.b       d0
                          bmi.w       initerr
                          move.b      d0,sigbitnum-DB(a4)
;   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ prepare IORequest
                          lea         allocport-DB(a4),a1
                          move.b      d0,15(a1)                                                                    ;set mp_SigBit
                          move.l      a1,-(sp)
                          suba.l      a1,a1
                          jsr         _LVOFindTask(a6)                                                             ;FindTask(0)
                          move.l      (sp)+,a1
                          move.l      d0,16(a1)                                                                    ;set mp_SigTask
                          lea         reqlist-DB(a4),a0
                          move.l      a0,(a0)                                                                      ;NEWLIST begins...
                          addq.l      #4,(a0)
                          clr.l       4(a0)
                          move.l      a0,8(a0)                                                                     ;NEWLIST ends...
;   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ open audio.device
                          moveq       #2,d2
                          lea         allocreq-DB(a4),a1
                          lea         audiodevname-DB(a4),a0
                          moveq       #0,d0
                          moveq       #0,d1
                          movea.l     4.w,a6
                          jsr         _LVOOpenDevice(a6)                                                           ;OpenDevice()
                          tst.b       d0
                          bne.w       initerr
                          st          audiodevopen-DB(a4)
;   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ open cia resource
                          moveq       #3,d2
                          ENDC

                          IFNE        CIAB
                          cmp.b       #50,$212(a6)                                                                 ;ExecBase->VBlankFrequency
                          beq.s       init_pal
                          move.l      #474326,timerdiv-DB(a4)                                                      ;Assume that CIA freq is 715 909 Hz
                          move.l      #3579545/2,bpmdiv-DB(a4)
init_pal                  moveq       #0,d3
                          lea         cianame-DB(a4),a1
                          move.b      #'a',3(a1)
open_ciares               moveq       #0,d0
                          jsr         _LVOOpenResource(a6)                                                         ;OpenResource()
                          move.l      d0,_ciaresource
                          beq.s       try_CIAB
                          moveq       #4,d2
                          move.l      d0,a6
                          lea         timerinterrupt-DB(a4),a1
                          moveq       #0,d0                                                                        ;Timer A
                          jsr         _LVOAddICRVector(a6)                                                         ;AddICRVector()
                          tst.l       d0
                          beq.s       got_timer
                          addq.l      #4,d3                                                                        ;add base addr index
                          lea         timerinterrupt-DB(a4),a1
                          moveq       #1,d0                                                                        ;Timer B
                          jsr         _LVOAddICRVector(a6)                                                         ;AddICRVector()
                          tst.l       d0
                          beq.s       got_timer
try_CIAB                  lea         cianame-DB(a4),a1
                          cmp.b       #'a',3(a1)
                          bne.s       initerr
                          addq.b      #1,3(a1)
                          moveq       #8,d3                                                                        ;CIAB base addr index = 8
                          bra.w       open_ciares
;   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ attach interrupt
got_timer                 lea         craddr+8-DB(a4),a6
                          move.l      cia_addr(pc,d3.w),d0
                          move.l      d0,(a6)
                          sub.w       #$100,d0
                          move.l      d0,-(a6)
                          moveq       #2,d3                                                                        ;assume timer B
                          btst        #9,d0                                                                        ;timer A or B ?
                          bne.s       got_timerB
                          subq.b      #1,d3                                                                        ;not timer B -> subtract 1
                          add.w       #$100,d0                                                                     ;calc offset to timer control reg
got_timerB                add.w       #$900,d0
                          move.l      d0,-(a6)
                          move.l      d0,a0                                                                        ;get Control Register
                          and.b       #%10000000,(a0)                                                              ;clear CtrlReg bits 0 - 6
                          move.b      d3,_timeropen-DB(a4)                                                         ;d3: 1 = TimerA 2 = TimerB
                          ENDC

                          IFNE        VBLANK
                          moveq       #5,d0                                                                        ;INTB_VERTB
                          lea         timerinterrupt-DB(a4),a1
                          jsr         _LVOAddIntServer(a6)                                                         ;AddIntServer
                          st          _timeropen-DB(a4)
                          ENDC
                          
                          moveq       #0,d0
initret:                  movem.l     (sp)+,a4/a6/d2-d3
                          rts

;============================================================================

initerr:                  move.l      d2,d0
                          bra.s       initret

cia_addr:                 dc.l        $BFE501,$BFE701,$BFD500,$BFD700

_AudioRem:                movem.l     a5-a6,-(sp)
                          lea         DB,a5
                          moveq       #0,d0
                          move.b      _timeropen,d0
                          beq.s       rem1
;   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ remove interrupt
                          clr.b       _timeropen
                          IFNE        CIAB
                          move.l      _ciaresource,a6
                          lea         timerinterrupt-DB(a5),a1
                          subq.b      #1,d0
                          jsr         _LVORemICRVector(a6)                                                         ;RemICRVector
                          ENDC
                          IFNE        VBLANK
                          movea.l     4.w,a6
                          lea         timerinterrupt(pc),a1
                          moveq       #5,d0
                          jsr         _LVORemICRVector(a6)                                                         ;RemIntServer
                          ENDC
rem1:
                          IFNE        AUDDEV
                          movea.l     4.w,a6
                          tst.b       audiodevopen-DB(a5)
                          beq.s       rem2
                          move.w      #$000f,$dff096                                                               ;stop audio DMA
;   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ close audio.device
                          lea         allocreq-DB(a5),a1
                          jsr         _LVOCloseDevice(a6)                                                          ;CloseDevice()
                          clr.b       audiodevopen-DB(a5)
rem2:                     moveq       #0,d0
                          move.b      sigbitnum-DB(a5),d0
                          bmi.s       rem3
;   +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+ free signal bit
                          jsr         _LVOFreeSignal(a6)                                                           ;FreeSignal()
                          st          sigbitnum-DB(a5)
rem3:
                          ENDC
                          movem.l     (sp)+,a5-a6
                          rts

                          IFNE        MIDI
_GetSerial:               movem.l     a5-a6,-(sp)                                                                  ;Get serial port for MIDI
                          lea         DB,a5
                          bsr.s       GetSer2
                          tst.l       d0                                                                           ;got the port??
                          beq.s       rgser                                                                        ;yes
                          movea.l     4.w,a6                                                                       ;no..try to flush serial.device:
                          jsr         _LVOForbid(a6)                                                               ;Forbid
                          lea         $15e(a6),a0                                                                  ;ExecBase->DeviceList
                          lea         serdev-DB(a5),a1                                                             ;"serial.device"
                          jsr         _LVOFindName(a6)                                                             ;FindName
                          tst.l       d0
                          beq.s       serdnotf                                                                     ;no serial.device!!
                          move.l      d0,a1
                          jsr         _LVORemDevice(a6)                                                            ;RemDevice
serdnotf:                 jsr         _LVOPermit(a6)                                                               ;and Permit
                          bsr.s       GetSer2                                                                      ;now try it again...
rgser:                    movem.l     (sp)+,a5-a6
                          rts

GetSer2:                  movea.l     4.w,a6
                          moveq       #0,d0
                          lea         miscresname-DB(a5),a1
                          jsr         _LVOOpenResource(a6)                                                         ;OpenResource()
                          move.l      d0,miscresbase-DB(a5)
                          tst.l       d0
                          beq.s       gserror

                          move.l      d0,a6
                          lea         medname-DB(a5),a1
                          moveq       #MR_SERIALPORT,d0                                                            ;serial port
                          jsr         _LVOAllocMiscResource(a6)                                                    ;AllocMiscResource()
                          tst.l       d0
                          bne.s       gserror
                          
                          lea         medname-DB(a5),a1
                          moveq       #MR_SERIALBITS,d0                                                            ;serial bits
                          jsr         _LVOAllocMiscResource(a6)
                          tst.l       d0
                          beq.s       gs2_allocok

                          moveq       #0,d0
                          jsr         _LVOFreeMiscResource(a6)                                                     ;bits failed -> Free serial port
                          bra.s       gserror

gs2_allocok               move.w      $dff01c,d0
                          btst        #0,d0
                          sne         intrson-DB(a5)
                          moveq       #0,d0                                                                        ;TBE
                          lea         serinterrupt-DB(a5),a1
                          move.l      4.w,a6
                          jsr         _LVOSetIntVector(a6)                                                         ;SetIntVector()
                          move.l      d0,prevtbe-DB(a5)
                          move.w      #$8001,$dff09a                                                               ;TBE on
                          move.w      #114,$dff032                                                                 ;set baud rate (SERPER)
                          st          serportalloc-DB(a5)
                          moveq       #0,d0
                          rts

gserror:                  moveq       #-1,d0
                          rts

_FreeSerial:              movem.l     a5-a6,-(sp)
                          lea         DB,a5
                          tst.l       miscresbase-DB(a5)
                          beq.s       retfs
                          tst.b       serportalloc-DB(a5)
                          beq.s       retfs

wmb_loop                  move.w      $dff018,d0                                                                   ;WAIT until all data sent
                          btst        #12,d0                                                                       ;test TSRE bit of serdat
                          beq.s       wmb_loop

                          move.w      #$0001,$dff09a                                                               ;disable TBE
                          movea.l     4.w,a6
                          move.l      prevtbe-DB(a5),a1
                          moveq       #0,d0
                          jsr         _LVOSetIntVector(a6)                                                         ;SetIntVector()
                          
fs_noptbe                 movea.l     miscresbase-DB(a5),a6
                          moveq       #MR_SERIALPORT,d0                                                            ;serial port
                          jsr         _LVOFreeMiscResource(a6)                                                     ;FreeMiscResource()
                          
                          moveq       #MR_SERIALBITS,d0                                                            ;serial bits
                          jsr         _LVOFreeMiscResource(a6)
                          
                          clr.b       serportalloc-DB(a5)
                          clr.b       lastcmdbyte-DB(a5)
retfs:                    movem.l     (sp)+,a5-a6
                          rts

; Message number in d0.
_InitMIDIDump:            tst.b       serportalloc
                          beq.s       idd_rts
                          movem.l     a1/a5/a6,-(sp)                                                               ;a1 = data pointer, d1 = length
                          lea         DB,a5
                          movea.l     4.w,a6                                                                       ;ExecBase
                          jsr         _LVODisable(a6)                                                              ;Disable()
                          cmp.w       #16,dqentries-DB(a5)                                                         ;dump queue full?
                          bge.s       idd_exit                                                                     ;exit without doing anything
                          lea         dqwriteptr-DB(a5),a1
                          movea.l     (a1),a0
                          move.w      d0,(a0)+                                                                     ;store message number
                          cmpa.l      a1,a0                                                                        ;queue end?
                          bne.s       idd_noresetbuff
                          lea         dumpqueue-DB(a5),a0                                                          ;reset write pointer
idd_noresetbuff           move.l      a0,(a1)                                                                      ;and write it back.
                          addq.w      #1,dqentries-DB(a5)
                          tst.b       sysx-DB(a5)                                                                  ;already sending data?
                          bne.s       idd_exit                                                                     ;yes. Don't initiate new send.

                          clr.b       lastcmdbyte-DB(a5)
                          bsr         StartNewDump
                          move.w      $dff018,d0                                                                   ;serdatr
                          btst        #13,d0
                          beq.s       idd_exit

                          move.w      #$8001,$dff09c                                                               ;request TBE
idd_exit                  jsr         _LVOEnable(a6)                                                               ;Enable()
                          movem.l     (sp)+,a1/a5/a6
idd_rts                   rts

SerIntHandler:            move.w      #$4000,$9a(a0)                                                               ;disable..(Interrupts are enabled anyway)
                          move.w      #1,$9c(a0)                                                                   ;clear intreq bit
                          tst.b       sysx-buffptr(a1)                                                             ;sysx??
                          bne.s       sih_sysx
                          move.w      bytesinbuff-buffptr(a1),d0                                                   ;bytesinbuff
                          beq.s       exsih                                                                        ;buffer empty
                          movea.l     readbuffptr-buffptr(a1),a5                                                   ;get buffer read pointer
                          move.w      #$100,d1                                                                     ;Stop bit
                          move.b      (a5)+,d1                                                                     ;get byte
                          move.w      d1,$30(a0)                                                                   ;and push it to serdat
                          cmpa.l      a1,a5                                                                        ;shall we reset ptr?
                          bne.s       norrbuffptr                                                                  ;not yet..
                          lea         -256(a1),a5
norrbuffptr               subq.w      #1,d0                                                                        ;one less bytes in buffer
                          move.w      d0,bytesinbuff-buffptr(a1)                                                   ;remember it
                          move.l      a5,readbuffptr-buffptr(a1)                                                   ;push new read ptr back
exsih                     move.w      #$c000,$9a(a0)
                          rts
sih_sysx                  move.w      #$100,d1
                          movea.l     sysxptr-buffptr(a1),a5                                                       ;data pointer
                          move.b      (a5)+,d1
                          move.l      a5,sysxptr-buffptr(a1)
                          move.w      d1,$30(a0)                                                                   ;-> serdat
                          subq.l      #1,sysxleft-buffptr(a1)                                                      ;sub data left length
                          bne.s       exsih                                                                        ;not 0w
                          lea         DB,a5
                          clr.b       lastcmdbyte-DB(a5)
                          bsr.s       StartNewDump
                          bra.s       exsih

StartNewDump:             tst.w       dqentries-DB(a5)                                                             ;queue empty?
                          beq.s       snd_exit2
                          movea.l     dqreadptr-DB(a5),a1                                                          ;get read pointer
                          move.w      (a1)+,d0                                                                     ;get message number (D0)
                          cmpa.l      #dqwriteptr,a1                                                               ;queue end?
                          bne.s       snd_noresetbuff
                          lea         dumpqueue-DB(a5),a1                                                          ;reset write pointer
snd_noresetbuff           move.l      a1,dqreadptr-DB(a5)                                                          ;and write it back.
                          subq.w      #1,dqentries-DB(a5)
; then attempt to search the given message (# in D0)
                          move.l      _module-DB(a5),d1
                          beq.s       StartNewDump
                          move.l      d1,a1
                          move.l      mmd_expdata(a1),d1
                          beq.s       StartNewDump
                          move.l      d1,a1
                          move.l      52(a1),d1                                                                    ;exp_dump
                          beq.s       StartNewDump
                          move.l      d1,a1
                          cmp.w       (a1),d0
                          bge.s       StartNewDump
                          addq.l      #8,a1                                                                        ;points to MMDDump ptr table
                          add.w       d0,d0
                          add.w       d0,d0                                                                        ;number *= 4
                          adda.w      d0,a1
                          movea.l     (a1),a1
; initialize send variables (msg addr. in A0)
snd_found                 move.l      (a1)+,sysxleft-DB(a5)                                                        ;length
                          move.l      (a1),sysxptr-DB(a5)                                                          ;data pointer
                          st          sysx-DB(a5)
                          rts
snd_exit2                 clr.b       sysx-DB(a5)                                                                  ;finish dump
                          rts

_AddMIDIData              move.l      a6,-(sp)
                          lea         DB,a6
                          bsr.s       _AddMIDId
                          move.l      (sp)+,a6
                          rts

_AddMIDId                 movem.l     a1-a3/a5,-(sp)
                          tst.b       serportalloc-DB(a6)
                          beq.s       retamd1
                          movea.l     4.w,a5
                          lea         $dff09a,a3
                          move.w      #$4000,(a3)                                                                  ;Disable interrupts
                          addq.b      #1,$126(a5)                                                                  ;ExecBase->IDNestCnt
                          lea         buffptr-DB(a6),a2                                                            ;end of buffer (ptr)
                          move.w      -130(a3),d1                                                                  ;-130(a3) = $dff018 (serdatr)
                          btst        #13,d1
                          beq.s       noTBEreq
                          move.w      #$8001,2(a3)                                                                 ;request TBE [2(a3) = $dff09c]
noTBEreq                  movea.l     (a2),a1                                                                      ;buffer pointer
                          subq.w      #1,d0                                                                        ;-1 for DBF
adddataloop               move.b      (a0)+,d1                                                                     ;get byte
                          bpl.s       norscheck                                                                    ;this isn't a status byte
                          cmp.b       #$ef,d1                                                                      ;ignore system messages
                          bhi.s       norscheck
                          cmp.b       lastcmdbyte-DB(a6),d1                                                        ;same as previous status byte?
                          beq.s       samesb                                                                       ;yes, skip
                          move.b      d1,lastcmdbyte-DB(a6)                                                        ;no, don't skip but store.
norscheck                 move.b      d1,(a1)+                                                                     ;push to midi send buffer
                          addq.w      #1,8(a2)
samesb                    cmpa.l      a2,a1                                                                        ;end of buffer??
                          bne.s       noresbuffptr                                                                 ;no.
                          lea         sendbuffer-DB(a6),a1                                                         ;reset
noresbuffptr              dbf         d0,adddataloop
                          move.l      a1,(a2)                                                                      ;push back new buffer ptr
                          subq.b      #1,$126(a5)
                          bge.s       retamd1
                          move.w      #$c000,(a3)                                                                  ;enable interrupts again
retamd1                   movem.l     (sp)+,a1-a3/a5
                          rts
                          ENDC

                          DATA
DB:     ;Data base pointer
                          IFNE        MIDI
sendbuffer                ds.b        256
buffptr                   dc.l        sendbuffer
readbuffptr               dc.l        sendbuffer
bytesinbuff               dc.w        0
sysx                      dc.b        0
lastcmdbyte               dc.b        0
sysxptr                   dc.l        0
sysxleft                  dc.l        0
dumpqueue                 ds.w        16
dqwriteptr                dc.l        dumpqueue
dqreadptr                 dc.l        dumpqueue
dqentries                 dc.w        0
                          ENDC
miscresbase               dc.l        0
timerdiv                  dc.l        470000
                          IFNE        AUDDEV
audiodevopen              dc.b        0
sigbitnum                 dc.b        -1
                          ENDC
                          IFNE        MIDI
serportalloc              dc.b        0
                          ENDC
                          even
                          IFNE        MIDI
preschgdata               dc.l        0
noteondata                dc.l        0
                          ENDC
_module                   dc.l        0
dmaonmsk                  dc.w        0                                                                            ;\_May not be
                          IFNE        MIDI
bytesinnotebuff           dc.w        0                                                                            ;/ separated!
noteonbuff                ds.b        (MAX_NUMTRACKS+2)*3
                          even
intrson                   dc.b        0,0
prevtbe                   dc.l        0
                          ENDC
                          IFNE        CIAB
_ciaresource              dc.l        0
craddr                    dc.l        0
                          dc.l        0                                                                            ;tloaddr
                          dc.l        0                                                                            ;thiaddr
                          ENDC
timerinterrupt            dc.w        0,0,0,0,0
                          dc.l        timerintname,DB
                          dc.l        _IntHandler
                          IFNE        MIDI
serinterrupt              dc.w        0,0,0,0,0
                          dc.l        serintname,buffptr,SerIntHandler
                          ENDC
                          IFNE        AUDDEV
allocport                 dc.l        0,0                                                                          ;succ, pred
                          dc.b        4,0                                                                          ;NT_MSGPORT
                          dc.l        0                                                                            ;name
                          dc.b        0,0                                                                          ;flags = PA_SIGNAL
                          dc.l        0                                                                            ;task
reqlist                   dc.l        0,0,0                                                                        ;list head, tail and tailpred
                          dc.b        5,0
allocreq                  dc.l        0,0
                          dc.b        0,127                                                                        ;NT_UNKNOWN, use maximum priority (127)
                          dc.l        0,allocport                                                                  ;name, replyport
                          dc.w        68                                                                           ;length
                          dc.l        0                                                                            ;io_Device
                          dc.l        0                                                                            ;io_Unit
                          dc.w        0                                                                            ;io_Command
                          dc.b        0,0                                                                          ;io_Flags, io_Error
                          dc.w        0                                                                            ;ioa_AllocKey
                          dc.l        sttempo                                                                      ;ioa_Data
                          dc.l        1                                                                            ;ioa_Length
                          dc.w        0,0,0                                                                        ;ioa_Period, Volume, Cycles
                          dc.w        0,0,0,0,0,0,0,0,0,0                                                          ;ioa_WriteMsg
audiodevname              dc.b        'audio.device',0
                          ENDC
                          IFNE        CIAB
cianame                   dc.b        'ciax.resource',0
_timeropen                dc.b        0
                          ENDC
timerintname              dc.b        'OMEDTimerInterrupt',0
                          IFNE        MIDI
serintname                dc.b        'OMEDSerialInterrupt',0
miscresname               dc.b        'misc.resource',0
serdev                    dc.b        'serial.device',0
medname                   dc.b        'OctaMED Pro modplayer',0
                          ENDC
                          even
                          IFNE        MIDI
midiresd                  dc.b        $e0,$00,$40,$b0,$01,$00

midicontrnum              ds.b        16

prevmidicpres             dc.l        0,0,0,0,0,0,0,0                                                              ; 16 * 2 bytes

prevmidipbend             dc.w        $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
                          dc.w        $2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
                          ENDC
; TRACK-data structures (see definitions at the end of this file)
t03d                      ds.b        TAAOFFS
                          dc.l        $dff0a0
                          ds.b        TTMPVOLOFFS-(TAAOFFS+4)
                          dc.b        $ff
t03de                     ds.b        T03SZ-(t03de-t03d)
                          ds.b        TAAOFFS
                          dc.l        $dff0b0
                          ds.b        TTMPVOLOFFS-(TAAOFFS+4)
                          dc.b        $ff
                          ds.b        T03SZ-(t03de-t03d)
                          ds.b        TAAOFFS
                          dc.l        $dff0c0
                          ds.b        TTMPVOLOFFS-(TAAOFFS+4)
                          dc.b        $ff
                          ds.b        T03SZ-(t03de-t03d)
                          ds.b        TAAOFFS
                          dc.l        $dff0d0
                          ds.b        TTMPVOLOFFS-(TAAOFFS+4)
                          dc.b        $ff
                          ds.b        T03SZ-(t03de-t03d)
t463d                     ds.b        (MAX_NUMTRACKS-4)*T415SZ
trackdataptrs             dc.l        t03d,t03d+T03SZ,t03d+2*T03SZ,t03d+3*T03SZ
; Build pointer table. This works on Devpac assembler, other assemblers
; may need modifications.
TRKCOUNT                  SET         0
                          REPT        (MAX_NUMTRACKS-4)
                          dc.l        t463d+TRKCOUNT
TRKCOUNT                  SET         TRKCOUNT+T415SZ
                          ENDR

nextblock                 dc.b        0                                                                            ;\ DON'T SEPARATE
nxtnoclrln                dc.b        0 :/
numtracks                 dc.w        0                                                                            ;\ DON'T SEPARATE
numlines                  dc.w        0                                                                            ;/
numpages                  dc.w        0
nextblockline             dc.w        0
rptline                   dc.w        0                                                                            ;\ DON'T SEPARATE
rptcounter                dc.w        0                                                                            ;/
blkdelay                  dc.w        0                                                                            ;block delay (PT PatternDelay)
bpmcounter                dc.w        0
bpmdiv                    dc.l        3546895/2
fxplineblk                dc.l        0                                                                            ;for reading effects

; Fields in struct InstrExt (easier to access this way rather than
; searching through the module).
holdvals                  ds.b        63
decays                    ds.b        63
finetunes                 ds.b        63
flags                     ds.b        63
ext_midipsets             ds.w        63
outputdevs                ds.b        63
playing_aura              ds.b        1
                          EVEN

; Below are the period tables. There's one table for each finetune position.
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3424,3232,3048,2880,2712,2560,2416,2280,2152,2032,1920,1812
                          dc.w        1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,906
                          ENDC
per0                      dc.w        856,808,762,720,678,640,604,570,538,508,480,453
                          dc.w        428,404,381,360,339,320,302,285,269,254,240,226
                          dc.w        214,202,190,180,170,160,151,143,135,127,120,113
                          dc.w        214,202,190,180,170,160,151,143,135,127,120,113
                          dc.w        214,202,190,180,170,160,151,143,135,127,120,113
                          dc.w        214,202,190,180,170,160,151,143,135,127,120,113
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3400,3209,3029,2859,2699,2547,2404,2269,2142,2022,1908,1801
                          dc.w        1700,1605,1515,1430,1349,1274,1202,1135,1071,1011,954,901
                          ENDC
per1                      dc.w        850,802,757,715,674,637,601,567,535,505,477,450
                          dc.w        425,401,379,357,337,318,300,284,268,253,239,225
                          dc.w        213,201,189,179,169,159,150,142,134,126,119,113
                          dc.w        213,201,189,179,169,159,150,142,134,126,119,113
                          dc.w        213,201,189,179,169,159,150,142,134,126,119,113
                          dc.w        213,201,189,179,169,159,150,142,134,126,119,113
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3376,3187,3008,2839,2680,2529,2387,2253,2127,2007,1895,1788
                          dc.w        1688,1593,1504,1419,1340,1265,1194,1127,1063,1004,947,894
                          ENDC
per2                      dc.w        844,796,752,709,670,632,597,563,532,502,474,447
                          dc.w        422,398,376,355,335,316,298,282,266,251,237,224
                          dc.w        211,199,188,177,167,158,149,141,133,125,118,112
                          dc.w        211,199,188,177,167,158,149,141,133,125,118,112
                          dc.w        211,199,188,177,167,158,149,141,133,125,118,112
                          dc.w        211,199,188,177,167,158,149,141,133,125,118,112
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3352,3164,2986,2819,2660,2511,2370,2237,2112,1993,1881,1776
                          dc.w        1676,1582,1493,1409,1330,1256,1185,1119,1056,997,941,888
                          ENDC
per3                      dc.w        838,791,746,704,665,628,592,559,528,498,470,444
                          dc.w        419,395,373,352,332,314,296,280,264,249,235,222
                          dc.w        209,198,187,176,166,157,148,140,132,125,118,111
                          dc.w        209,198,187,176,166,157,148,140,132,125,118,111
                          dc.w        209,198,187,176,166,157,148,140,132,125,118,111
                          dc.w        209,198,187,176,166,157,148,140,132,125,118,111
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3328,3141,2965,2799,2641,2493,2353,2221,2097,1979,1868,1763
                          dc.w        1664,1571,1482,1399,1321,1247,1177,1111,1048,989,934,881
                          ENDC
per4                      dc.w        832,785,741,699,660,623,588,555,524,495,467,441
                          dc.w        416,392,370,350,330,312,294,278,262,247,233,220
                          dc.w        208,196,185,175,165,156,147,139,131,124,117,110
                          dc.w        208,196,185,175,165,156,147,139,131,124,117,110
                          dc.w        208,196,185,175,165,156,147,139,131,124,117,110
                          dc.w        208,196,185,175,165,156,147,139,131,124,117,110
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3304,3119,2944,2778,2622,2475,2336,2205,2081,1965,1854,1750
                          dc.w        1652,1559,1472,1389,1311,1238,1168,1103,1041,982,927,875
                          ENDC
per5                      dc.w        826,779,736,694,655,619,584,551,520,491,463,437
                          dc.w        413,390,368,347,328,309,292,276,260,245,232,219
                          dc.w        206,195,184,174,164,155,146,138,130,123,116,109
                          dc.w        206,195,184,174,164,155,146,138,130,123,116,109
                          dc.w        206,195,184,174,164,155,146,138,130,123,116,109
                          dc.w        206,195,184,174,164,155,146,138,130,123,116,109
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3280,3096,2922,2758,2603,2457,2319,2189,2066,1950,1841,1738
                          dc.w        1640,1548,1461,1379,1302,1229,1160,1095,1033,975,920,869
                          ENDC
per6                      dc.w        820,774,730,689,651,614,580,547,516,487,460,434
                          dc.w        410,387,365,345,325,307,290,274,258,244,230,217
                          dc.w        205,193,183,172,163,154,145,137,129,122,115,109
                          dc.w        205,193,183,172,163,154,145,137,129,122,115,109
                          dc.w        205,193,183,172,163,154,145,137,129,122,115,109
                          dc.w        205,193,183,172,163,154,145,137,129,122,115,109
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3256,3073,2901,2738,2584,2439,2302,2173,2051,1936,1827,1725
                          dc.w        1628,1537,1450,1369,1292,1220,1151,1087,1026,968,914,862
                          ENDC
per7                      dc.w        814,768,725,684,646,610,575,543,513,484,457,431
                          dc.w        407,384,363,342,323,305,288,272,256,242,228,216
                          dc.w        204,192,181,171,161,152,144,136,128,121,114,108
                          dc.w        204,192,181,171,161,152,144,136,128,121,114,108
                          dc.w        204,192,181,171,161,152,144,136,128,121,114,108
                          dc.w        204,192,181,171,161,152,144,136,128,121,114,108
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3628,3424,3232,3051,2880,2718,2565,2421,2285,2157,2036,1922
                          dc.w        1814,1712,1616,1525,1440,1359,1283,1211,1143,1079,1018,961
                          ENDC
per_8                     dc.w        907,856,808,762,720,678,640,604,570,538,508,480
                          dc.w        453,428,404,381,360,339,320,302,285,269,254,240
                          dc.w        226,214,202,190,180,170,160,151,143,135,127,120
                          dc.w        226,214,202,190,180,170,160,151,143,135,127,120
                          dc.w        226,214,202,190,180,170,160,151,143,135,127,120
                          dc.w        226,214,202,190,180,170,160,151,143,135,127,120
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3588,3387,3197,3017,2848,2688,2537,2395,2260,2133,2014,1901
                          dc.w        1794,1693,1598,1509,1424,1344,1269,1197,1130,1067,1007,950
                          ENDC
per_7                     dc.w        900,850,802,757,715,675,636,601,567,535,505,477
                          dc.w        450,425,401,379,357,337,318,300,284,268,253,238
                          dc.w        225,212,200,189,179,169,159,150,142,134,126,119
                          dc.w        225,212,200,189,179,169,159,150,142,134,126,119
                          dc.w        225,212,200,189,179,169,159,150,142,134,126,119
                          dc.w        225,212,200,189,179,169,159,150,142,134,126,119
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3576,3375,3186,3007,2838,2679,2529,2387,2253,2126,2007,1894
                          dc.w        1788,1688,1593,1504,1419,1339,1264,1193,1126,1063,1003,947
                          ENDC
per_6                     dc.w        894,844,796,752,709,670,632,597,563,532,502,474
                          dc.w        447,422,398,376,355,335,316,298,282,266,251,237
                          dc.w        223,211,199,188,177,167,158,149,141,133,125,118
                          dc.w        223,211,199,188,177,167,158,149,141,133,125,118
                          dc.w        223,211,199,188,177,167,158,149,141,133,125,118
                          dc.w        223,211,199,188,177,167,158,149,141,133,125,118
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3548,3349,3161,2984,2816,2658,2509,2368,2235,2110,1991,1879
                          dc.w        1774,1674,1580,1492,1408,1329,1254,1184,1118,1055,996,940
                          ENDC
per_5                     dc.w        887,838,791,746,704,665,628,592,559,528,498,470
                          dc.w        444,419,395,373,352,332,314,296,280,264,249,235
                          dc.w        222,209,198,187,176,166,157,148,140,132,125,118
                          dc.w        222,209,198,187,176,166,157,148,140,132,125,118
                          dc.w        222,209,198,187,176,166,157,148,140,132,125,118
                          dc.w        222,209,198,187,176,166,157,148,140,132,125,118
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3524,3326,3140,2963,2797,2640,2492,2352,2220,2095,1978,1867
                          dc.w        1762,1663,1570,1482,1399,1320,1246,1176,1110,1048,989,933
                          ENDC
per_4                     dc.w        881,832,785,741,699,660,623,588,555,524,494,467
                          dc.w        441,416,392,370,350,330,312,294,278,262,247,233
                          dc.w        220,208,196,185,175,165,156,147,139,131,123,117
                          dc.w        220,208,196,185,175,165,156,147,139,131,123,117
                          dc.w        220,208,196,185,175,165,156,147,139,131,123,117
                          dc.w        220,208,196,185,175,165,156,147,139,131,123,117
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3500,3304,3118,2943,2778,2622,2475,2336,2205,2081,1964,1854
                          dc.w        1750,1652,1559,1472,1389,1311,1237,1168,1102,1041,982,927
                          ENDC
per_3                     dc.w        875,826,779,736,694,655,619,584,551,520,491,463
                          dc.w        437,413,390,368,347,328,309,292,276,260,245,232
                          dc.w        219,206,195,184,174,164,155,146,138,130,123,116
                          dc.w        219,206,195,184,174,164,155,146,138,130,123,116
                          dc.w        219,206,195,184,174,164,155,146,138,130,123,116
                          dc.w        219,206,195,184,174,164,155,146,138,130,123,116
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3472,3277,3093,2920,2756,2601,2455,2317,2187,2064,1949,1839
                          dc.w        1736,1639,1547,1460,1378,1301,1228,1159,1094,1032,974,920
                          ENDC
per_2                     dc.w        868,820,774,730,689,651,614,580,547,516,487,460
                          dc.w        434,410,387,365,345,325,307,290,274,258,244,230
                          dc.w        217,205,193,183,172,163,154,145,137,129,122,115
                          dc.w        217,205,193,183,172,163,154,145,137,129,122,115
                          dc.w        217,205,193,183,172,163,154,145,137,129,122,115
                          dc.w        217,205,193,183,172,163,154,145,137,129,122,115
                          IFNE        SYNTH|IFFMOCT
                          dc.w        3448,3254,3072,2899,2737,2583,2438,2301,2172,2050,1935,1827
                          dc.w        1724,1627,1536,1450,1368,1292,1219,1151,1086,1025,968,913
                          ENDC
per_1                     dc.w        862,814,768,725,684,646,610,575,543,513,484,457
                          dc.w        431,407,384,363,342,323,305,288,272,256,242,228
                          dc.w        216,203,192,181,171,161,152,144,136,128,121,114
                          dc.w        216,203,192,181,171,161,152,144,136,128,121,114
                          dc.w        216,203,192,181,171,161,152,144,136,128,121,114
                          dc.w        216,203,192,181,171,161,152,144,136,128,121,114

_periodtable
                          dc.l        per_8,per_7,per_6,per_5,per_4,per_3,per_2,per_1,per0
                          dc.l        per1,per2,per3,per4,per5,per6,per7

                          IFND        __G2
                          section     "ProPlayerDataChip",data,chip                                                         ;for A68k
                          ENDC
                          IFD         __G2
                          section     "ProPlayerDataChip",data_c                                                            ;this is for Devpac 2
                          ENDC
                          XDEF        _modnum
                          IFNE        EASY
easymod                   INCBIN      "module"                                                                     ;<<<<< MODULE NAME HERE!
                          ENDC
_chipzero                 dc.l        0
_modnum                   dc.w        0                                                                            ;number of module to play

; macros for entering offsets
DEFWORD                   MACRO
\1                        EQU         OFFS
OFFS                      SET         OFFS+2
                          ENDM
DEFBYTE                   MACRO
\1                        EQU         OFFS
OFFS                      SET         OFFS+1
                          ENDM
DEFLONG                   MACRO
\1                        EQU         OFFS
OFFS                      SET         OFFS+4
                          ENDM

OFFS                      SET         0
; the track-data structure definition:
                          DEFBYTE     trk_prevnote                                                                 ;previous note number (0 = none, 1 = C-1..)
                          DEFBYTE     trk_previnstr                                                                ;previous instrument number
                          DEFBYTE     trk_prevvol                                                                  ;previous volume
                          DEFBYTE     trk_prevmidich                                                               ;previous MIDI channel
                          DEFBYTE     trk_prevmidin                                                                ;previous MIDI note
                          DEFBYTE     trk_noteoffcnt                                                               ;note-off counter (hold)
                          DEFBYTE     trk_inithold                                                                 ;default hold for this instrument
                          DEFBYTE     trk_initdecay                                                                ;default decay for....
                          DEFBYTE     trk_stransp                                                                  ;instrument transpose
                          DEFBYTE     trk_finetune                                                                 ;finetune
                          DEFWORD     trk_soffset                                                                  ;new sample offset | don't sep this and 2 below!
                          DEFBYTE     trk_miscflags                                                                ;bit: 7 = cmd 3 exists, 0 = cmd E exists
                          DEFBYTE     trk_currnote                                                                 ;note on CURRENT line (0 = none, 1 = C-1...)
                          DEFBYTE     trk_outputdev                                                                ;output device
                          DEFBYTE     trk_fxtype                                                                   ;fx type: 0 = norm, 1 = none, -1 = MIDI
                          DEFLONG     trk_previnstra                                                               ;address of the previous instrument data
                          DEFWORD     trk_trackvol
; the following data only on tracks 0 - 3
                          DEFWORD     trk_prevper                                                                  ;previous period
                          DEFLONG     trk_audioaddr                                                                ;hardware audio channel base address
                          DEFLONG     trk_sampleptr                                                                ;pointer to sample
                          DEFWORD     trk_samplelen                                                                ;length (>> 1)
                          DEFWORD     trk_porttrgper                                                               ;portamento (cmd 3) target period
                          DEFBYTE     trk_vibshift                                                                 ;vibrato shift for ASR instruction
                          DEFBYTE     trk_vibrspd                                                                  ;vibrato speed/size (cmd 4 qualifier)
                          DEFWORD     trk_vibrsz                                                                   ;vibrato size
                          DEFLONG     trk_synthptr                                                                 ;pointer to synthetic/hybrid instrument
                          DEFWORD     trk_arpgoffs                                                                 ;SYNTH: current arpeggio offset
                          DEFWORD     trk_arpsoffs                                                                 ;SYNTH: arpeggio restart offset
                          DEFBYTE     trk_volxcnt                                                                  ;SYNTH: volume execute counter
                          DEFBYTE     trk_wfxcnt                                                                   ;SYNTH: waveform execute counter
                          DEFWORD     trk_volcmd                                                                   ;SYNTH: volume command pointer
                          DEFWORD     trk_wfcmd                                                                    ;SYNTH: waveform command pointer
                          DEFBYTE     trk_volwait                                                                  ;SYNTH: counter for WAI (volume list)
                          DEFBYTE     trk_wfwait                                                                   ;SYNTH: counter for WAI (waveform list)
                          DEFWORD     trk_synthvibspd                                                              ;SYNTH: vibrato speed
                          DEFWORD     trk_wfchgspd                                                                 ;SYNTH: period change
                          DEFWORD     trk_perchg                                                                   ;SYNTH: curr. period change from trk_prevper
                          DEFLONG     trk_envptr                                                                   ;SYNTH: envelope waveform pointer
                          DEFWORD     trk_synvibdep                                                                ;SYNTH: vibrato depth
                          DEFLONG     trk_synvibwf                                                                 ;SYNTH: vibrato waveform
                          DEFWORD     trk_synviboffs                                                               ;SYNTH: vibrato pointer
                          DEFBYTE     trk_initvolxspd                                                              ;SYNTH: volume execute speed
                          DEFBYTE     trk_initwfxspd                                                               ;SYNTH: waveform execute speed
                          DEFBYTE     trk_volchgspd                                                                ;SYNTH: volume change
                          DEFBYTE     trk_prevnote2                                                                ;SYNTH: previous note
                          DEFBYTE     trk_synvol                                                                   ;SYNTH: current volume
                          DEFBYTE     trk_synthtype                                                                ;>0 = synth, -1 = hybrid, 0 = no synth
                          DEFLONG     trk_periodtbl                                                                ;pointer to period table
                          DEFWORD     trk_prevportspd                                                              ;portamento (cmd 3) speed
                          DEFBYTE     trk_decay                                                                    ;decay
                          DEFBYTE     trk_fadespd                                                                  ;decay speed
                          DEFLONG     trk_envrestart                                                               ;SYNTH: envelope waveform restart point
                          DEFBYTE     trk_envcount                                                                 ;SYNTH: envelope counter
                          DEFBYTE     trk_split                                                                    ;0 = this channel not splitted (OctaMED V2)
                          DEFWORD     trk_newper                                                                   ;new period (for synth use)
                          DEFBYTE     trk_vibroffs                                                                 ;vibrato table offset \ DON'T SEPARATE
                          DEFBYTE     trk_tremoffs                                                                 ;tremolo table offset /
                          DEFWORD     trk_tremsz                                                                   ;tremolo size
                          DEFBYTE     trk_tremspd                                                                  ;tremolo speed
                          DEFBYTE     trk_tempvol                                                                  ;temporary volume (for tremolo)
                          DEFWORD     trk_vibradjust                                                               ;vibrato +/- change from base period \ DON'T SEPARATE
                          DEFWORD     trk_arpadjust                                                                ;arpeggio +/- change from base period/
       