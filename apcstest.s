;;        AREA main, CODE, READONLY
;;        ENTRY start

start:
        ADR    r0, title
        SWI    &02         ; OS_Write0

        SWI    &10         ; OS_GetEnv
        SWI    &02         ; OS_Write0
        SWI    &03         ; OS_NewLine
        SWI    &11         ; OS_Exit

title:
        DCB   "This program was called with:", #10, #13, "   ", 0
        ALIGN
	
