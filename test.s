#!/usr/bin/env ./arm.pl
	NOP			; 0
	BL sub			; 4
	B foo			; 8
bar:	B baz			; 12
foo:	B bar			; 16
baz:	END			; 20
sub:	NOP			; 24
	MOV R1, R14		; 28
	BL subsub		; 32
	MOV R15, R1		; 36
subsub: NOP			; 40
	MOV R15, R14		; 44
