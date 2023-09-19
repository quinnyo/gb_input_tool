include "defines.inc"

section "InputTool", rom0


def vMarker equ $8000
def vKeys equ $8800
def vNibble equ $8A00


def MARKER_X_OFS equ OAM_X_OFS - 4
def MARKER_Y_OFS equ OAM_Y_OFS - 4

rsreset
def tMarker00 rb 1
def tMarker01 rb 1
def tMarker02 rb 1
def tMarker03 rb 1
def tMarker04 rb 1
def tMarker05 rb 1
def tMarker06 rb 1
def tMarker07 rb 1
def tMarker08 rb 1
def tMarker09 rb 1

marker_2bpp:
	incbin "res/marker.2bpp"
.end

rsset 128
def tKeyD0 rb 1
def tKeyD1 rb 1
def tKeyD2 rb 1
def tKeyD3 rb 1
def tKeyU0 rb 1
def tKeyU1 rb 1
def tKeyU2 rb 1
def tKeyU3 rb 1
def tKeyL0 rb 1
def tKeyL1 rb 1
def tKeyL2 rb 1
def tKeyL3 rb 1
def tKeyR0 rb 1
def tKeyR1 rb 1
def tKeyR2 rb 1
def tKeyR3 rb 1
def tKeyCentre0 rb 1
def tKeyCentre1 rb 1
def tKeyCentre2 rb 1
def tKeyCentre3 rb 1
def tKeySta0 rb 1
def tKeySta1 rb 1
def tKeySel0 equ tKeySta0
def tKeySel1 equ tKeySta1
def tKeyB0 rb 1
def tKeyB1 rb 1
def tKeyB2 rb 1
def tKeyB3 rb 1
def tKeyA0 equ tKeyB0
def tKeyA1 equ tKeyB1
def tKeyA2 equ tKeyB2
def tKeyA3 equ tKeyB3

def tLabelSta0 rb 1
def tLabelSta1 rb 1
def tLabelSel0 rb 1
def tLabelSel1 rb 1
def tLabelB rb 1
def tLabelA rb 1


keys_2bpp:
	incbin "res/keys.2bpp"
.end


def tNibble rb 16

nibble_2bpp:
	incbin "res/nibble.2bpp"
.end


def BGBaseAddr = $9800
def _MapX = 0
def _MapY = 0
def _MapIdx = 0

def cToAddr equ $80
def cDone equ $FF

macro ToCell
	assert _NARG == 2
	def _MapX = (\1)
	def _MapY = (\2)
	assert _MapX >= 0 && _MapY >= 0 && _MapX < 32 && _MapY < 32
	def _MapIdx = _MapY * 32 + _MapX
	db cToAddr
	dw BGBaseAddr + _MapIdx
endm

macro Move
	assert _NARG == 2
	def _MapX += (\1)
	def _MapY += (\2)
	assert _MapX >= 0 && _MapY >= 0 && _MapX < 32 && _MapY < 32
	def _MapIdx = _MapY * 32 + _MapX
	db cToAddr
	dw BGBaseAddr + _MapIdx
endm

macro Place
	assert _NARG != 0
	assert _NARG < 128
	db {_NARG}, \#
	def _MapIdx += _NARG
	def _MapX = _MapIdx % 32
	def _MapY = _MapIdx >>> 5
endm

macro Done
	db cDone
endm


def mDirCentreX equ 4
def mDirCentreY equ 4

