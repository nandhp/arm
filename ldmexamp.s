	ADR R0, start
	OUT R0
reload	LDMIA R0, {R1-R3}
	OUT R1
	OUT R2
	OUT R3
	ADD R1, R1, #3
	ADD R2, R2, #3
	ADD R3, R3, #3
	STMIA R0, {R1-R3}
	CMP R9, #9
	MOVNE R9, #9
	BNE reload
	END

start	DCW #4 ; R1
	DCW #9 ; R2
	DCW #7 ; R3
