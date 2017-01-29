
#
# current project (game) name
#

GAME=stevedore

#
# commands
#

ASM=asmsx
# ASM=sjasm
# ASM=sjasmpg32_esp
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

PACK=pletter
PACK_EXTENSION=plet5
PCX2MSX=pcx2msx+
PCX2SPR=pcx2spr
TMX2BIN=tmx2bin

#
# paths and file lists
#

GAME_PATH=\
	games\$(GAME)

ROM=\
	roms\$(GAME).rom
	
ROM_INTERMEDIATE=\
	$(GAME_PATH)\$(GAME).rom

SRCS=\
	$(GAME_PATH)\$(GAME).asm \
	lib\msx_cartridge.asm \
	lib\asm.asm \
	lib\msx_input.asm \
	lib\msx_vram.asm \
	lib\msx_sprites.asm \
	lib\game\tiles.asm \
	lib\game\player.asm \
	lib\game\enemy.asm \
	lib\game\enemy\default_routines.asm \
	lib\game\enemy\default_handlers.asm \
	lib\ram_begin.asm \
	lib\ram_end.asm

# lib\optional\msx2options.asm \
# lib\optional\msx2options.ram.asm \
# lib\optional\pt3hook.asm \
# lib\optional\pt3hook.ram.asm \
# lib\optional\spriteables.asm \
# lib\optional\spriteables.ram.asm \
# libext\pt3-rom.asm \
# libext\pt3-ram.asm

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
	$(GAME_PATH)\screen.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\tutorial_01.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\tutorial_02.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\tutorial_03.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\tutorial_04.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\tutorial_05.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\jungle_01.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\vulcan_01.tmx.bin.$(PACK_EXTENSION)

DATAS_INTERMEDIATE=\
	$(GAME_PATH)\screen.tmx.bin \
	$(GAME_PATH)\tutorial_01.tmx.bin \
	$(GAME_PATH)\tutorial_02.tmx.bin \
	$(GAME_PATH)\tutorial_03.tmx.bin \
	$(GAME_PATH)\tutorial_04.tmx.bin \
	$(GAME_PATH)\tutorial_05.tmx.bin \
	$(GAME_PATH)\jungle_01.tmx.bin \
	$(GAME_PATH)\vulcan_01.tmx.bin

#
# phony targets
#

# default target
default: rom

clean:
	$(REMOVE) ~tmppre.? $(GAME_PATH)\$(GAME).txt $(GAME_PATH)\$(GAME).sym

cleangfx:
	$(REMOVE) $(GFXS) $(GFXS_INTERMEDIATE)

cleanspr:
	$(REMOVE) $(SPRS) $(SPRS_INTERMEDIATE)

cleandata:
	$(REMOVE) $(DATAS) $(DATAS_INTERMEDIATE)

cleanall: clean cleangfx cleanspr cleandata

cleanrom:
	$(REMOVE) $(ROM_INTERMEDIATE)
	
cleanallrom: cleanall cleanrom

rom: $(ROM_INTERMEDIATE)

debug: $(ROM_INTERMEDIATE)
	$(DEBUGGER) $<

run: $(ROM_INTERMEDIATE)
	$(EMULATOR) $<

deploy: $(ROM)

# secondary targets
.secondary: $(GFXS_INTERMEDIATE) $(SPRS_INTERMEDIATE) $(DATAS_INTERMEDIATE)

#
# main targets
#
	
$(ROM): $(ROM_INTERMEDIATE)
	$(COPY) $< $@
	
$(ROM_INTERMEDIATE): $(SRCS) $(GFXS) $(SPRS) $(DATAS)
	$(REMOVE) $(GAME_PATH)\$(GAME).txt
	$(ASM) $<
	$(TYPE) $(GAME_PATH)\$(GAME).txt

$(GAME_PATH):
	$(MKDIR) $@
	$(COPY) template $@
	$(RENAME) $(GAME_PATH)\template.asm $(GAME).asm
	
#
# GFXs targets
#

%.pcx.chr.$(PACK_EXTENSION): %.pcx.chr
	$(PACK) $<

%.pcx.clr.$(PACK_EXTENSION): %.pcx.clr
	$(PACK) $<

%.pcx.nam.$(PACK_EXTENSION): %.pcx.nam
	$(PACK) $<

# -lh by default as packing produces smaller binaries
%.pcx.chr %.pcx.clr: %.pcx
	$(PCX2MSX) -lh $<

#
# SPRs targets
#

%.pcx.spr.$(PACK_EXTENSION): %.pcx.spr
	$(PACK) $<

%.pcx.spr: %.pcx
	$(PCX2SPR) $<

#
# BINs targets
#

%.tmx.bin.$(PACK_EXTENSION): %.tmx.bin
	$(PACK) $<

%.tmx.bin: %.tmx
	$(TMX2BIN) $< $@
