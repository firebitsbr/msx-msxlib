
; -----------------------------------------------------------------------------
; Cartridge header
	org	$4000, $bfff
ROM_START:
	db	"AB"		; ID ("AB")
	dw	.INIT		; INIT
	ds	$4010 - $, $00	; STATEMENT, DEVICE, TEXT, Reserved
.INIT:
	call	.RETROEUSKAL
	jr	$
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Splash screen
.RETROEUSKAL:
	include "retroeuskal.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Padding to a 8kB boundary
PADDING:
	ds	($ OR $1fff) -$ +1, $ff ; $ff = rst $38
	.SIZE:	equ $ - PADDING
; -----------------------------------------------------------------------------

; EOF