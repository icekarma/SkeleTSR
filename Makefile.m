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

## Set to "yes" to build browse information (debug builds only).
BROWSEINFO=no

##================================================
## No user-serviceable parts below here
##================================================

NAME=skeletsr

LSTS=segments.lst skeletsr.lst bss.lst cmdline.lst mplex.lst
OBJS=segments.obj skeletsr.obj bss.obj cmdline.obj mplex.obj
!if ( "$(BUILDTYPE)" != "release" ) && ( "$(BROWSEINFO)" == "yes" )
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

MASMOPTS=/AT /c /Cp /nologo
LINKOPTS=/noi /nol /t
!if "$(BUILDTYPE)" != "release"
MASMOPTS=$(MASMOPTS) /Fl /Sa /Sc /Sg /Sx /W3 /Zi
!if "$(BROWSEINFO)" == "yes"
MASMOPTS=$(MASMOPTS) /FR
!endif
LINKOPTS=$(LINKOPTS) /co /m
!endif

all: $(NAME)

!if ( "$(BUILDTYPE)" != "release" ) && ( "$(BROWSEINFO)" == "yes" )
$(NAME): $(COM) $(BSC)
!else
$(NAME): $(COM)
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

!if ( "$(BUILDTYPE)" != "release" ) && ( "$(BROWSEINFO)" == "yes" )
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

!if ( "$(BUILDTYPE)" != "release" ) && ( "$(BROWSEINFO)" == "yes" )
.asm.sbr:
	ml $(MASMOPTS) $<
!endif

##
## Clean up
##

clean:
!if "$(BUILDTYPE)" != "release"
	-for %a in ($(LSTS)) do if exist %a del %a
!endif
	-for %a in ($(OBJS)) do if exist %a del %a
!if ( "$(BUILDTYPE)" != "release" ) && ( "$(BROWSEINFO)" == "yes" )
	-for %a in ($(SBRS)) do if exist %a del %a
	-if exist $(BSC) del $(BSC)
!endif
	-if exist $(COM) del $(COM)
!if "$(BUILDTYPE)" != "release"
	-if exist $(DBG) del $(DBG)
	-if exist $(MAP) del $(MAP)
!endif
