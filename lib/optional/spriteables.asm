	
; Rutinas para la actualizaci�n diferida de NAMTBL
	CFG_VRAM_DELAYED_WRTVRM	equ 1
	DELAYED_WRTVRM_SIZE	equ 64
	
; N�mero m�ximo de tiles convertibles en sprites
	CFG_MAX_SPRITEABLES	equ 16

; Constantes simb�licas de tiles convertibles en sprites
	MASK_SPRITEABLE_PENDING		equ $0f ; movimiento en p�xeles
	MASK_SPRITEABLE_DIRECTION	equ $70
	SPRITEABLE_PENDING_0		equ 7 ; n�mero de p�xeles: 8 (= 1 tile)
	SPRITEABLE_IDLE			equ $00
	SPRITEABLE_DIR_UP		equ $10
	SPRITEABLE_DIR_DOWN		equ $20
	SPRITEABLE_DIR_RIGHT		equ $30
	SPRITEABLE_DIR_LEFT		equ $40
	SPRITEABLE_STOPPED		equ $80

;
; =============================================================================
;	Subrutinas para tiles convertibles en sprites
; =============================================================================
;

; -----------------------------------------------------------------------------
; Inicializa la cola de volcados de NAMTBL
INIT_DELAYED_WRTVRM_ARRAY:
	xor	a
	ld	[delayed_wrtvrm_count], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; A�ade un elemento a la cola de volcados de NAMTBL
; param hl: offset de NAMTBL
; param a: valor a escribir
; ret hl: offset de NAMTBL
; ret a: valor escrito
; touches bc
DELAYED_WRTVRM:
	push	ix ; preserva el valor anterior de IX
	push	af ; preserva el valor a escribir
; A�ade un elemento al array
	ld	ix, delayed_wrtvrm_count
	ld	bc, 3
	call	ADD_ARRAY_IX
; Informa el elemento a�adido
	pop	af ; restaura el valor a escribir
	ld	[ix +0], l
	ld	[ix +1], h
	ld	[ix +2], a
	pop	ix ; restaura el valor anterior de IX
	ret
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Ejecuta los volcados de NAMTBL encolados y vac�a la cola
EXECUTE_DELAYED_WRTVRM:
; Comprueba si hay elementos encolados
	ld	ix, delayed_wrtvrm_count
	ld	a, [ix]
	or	a
	ret	z ; no hay elementos
; hay elementos
	ld	b, a
	xor	a ; resetea el contador para la pr�xima ejecuci�n
	ld	[ix], a
	inc	ix ; ix = delayed_wrtvrm_array
	ld	de, NAMTBL ; para convertir offsets en NAMTBL

; Para cada elemento
@@LOOP:
	push	bc ; preserva el contador
	
; Lee el offset en bc
	ld	l, [ix +0]
	ld	h, [ix +1]
	ld	a, [ix +2]
; Vuelca el byte en VRAM
	add	hl, de
	call	WRTVRM
; Avanza al siguiente elemento
	ld	bc, 3
	add	ix, bc
	
	pop	bc ; restaura el contador
	djnz	@@LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Resetea toda la informaci�n de los tiles convertibles
RESET_SPRITEABLES:
; Vac�a el contador y el array
	ld	hl, spriteables_data
	ld	de, spriteables_data +1
	ld	bc, SPRITEABLES_SIZE -1
	ld	[hl], 0
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Inicializa un tiles convertibles en sprite
; param hl: puntero del buffer namtbl del caracter superior izquierdo
; ret ix: puntero al spriteable creado
; 	(para escribir el patr�n y el color del posible sprite)
INIT_SPRITEABLE:
; Calcula el offset en funci�n del puntero
	ex	de, hl ; puntero en de
	ld	hl, -namtbl_buffer +$10000 ; +$10000: evita 16-bit overflow
	add	hl, de ; offset en hl
; Actualiza el contador de elementos y accede a la �ltima posici�n
	ld	ix, spriteables_count
	ld	bc, SPRITEABLE_SIZE
	call	ADD_ARRAY_IX
; Escribe el estado
	xor	a
	ld	[ix + _SPRITEABLE_STATUS], a
; Escribe el offset
	ld	[ix + _SPRITEABLE_OFFSET +0], l
	ld	[ix + _SPRITEABLE_OFFSET +1], h
