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
## Set to "jwlink" to use Japheth's JWLINK linker.
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
!if ( "$(LINKER)" != "link" ) && ( "$(LINKER)" != "tlink" ) && ( "$(LINKER)" != "jwlink" )
!	error Unknown linker specified: "$(LINKER)". Valid options are "link", "tlink", and "jwlink".
!endif

## Disable browse info if not using MASM in debug build
!if ( "$(BROWSEINFO)" == "yes" ) && ( ( "$(ASSEMBLER)" != "masm" ) || ( "$(BUILDTYPE)" != "debug" ) )
BROWSEINFO=no
!endif

## Configure assembler
!if "$(ASSEMBLER)" == "tasm"
AS=tasm
!	if "$(BUILDTYPE)" == "debug"
AFLAGS=-zi -c -la
!	else
AFLAGS=-zn
!	endif
!elseif "$(ASSEMBLER)" == "masm"
AS=ml
AFLAGS=-c -Cp -nologo
!	if "$(BUILDTYPE)" == "debug"
AFLAGS=$(AFLAGS) -Fl -Sa -Sc -W3 -Zi -D_DEBUG
!		if "$(BROWSEINFO)" == "yes"
AFLAGS=$(AFLAGS) -FR
!		endif
!	else
AFLAGS=$(AFLAGS) -DNDEBUG
!	endif
!elseif "$(ASSEMBLER)" == "jwasm"
AS=jwasmr
AFLAGS=-c -Cp -nologo
!	if "$(BUILDTYPE)" == "debug"
AFLAGS=$(AFLAGS) -Fl -Sa -W4 -Zi3 -D_DEBUG
!	else
AFLAGS=$(AFLAGS) -DNDEBUG
!	endif
!endif

## Configure linker
!if "$(LINKER)" == "link"
LD=link
LFLAGS=/noi /nol /t
!	if "$(BUILDTYPE)" == "debug"
LFLAGS=$(LFLAGS) /co /m
!	endif
!elseif "$(LINKER)" == "tlink"
LD=tlink
!	if "$(BUILDTYPE)" == "debug"
LFLAGS=-Tde -s -v
!	else
LFLAGS=-Tdc -x
!	endif
!elseif "$(LINKER)" == "jwlink"
LD=jwlink
!endif

## Configure output files
ASMS=segstart.asm skeletsr.asm cmdline.asm mplex.asm segend.asm
!if "$(ASSEMBLER)" == "jwasm"
ERRS=$(ASMS:.asm=.err)
!endif
!if "$(BUILDTYPE)" == "debug"
LSTS=$(ASMS:.asm=.lst)
!endif
OBJS=$(ASMS:.asm=.obj)
!if "$(BROWSEINFO)" == "yes"
SBRS=$(ASMS:.asm=.sbr)
BSC=$(NAME).bsc
!endif
COM=$(NAME).com
!if "$(BUILDTYPE)" == "debug"
!	if "$(LINKER)" == "link"
DBG=$(NAME).dbg
!	elseif "$(LINKER)" == "tlink"
DBG=$(NAME).tds
EXE=$(NAME).exe
!	elseif "$(LINKER)" == "jwlink"
DBG=$(NAME).sym
!	endif
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
	@echo ASSEMBLER=$(ASSEMBLER)
	@echo LINKER=$(LINKER)
	@echo BROWSEINFO=$(BROWSEINFO)

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
	$(LD) @<<
$(LFLAGS) $**
$(COM)
$(MAP);
<<
	-if not errorlevel 1 dir $(COM)
!elseif "$(LINKER)" == "tlink"
!	if "$(BUILDTYPE)" == "debug"
$(COM): $(EXE)
	tdstrip -c -s $(EXE)
	-if not errorlevel 1 dir $(COM)

$(EXE): $(OBJS)
	$(LD) $(LFLAGS) $(OBJS),$(EXE),$(MAP)
!	else
$(COM): $(OBJS)
	$(LD) $(LFLAGS) $(OBJS),$(COM)
	-if not errorlevel 1 dir $(COM)
!	endif
!elseif "$(LINKER)" == "jwlink"
!	if "$(BUILDTYPE)" == "debug"
$(COM): $(OBJS)
	# JWlink gets upset if any of the output files already exist
	@-if exist $(COM) del $(COM)
	@-if exist $(DBG) del $(DBG)
	@-if exist $(MAP) del $(MAP)
	$(LD) @<<
system com
name   $(COM)
debug  watcom all
option map=$(MAP)
file   $(**: =,)
<<
	-if not errorlevel 1 dir $(COM)
!	else
$(COM): $(OBJS)
	# JWlink gets upset if any of the output files already exist
	@-if exist $(COM) del $(COM)
	$(LD) @<<
system com
name   $(COM)
file   $(**: =,)
<<
	-if not errorlevel 1 dir $(COM)
!	endif
!endif

!if "$(BROWSEINFO)" == "yes"
$(BSC): $(SBRS)
	bscmake /Iu /n /nologo /o $(BSC) $(SBRS)
!endif

##
## Dependencies
##

cmdline.obj:  cmdline.asm  common.inc cpumacs.inc dosmacs.inc
mplex.obj:    mplex.asm    common.inc cpumacs.inc dosmacs.inc
segend.obj:   segend.asm   common.inc cpumacs.inc dosmacs.inc
segstart.obj: segstart.asm common.inc cpumacs.inc dosmacs.inc
skeletsr.obj: skeletsr.asm common.inc cpumacs.inc dosmacs.inc
stackmgr.obj: stackmgr.asm common.inc cpumacs.inc dosmacs.inc

##
## Generic rules
##

!if "$(BROWSEINFO)" == "yes"
.asm.sbr:
	ml $(AFLAGS) $<
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
!	if "$(LINKER)" == "tlink"
	-if exist $(EXE) del $(EXE)
!	endif
!	if "$(MAP)" != "NUL"
	-if exist $(MAP) del $(MAP)
!	endif
!endif
