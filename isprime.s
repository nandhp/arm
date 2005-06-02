;	MOV R2, #17
;	BL IsPrime
;	OUT R2
;	END
;	MOV R9, #9999999
;	MOV R10, #0
;Main:	
;	MOV R2, #0
;	BL IsPrime
;	OUT R2
;	END
	B Main

;;;; R2 = Prime-to-check -- R0,R1 will be trampled!
;;;; Output => R2

IsPrime:
	; Store R14 in memory
	STR R14, PrimeTemp

	; Special-cace for 2
	CMP R2, #2
	BEQ YesPrime
	BLT NotPrime

	; Divide R2 by 2
	MOVS R0, R2, LSR #1
	BCC NotPrime
	STR R0, Quotient
	;ANDS R0, R2, 1

	;MOV R0, R2
	;MOV R1, #2
	;BL Mod
	;CMP R0, #0
	;BEQ NotPrime
	MOV R1, #1

PrimeLoop:
	ADD R1, R1, #2
	; Divide R2 by R1
	LDR R0, Quotient
	CMP R0, R1
	BLT YesPrime
	MOV R0, R2
	;BEQ YesPrime

	;OUT R9
	BL Mod
	;OUT R10

	CMP R0, #0
	BEQ NotPrime
	B PrimeLoop

NotPrime:
	MOV R2, #0
	LDR R14, PrimeTemp
	MOV R15, R14
YesPrime:
	LDR R14, PrimeTemp
	MOV R15, R14

PrimeTemp:
	DCW #0
