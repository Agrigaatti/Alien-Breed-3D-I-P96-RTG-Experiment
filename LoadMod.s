*********************************************************************************************
;	(Octa)MED module load routines, by Teijo Kinnunen
;	MED V3.00 module support added		22-Jan-1991
;	upgraded for V3.20 (OctaMED V2.00)	02-Aug-1991
;	and for OctaMED Pro V3.00		02-Apr-1992
;	(bug fix)				31-May-1992
;	OctaMED Pro V5 support (MMD2)		18-May-1993
;	OctaMED Pro V6 support (cmd pages)	16-Jan-1995
;	2 bug fixes (Thanks to Peter Kunath.)	14-Feb-1995

;	$VER: loadmod_a 6.1 (14.02.1995)

;	Function: d0 = _LoadModule(a0)
;	a0 = module name
;	d0 = pointer to loaded module, zero if load failed
*********************************************************************************************

                          incdir     "includes"
                          include    "macros.i"

*********************************************************************************************

                          XDEF       _LoadModule
                          XDEF       _UnLoadModule
                          XDEF       _RelocModule

*********************************************************************************************

mmd_songinfo    EQU 8
mmd_blockarr    EQU 16
mmd_expdata     EQU 32
mmd_songsleft   EQU 51
msng_numblocks  EQU 504
msng_pseqs      EQU 508
msng_numsamples EQU 787

*********************************************************************************************

                          SECTION    LoadMEDMusicCode,CODE_F

*********************************************************************************************

_LoadModule:
                          movem.l    a2-a4/a6/d2-d6,-(sp)
                          moveq      #0,d6                     ;d6 = return value (zero = error)
                          move.l     a0,a4                     ;a4 = module name
                          movea.l    4,a6
                          lea        dosname(pc),a1
                          moveq      #0,d0
                          jsr        -$228(a6)                 ;OpenLibrary()
                          tst.l      d0
                          beq        xlm1
                          move.l     d0,a3                     ;a3 = DOSBase
                          move.l     d0,a6
                          move.l     a4,d1                     ;name = d1
                          move.l     #1005,d2                  ;accessmode = MODE_OLDFILE
                          jsr        -$1e(a6)                  ;Open()
                          move.l     d0,d4                     ;d4 = file handle
                          beq        xlm2
                          move.l     d4,d1
                          moveq      #0,d2
                          moveq      #1,d3                     ;OFFSET_END
                          jsr        -$42(a6)                  ;Seek(fh,0,OFFSET_END)
                          move.l     d4,d1
                          moveq      #-1,d3                    ;OFFSET_BEGINNING
                          jsr        -$42(a6)                  ;Seek(fh,0,OFFSET_BEGINNING)
                          move.l     d0,d5                     ;d5 = file size
                          movea.l    4,a6
                          moveq      #2,d1                     ;get chip mem
                          jsr        -$c6(a6)                  ;AllocMem()
                          tst.l      d0
                          beq.s      xlm3
                          move.l     d0,a2                     ;a2 = pointer to module
                          move.l     d4,d1                     ;file
                          move.l     d0,d2                     ;buffer
                          move.l     d5,d3                     ;length
                          move.l     a3,a6
                          jsr        -$2a(a6)                  ;Read()
                          cmp.l      d5,d0
                          bne.s      xlm4                      ;something wrong...
                          cmp.l      #'MMD2',(a2)              ;Pro V5 module?
                          beq.s      id_ok
                          cmp.l      #'MMD1',(a2)              ;Pro module?
                          beq.s      id_ok
                          cmp.l      #'MMD0',(a2)
                          bne.s      xlm4                      ;this is not a module!!!
id_ok                     movea.l    a2,a0
                          bsr        _RelocModule
                          move.l     a2,d6                     ;no error...
                          bra.s      xlm3
xlm4                      move.l     a2,a1                     ;error: free the memory
                          move.l     d5,d0
                          movea.l    4,a6
                          jsr        -$d2(a6)                  ;FreeMem()
xlm3                      move.l     a3,a6                     ;close the file
                          move.l     d4,d1
                          jsr        -$24(a6)                  ;Close(fhandle)
xlm2                      move.l     a3,a1                     ;close dos.library
                          movea.l    4,a6
                          jsr        -$19e(a6)
xlm1                      move.l     d6,d0                     ;push return value
                          movem.l    (sp)+,a2-a4/a6/d2-d6      ;restore registers
                          rts                                  ;and exit...

*********************************************************************************************

dosname                   dc.b       'dos.library',0
                          cnop       0,32

*********************************************************************************************
;	Function: _RelocModule(a0)
;	a0 = pointer to module

; This function is a bit strangely arranged around the small reloc-routine.
reloci                    move.l     24(a2),d0
                          beq.s      xloci
                          movea.l    d0,a0
                          moveq      #0,d0
                          move.b     msng_numsamples(a1),d0    ;number of samples
                          subq.b     #1,d0
relocs                    bsr.s      relocentr
                          move.l     -4(a0),d3                 ;sample ptr
                          beq.s      nosyn
                          move.l     d3,a3
                          tst.w      4(a3)
                          bpl.s      nosyn                     ;type >= 0
                          move.w     20(a3),d2                 ;number of waveforms
                          lea        278(a3),a3                ;ptr to wf ptrs
                          subq.w     #1,d2
relsyn                    add.l      d3,(a3)+
                          dbf        d2,relsyn
nosyn                     dbf        d0,relocs
xloci                     rts
norel                     addq.l     #4,a0
                          rts
relocentr                 tst.l      (a0)
                          beq.s      norel
                          add.l      d1,(a0)+
                          rts

