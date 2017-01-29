
rom_end:
	.printtext	" ... user code/data"
	.printhex	$

;
; =============================================================================
; 	RAM
; =============================================================================
;

IF (CFG_INIT_16KB_RAM > 0)
	.page	3
	.printtext	"------------------------------$c000-RAM-"
	.printhex	$
ELSE
	.org	$e000
	.printtext	"------------------------------$e000-RAM-"
	.printhex	$
ENDIF
ram_start:

;
; =============================================================================
; 	RAM: main MSXlib variables
; =============================================================================
;

; rom_begin.asm

; -----------------------------------------------------------------------------
; Refresh rate in Hertzs (50Hz/60Hz)
frame_rate:
	.byte
; Convenience vars that depends on the refresh rate
frames_per_tenth:
	.byte
; -----------------------------------------------------------------------------

; helper_msx.asm

; -----------------------------------------------------------------------------
; Stores GET_TRIGGER result
trigger:
	.byte
; Stores GET_STICK_TRIGGER_BITS result
stick:
	.byte
stick_edge:
	.byte
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; VRAM buffers (namtbl, spratr)

; NAMTBL buffer in RAM
namtbl_buffer:
	.ds	NAMTBL_SIZE
	
; SPRATR buffer in RAM
spratr_buffer:
	.ds	SPRATR_SIZE
spratr_buffer_end:
	.byte	; to store one SPAT_END when the buffer is full
; Direct pointers inside SPRATR buffer
	spratr_player	equ spratr_buffer + 4* CFG_SPRITES_RESERVED_BEFORE
	dynamic_sprites	equ spratr_buffer + 4* (CFG_SPRITES_RESERVED_BEFORE + CFG_PLAYER_SPRITES + CFG_SPRITES_RESERVED_AFTER)
; -----------------------------------------------------------------------------

;
; =============================================================================
; 	RAM: lib/game
; =============================================================================
;

; -----------------------------------------------------------------------------
; Player vars
player_vars:

; Logical coordinates (in pixels)
player_xy:
player_y:
	.byte
player_x:
	.byte
; Current animation delay (e.g.: when walking) (in frames)
player_animation_delay:
	.byte
; Current player state
player_state:
	.byte
; dY table index (when jumping and falling)
player_dy_index:
	.byte

	PLAYER_VARS_SIZE	equ $ - player_vars
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Enemies array
enemies_array:
; Logical coordinates (in pixels)
	_ENEMY_Y		equ $ - enemies_array
	.byte
	_ENEMY_X		equ $ - enemies_array
	.byte
; Dynamic sprite attributes
	_ENEMY_PATTERN		equ $ - enemies_array
	.byte
	_ENEMY_COLOR		equ $ - enemies_array
	.byte
; Pointer to the current state
	_ENEMY_STATE_L		equ $ - enemies_array
	.byte
	_ENEMY_STATE_H		equ $ - enemies_array
	.byte
; Current animation delay
	_ENEMY_ANIMATION_DELAY	equ $ - enemies_array
	.byte
; Current frame counter
	_ENEMY_FRAME_COUNTER	equ $ - enemies_array
	.byte
	ENEMY_SIZE		equ $ - enemies_array

; (rest of the array)
IF (CFG_ENEMY_COUNT > 1)
	.ds	(CFG_ENEMY_COUNT -1) * ENEMY_SIZE
ENDIF
	ENEMIES_SIZE	equ $ - enemies_array
; -----------------------------------------------------------------------------

; ;
; ; =============================================================================
; ; 	RAM: optional MSXlib variables
; ; =============================================================================
; ;

; ; -----------------------------------------------------------------------------
; IF (CFG_OPTIONAL_MSX2_OPTIONS > 0)
	; .include	"lib/optional/msx2options.ram.asm"
; ENDIF ; (CFG_OPTIONAL_MSX2_OPTIONS > 0)
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; IF (CFG_OPTIONAL_PT3HOOK > 0)
	; .include	"lib/optional/pt3hook.ram.asm"
; ENDIF ; (CFG_OPTIONAL_PT3HOOK > 0)
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; IF (CFG_VRAM_DELAYED_WRTVRM > 0)
	; .include	"lib/optional/spriteables.ram.asm"
; ENDIF ; (CFG_VRAM_DELAYED_WRTVRM > 0)
; ; -----------------------------------------------------------------------------

	; .printtext	" ... msxlib vars"
	; .printhex	$

; EOF
