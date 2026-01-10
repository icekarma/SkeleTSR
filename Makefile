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

## Set to "tasm" to use Borland's Turbo Assembler.
## Set to "masm" to use Microsoft's Macro Assembler (MASM).
## Set to "jwasm" to use Japheth's JWASM assembler.
ASSEMBLER=masm

## Set to "link" to use Microsoft's LINK linker.
## Set to "tlink" to use Borland's Turbo Linker.
## ("wlink" and "jwlink" may be added in the future.)
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
!if ( "$(ASSEMBLER)" != "tasm" ) && ( "$(ASSEMBLER)" != "masm" ) && ( "$(ASSEMBLER)" != "jwasm" )
!	error Unknown assembler specified: "$(ASSEMBLER)". Valid options are "tasm", "masm", and "jwasm".
!endif
!if ( "$(LINKER)" != "link" ) && ( "$(LINKER)" != "tlink" )
!	error Unknown linker specified: "$(LINKER)". Valid options are "link" and "tlink".
!endif

## Disable browse info if not using MASM in debug build
!if ( "$(BROWSEINFO)" == "yes" ) && ( ( "$(ASSEMBLER)" != "masm" ) || ( "$(BUILDTYPE)" != "debug" ) )
BROWSEINFO=no
!endif

## Configure assembler
!if "$(ASSEMBLER)" == "tasm"
ASMCMD=tasm
!	if "$(BUILDTYPE)" == "debug"
ASMOPTS=-zi -c -la
!	else
ASMOPTS=-zn
!	endif
!elseif "$(ASSEMBLER)" == "masm"
ASMCMD=ml
ASMOPTS=-c -Cp -nologo
!	if "$(BUILDTYPE)" == "debug"
ASMOPTS=$(ASMOPTS) -Fl -Sa -Sc -W3 -Zi -D_DEBUG
!		if "$(BROWSEINFO)" == "yes"
ASMOPTS=$(ASMOPTS) -FR
!		endif
!	else
ASMOPTS=$(ASMOPTS) -DNDEBUG
!	endif
!elseif "$(ASSEMBLER)" == "jwasm"
ASMCMD=jwasmr
ASMOPTS=-c -Cp -nologo
!	if "$(BUILDTYPE)" == "debug"
ASMOPTS=$(ASMOPTS) -Fl -Sa -W4 -Zi3 -D_DEBUG
!	else
ASMOPTS=$(ASMOPTS) -DNDEBUG
!	endif
!endif

## Configure linker
!if "$(LINKER)" == "link"
LINKOPTS=/noi /nol /t
!	if "$(BUILDTYPE)" == "debug"
LINKOPTS=$(LINKOPTS) /co /m
!	endif
!elseif "$(LINKER)" == "tlink"
# most TLINK options are in tlink.cfg.
!	if "$(BUILDTYPE)" == "debug"
LINKOPTS=-Tde -s -v
!	else
LINKOPTS=-Tdc -x
!	endif
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
!	if "$(LINKER)" == "link"
DBG=$(NAME).dbg
!	endif
!	if "$(LINKER)" == "tlink"
EXE=$(NAME).exe
!	endif
MAP=$(NAME).map
!	if "$(LINKER)" == "tlink"
TDS=$(NAME).tds
!	endif
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

!if "$(LINKER)" == "link"
$(COM): $(OBJS)
	link $(LINKOPTS) $(OBJS),$(COM),$(MAP),,,
	if not errorlevel 1 dir $(COM)
!elseif "$(LINKER)" == "tlink"
!	if "$(BUILDTYPE)" == "debug"
$(COM): $(EXE)
	tdstrip -c -s $(EXE)
	if not errorlevel 1 dir $(COM)

$(EXE): $(OBJS)
	tlink $(LINKOPTS) $(OBJS),$(EXE),$(MAP)
!	else
$(COM): $(OBJS)
	tlink $(LINKOPTS) $(OBJS),$(COM)
	if not errorlevel 1 dir $(COM)
!	endif
!endif

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
	$(ASMCMD) $(ASMOPTS) $<

!if "$(BROWSEINFO)" == "yes"
.asm.sbr:
	ml $(ASMOPTS) $<
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
!	if "$(LINKER)" == "link"
	-if exist $(DBG) del $(DBG)
!	elseif "$(LINKER)" == "tlink"
	-if exist $(EXE) del $(EXE)
!	endif
	-if exist $(MAP) del $(MAP)
!	if "$(LINKER)" == "tlink"
	-if exist $(TDS) del $(TDS)
!	endif
!endif