*********************************************************************************************

_RelocModule:
                          movem.l    a2-a4/d2-d4,-(sp)
                          movea.l    a0,a2
                          move.l     a2,d1                     ;d1 = ptr to start of module
                          bsr.s      relocp
                          movea.l    mmd_songinfo(a2),a1
                          bsr.s      reloci
                          move.b     mmd_songsleft(a2),d4
rel_lp                    bsr.s      relocb
                          cmp.b      #'2',3(a2)                ;MMD2?
                          bne.s      norelmmd2
                          bsr.w      relocmmd2sng
norelmmd2                 move.l     mmd_expdata(a2),d0        ;extension struct
                          beq.s      rel_ex
                          move.l     d0,a0
                          bsr.s      relocentr                 ;ptr to next module
                          bsr.s      relocentr                 ;InstrExt...
                          addq.l     #4,a0                     ;skip sizes of InstrExt
; We reloc the pointers of MMD0exp, so anybody who needs them can easily
; read them.
                          bsr.s      relocentr                 ;annotxt
                          addq.l     #4,a0                     ;annolen
                          bsr.s      relocentr                 ;InstrInfo
                          addq.l     #8,a0
                          bsr.s      relocentr                 ;rgbtable (not useful for most people)
                          addq.l     #4,a0                     ;skip channelsplit
                          bsr.s      relocentr                 ;NotationInfo
                          bsr.s      relocentr                 ;songname
                          addq.l     #4,a0                     ;skip song name length
                          bsr.s      relocentr                 ;MIDI dumps
                          bsr.s      relocmdd
                          subq.b     #1,d4                     ;songs left..?
                          bcs.s      rel_ex
                          move.l     d0,a0
                          move.l     (a0),d0
                          beq.s      rel_ex
                          move.l     d0,a2
                          bsr.s      relocp
                          movea.l    8(a2),a1
                          bra.s      rel_lp
rel_ex                    movem.l    (sp)+,d2-d4/a2-a4
                          rts

relocp                    lea        mmd_songinfo(a2),a0
                          bsr.s      relocentr
                          addq.l     #4,a0
                          bsr.s      relocentr
                          addq.l     #4,a0
                          bsr.s      relocentr
                          addq.l     #4,a0
                          bra.s      relocentr

relocb                    move.l     mmd_blockarr(a2),d0
                          beq.s      xlocb
                          movea.l    d0,a0
                          move.w     msng_numblocks(a1),d0
                          subq.b     #1,d0
rebl                      bsr        relocentr
                          dbf        d0,rebl
                          cmp.b      #'T',3(a2)                ;MMD0 (= MCNT)
                          beq.s      xlocb
                          cmp.b      #'1',3(a2)                ;test MMD type
                          bge.s      relocbi
xlocb                     rts

relocmdd                  move.l     d0,-(sp)
                          tst.l      -(a0)
                          beq.s      xlocmdd
                          movea.l    (a0),a0
                          move.w     (a0),d0                   ;# of msg dumps
                          addq.l     #8,a0
mddloop                   beq.s      xlocmdd
                          bsr        relocentr
                          bsr.s      relocdmp
                          subq.w     #1,d0
                          bra.s      mddloop
xlocmdd                   move.l     (sp)+,d0
                          rts

relocdmp                  move.l     -4(a0),d3
                          beq.s      xlocdmp
                          exg.l      a0,d3                     ;save
                          addq.l     #4,a0
                          bsr        relocentr                 ;reloc data pointer
                          move.l     d3,a0                     ;restore
xlocdmp                   rts

relocbi                   move.w     msng_numblocks(a1),d0
                          move.l     a0,a3
biloop                    subq.w     #1,d0
                          bmi.s      xlocdmp
                          move.l     -(a3),a0
                          addq.l     #4,a0
                          bsr        relocentr                 ;BlockInfo ptr
                          tst.l      -(a0)
                          beq.s      biloop
                          move.l     (a0),a0
                          bsr        relocentr                 ;hldata
                          bsr        relocentr                 ;block name
                          addq.l     #4,a0                     ;skip blocknamelen
                          bsr        relocentr                 ;pagetable
                          tst.l      -(a0)
                          bne.s      relocpgtbl
                          bra.s      biloop
; take care of the new features of MMD2s
relocmmd2sng              move.l     mmd_songinfo(a2),a0
                          lea        msng_pseqs(a0),a0
                          bsr        relocentr                 ;playseqtable
                          bsr        relocentr                 ;sectiontable
                          bsr        relocentr                 ;trackvols
                          move.w     2(a0),d0                  ;numpseqs
                          move.l     -12(a0),a0                ;get back to playseqtable
                          subq.w     #1,d0
psqtblloop                bsr        relocentr
                          dbf        d0,psqtblloop
                          rts
relocpgtbl                movea.l    (a0),a4                   ;page table list hdr
                          move.w     (a4),d2
                          subq.w     #1,d2
                          lea        4(a4),a0
pgtblloop                 bsr        relocentr
                          dbf        d2,pgtblloop
                          bra        biloop

*********************************************************************************************
;	Function: _UnLoadModule(a0)
;	a0 = pointer to module

_UnLoadModule:
                          move.l     a6,-(sp)
                          move.l     a0,d0
                          beq.s      xunl
                          movea.l    4,a6
                          move.l     4(a0),d0
                          beq.s      xunl
                          movea.l    a0,a1
                          jsr        -$d2(a6)                  ;FreeMem()
xunl                      move.l     (sp)+,a6
                          rts

*********************************************************************************************