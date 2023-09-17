if !def(DEFINES_INC)
def DEFINES_INC equ 1


include "hardware.inc"
	rev_Check_hardware_inc 4.8


include "res/onebit-mono.inc"


; Wait until safe to access VRAM (Mode 0-1)
; @mut A
macro WaitVRAM
	ldh a, [rSTAT]	;+2
	and STATF_BUSY	;+1
	jr nz, @ - 4 	;+1=4
endm


macro WaitVBL
	ldh a, [rSTAT]
	and STATF_VBL
	jr nz, @ - 4
endm

endc ; DEFINES_INC