; Escribe los caracteres que definen el tile convertible
	ld	a, [de]
	; jr	SET_SPRITEABLE_FOREGROUND ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Asigna los caracteres (cuatro consecutivos) del tile convertible
; param ix: puntero al tile convertible
; param a: primer caracter del tile convertible
SET_SPRITEABLE_FOREGROUND:
	ld	[ix + _SPRITEABLE_FOREGROUND +0], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +1], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +2], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +3], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Localiza un tile convertible
; param de: coordenadas l�gicas (en p�xeles) u offset del caracter superior izquierdo
; return ix: puntero al tile convertible cuyas coordenadas coinciden
GET_SPRITEABLE_COORDS:
; Convierte coordenadas l�gicas (en p�xeles) en offset
	call	COORDS_TO_OFFSET
	ld	de, -32 -32 -1 ; -(1,2)
	add	hl, de
	ex	de, hl ; offset en de
GET_SPRITEABLE_OFFSET:
; Recorre el array de elementos
	ld	ix, spriteables_array
@@LOOP:
; �Coincide la coordenada y?
	ld	a, [ix +_SPRITEABLE_OFFSET +0]
	cp	e
	jr	nz, @@NEXT ; no
; s�: �coincide la coordenada x?
	ld	a, [ix +_SPRITEABLE_OFFSET +1]
	cp	d
	ret	z ; s�
; no: siguiente elemento
@@NEXT:
	ld	bc, SPRITEABLE_SIZE
	add	ix, bc
	jr	@@LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
UPDATE_SPRITEABLES:
; Lee el contador de elementos
	ld	ix, spriteables_count
	ld	a, [ix]
	or	a
	ret	z ; no hay elementos
; hay elementos
	ld	b, a ; inicializa contador
	inc	ix ; ix = spriteables_array
	
; Para cada elemento
@@LOOP:
	push	bc ; preserva contador
	
; Comprueba si tiene direcci�n de movimiento
	ld	a, [ix + _SPRITEABLE_STATUS]
	ld	b, a ; preserva status
	and	MASK_SPRITEABLE_DIRECTION
	jr	z, @@NEXT ; no
	
; s�: comprueba si tiene pendiente movimiento
	ld	a, MASK_SPRITEABLE_PENDING
	and	b
	jr	z, @@END ; no
	
; s�: muestra el sprite
	dec	[ix + _SPRITEABLE_STATUS]
	call	PUT_SPRITEABLE_SPRITE
	jr	@@NEXT
	
@@END:
; desactiva el tile convertible para el siguiente frame
	; xor	a ; innecesario
	ld	[ix + _SPRITEABLE_STATUS], a
; vuelca en VRAM los caracteres que definen del tile convertible
	call	DELAYED_WRTVRM_SPRITEABLE_FOREGROUND
	
; siguiente elemento
@@NEXT:
	ld	bc, SPRITEABLE_SIZE
	add	ix, bc
	pop	bc ; restaura contador
	djnz	@@LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Inicia el movimiento de un tile convertible hacia la derecha
; param ix: puntero al tile convertible
MOVE_SPRITEABLE_RIGHT:
; Cambio de estado del elemento
	ld	a, SPRITEABLE_DIR_RIGHT | SPRITEABLE_PENDING_0
	ld	[ix +_SPRITEABLE_STATUS], a
; Limpia el tile convertible en VRAM y en buffer
	call	DELAYED_WRTVRM_SPRITEABLE_BACKGROUND
	call	NAMTBL_BUFFER_ERASE
; Actualiza las coordenadas del tile convertible
	ld	e, [ix +_SPRITEABLE_OFFSET +0]
	ld	d, [ix +_SPRITEABLE_OFFSET +1]
	inc	de
	ld	[ix +_SPRITEABLE_OFFSET +0], e
	ld	[ix +_SPRITEABLE_OFFSET +1], d
; Pinta el sprite en VRAM y la tabla de nombres s�lo en buffer
	call	PUT_SPRITEABLE_SPRITE
	jp	NAMTBL_BUFFER_PRINT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Inicia el movimiento de un tile convertible hacia la izquierda
; param ix: puntero al tile convertible
MOVE_SPRITEABLE_LEFT:
; cambio de estado del elemento
	ld	a, SPRITEABLE_DIR_LEFT | SPRITEABLE_PENDING_0
	ld	[ix +_SPRITEABLE_STATUS], a
