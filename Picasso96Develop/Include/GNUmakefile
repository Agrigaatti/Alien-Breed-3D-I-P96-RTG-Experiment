#
#	$Id: GNUmakefile,v 1.1 2020/04/13 17:28:41 thor Exp $
#

FILES :=	$(wildcard *.c *.h *.asm *.i *.rev *.fd *.doc smakefile GNUmakefile SCOPTIONS)
DIRS :=	autodocs clib fd inline libraries pragmas proto

###############################################################################
#
#	Ab hier bitte nichts mehr manuell �ndern
#
###############################################################################

all:
	@echo "Dieses GNUmakefile bitte nicht direkt aufrufen."

checkin:
	@-makedir >nil: RCS
	$(foreach file,$(FILES),ci -M -l -m. -t-. $(file); )
ifneq ($(DIRS),)
	$(foreach dir,$(DIRS),cd "$(dir)"; $(MAKE) -f GNUmakefile $(TESTING) $@ MAKE=$(MAKE); cd /;)
endif

freeze:
	$(foreach file,$(FILES),rcs -q -n$(SYMBOLIC_NAME):  $(file); )
ifneq ($(DIRS),)
	$(foreach dir,$(DIRS),cd "$(dir)"; \
		$(MAKE) -f GNUmakefile $(TESTING) $@ SYMBOLIC_NAME=$(SYMBOLIC_NAME) MAKE=$(MAKE); \
		cd /;)
endif

.PHONY: all checkin freeze
.SUFFIXES: .c .h .asm .i .rev .doc .fd
