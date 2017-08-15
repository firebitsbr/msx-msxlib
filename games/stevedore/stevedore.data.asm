
;
; =============================================================================
;	Game data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Literals
TXT_PUSH_SPACE_KEY:
	db	"PUSH SPACE KEY", $00

; TXT_START:
	; db	"   START", $00
	; .CENTER:	equ TXT_CONTINUE.CENTER
; TXT_CONTINUE:
	; db	$5e, $5f, " CONTINUE"
	; .SIZE:		equ $ - TXT_CONTINUE
	; .CENTER:	equ (SCR_WIDTH - .SIZE) /2
	; db	$00
	
TXT_STAGE:
	db	"STAGE"
	.SIZE:		equ ($ + 3) - TXT_STAGE ; "... 00"
	.CENTER:	equ (SCR_WIDTH - .SIZE) /2
	db	$00
	
TXT_LIVES:
	db	"LIVES LEFT"
	.SIZE: 		equ $ - TXT_LIVES
	.CENTER:	equ (SCR_WIDTH - .SIZE - 2) /2 ; "0 ..."
	db	$00
	
TXT_GAME_OVER:
	db	"GAME OVER", $00

TXT_STAGE_SELECT:
	db	"STAGE SELECT", $00
	
._0:	db	"WAREHOUSE (TUTORIAL)",		$00
._1:	db	"LIGHTHOUSE",			$00
._2:	db	"ABANDONED SHIP",		$00
._3:	db	"SHIPWRECK ISLAND",		$00 ; (jungle)
._4:	db	"UNCANNY CAVE",			$00 ; (volcano)
._5:	db	"ANCIENT TEMPLE RUINS",		$00 ; (temple)
	
	; db	"SORRY, STEVEDORE",		$00
	; db	"BUT THE LIGHTHOUSE KEEPER",	$00
	; db	"IS IN ANOTHER BUILDING",	$00
	; db	"WAS KIDNAPPED BY PIRATES",	$00
	; db	"SHIPWRECKED",			$00
	; db	"FELL INTO A CAVE",		$00
	; db	"WAS CAPTURED BY PANTOJOS",	$00
	
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initial value of the globals
GLOBALS_0:
	db	TUTORIAL_STAGES + 1	; .max_stage
	db	$00, $00, $00		; .hi_score
	db	0			; game.stage (for intro)
	.SIZE:	equ $ - GLOBALS_0
	
; Initial value of the game-scope vars
GAME_0:
	db	$00, $00, $00		; .score
	db	5			; .lives
	.SIZE:	equ $ - GAME_0

; Initial value of the stage-scoped vars
STAGE_0:
	db	0			; player.pushing
	db	0			; .flags
	db	0			; .frame_counter
	.SIZE:	equ $ - STAGE_0

; Initial (per stage) sprite attributes table
SPRATR_0:
; Player sprites
	db	SPAT_OB, 0, 0, PLAYER_SPRITE_COLOR_1
	db	SPAT_OB, 0, 0, PLAYER_SPRITE_COLOR_2
; SPAT end marker
	db	SPAT_END
	
; Initial (per stage) player vars
PLAYER_0:
	db	48, 128			; .y, .x
	db	0			; .animation_delay
	db	PLAYER_STATE_FLOOR	; .state
	db	0			; .dy_index
	.SIZE:	equ $ - PLAYER_0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initial enemy data
ENEMY_0:

; Bat: the bat flies, the turns around and continues
.BAT:
	db	BAT_SPRITE_PATTERN
	db	BAT_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL
	dw	ENEMY_TYPE_FLYER

; Spider: the spider falls onto the ground the the player is near
.SPIDER:
	db	SPIDER_SPRITE_PATTERN
	db	SPIDER_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL
	dw	ENEMY_TYPE_FALLER.WITH_TRIGGER

; Octopus: not implemented yet	
.OCTOPUS:

