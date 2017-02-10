
#
# current game name
#

GAME=template

#
# commands
#

# ASM=asmsx
ASM=tniasm
COPY=cmd /c copy
EMULATOR=cmd /c start
DEBUGGER=cmd /c start \MSX\bin\blueMSX_2.8.2\blueMSX.exe
MKDIR=cmd /c mkdir
MOVE=cmd /c move
REMOVE=cmd /c del
RENAME=cmd /c ren
TYPE=cmd /c type

#
# tools
#

PCX2MSX=pcx2msx+
PCX2SPR=pcx2spr
TMX2BIN=tmx2bin

# Uncomment for Pletter 0.5c1
# PACK=pletter
# PACK_EXTENSION=plet5

# Uncomment for ZX7
# (please note that ZX7 does not overwrite output)
PACK=zx7.exe
PACK_EXTENSION=zx7

#
# paths and file lists
#

GAME_PATH=\
	games\$(GAME)
	
TEMPLATE_PATH=\
	games\template

ROM=\
	roms\$(GAME).rom
	
ROM_INTERMEDIATE=\
	$(GAME_PATH)\$(GAME).rom
	
SYM_INTERMEDIATE=\
	$(GAME_PATH)\$(GAME).sym

SRCS_MSXLIB=\
	lib\ram.asm \
	lib\asm.asm \
	lib\msx\symbols.asm \
	lib\msx\cartridge.asm \
	lib\msx\input.asm \
	lib\msx\vram.asm \
	lib\msx\vram_x.asm \
	lib\game\tiles.asm \
	lib\game\player.asm \
	lib\game\player_x.asm \
	lib\game\enemy.asm \
	lib\game\enemy_routines.asm \
	lib\game\enemy_handlers.asm

GFXS=\
	$(GAME_PATH)\charset.pcx.chr.$(PACK_EXTENSION) \
	$(GAME_PATH)\charset.pcx.clr.$(PACK_EXTENSION)

GFXS_INTERMEDIATE=\
	$(GAME_PATH)\charset.pcx.chr \
	$(GAME_PATH)\charset.pcx.clr

SPRS=\
	$(GAME_PATH)\sprites.pcx.spr.$(PACK_EXTENSION)

SPRS_INTERMEDIATE=\
	$(GAME_PATH)\sprites.pcx.spr

DATAS=\
	$(GAME_PATH)\screen.tmx.bin.$(PACK_EXTENSION)

DATAS_INTERMEDIATE=\
	$(GAME_PATH)\screen.tmx.bin

#
# phony targets
#

# default target
default: compile

clean:
	$(REMOVE) $(ROM_INTERMEDIATE)
	$(REMOVE) $(SYM_INTERMEDIATE) tniasm.sym tniasm.tmp

cleandata:
	$(REMOVE) $(GFXS) $(GFXS_INTERMEDIATE)
	$(REMOVE) $(SPRS) $(SPRS_INTERMEDIATE)
	$(REMOVE) $(DATAS) $(DATAS_INTERMEDIATE)

cleanall: clean cleandata

compile: $(ROM_INTERMEDIATE)

test: $(ROM_INTERMEDIATE)
	cmd /c dir $(GAME_PATH)\$(GAME).*
	$(EMULATOR) $<

debug: $(ROM_INTERMEDIATE) $(SYM_INTERMEDIATE)
	cmd /c dir $(GAME_PATH)\$(GAME).*
	$(DEBUGGER) $<

deploy: $(ROM)

# secondary targets
.secondary: $(GFXS_INTERMEDIATE) $(SPRS_INTERMEDIATE) $(DATAS_INTERMEDIATE)

#
# main targets
#
	
$(GAME_PATH):
	$(MKDIR) $@
	$(COPY) $(TEMPLATE_PATH) $@
	$(RENAME) $(GAME_PATH)\template.asm $(GAME).asm
	
$(ROM_INTERMEDIATE) tniasm.sym: $(GAME_PATH)\$(GAME).asm $(SRCS_MSXLIB) $(GFXS) $(SPRS) $(DATAS)
	$(ASM) $< $@

$(SYM_INTERMEDIATE): tniasm.sym
	$(COPY) $< $@

$(ROM): $(ROM_INTERMEDIATE)
	$(COPY) $< $@
	
#
# GFXs targets
#

%.pcx.chr.$(PACK_EXTENSION): %.pcx.chr
	$(REMOVE) $@
	$(PACK) $<

%.pcx.clr.$(PACK_EXTENSION): %.pcx.clr
	$(REMOVE) $@
	$(PACK) $<

%.pcx.nam.$(PACK_EXTENSION): %.pcx.nam
	$(REMOVE) $@
	$(PACK) $<

# -lh by default because packing usally produces smaller binaries
%.pcx.chr %.pcx.clr: %.pcx
	$(PCX2MSX) -lh $<

#
# SPRs targets
#

%.pcx.spr.$(PACK_EXTENSION): %.pcx.spr
	$(REMOVE) $@
	$(PACK) $<

%.pcx.spr: %.pcx
	$(PCX2SPR) $<

#
# BINs targets
#

%.tmx.bin.$(PACK_EXTENSION): %.tmx.bin
	$(REMOVE) $@
	$(PACK) $<

%.tmx.bin: %.tmx
	$(TMX2BIN) $< $@