; Limpia el tile convertible en VRAM y en buffer
	call	DELAYED_WRTVRM_SPRITEABLE_BACKGROUND
	call	NAMTBL_BUFFER_ERASE
; Actualiza las coordenadas del tile convertible
	ld	e, [ix +_SPRITEABLE_OFFSET +0]
	ld	d, [ix +_SPRITEABLE_OFFSET +1]
	dec	de
	ld	[ix +_SPRITEABLE_OFFSET +0], e
	ld	[ix +_SPRITEABLE_OFFSET +1], d
; Pinta el sprite en VRAM y la tabla de nombres s�lo en buffer
	call	PUT_SPRITEABLE_SPRITE
	jp	NAMTBL_BUFFER_PRINT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Inicia el movimiento de un tile convertible hacia la izquierda
; param ix: puntero al tile convertible
MOVE_SPRITEABLE_DOWN:
; cambio de estado del elemento
	ld	a, SPRITEABLE_DIR_DOWN | SPRITEABLE_PENDING_0
	ld	[ix +_SPRITEABLE_STATUS], a
; Limpia el tile convertible en VRAM y en buffer
	call	DELAYED_WRTVRM_SPRITEABLE_BACKGROUND
	call	NAMTBL_BUFFER_ERASE
; Actualiza las coordenadas del tile convertible
	ld	l, [ix +_SPRITEABLE_OFFSET +0]
	ld	h, [ix +_SPRITEABLE_OFFSET +1]
	ld	bc, 32
	add	hl, bc
	ld	[ix +_SPRITEABLE_OFFSET +0], l
	ld	[ix +_SPRITEABLE_OFFSET +1], h
; Pinta el sprite en VRAM y la tabla de nombres s�lo en buffer
	call	PUT_SPRITEABLE_SPRITE
	jp	NAMTBL_BUFFER_PRINT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca en el buffer de NAMTBL los caracteres de fondo del tile convertible
; param ix: puntero al tile convertible
NAMTBL_BUFFER_ERASE:
; Caracter superior izquierdo
	ld	l, [ix +_SPRITEABLE_OFFSET +0]
	ld	h, [ix +_SPRITEABLE_OFFSET +1]
	ld	de, namtbl_buffer
	add	hl, de ; hl = namtbl_buffer + offset
	ld	a, [ix +_SPRITEABLE_BACKGROUND +0]
	ld	[hl], a
; Caracter superior derecho
	inc	hl
	ld	a, [ix +_SPRITEABLE_BACKGROUND +1]
	ld	[hl], a
; Caracter inferior izquierdo
	ld	de, SCR_WIDTH -1
	add	hl, de
	ld	a, [ix +_SPRITEABLE_BACKGROUND +2]
	ld	[hl], a
; Caracter inferior derecho
	inc	hl
	ld	a, [ix +_SPRITEABLE_BACKGROUND +3]
	ld	[hl], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Preserva los caracteres de fondo del buffer de NAMTBL
; y vuelca los caracteres que definen el tile convertible
; param ix: puntero al tile convertible
NAMTBL_BUFFER_PRINT:
; Caracter superior izquierdo
	ld	l, [ix +_SPRITEABLE_OFFSET +0]
	ld	h, [ix +_SPRITEABLE_OFFSET +1]
	ld	de, namtbl_buffer
	add	hl, de ; hl = namtbl_buffer + offset
	ld	a, [hl]
	ld	[ix +_SPRITEABLE_BACKGROUND +0], a
	ld	a, [ix +_SPRITEABLE_FOREGROUND +0]
	ld	[hl], a
; Caracter superior derecho
	inc	hl
	ld	a, [hl]
	ld	[ix +_SPRITEABLE_BACKGROUND +1], a
	ld	a, [ix +_SPRITEABLE_FOREGROUND +1]
	ld	[hl], a
; Caracter inferior izquierdo
	ld	de, SCR_WIDTH -1
	add	hl, de
	ld	a, [hl]
	ld	[ix +_SPRITEABLE_BACKGROUND +2], a
	ld	a, [ix +_SPRITEABLE_FOREGROUND +2]
	ld	[hl], a
