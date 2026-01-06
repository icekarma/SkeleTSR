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

NAME=SKELETSR

LSTS=SEGMENTS.LST SKELETSR.LST BSS.LST CMDLINE.LST MPLEX.LST
OBJS=SEGMENTS.OBJ SKELETSR.OBJ BSS.OBJ CMDLINE.OBJ MPLEX.OBJ
!if "$(BUILDTYPE)" != "release"
SBRS=SEGMENTS.SBR SKELETSR.SBR BSS.SBR CMDLINE.SBR MPLEX.SBR
BSC=$(NAME).BSC
!endif
COM=$(NAME).COM
!if "$(BUILDTYPE)" == "release"
MAP=NUL
!else
DBG=$(NAME).DBG
MAP=$(NAME).MAP
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

bss.obj:      bss.asm      common.inc dosmacs.inc
cmdline.obj:  cmdline.asm  common.inc dosmacs.inc
mplex.obj:    mplex.asm    common.inc dosmacs.inc
segments.obj: segments.asm common.inc dosmacs.inc
skeletsr.obj: skeletsr.asm common.inc dosmacs.inc
stackmgr.obj: stackmgr.asm common.inc dosmacs.inc

##
## Generic rules
##

.asm.obj:
	ml $(MASMOPTS) $<

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
