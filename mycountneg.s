#!/usr/bin/env ./arm.pl
	LDR R0, =Data1		; R0 = Current position in memory
	MOV R2, #0		; R2 = How many were negative
	LDR R3, =EndAddr

Loop:
	CMP R0, R3		; EndAddr is the end, which should have 0
	BEQ Done
	LDR R1, [R0]		; R1 = Current value
	CMP R1, #0
	ADDMI R2, R2, #1
	ADD R0, R0, #4
	B Loop

Done:	OUT R2
	END
				;foo
Data1:	DCD	&F0000012
	DCD	&00000159
	DCD     &F0000197
EndAddr: DCD #0
