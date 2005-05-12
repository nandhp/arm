#!/usr/bin/env ./arm.pl
	;FIX
	LDR	R0, =Data1		;load the address of the lookup table
	EOR	R1, R1, R1		;clear R1 to store count
	LDR	R2, Length		;init element count
	CMP	R2, #0
	BEQ	Done			;if table is empty
Loop:
	LDR	R3, [R0]		;get the data
	CMP	R3, #0
	BPL	Looptest		;skip next line if +ve or zero
	ADD	R1, R1, #1		;increment -ve number count
Looptest:
	ADD	R0, R0, #+4		;increment pointer
	SUBS	R2, R2, #0x1		;decrement count with zero set
	BNE	Loop			;if zero flag is not set, loop
Done:
	STR	R1, Result		;otherwise done - store result
	OUT	R1
	END

;Data1:	DCD	&F1522040		;table of values to be added
;	DCD	&7F611C22
;	DCD	&80000242
Data1:	DCD	&F0000012
	DCD	&00000159
	DCD     &F0000197
TablEnd: DCD	0
Length:	DCW	3 ;(TablEnd - Table) / 4	;because we're having to align
;	ALIGN				;gives the loop count
Result:	DCW	0			;storage for result
