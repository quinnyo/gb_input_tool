include "defines.inc"

def OAM_BUFFER_SIZE equ OAM_COUNT * sizeof_OAM_ATTRS

section "OAMBufferState", wram0, align[8]
wOAMBuffer::
	ds OAM_BUFFER_SIZE

; Points to next unused OAM entry
wNext: dw


section "OAM setup", rom0
; Store HL as next available OAM entry address
; @mut: A
oam_next_store::
	ld a, l
	ld [wNext], a
	ld a, h
	ld [wNext + 1], a
	ret

; Load (previously stored) next available OAM entry address into HL
; @ret HL: the 'Next' pointer.
; @mut: A
oam_next_recall::
	ld a, [wNext]
	ld l, a
	ld a, [wNext + 1]
	ld h, a
	ret

; Clear OAM buffer, reset the 'Next' pointer.
oam_clear::
	ld hl, wOAMBuffer
	call oam_next_store
	ld c, OAM_BUFFER_SIZE
	xor a
:
	ld [hl+], a
	dec c
	jr nz, :-
	ret

; Initialize the OAM shadow buffer, and setup the OAM copy routine in HRAM.
oam_init::
	call oam_clear

	ld hl, hOAMCopyRoutine
	ld de, oamCopyRoutine
	ld c, hOAMCopyRoutine.end - hOAMCopyRoutine
.copyOAMRoutineLoop
	ld a, [de]
	inc de
	ld [hl+], a
	dec c
	jr nz, .copyOAMRoutineLoop
	; We directly copy to clear the initial OAM memory, which else contains garbage.
	call hOAMCopyRoutine
	ret

oamCopyRoutine:
load "hram", hram
; Copy buffered data to OAM (DMA)
hOAMCopyRoutine::
	ld a, high(wOAMBuffer)
	ldh [rDMA], a
	ld a, OAM_COUNT
.wait
	dec a
	jr nz, .wait
	ret
.end:
endl
