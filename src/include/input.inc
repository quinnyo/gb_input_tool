if !def(INPUT_INC)
def INPUT_INC equ 1


;******************************************************************************
;* Macros to define Input system
;******************************************************************************

;; DefInputRead W_STATE, W_PRESSED, W_RELEASED
;; Create the 'read' routine
;; USAGE:
;; 	MyInput.Read::
;; 		DefInputRead wMyInput.state[, wMyInput.pressed[, wMyInput.released]]
macro DefInputRead
	assert !def(_ARG_W_STATE) && !def(_ARG_W_PRESSED) && !def(_ARG_W_RELEASED)
	assert _NARG >= 1
	def _ARG_W_STATE equs \1
	if _NARG >= 2
		def _ARG_W_PRESSED equs \2
	endc
	if _NARG >= 3
		def _ARG_W_RELEASED equs \3
	endc

;; input 'read' impl
	di

	; BUTTONS
	ld a, P1F_GET_BTN
	ldh [rP1], a
rept 6 ; ~18 cycles
	ldh a, [rP1]
endr
rept 2
	ld b, a
	ldh a, [rP1]
	or b
endr
	or $F0
	ld b, a ; B = buttons (0 == CLOSED)

	; DPAD
	ld a, P1F_GET_DPAD
	ldh [rP1], a
rept 2 ; ~twice
	ldh a, [rP1]
endr
	or $F0
	swap a
	xor b ; combine dpad with buttons (also inverts, so 1 == CLOSED)

if def(_ARG_W_PRESSED) || def(_ARG_W_RELEASED)
	; update pressed / released buttons
	ld b, a ; (B) = new state
	ld a, [_ARG_W_STATE] ; (A) = previous state
	xor b
	ld c, a ; (C) = keys that changed

if def(_ARG_W_PRESSED)
	and b ; (A) = keys that changed to pressed
	ld [_ARG_W_PRESSED], a
endc ; DEF(_W_PRESSED)

	ld a, b ; (A) = new state
endc ; DEF(_W_PRESSED) || DEF(_W_RELEASED)

	ld [_ARG_W_STATE], a

if def(_ARG_W_RELEASED)
	cpl
	and c
	ld [_ARG_W_RELEASED], a
endc ; DEF(_W_RELEASED)

	ld a, P1F_GET_NONE
	ldh [rP1], a

	ei

	ret
;; end input 'read impl

	purge _ARG_W_STATE, _ARG_W_PRESSED, _ARG_W_RELEASED
endm ; DefInputRead


endc ; INPUT_INC
