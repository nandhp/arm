	ldr sp, stack		; setup the stack
	ldr sl, stack_limit	; and its limit
	mov lr, pc
	LDR pc, exec_start
	end
	end
	end
exec_start:	dcw &813C
stack_limit: dcw &08000
stack:	    dcw &10000
	
	    dcw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	    dcw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	    dcw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	    dcw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

	    END
