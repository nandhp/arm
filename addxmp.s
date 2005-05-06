#!/usr/bin/env ./arm.pl
	LDR R1, Value1
	LDR R2, Value2
	ADD R1, R1, R2
	STR R1, Result
	OUT R1
	END

Value1:	DCD &37E3C123
Value2:	DCD &367402AA
Result:	DCD 0			; Result should be 1851245517/0x6e57c3cd
