##================================================
## SKELETSR: A skeleton DOS TSR program
## Makefile: `make` recipes for building SKELETSR with Borland MAKE
## Copyright © 2026 Zive Technology Research
## Licensed under the BSD 2-Clause License
##================================================

##================================================
## User-configurable options
##================================================

## Set to "release" for a release build, "debug" for a debug build.
##
## The debug build is complicated, in order to generate debugging information
## for a .COM file, but *does* allow you to step through the code in Turbo
## Debugger.
##
## The release build is a straightforward .COM build with no debug information.
##
## To switch build types, it is recommended to run `make clean` first, *before*
## changing the BUILDTYPE variable.

BUILDTYPE=debug

##================================================
## No user-serviceable parts below here
##================================================

NAME=skeletsr

LSTS=segments.lst skeletsr.lst bss.lst cmdline.lst mplex.lst
OBJS=segments.obj skeletsr.obj bss.obj cmdline.obj mplex.obj
COM=$(NAME).com
EXE=$(NAME).exe
MAP=$(NAME).map
TDS=$(NAME).tds

## Options common to both builds are set in TASM.CFG and TLINK.CFG.
!if "$(BUILDTYPE)" == "release"
TASMOPTS=-zn
TLINKOPTS=-Tdc -x
!else
TASMOPTS=-zi -c -la
TLINKOPTS=-Tde -s -v
!endif

all: $(NAME)

$(NAME): $(COM)

##
## Silly/useful targets, since DOSBox's command line is lame and doesn't support multiple commands on one line
##

build:
	@echo Current build type is: $(BUILDTYPE)

cls:
	cls

load: $(COM)
	$(NAME)

unload: $(COM)
	$(NAME) /u

world: cls build clean all

##
## SKELETSR
##

!if "$(BUILDTYPE)" == "release"
$(COM): $(OBJS)
	tlink $(TLINKOPTS) $(OBJS),$(COM)
	if not errorlevel 1 dir $(COM)
!else
$(COM): $(EXE)
	tdstrip -c -s $(EXE)
	if not errorlevel 1 dir $(COM)

$(EXE): $(OBJS)
	tlink $(TLINKOPTS) $(OBJS),$(EXE),$(MAP)
!endif

##
## Dependencies
##

bss.obj:      bss.asm      common.inc cpumacs.inc dosmacs.inc
cmdline.obj:  cmdline.asm  common.inc cpumacs.inc dosmacs.inc
mplex.obj:    mplex.asm    common.inc cpumacs.inc dosmacs.inc
segments.obj: segments.asm common.inc cpumacs.inc dosmacs.inc
skeletsr.obj: skeletsr.asm common.inc cpumacs.inc dosmacs.inc
stackmgr.obj: stackmgr.asm common.inc cpumacs.inc dosmacs.inc

##
## Generic rules
##

.asm.obj:
	tasm $(TASMOPTS) $<

##
## Clean up
##

clean:
!if "$(BUILDTYPE)" != "release"
	-for %a in ($(LSTS)) do if exist %a del %a
!endif
	-for %a in ($(OBJS)) do if exist %a del %a
	-for %a in ($(COM)) do if exist %a del %a
!if "$(BUILDTYPE)" != "release"
	-for %a in ($(EXE)) do if exist %a del %a
	-for %a in ($(MAP)) do if exist %a del %a
	-for %a in ($(TDS)) do if exist %a del %a
!endif
