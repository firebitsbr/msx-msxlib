;
; =============================================================================
;	Bullet related routines (generic)
;	Bullet-tile helper routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Bounding box coordinates offset from the logical coordinates
	BULLET_BOX_X_OFFSET:	equ -(CFG_BULLET_WIDTH / 2)
	BULLET_BOX_Y_OFFSET:	equ -CFG_BULLET_HEIGHT

	MASK_BULLET_SPEED:	equ $0f ; speed (in pixels / frame)
	MASK_BULLET_DIRECTION:	equ $70 ; movement direction

	BULLET_DIR_UP:		equ $10
	BULLET_DIR_DOWN:	equ $20
	BULLET_DIR_RIGHT:	equ $30
	BULLET_DIR_LEFT:	equ $40
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Empties the bullets array
RESET_BULLETS:
; Fills the array with zeroes
	ld	hl, bullets
	ld	de, bullets +1
	ld	bc, bullets.SIZE -1
	ld	[hl], 0
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new from the enemy coordinates in the first empty bullet slot
; param hl: pointer to the new bullet data (pattern, color, speed and direction)
; touches: a, hl, de, bc
INIT_BULLET_FROM_ENEMY:
	push	hl ; preserves source
; Search for the first empty enemy slot
	ld	hl, bullets
	ld	bc, bullet.SIZE
	xor	a ; (marker value: y = 0)
.LOOP:
	cp	[hl]
	jr	z, .INIT ; empty slot found
; Skips to the next element of the array
	add	hl, bc
	jr	.LOOP
	
.INIT:
; Stores the logical coordinates
	push	ix ; hl = ix, de = empy bullet slot
	pop	de
	ex	de, hl
	ldi	; .y
	ldi	; .x
; Stores the pattern, color and type (speed and direction)
	pop	hl ; restores source in hl
	ldi	; .pattern
	ldi	; .color
	ldi	; .type
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the bullets
UPDATE_BULLETS:
; For each bullet in the array
	ld	ix, bullets
	ld	b, CFG_BULLET_COUNT
.LOOP:
	push	bc ; preserves counter in b
; Is the bullet slot empty?
	xor	a ; (marker value: y = 0)
	cp	[ix + bullet.y]
	call	nz, .UPDATE ; no
; Skips to the next bullet
	ld	bc, bullet.SIZE
	add	ix, bc
	pop	bc ; restores counter
	djnz	.LOOP
	ret

.UPDATE:
	ld	e, [ix + bullet.y]
	ld	d, [ix + bullet.x]
	ld	c, [ix + bullet.pattern]
	ld	b, [ix + bullet.color]
	call	PUT_SPRITE
	
	; inc	[ix + bullet.x]
	; inc	[ix + bullet.x]
	; inc	[ix + bullet.x]
	; inc	[ix + bullet.x]
	
	ret

; ; Dereferences the state pointer
	; ld	l, [ix + enemy.state_l]
	; ld	h, [ix + enemy.state_h]
	; push	hl ; iy = hl
	; pop	iy
; .HANDLER_LOOP:
; ; Invokes the current state handler
	; ld	l, [iy + ENEMY_STATE.HANDLER_L]
	; ld	h, [iy + ENEMY_STATE.HANDLER_H]
	; call	JP_HL ; emulates "call [hl]"
; ; Has the handler finished?
	; jp	nz, .SKIP_ENEMY ; no: pending frames
; ; Skips to the next state handler
	; ld	bc, ENEMY_STATE.SIZE
	; add	iy, bc
	; jp	.HANDLER_LOOP
; -----------------------------------------------------------------------------

; ;
; ; =============================================================================
; ;	Convenience enemy state handlers (generic)
; ; =============================================================================
; ;

