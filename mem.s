#!/usr/bin/env ./arm.pl
	LDR R1, #0
	CMP R1, #257
	DIENE
	LDRB R2, #3
	CMP R2, #1
	DIENE
	
	STR #40, #4
	
	LDR R1, #4
	CMP R1, #40
	DIENE

	STR #9, #8
	
	LDR R1, #8
	CMP R1, #9
	DIENE
