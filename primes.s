#!/usr/bin/perl ./arm.pl isprime.s divide.s
Main:
	; Max
	MOV R9, #50

	MOV R3, #2
	MOV R2, R3
	BL IsPrime
	OUT R2
	ADD R3, R3, #1

Loop:	MOV R2, R3
	BL IsPrime
	CMP R2, #0
	OUTGT R2
	ADD R3, R3, #2
	CMP R3, R9
	BLE Loop
	END
