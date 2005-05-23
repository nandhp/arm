	;	MOV R0, #99994
;	MOV R1,	#21
;	BL Mod
;	OUT R0
;	END

;	MOV R0, #4
;	MOV R1, #2
;	BL Mod
;	LDR R1, Quotient
;	OUT R0, R1
;	END
	B Main

;;;; R0 = Numerator, R1 = Denominator (Divisor)
;;;; Output => R0
;;;; R13 and R14 used as temp

; 500 = 0m12.939s user
Mod:	CMP R1, #0
	MOVEQ R15, R14

	; Save R14 because we evilly use it for a temporary register
	STR R14, DivideTemp
	MOV R14, #0
	MOV R13, #0

ModPrep:
	CMP R1, R0
	BGT ModPrepDone
	MOV R1, R1, LSL #1
	ADD R13, R13, #1
	B ModPrep

ModPrepDone:
	MOV R1, R1, LSR #1
	SUBS R13, R13, #1
	BMI ModDone

ModLoop:
	; ???
	CMP R1, R0
	SUBLE R0, R0, R1
	ADDLE R14, R14, #1
	CMP R13, #0
	BEQ ModDone
	SUB R13, R13, #1
	MOV R1, R1, LSR #1
	MOV R14, R14, LSL #1
	B ModLoop

ModDone:
	;MOV R0, R13
	STR R14, Quotient
	LDR R14, DivideTemp
	MOV R15, R14

; 500 =  0m31.163s
OldMod:
	CMP R1, #0
	MOVEQ R15, R14

	; Save R14 because we evilly use it for a temporary register
	STR R14, DivideTemp
	MOV R14, #0
OldModLoop:
	CMP R0, R1
	;OUTLT R14
	STRLT R14, Quotient
	LDRLT R14, DivideTemp
	MOVLT R15, R14

	ADD R14, R14, #1
	SUB R0, R0, R1
	B OldModLoop

; Some memory
Quotient: DCW #0
DivideTemp: DCW #0
