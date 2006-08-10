	LDR R0, sa
	LDR R1, sb
	CMP R0, R1, LSR #1
sa:	DCW #0x5fffffff
sb:	DCW #0xa0000000
