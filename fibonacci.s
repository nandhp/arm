#!/usr/bin/env ./arm.pl
	MOV R0, #1
	MOV R1, R0
	OUT R0
	
Loop:	OUT R0
	MOV R2, R0
	ADD R0, R0, R1
	MOV R1, R2
	B Loop
