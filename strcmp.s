#!/usr/bin/env ./arm.pl
; Compare two null terminated strings for equality
Test_Strcmp_Main:
	mov r9, #0x4C		; less
	mov r10, #0x45		; equal
	mov r11, #0x47		; greater
	
	LDR	R0, =Data1		;load the address of the lookup table
	LDR	R1, =Data2
;	LDR	R2, Match		;assume strings not equal, set to -1
	bl strcmp
	str r2, Match
	out r2
	out #1			; should be greater
	mov r2, r0
	mov r0, r1
	mov r1, r2
	bl strcmp
	out r2
	out #-1			; should be less, tho same length

	LDR	R0, =Data1		;load the address of the lookup table
	LDR	R1, =Data3
	bl strcmp
	out r2
	out #-1			; should be less, tho same length
	mov r2, r0
	mov r0, r1
	mov r1, r2
	bl strcmp
	out r2
	out #1			; should be more, tho same length
	
	LDR	R0, =Data2		;load the address of the lookup table
	LDR	R1, =Data3
	bl strcmp
	out r2
	out #-1			; should be less
	
	ldr r0, =Data3
	mov r1,r0
	bl strcmp
	out r2
	out #0			; should be equal
	
	ldr r0, =Data3
	mov r1,r0
	sub r0, r0, #1		; zero length strings
	bl strcmp
	out r2
	out #-1			; should be less
	mov r1, r0
	bl strcmp
	out r2
	out #0		     ; two zero length strings should be equal
	ldr r0, =Data3
	bl strcmp
	out r2
	out #1		     ; should be greater

	end

;;; Compares two string, in r0 and r1, for equality.
;;; Returns -- in r2 with zero meaning equal,
;;;	       less than zero meaning r0 is less than r1 and positive for the
;;;	       reverse.
;;; Note -- Bashes registers 3-6
strcmp:	
;	MOV	R3, #0			;init register
;	MOV	R4, #0
;Count1:
;	LDRB	R5, [R0, R3]		;load the first byte into R5
;	CMP	R5, #0			;is it the terminator
;	BEQ	Count2			;if not, Loop
;	ADD	R3, R3, #1		;increment count
;	BAL	Count1
;Count2:
;	LDRB	R5, [R1, R4]		;load the first byte into R5
;	CMP	R5, #0			;is it the terminator
;	BEQ	Next			;if not, Loop
;	ADD	R4, R4, #1		;increment count
;	BAL	Count2
;
;Next:	CMP	R3, R4
;	BNE	Done			;if they are different lengths, 
;					;they can't be equal
;	CMP	R3, #0			;test for zero length if both are
;	BEQ	Same			;zero length, nothing else to do
;	mov r0,r7		; reset string pointers
;	mov r1,r8

	mov r3, #0
Loop:
	LDRB	R5, [R0, R3]		;character of first string
	cmp	r5, #0
	BEQ	less_or_equal
	LDRB	R6, [R1, R3]		;character of second string
	cmp	r6, #0
	BEQ	more
	CMP	R5, R6			;are they the same
	blt	less
	bgt	more
	add	r3, r3, #1
	B	Loop			;not done, loop

less_or_equal:
	LDRB	r6, [r1, r3]
	cmp	r6, #0
	bne	less

Same:
	MOV	R2, #0			;clear the -1 from match (0 = match)
	b Return

less:	MOV	r2, #-1
	b	Return
more:	MOV	r2, 1

Return:	
	mov r15, r14
;	STR	R2, Match		;store the result
;	OUT	R2
	END

Data1:	DCB	"Hello, World", 0	;the string
Data2:	DCB	"Hello, Worl", 0	;the string
Data3:	DCB	"Hello, vorld", 0	;the string
Match:	DCD	&FFFF			;flag for match
