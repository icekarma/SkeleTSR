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

## Set to "masm" to use Microsoft's Macro Assembler (MASM).
## Set to "jwasm" to use Japheth's JWASM assembler.
## (If I can unify the Makefile:s, "tasm" will be supported for Borland''s Turbo
## Assembler.)
ASSEMBLER=masm

## Set to "link" to use Microsoft's LINK linker.
## (If I can unify the Makefile:s, "tlink" will be supported for Borland''s
## Turbo Linker. "wlink" and "jwlink" may be added as well.)
LINKER=link

## Set to "yes" to build browse information (MASM debug builds only).
BROWSEINFO=no

##================================================
## No user-serviceable parts below here
##================================================

NAME=skeletsr

all: $(NAME)

## Validate configuration options
!if ( "$(BUILDTYPE)" != "release" ) && ( "$(BUILDTYPE)" != "debug" )
!	error Unknown build type specified: "$(BUILDTYPE)". Valid options are "release" and "debug".
!endif
!if ( "$(BROWSEINFO)" != "yes" ) && ( "$(BROWSEINFO)" != "no" )
!	error Unknown BROWSEINFO option specified: "$(BROWSEINFO)". Valid options are "yes" and "no".
!endif
!if ( "$(ASSEMBLER)" != "masm" ) && ( "$(ASSEMBLER)" != "jwasm" )
!	error Unknown assembler specified: "$(ASSEMBLER)". Valid options are "masm" and "jwasm".
!endif
!if ( "$(LINKER)" != "link" )
!	error Unknown linker specified: "$(LINKER)". Valid options are "link".
!endif

## Disable browse info if not using MASM in debug build
!if ( "$(BROWSEINFO)" == "yes" ) && ( ( "$(ASSEMBLER)" != "masm" ) || ( "$(BUILDTYPE)" != "debug" ) )
BROWSEINFO=no
!endif

## Configure assembler
MASMOPTS=-c -Cp -nologo
!if "$(ASSEMBLER)" == "masm"
ASMCMD=ml
!	if "$(BUILDTYPE)" == "debug"
MASMOPTS=$(MASMOPTS) -Fl -Sa -Sc -W3 -Zi -D_DEBUG
!		if "$(BROWSEINFO)" == "yes"
MASMOPTS=$(MASMOPTS) -FR
!		endif
!	else
MASMOPTS=$(MASMOPTS) -DNDEBUG
!	endif
!elseif "$(ASSEMBLER)" == "jwasm"
ASMCMD=jwasmr
!	if "$(BUILDTYPE)" == "debug"
MASMOPTS=$(MASMOPTS) -Fl -Sa -W4 -Zi3 -D_DEBUG
!	else
MASMOPTS=$(MASMOPTS) -DNDEBUG
!	endif
!endif

## Configure linker
LINKOPTS=/noi /nol /t
!if "$(BUILDTYPE)" == "debug"
LINKOPTS=$(LINKOPTS) /co /m
!endif

## Configure output files
!if "$(ASSEMBLER)" == "jwasm"
ERRS=segments.err skeletsr.err bss.err cmdline.err mplex.err
!endif
!if "$(BUILDTYPE)" == "debug"
LSTS=segments.lst skeletsr.lst bss.lst cmdline.lst mplex.lst
!endif
OBJS=segments.obj skeletsr.obj bss.obj cmdline.obj mplex.obj
!if "$(BROWSEINFO)" == "yes"
SBRS=segments.sbr skeletsr.sbr bss.sbr cmdline.sbr mplex.sbr
BSC=$(NAME).bsc
!endif
COM=$(NAME).com
!if "$(BUILDTYPE)" == "debug"
DBG=$(NAME).dbg
MAP=$(NAME).map
!else
MAP=NUL
!endif

!if "$(BROWSEINFO)" == "yes"
$(NAME): $(COM) $(BSC)
!else
$(NAME): $(COM)
!endif

##
## Silly/useful targets, since DOSBox's command line is lame and doesn't support
## multiple commands on one line.
##

build:
	@echo BUILDTYPE=$(BUILDTYPE)
	@echo BROWSEINFO=$(BROWSEINFO)
	@echo ASSEMBLER=$(ASSEMBLER)
	@echo LINKER=$(LINKER)

cls:
	cls

load: $(COM)
	$(NAME)

unload: $(COM)
	$(NAME) /u

world: cls build clean all

##
## Target executable
##

$(COM): $(OBJS)
	link $(LINKOPTS) $(OBJS),$(COM),$(MAP),,,
	if not errorlevel 1 dir $(COM)

!if "$(BROWSEINFO)" == "yes"
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
	$(ASMCMD) $(MASMOPTS) $<

!if "$(BROWSEINFO)" == "yes"
.asm.sbr:
	ml $(MASMOPTS) $<
!endif

##
## Cleanup
##

clean:
!if "$(ASSEMBLER)" == "jwasm"
	-for %a in ($(ERRS)) do if exist %a del %a
!endif
!if "$(BUILDTYPE)" == "debug"
	-for %a in ($(LSTS)) do if exist %a del %a
!endif
	-for %a in ($(OBJS)) do if exist %a del %a
!if "$(BROWSEINFO)" == "yes"
	-for %a in ($(SBRS)) do if exist %a del %a
	-if exist $(BSC) del $(BSC)
!endif
	-if exist $(COM) del $(COM)
!if "$(BUILDTYPE)" == "debug"
	-if exist $(DBG) del $(DBG)
	-if exist $(MAP) del $(MAP)
!endif
