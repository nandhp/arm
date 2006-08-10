#!/usr/bin/env ./arm.pl
; Count the number of times character CHAR appears in string DATA
	ADR	R0, Data	; Address of string
	LDRB	R1, Char	; Character to count up (C)
	OUTB R1
	MOV	R2, #0		; Current char
	MOV	R3, #0		; Index in string
	MOV	R4, #0		; Count of C

Loop:	LDRB	R2, [R0,R3]
	CMP	R2, #0
	BEQ	Done
	CMP	R2, R1
	ADDEQ	R4, R4, #1
	ADD	R3, R3, #1
	B	Loop

Done:	OUT	R4
	END
	
Data:	DCB	"Hello", 0

Char:	DCB	"l"
	