map_keys:
	ToCell 3, 1
	def mU01 equ _MapIdx
	Place tKeyU0, tKeyU1
	Move -2, 1
	def mU23 equ _MapIdx
	Place tKeyU2, tKeyU3
	Move -4, 1
	def mL01 equ _MapIdx
	Place tKeyL0, tKeyL1, tKeyCentre0, tKeyCentre1, tKeyR0, tKeyR1
	def mR01 equ _MapIdx - 2
	Move -6, 1
	def mL23 equ _MapIdx
	Place tKeyL2, tKeyL3, tKeyCentre2, tKeyCentre3, tKeyR2, tKeyR3
	def mR23 equ _MapIdx - 2
	Move -4, 1
	def mD01 equ _MapIdx
	Place tKeyD0, tKeyD1
	Move -2, 1
	def mD23 equ _MapIdx
	Place tKeyD2, tKeyD3

	ToCell 16, 3
	def mA_x equ _MapX + 1
	def mA_y equ _MapY + 1
	def mA01 equ _MapIdx
	Place tKeyA0, tKeyA1
	Move -2, 1
	def mA23 equ _MapIdx
	Place tKeyA2, tKeyA3, tLabelA

	ToCell 13, 4
	def mB_x equ _MapX + 1
	def mB_y equ _MapY + 1
	def mB01 equ _MapIdx
	Place tKeyB0, tKeyB1
	Move -2, 1
	def mB23 equ _MapIdx
	Place tKeyB2, tKeyB3, tLabelB

	ToCell 8, 7
	def mSel_x equ _MapX + 1
	def mSel_y equ _MapY
	def mSel01 equ _MapIdx
	Place tKeySel0, tKeySel1
	Move -2, 1
	Place tLabelSel0, tLabelSel1

	ToCell 11, 7
	def mSta_x equ _MapX + 1
	def mSta_y equ _MapY
	def mSta01 equ _MapIdx
	Place tKeySta0, tKeySta1
	Move -2, 1
	Place tLabelSta0, tLabelSta1

	Done
.end


cmap_eval::
.loop
	ld a, [de]
	inc de

	bit 7, a
	jr nz, :+
	ld c, a
.place
	ld a, [de]
	inc de
	ld [hl+], a
	dec c
	jr nz, .place
	jr .loop
:

	cp cToAddr
	jr nz, :+
	ld a, [de]
	inc de
	ld l, a
	ld a, [de]
	inc de
	ld h, a
	jr .loop
:

	cp cDone
	ret z

:
	ld b, b
	ld a, d
	halt
	nop
	jr :-


; ColorW R, G, B
; Define a color, stored in a 2 byte word, encoded as RGB555 for CGB.
macro ColorW
	dw (($1F & (\3)) << 10) | (($1F & (\2)) << 5) | ($1F & (\1))
endm

def CPAL_SIZE equ 8
def BCPAL_COUNT equ 2

bcpal0:
	ColorW $1E, $19, $14
	ColorW $11, $17, $19
	ColorW $0A, $0B, $0C
	ColorW $06, $07, $08

bcpal1:
	ColorW 4, 4, 5
	ColorW 21, 20, 18
	ColorW 27, 28, 26
	ColorW 12, 10, 11

ocpal0:
	ColorW 31, 31, 31
	ColorW 31, 12, 24
	ColorW 1, 4, 2
	ColorW 12, 22, 27


InputTool_init::
	ld hl, vMarker
	ld de, marker_2bpp
	ld bc, marker_2bpp.end - marker_2bpp
	call mem_copy

	ld hl, vKeys
	ld de, keys_2bpp
	ld bc, keys_2bpp.end - keys_2bpp
	call mem_copy

	ld hl, vNibble
	ld de, nibble_2bpp
	ld bc, nibble_2bpp.end - nibble_2bpp
	call mem_copy

	ld a, BCPSF_AUTOINC
	ldh [rBCPS], a
	ld c, CPAL_SIZE * BCPAL_COUNT
	ld hl, bcpal0
:
	ld a, [hl+]
	ldh [rBCPD], a
	dec c
	jr nz, :-

	ld a, OCPSF_AUTOINC
	ldh [rOCPS], a
	ld c, CPAL_SIZE
	ld hl, ocpal0
:
	ld a, [hl+]
	ldh [rOCPD], a
	dec c
	jr nz, :-

	ld hl, $9800
	ld d, 0
	ld bc, 32 * 32
	call mem_fill

	; GB type
	ld e, "D"
	ld a, [wBoot_A]
	cp BOOTUP_A_DMG
	jr z, :+
	ld e, "M"
	cp BOOTUP_A_MGB
	jr z, :+
	ld e, "C"
	cp BOOTUP_A_CGB
	jr z, :+
	ld e, "?"
:
	ld hl, $9800
	ld a, "Q"
	ld [hl+], a
	ld [hl], e

	ld de, map_keys
	call cmap_eval

	ld hl, wKeyFade
	ld a, 9
	ld c, 8
	call mem_fill_byte

	; window palette
	ld a, 1
	ldh [rVBK], a
	ld hl, $9C00
	ld d, 1
	ld bc, 32 * 32
	call mem_fill
	xor a
	ldh [rVBK], a

	ret