; ; -----------------------------------------------------------------------------
; ; Sets a new current state for the current enemy, relative to the current state
; ; (this state handler is usually the last handler of a state)
; ; param ix: pointer to the current enemy
; ; param iy: pointer to the current enemy state
; ; param [iy + ENEMY_STATE.ARGS]: offset to the next state (in bytes)
; ; ret nz (halt)
; SET_NEW_STATE_HANDLER:
; ; Reads the offset to the next state in bc (16-bit signed)
	; ld	a, [iy + ENEMY_STATE.ARGS]
	; ld	c, a ; ld bc, a
	; rla
	; sbc	a, a
	; ld	b, a
; ; Sets the new state as the enemy state
	; push	iy ; hl = iy + bc
	; pop	hl
	; add	hl, bc
	; ld	[ix + enemy.state_h], h
	; ld	[ix + enemy.state_l], l
; ; Resets the animation flag
	; res	BIT_ENEMY_PATTERN_ANIM, [ix + enemy.pattern]
; ; Resets the animation delay and the frame counter
	; xor	a
	; ld	[ix + enemy.animation_delay], a
	; ld	[ix + enemy.frame_counter], a
; ; ret nz (halt)
	; inc	a
	; ret
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Sets a new current state for the current enemy,
; ; relative to the current state,
; ; when the player and the enemy are in overlapping x coordinates
; ; param ix: pointer to the current enemy
; ; param iy: pointer to the current enemy state
; ; param [iy + ENEMY_STATE.ARGS]: offset to the next state (in bytes)
; ; ret z (continue) if the state does not change (no overlapping coordinates)
; ; ret nz (halt) if the state changes
; .ON_X_COLLISION:
	; call	CHECK_PLAYER_ENEMY_COLLISION.X
	; jp	c, SET_NEW_STATE_HANDLER
; ; ret z (continue)
	; xor	a
	; ret
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Sets a new current state for the current enemy,
; ; relative to the current state,
; ; when the player and the enemy are in overlapping y coordinates
; ; param ix: pointer to the current enemy
; ; param iy: pointer to the current enemy state
; ; param [iy + ENEMY_STATE.ARGS]: offset to the next state (in bytes)
; ; ret z (continue) if the state does not change (no overlapping coordinates)
; ; ret nz (halt) if the state changes
; .ON_Y_COLLISION:
	; call	CHECK_PLAYER_ENEMY_COLLISION.Y
	; jp	c, SET_NEW_STATE_HANDLER
; ; ret z (continue)
	; xor	a
	; ret
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Updates animation counter and toggles the animation flag,
; ; then puts the enemy sprite
; ; param ix: pointer to the current enemy
; ; param iy: pointer to the current enemy state (ignored)
; ; ret z (continue)
; PUT_ENEMY_SPRITE_ANIM:
; ; Updates animation counter
	; ld	a, [ix + enemy.animation_delay]
	; inc	a
	; cp	CFG_ENEMY_ANIMATION_DELAY
	; jr	nz, .DONT_ANIMATE
; ; Toggles the animation flag
	; ld	a, FLAG_ENEMY_PATTERN_ANIM
	; xor	[ix + enemy.pattern]
	; ld	[ix + enemy.pattern], a
; ; Resets animation counter
	; xor	a
; .DONT_ANIMATE:
	; ld	[ix + enemy.animation_delay], a
; ; ------VVVV----falls through--------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Puts the enemy sprite
; ; param ix: pointer to the current enemy
; ; param iy: pointer to the current enemy state (ignored)
; ; ret z (continue)
; PUT_ENEMY_SPRITE:
	; ld	e, [ix + enemy.y]
	; ld	d, [ix + enemy.x]
	; ld	c, [ix + enemy.pattern]
	; ld	b, [ix + enemy.color]
	; call	PUT_SPRITE
; ; ret z (continue)
	; xor	a
	; ret
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Toggles the left flag of the enemy
; ; param ix: pointer to the current enemy
; ; param iy: pointer to the current enemy state (ignored)
; ; ret z (continue)
; TURN_ENEMY:
; ; Toggles the left flag
	; ld	a, FLAG_ENEMY_PATTERN_LEFT
	; xor	[ix + enemy.pattern]
	; ld	[ix + enemy.pattern], a