; Caracter inferior derecho
	inc	hl
	ld	a, [hl]
	ld	[ix +_SPRITEABLE_BACKGROUND +3], a
	ld	a, [ix +_SPRITEABLE_FOREGROUND +3]
	ld	[hl], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca en VRAM los caracteres de fondo del tile convertible
; param ix: puntero al tile convertible
DELAYED_WRTVRM_SPRITEABLE_BACKGROUND:
; Caracter superior izquierdo
	ld	l, [ix +_SPRITEABLE_OFFSET +0]
	ld	h, [ix +_SPRITEABLE_OFFSET +1]
	ld	a, [ix +_SPRITEABLE_BACKGROUND +0]
	call	DELAYED_WRTVRM
; Caracter superior derecho
	inc	hl
	ld	a, [ix +_SPRITEABLE_BACKGROUND +1]
	call	DELAYED_WRTVRM
; Caracter inferior izquierdo
	ld	de, SCR_WIDTH -1
	add	hl, de
	ld	a, [ix +_SPRITEABLE_BACKGROUND +2]
	call	DELAYED_WRTVRM
; Caracter inferior derecho
	inc	hl
	ld	a, [ix +_SPRITEABLE_BACKGROUND +3]
	jp	DELAYED_WRTVRM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca en VRAM los caracteres que definen del tile convertible
; param ix: puntero al tile convertible
DELAYED_WRTVRM_SPRITEABLE_FOREGROUND:
; Caracter superior izquierdo
	ld	l, [ix +_SPRITEABLE_OFFSET +0]
	ld	h, [ix +_SPRITEABLE_OFFSET +1]
	ld	a, [ix +_SPRITEABLE_FOREGROUND +0]
	call	DELAYED_WRTVRM
; Caracter superior derecho
	inc	hl
	ld	a, [ix +_SPRITEABLE_FOREGROUND +1]
	call	DELAYED_WRTVRM
; Caracter inferior izquierdo
	ld	de, SCR_WIDTH -1
	add	hl, de
	ld	a, [ix +_SPRITEABLE_FOREGROUND +2]
	call	DELAYED_WRTVRM
; Caracter inferior derecho
	inc	hl
	ld	a, [ix +_SPRITEABLE_FOREGROUND +3]
	jp	DELAYED_WRTVRM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; param ix: puntero al tile convertible
PUT_SPRITEABLE_SPRITE:
; Lee las coordenadas finales del sprite
	ld	e, [ix +_SPRITEABLE_OFFSET +0]
	ld	d, [ix +_SPRITEABLE_OFFSET +1]
	call	OFFSET_TO_COORDS
	dec	d ; (ajuste y)
; �Hay movimiento pendiente?
	ld	a, [ix +_SPRITEABLE_STATUS]
	and	MASK_SPRITEABLE_PENDING
	jr	z, @@DE_OK ; no
; s�: ajuste de coordenadas en funci�n de la direcci�n
	ld	b, a ; preserva el n�mero de p�xeles pendientes
	ld	a, [ix +_SPRITEABLE_STATUS]
	and	MASK_SPRITEABLE_DIRECTION
	cp	SPRITEABLE_DIR_RIGHT
	jr	z, @@RIGHT
	cp	SPRITEABLE_DIR_LEFT
	jr	z, @@LEFT
	cp	SPRITEABLE_DIR_DOWN
	jr	z, @@DOWN
	; jr	@@UP ; falls through
	
@@UP:
; arriba: ajuste de coordenada y += pediente
	ld	a, d
	add	b
	ld	d, a
	jr	@@DE_OK
	
@@RIGHT:
; derecha: ajuste de coordenada x -= pediente
	ld	a, e
	sub	b
	ld	e, a
	jr	@@DE_OK
	
@@LEFT:
; izquierda: ajuste de coordenada x += pediente
	ld	a, e
	add	b
	ld	e, a
	jr	@@DE_OK
	
@@DOWN:
; abajo: ajuste de coordenada y -= pediente
	ld	a, d
	sub	b
	ld	d, a
	jr	@@DE_OK
	
@@DE_OK:
	ld	c, [ix + _SPRITEABLE_SPRATR +0] ; patr�n
	ld	b, [ix + _SPRITEABLE_SPRATR +1] ; color
	jp	PUT_DYNAMIC_SPRITE
; -----------------------------------------------------------------------------

; EOF
