##================================================
## SKELETSR: A skeleton DOS TSR program
## Makefile: `make` recipes for building SKELETSR with Microsoft NMAKE
## Copyright © 2026 Zive Technology Research
## Licensed under the BSD 2-Clause License
##================================================

##================================================
## User-configurable options
##================================================

## Set to "release" for a release build, "debug" for a debug build.
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
!if "$(BUILDTYPE)" != "release"
SBRS=segments.sbr skeletsr.sbr bss.sbr cmdline.sbr mplex.sbr
BSC=$(NAME).bsc
!endif
COM=$(NAME).com
!if "$(BUILDTYPE)" == "release"
MAP=NUL
!else
DBG=$(NAME).dbg
MAP=$(NAME).map
!endif

!if "$(BUILDTYPE)" == "release"
MASMOPTS=/AT /c /Cp /W3 /nologo
LINKOPTS=/noi /nol /t
!else
MASMOPTS=/AT /c /Cp /W3 /nologo /Fl /FR /Sa /Sc /Sg /Sx /Zi
LINKOPTS=/noi /nol /t /co /m
!endif

all: $(NAME)

!if "$(BUILDTYPE)" == "release"
$(NAME): $(COM)
!else
$(NAME): $(COM) $(BSC)
!endif

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

$(COM): $(OBJS)
	link $(LINKOPTS) $(OBJS),$(COM),$(MAP),,,
	if not errorlevel 1 dir $(COM)

!if "$(BUILDTYPE)" != "release"
$(BSC): $(SBRS)
	bscmake /Iu /n /nologo /o $(BSC) $(SBRS)
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
	ml $(MASMOPTS) $<

!if "$(BUILDTYPE)" != "release"
.asm.sbr:
	ml $(MASMOPTS) $<
!endif

##
## Clean up
##

clean:
	-for %a in ($(OBJS)) do if exist %a del %a
!if "$(BUILDTYPE)" != "release"
	-for %a in ($(LSTS)) do if exist %a del %a
	-for %a in ($(SBRS)) do if exist %a del %a
!endif
	-for %a in ($(BSC)) do if exist %a del %a
	-for %a in ($(COM)) do if exist %a del %a
!if "$(BUILDTYPE)" != "release"
	-for %a in ($(DBG)) do if exist %a del %a
	-for %a in ($(MAP)) do if exist %a del %a
!endif
