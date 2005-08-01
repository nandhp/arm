home:
	B foo
	OUT  #31
	OUT  R0 ;, R1, R2
	OUTS R3 ;, R4, R5
minx:	B swis
	DIE
	OUTB R6 ;, R7, R8
foo:
	B minx
	
swis:
	SWI &EFEFEF
	SWI &FFFFFF
	SWI &EEEEEE
	SWI &11
	END
	DIE