InputTool_main_iter::
	ld a, [wInput.state]
	ld b, a
	ld c, 8
	ld hl, wKeyFade
.key_loop
	xor a
	bit 0, b
	jr nz, :+
	ld a, [hl]
	cp 9
	jr nc, :+
	inc a
:
	ld [hl+], a
	srl b
	dec c
	jr nz, .key_loop

	call oam_next_recall

	ld de, wKeyFade

	; A
	ld a, mA_y * 8 + MARKER_Y_OFS
	ld [hl+], a
	ld a, mA_x * 8 + MARKER_X_OFS
	ld [hl+], a
	ld a, [de]
	inc de
	add tMarker00
	ld [hl+], a
	ld a, OAMF_PAL1
	ld [hl+], a

	; B
	ld a, mB_y * 8 + MARKER_Y_OFS
	ld [hl+], a
	ld a, mB_x * 8 + MARKER_X_OFS
	ld [hl+], a
	ld a, [de]
	inc de
	add tMarker00
	ld [hl+], a
	ld a, OAMF_PAL1
	ld [hl+], a

	; Sel
	ld a, mSel_y * 8 + MARKER_Y_OFS + 4
	ld [hl+], a
	ld a, mSel_x * 8 + MARKER_X_OFS + 1
	ld [hl+], a
	ld a, [de]
	inc de
	add tMarker00
	ld [hl+], a
	ld a, OAMF_PAL1
	ld [hl+], a

	; Sta
	ld a, mSta_y * 8 + MARKER_Y_OFS + 4
	ld [hl+], a
	ld a, mSta_x * 8 + MARKER_X_OFS + 1
	ld [hl+], a
	ld a, [de]
	inc de
	add tMarker00
	ld [hl+], a
	ld a, OAMF_PAL1
	ld [hl+], a

	; R
	ld a, mDirCentreY * 8 + MARKER_Y_OFS
	ld [hl+], a
	ld a, (mDirCentreX + 3) * 8 + MARKER_X_OFS - 1
	ld [hl+], a
	ld a, [de]
	inc de
	add tMarker00
	ld [hl+], a
	ld a, OAMF_PAL1
	ld [hl+], a

	; L
	ld a, mDirCentreY * 8 + MARKER_Y_OFS
	ld [hl+], a
	ld a, (mDirCentreX - 3) * 8 + MARKER_X_OFS + 2
	ld [hl+], a
	ld a, [de]
	inc de
	add tMarker00
	ld [hl+], a
	ld a, OAMF_PAL1
	ld [hl+], a

	; U
	ld a, (mDirCentreY - 3) * 8 + MARKER_Y_OFS + 2
	ld [hl+], a
	ld a, mDirCentreX * 8 + MARKER_X_OFS
	ld [hl+], a
	ld a, [de]
	inc de
	add tMarker00
	ld [hl+], a
	ld a, OAMF_PAL1
	ld [hl+], a

	; D
	ld a, (mDirCentreY + 3) * 8 + MARKER_Y_OFS - 1
	ld [hl+], a
	ld a, mDirCentreX * 8 + MARKER_X_OFS
	ld [hl+], a
	ld a, [de]
	inc de
	add tMarker00
	ld [hl+], a
	ld a, OAMF_PAL1
	ld [hl+], a

	call oam_next_store

:
	ldh a, [rLY]
	cp SCRN_Y
	jr c, :-

	ld hl, $9C00
	ld a, "P"
	ld [hl+], a
	ld a, "x"
	ld [hl+], a
	ld a, "R"
	ld [hl+], a
	ld hl, $9C20
	ld a, [wInput.pressed]
	call .draw_nibble
	ld a, [wInput.state]
	call .draw_nibble
	ld a, [wInput.released]
	call .draw_nibble
	ld hl, $9C40
	ld a, [wInput.pressed]
	call .draw_nibble_hi
	ld a, [wInput.state]
	call .draw_nibble_hi
	ld a, [wInput.released]
	call .draw_nibble_hi

	ld a, SCRN_Y - 24 - 4
	ldh [rWY], a
	ld a, SCRN_X - 24 + WX_OFS - 4
	ldh [rWX], a

	ret

.draw_nibble_hi
	swap a
.draw_nibble
	and $0F
	add tNibble
	ld [hl+], a
	ret


section "wInputTool", wram0

wKeyFade:
	ds 8