; Snake: the snake walks, the pauses, turning around, and continues
.SNAKE:
	db	SNAKE_SPRITE_PATTERN
	db	SNAKE_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL
	dw	ENEMY_TYPE_WALKER.WITH_PAUSE

; Skeleton: the skeleton is slept until the star is picked up,
; then, it becomes of type walker (follower with pause)
.SKELETON:
	db	SKELETON_SPRITE_PATTERN OR FLAG_ENEMY_PATTERN_LEFT
	db	SKELETON_SPRITE_COLOR
	db	$00 ; (not lethal in the initial state)
	dw	$ + 2
; Slept until the star is picked up
	dw	ENEMY_SKELETON.HANDLER
	db	0 ; (unused)

; Savage: the savage walks towards the player, pausing briefly
.SAVAGE:
	db	SAVAGE_SPRITE_PATTERN
	db	SAVAGE_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL
	dw	ENEMY_TYPE_WALKER.FOLLOWER

; Trap (pointing right): shoots when the player is in front of it
.TRAP_RIGHT:
	db	ARROW_RIGHT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	$00 ; (not lethal)
	dw	$ + 2
; Does the player overlaps y coordinate?
	dw	ENEMY_TRAP.TRIGGER_RIGHT_HANDLER
	db	0 ; (unused)
; Shoot
	dw	ENEMY_TRAP.SHOOT_RIGHT_HANDLER
	db	0 ; (unused)
	dw	SET_NEW_STATE_HANDLER
	db	ENEMY_STATE.NEXT
; then pause and restart
	dw	STATIONARY_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_M
	dw	SET_NEW_STATE_HANDLER
	db	-4 * ENEMY_STATE.SIZE; (restart)
	
; Trap (pointing left): shoots when the player is in front of it
.TRAP_LEFT:
	db	ARROW_LEFT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	$00 ; (not lethal)
	dw	$ + 2
; Does the player overlaps y coordinate?
	dw	ENEMY_TRAP.TRIGGER_LEFT_HANDLER
	db	0 ; (unused)
; Shoot
	dw	ENEMY_TRAP.SHOOT_LEFT_HANDLER
	db	0 ; (unused)
	dw	SET_NEW_STATE_HANDLER
	db	ENEMY_STATE.NEXT
; then pause and restart
	dw	STATIONARY_ENEMY_HANDLER
	db	CFG_ENEMY_PAUSE_M
	dw	SET_NEW_STATE_HANDLER
	db	-4 * ENEMY_STATE.SIZE; (restart)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initial bullet data
BULLET_0:

.ARROW_RIGHT:
	db	ARROW_RIGHT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	BULLET_DIR_RIGHT OR 4 ; (4 pixels / frame)
	
.ARROW_LEFT:
	db	ARROW_LEFT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	BULLET_DIR_LEFT OR 4 ; (4 pixels / frame)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Screens binary data (NAMTBL)
INTRO_DATA:

.NAMTBL_PACKED:
	incbin	"games/stevedore/maps/intro_screen.tmx.bin.zx7"
	
.BROKEN_BRIDGE_CHARS:
	db	$d2, $00, $d0 ; 3 bytes
	
.FLOOR_CHARS:
	db	$02, $01, $02, $64, $84, $85, $10, $01, $02 ; 9 bytes
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Screens binary data (NAMTBL)
NAMTBL_PACKED_TABLE:
	dw	.INTRO_STAGE
	dw	.STAGE_01, .STAGE_02, .STAGE_03, .STAGE_04, .STAGE_05
	dw	.STAGE_06, .STAGE_07, .STAGE_08, .STAGE_09, .STAGE_10
	dw	.STAGE_11, .STAGE_12, .STAGE_13, .STAGE_14, .STAGE_15
	dw	.STAGE_16, .STAGE_17, .STAGE_18, .STAGE_19, .STAGE_20
	dw	.STAGE_21, .STAGE_22, .STAGE_23, .STAGE_24, .STAGE_25
	dw	.STAGE_26, .STAGE_27, .STAGE_28, .STAGE_29, .STAGE_30

