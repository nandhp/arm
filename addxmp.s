#!/usr/bin/env ./arm.pl
	LDR R1, Value1
	OUTS R1
	LDR R2, Value2
	OUTS R2
	ADD R3, R1, R2
	STR R3, Result
	OUTS R3
	END

Value1:	DCD &37E3C123
Value2:	DCD &367402AA
Result:	DCD 0			; Result should be 1851245517/0x6e57c3cd
