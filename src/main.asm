include "defines.inc"


section "IRQ_VBlank", rom0[$0040]
	jp ISR_VBlank

; section "IRQ_LCDSTAT", rom0[$0048]
; 	jp ISR_audio_update

; section "IRQ_Timer", rom0[$0050]
; 	jp ISR_audio_update

; section "IRQ_Serial", rom0[$0058]
; 	reti

; section "IRQ_P1", rom0[$0060]
; 	reti


section "Header", rom0[$0100]
	nop
	jp EntryPoint
	ds $150 - @, 0


section "ISR", rom0
ISR_VBlank:
	push af

	call hOAMCopyRoutine

	ld a, 1
	ld [wVBlankF], a

	pop af
	reti


/**********************************************************
* MAIN
**********************************************************/
section "Main", rom0
EntryPoint:
	ld [wBoot_A], a
	ld a, b
	ld [wBoot_B], a

Reset::
	di

	xor a
	ld [wVBlankF], a
	ld a, IEF_VBLANK
	ldh [rIE], a

	ld sp, $FFFE

	call audio_off
	call lcd_off
	call oam_init
	call input_init
	call gfx_load_default_font

	ld a, %11100100
	ldh [rBGP], a
	ldh [rOBP0], a
	ld a, %00011011
	ldh [rOBP1], a

	call Mode_init

	call lcd_on

	; enable interrupts
	xor a
	ldh [rIF], a
	ldh a, [rIE]
	or IEF_VBLANK
	ldh [rIE], a

	ei
	xor a
	ld [wVBlankF], a
	jr MainLoop.vblank_wait

MainLoop:
	call oam_clear

	call input_update
	call Mode_main_iter



	; Skip first HALT -- if already in VBLANK, don't want to wait for another one?
	jr .vblank_wait_entry
.vblank_wait
	halt
	nop
.vblank_wait_entry
	; wait for vblank interrupt
	ld a, [wVBlankF]
	and a
	jr z, .vblank_wait
	xor a
	ld [wVBlankF], a

	jr MainLoop


; Disable the LCD (waits for vblank)
lcd_off::
:
	ldh a, [rLY]
	cp SCRN_Y
	jr c, :-
	xor a
	ldh [rLCDC], a
	ret


; Enable the LCD
lcd_on::
	; Turn the LCD on, enable BG, enable OBJ
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_WINON | LCDCF_WIN9C00
	ldh [rLCDC], a
	ld a, 144
	ldh [rWY], a
	ret


wait_vblank::
	ldh a, [rLY]
	cp SCRN_Y
	jr c, wait_vblank
	ret


include "mem.inc"


; Font CHR data VRAM location
def vFont equ $9000

font_1bpp:
	incbin "res/onebit-mono.1bpp", 0, ONEBIT_MONO_RES_SIZE

gfx_load_default_font::
	ld hl, vFont
	ld de, font_1bpp
	ld bc, ONEBIT_MONO_RES_SIZE
	call vmem_copy_double

	ret


section "Main_State", wram0
wBoot_A:: db
wBoot_B:: db

; VBlank completion flag
wVBlankF:: db


/**********************************************************
* MODE
* Pluggable main program modes.
**********************************************************/
section "Mode", rom0

; Jump to the `init` routine of the current mode
Mode_init:
	jp InputTool_init

; Jump to the `main_iter` routine of the current mode
Mode_main_iter:
	jp InputTool_main_iter


/**********************************************************
* AUDIO
**********************************************************/
section "audio", rom0

audio_off::
	xor a
	ldh [rNR52], a
	ret