; ; ret z (continue)
	; xor	a
	; ret	; (no enemy is expected to have the pattern $00)
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Turns the enemy towards the player
; ; param ix: pointer to the current enemy
; ; param iy: pointer to the current enemy state (ignored)
; ; ret z (continue)
; .TOWARDS_PLAYER:
	; ld	a, [player.x]
	; cp	[ix + enemy.x]
	; jr	nc, .RIGHT
	; ; jp	.LEFT ; falls through
; ; ------VVVV----falls through--------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Turns the enemy left
; ; param ix: pointer to the current enemy
; ; param iy: pointer to the current enemy state (ignored)
; ; ret z (continue)
; .LEFT:
	; set	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
; ; ret z (continue)
	; xor	a
	; ret
; ; -----------------------------------------------------------------------------
	
; ; -----------------------------------------------------------------------------
; ; Turns the enemy right
; ; param ix: pointer to the current enemy
; ; param iy: pointer to the current enemy state (ignored)
; ; ret z (continue)
; .RIGHT:
	; res	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
; ; ret z (continue)
	; xor	a
	; ret
; ; -----------------------------------------------------------------------------

; ;
; ; =============================================================================
; ;	Enemy-tile helper routines
; ; =============================================================================
; ;

; ; -----------------------------------------------------------------------------
; ; Returns the OR-ed flags of the tiles to the left of the enemy
; ; when aligned to the tile boundary
; ; param ix: pointer to the current enemy
; ; ret a: OR-ed tile flags
; GET_ENEMY_TILE_FLAGS_LEFT_FAST:
; ; Aligned to tile boundary?
	; ld	a, [ix + enemy.x]
	; add	ENEMY_BOX_X_OFFSET
	; and	$07
	; jp	nz, CHECK_NO_TILES ; no: return no flags
; ; ------VVVV----falls through--------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Returns the OR-ed flags of the tiles to the left of the enemy
; ; param ix: pointer to the current enemy
; ; ret a: OR-ed tile flags
; GET_ENEMY_TILE_FLAGS_LEFT:
	; ld	a, ENEMY_BOX_X_OFFSET -1
	; jr	GET_ENEMY_V_TILE_FLAGS
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Returns the OR-ed flags of the tiles to the right of the enemy
; ; when aligned to the tile boundary
; ; param ix: pointer to the current enemy
; ; ret a: OR-ed tile flags
; GET_ENEMY_TILE_FLAGS_RIGHT_FAST:
; ; Aligned to tile boundary?
	; ld	a, [ix + enemy.x]
	; add	ENEMY_BOX_X_OFFSET + CFG_ENEMY_WIDTH
	; and	$07
	; jp	nz, CHECK_NO_TILES ; no: return no flags
; ; ------VVVV----falls through--------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Returns the OR-ed flags of the tiles to the right of the enemy
; ; param ix: pointer to the current enemy
; ; ret a: OR-ed tile flags
; GET_ENEMY_TILE_FLAGS_RIGHT:
	; ld	a, ENEMY_BOX_X_OFFSET + CFG_ENEMY_WIDTH
	; ; jr	GET_ENEMY_V_TILE_FLAGS ; falls through
; ; ------VVVV----falls through--------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Returns the OR-ed flags of a vertical serie of tiles
; ; relative to the enemy position
; ; param ix: pointer to the current enemy
; ; param a: x-offset from the enemy logical coordinates
; ; ret a: OR-ed tile flags
; GET_ENEMY_V_TILE_FLAGS:
; ; Enemy coordinates
	; ld	e, [ix + enemy.y]
	; ld	d, [ix + enemy.x]
; ; x += dx
	; add	d
	; ld	d, a
; ; y += ENEMY_BOX_Y_OFFSET
	; ld	a, ENEMY_BOX_Y_OFFSET
	; add	e
	; ld	e, a
; ; Enemy height
	; ld	b, CFG_ENEMY_HEIGHT
	; jp	GET_V_TILE_FLAGS
; ; -----------------------------------------------------------------------------

; EOF
