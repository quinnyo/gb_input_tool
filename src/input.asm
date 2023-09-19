include "defines.inc"


;******************************************************************************
;* wInput
;******************************************************************************

section "Input State", wram0
wInput::
	; Current controller state
	.state:: db
	; Keys that became pressed in the most recent update.
	.pressed:: db
	; Keys that became unpressed in the most recent update.
	.released:: db


;******************************************************************************
;* input routines
;******************************************************************************

section "Input", rom0

;; Initialise/reset input state.
input_init::
	ld hl, startof("Input State")
	xor a
	ld c, sizeof("Input State")
:
	ld [hl+], a
	dec c
	jr nz, :-

	ret


; Process the new input state.
; @param B: new input state
; @mut: A, C
input_update::
	ld a, [wInput.state]
	xor b
	ld c, a ; C = keys that changed
	and b ; A = keys that changed to pressed
	ld [wInput.pressed], a
	ld a, b ; A = new state
	ld [wInput.state], a
	cpl
	and c
	ld [wInput.released], a

	ret


; Read current input state
; - Reads dirs (delay: 2) then buttons (delay: 6)
; - Does work during button delay
; @ret B: input state
; @mut: A
input_read::
	ld a, P1F_GET_DPAD
	ldh [rP1], a
	ldh a, [rP1]
	ldh a, [rP1]
	ld b, a
	ld a, P1F_GET_BTN
	ldh [rP1], a
	ld a, b                 ; 1
	or $F0                  ; 2
	swap a                  ; 2
	ld b, a                 ; 1  (6)
	ldh a, [rP1]
	or $F0
	xor b
	ld b, a
	ld a, P1F_GET_NONE
	ldh [rP1], a

	ret


; Read current input state (zero delay)
; @ret B: input state
; @mut: A
input_read_0::
	ld a, P1F_GET_DPAD
	ldh [rP1], a
	ldh a, [rP1]
	or $F0
	swap a
	ld b, a
	ld a, P1F_GET_BTN
	ldh [rP1], a
	ldh a, [rP1]
	or $F0
	xor b
	ld b, a
	ld a, P1F_GET_NONE
	ldh [rP1], a

	ret
