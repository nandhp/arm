#!foo
Main:
	MOV R2, #9
	BL IsPrime
	CMP R2, #0
	OUTGT R2
	END
