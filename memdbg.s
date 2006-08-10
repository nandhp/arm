	LDR R0, sample
loop:	ADD R0, R0, #1
	STR R0, sample
	B loop
sample:	DCW #0
