#!/usr/bin/env ./arm.pl
	NOOP
	;; Branch Link
	BL sub
	;; Crash
	;B R19
	B foo
bar:	B baz
foo:	B bar
baz:
	;DIE
	END
sub:	NOOP
	MOV R1, R14
	BL subsub
	;; Should be MOV
	;B R1
	MOV R15, R1
subsub:
	NOOP
	;; Should be MOV
	;B R14
	MOV R15, #2