; Intro	
.INTRO_STAGE:	incbin	"games/stevedore/maps/intro_stage.tmx.bin.zx7"

; Warehouse (tutorial)
.STAGE_01:	incbin	"games/stevedore/maps/stage_01.tmx.bin.zx7"
.STAGE_02:	incbin	"games/stevedore/maps/stage_02.tmx.bin.zx7"
.STAGE_03:	incbin	"games/stevedore/maps/stage_03.tmx.bin.zx7"
.STAGE_04:	incbin	"games/stevedore/maps/stage_04.tmx.bin.zx7"
.STAGE_05:	incbin	"games/stevedore/maps/stage_05.tmx.bin.zx7"

; Lighthouse
.TEST_SCREEN:	
.STAGE_06:	incbin	"games/stevedore/maps/stage_06.tmx.bin.zx7"
.STAGE_07:	incbin	"games/stevedore/maps/stage_07.tmx.bin.zx7"
.STAGE_08:	incbin	"games/stevedore/maps/stage_08.tmx.bin.zx7"
.STAGE_09:	incbin	"games/stevedore/maps/stage_09.tmx.bin.zx7"
.STAGE_10:	incbin	"games/stevedore/maps/stage_10.tmx.bin.zx7"

; Ship
.STAGE_11:	incbin	"games/stevedore/maps/stage_01.tmx.bin.zx7"
.STAGE_12:	incbin	"games/stevedore/maps/stage_02.tmx.bin.zx7"
.STAGE_13:	incbin	"games/stevedore/maps/stage_03.tmx.bin.zx7"
.STAGE_14:	incbin	"games/stevedore/maps/stage_04.tmx.bin.zx7"
.STAGE_15:	incbin	"games/stevedore/maps/stage_05.tmx.bin.zx7"

; Jungle
.STAGE_16:	incbin	"games/stevedore/maps/stage_06.tmx.bin.zx7"
.STAGE_17:	incbin	"games/stevedore/maps/stage_07.tmx.bin.zx7"
.STAGE_18:	incbin	"games/stevedore/maps/stage_08.tmx.bin.zx7"
.STAGE_19:	incbin	"games/stevedore/maps/stage_09.tmx.bin.zx7"
.STAGE_20:	incbin	"games/stevedore/maps/stage_10.tmx.bin.zx7"

; Volcano
.STAGE_21:	incbin	"games/stevedore/maps/stage_01.tmx.bin.zx7"
.STAGE_22:	incbin	"games/stevedore/maps/stage_02.tmx.bin.zx7"
.STAGE_23:	incbin	"games/stevedore/maps/stage_03.tmx.bin.zx7"
.STAGE_24:	incbin	"games/stevedore/maps/stage_04.tmx.bin.zx7"
.STAGE_25:	incbin	"games/stevedore/maps/stage_05.tmx.bin.zx7"

; Temple
.STAGE_26:	incbin	"games/stevedore/maps/stage_06.tmx.bin.zx7"
.STAGE_27:	incbin	"games/stevedore/maps/stage_07.tmx.bin.zx7"
.STAGE_28:	incbin	"games/stevedore/maps/stage_08.tmx.bin.zx7"
.STAGE_29:	incbin	"games/stevedore/maps/stage_09.tmx.bin.zx7"
.STAGE_30:	incbin	"games/stevedore/maps/stage_10.tmx.bin.zx7"

; Test screen
; .TEST_SCREEN:	incbin	"games/stevedore/maps/test_screen.tmx.bin.zx7"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Charset binary data (CHRTBL and CLRTBL)
CHARSET_PACKED:
.CHR:
	incbin	"games/stevedore/gfx/charset.pcx.chr.zx7"
.CLR:
	incbin	"games/stevedore/gfx/charset.pcx.clr.zx7"
	
