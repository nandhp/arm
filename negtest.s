	MOV R0, #-4
	STR R0, memor
	LDR R1, memor
	OUT R1

memor:	DCW #0
