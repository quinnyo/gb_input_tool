include "defines.inc"

;******************************************************************************
;* wInput
;******************************************************************************

section "Input State", wram0
wInput::
	; Current controller state (as of the most recent input.update)
	.state:: db
	; Keys that became pressed in the most recent update.
	.pressed:: db
	; Keys that became unpressed in the most recent update.
	.released:: db
	; History of each key's state for the last 8 frames.
	; Each byte is one key/dir -- in the same order as PADB_*
	.hist::
	.hist_a:: db
	.hist_b:: db
	.hist_select:: db
	.hist_start:: db
	.hist_right:: db
	.hist_left:: db
	.hist_up:: db
	.hist_down:: db

	.held::
	.held_a:: db
	.held_b:: db
	.held_select:: db
	.held_start:: db
	.held_right:: db
	.held_left:: db
	.held_up:: db
	.held_down:: db


wInput_raw_btn:: ds Input_RawBufferLen
wInput_raw_dir:: ds Input_RawBufferLen


;******************************************************************************
;* input routines
;******************************************************************************

section "Input", rom0

;; input.init
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


;; input.update
;; Reads controller port, updates wInput.
;; Handles
input_update::
	; abort if LCD is off
	ldh a, [rLCDC]
	bit 7, a
	ret z

	call input_read

	; update pressed / released buttons
	ld b, a ; B = new state
	ld a, [wInput.state] ; A = previous state
	xor b
	ld c, a ; C = keys that changed
	and b ; A = keys that changed to pressed
	ld [wInput.pressed], a
	ld a, b ; A = new state
	ld [wInput.state], a
	cpl
	and c
	ld [wInput.released], a

	; update hist
	ld a, [wInput.state]
	ld b, a
	ld c, 8
	ld hl, wInput.hist
:
	ld a, [hl]
	sla a
	bit 0, b
	jr z, .continue
	or 1
.continue
	ld [hl+], a
	srl b
	dec c
	jr nz, :-

	; update held timers
	ld a, [wInput.pressed]
	ld b, a
	ld a, [wInput.state]
	xor b
	ld b, a ; B = held (not pressed)
	xor a
	ld c, 8
.held_loop
	bit 0, b
	jr z, .held_cont
	ld a, [hl]
	cp $FF
	jr nc, .held_cont
	inc a
.held_cont
	ld [hl+], a
	xor a
	srl b
	dec c
	jr nz, .held_loop

	ret


; Read P1, filling input raw sample buffers
; @ret A: latest combined input state
input_read:
	di

	; BUTTONS
	ld hl, wInput_raw_btn
	ld a, P1F_GET_BTN
	ldh [rP1], a

rept Input_RawBufferLen
	ldh a, [rP1]
	ld [hl+], a
endr

	; DPAD
	ld hl, wInput_raw_dir
	ld a, P1F_GET_DPAD
	ldh [rP1], a

rept Input_RawBufferLen
	ldh a, [rP1]
	ld [hl+], a
endr

	ld a, P1F_GET_NONE
	ldh [rP1], a

	; combine last samples as current state
	ld a, [wInput_raw_btn + Input_RawBufferLen - 1]
	or $F0
	ld b, a
	ld a, [wInput_raw_dir + Input_RawBufferLen - 1]
	or $F0
	swap a
	xor b

	reti