; Charset-related symbolic constants
	SKELETON_FIRST_CHAR:	equ $1a
	TRAP_UPPER_RIGHT_CHAR:	equ $6e
	TRAP_UPPER_LEFT_CHAR:	equ $6f
	TRAP_LOWER_RIGHT_CHAR:	equ $7e
	TRAP_LOWER_LEFT_CHAR:	equ $7f
	BOX_FIRST_CHAR:		equ $d8
	ROCK_FIRST_CHAR:	equ $dc
	CHAR_FIRST_ITEM:	equ $e0
	CHAR_WATER_SURFACE:	equ $f0
	CHAR_LAVA_SURFACE:	equ $f4
	CHAR_FIRST_DOOR:	equ $f8
	
CHARSET_DYNAMIC:
.CHR:
	incbin	"games/stevedore/gfx/charset_dynamic.pcx.chr"
	.SIZE:			equ $ - CHARSET_DYNAMIC
.CLR:
	incbin	"games/stevedore/gfx/charset_dynamic.pcx.clr"

	.ROW_SIZE:		equ 2 *4 *8; 2 doors/surfaces, 4 characters

	CHAR_FIRST_CLOSED_DOOR:	equ $00
	CHAR_FIRST_OPEN_DOOR:	equ $08
	CHAR_FIRST_SURFACES:	equ $10
	
; Dynamic charset-related symbolic constants
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sprites binary data (SPRTBL)
SPRTBL_PACKED:
	incbin	"games/stevedore/gfx/sprites.pcx.spr.zx7"

; Sprite-related symbolic constants (SPRATR)
	PLAYER_SPRITE_COLOR_1:		equ 9
	PLAYER_SPRITE_COLOR_2:		equ 15
	
	BAT_SPRITE_PATTERN:		equ $50
	BAT_SPRITE_COLOR:		equ 4

	SPIDER_SPRITE_PATTERN:		equ $60
	SPIDER_SPRITE_COLOR:		equ 13
	
	OCTOPUS_SPRITE_PATTERN:		equ $68
	OCTOPUS_SPRITE_COLOR:		equ 13
	
	SNAKE_SPRITE_PATTERN:		equ $70
	SNAKE_SPRITE_COLOR:		equ 2
	
	SKELETON_SPRITE_PATTERN:	equ $80
	SKELETON_SPRITE_COLOR:		equ 15
	
	SAVAGE_SPRITE_PATTERN:		equ $90
	SAVAGE_SPRITE_COLOR:		equ 8

	BOX_SPRITE_PATTERN:		equ $a0
	BOX_SPRITE_COLOR:		equ 9
	
	ROCK_SPRITE_PATTERN:		equ $a4
	ROCK_SPRITE_COLOR:		equ 14
	ROCK_SPRITE_COLOR_WATER:	equ 5
	ROCK_SPRITE_COLOR_LAVA:		equ 9

	ARROW_RIGHT_SPRITE_PATTERN:	equ $a8
	ARROW_LEFT_SPRITE_PATTERN:	equ $ac
	ARROW_SPRITE_COLOR:		equ 14
	
	PLAYER_SPRITE_INTRO_PATTERN:	equ $b0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; WYZPlayer data
TABLA_SONG:
	dw	.SONG_0, .SONG_1, .SONG_2, .SONG_3, .SONG_4, .SONG_5
.SONG_0:
	incbin	"games/stevedore/sfx/UWOLFantasma.mus"
.SONG_1:
	incbin	"games/stevedore/sfx/UWOLPiramide.mus"
.SONG_2:
	incbin	"games/stevedore/sfx/UWOLGameOver.mus"
.SONG_3:
	incbin	"games/stevedore/sfx/UWOLEndingKO.mus"
.SONG_4:
	incbin	"games/stevedore/sfx/UWOLEndingOK.mus"
.SONG_5:
	incbin	"games/stevedore/sfx/DonusTrak.mus"

	include	"games/stevedore/sfx/uwol.mus.asm"
; -----------------------------------------------------------------------------
		
; EOF
