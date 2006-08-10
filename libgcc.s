; .macro ARM_MOD_BODY dividend, divisor, order, spare
arm_mod_body:
	mov	r2, #0

	@ Unless the divisor is very big, shift it up in multiples of
	@ four bits, since this is the amount of unwinding in the main
	@ division loop.  Continue shifting until the divisor is 
	@ larger than the dividend.
.amb1:	cmp	r1, #0x10000000
	cmplo	r1, r0
	movlo	r1, r1, lsl #4
	addlo	r2, r2, #4
	blo	.amb1

	@ For very big divisors, we must shift it a bit at a time, or
	@ we will be in danger of overflowing.
.amb2:	cmp	r1, #0x80000000
	cmplo	r1, r0
	movlo	r1, r1, lsl #1
	addlo	r2, r2, #1
	blo	.amb2

	@ Perform all needed substractions to keep only the reminder.
	@ Do comparisons in batch of 4 first.
	subs	r2, r2, #3		@ yes, 3 is intended here
	blt	.amb4

.amb3:	cmp	r0, r1
	subhs	r0, r0, r1
	cmp	r0, r1,  lsr #1
	subhs	r0, r0, r1, lsr #1
	cmp	r0, r1,  lsr #2
	subhs	r0, r0, r1, lsr #2
	cmp	r0, r1,  lsr #3
	subhs	r0, r0, r1, lsr #3
	cmp	r0, #1
	mov	r1, r1, lsr #4
	subges	r2, r2, #4
	bge	.amb3

	tst	r2, #3
	teqne	r0, #0
	beq	.amb7

	@ Either 1, 2 or 3 comparison/substractions are left.
.amb4:	cmn	r2, #2
	blt	.amb6
	beq	.amb5
	cmp	r0, r1
	subhs	r0, r0, r1
	mov	r1,  r1,  lsr #1
.amb5:	cmp	r0, r1
	subhs	r0, r0, r1
	mov	r1,  r1,  lsr #1
.amb6:	cmp	r0, r1
	subhs	r0, r0, r1
.amb7:	mov r15, r14

;.macro ARM_DIV_BODY dividend, divisor, result, curbit
; \dividend r3    \divisor r1    \result r0    \curbit r2
arm_div_body:
	@ Initially shift the divisor left 3 bits if possible,
	@ set curbit accordingly.  This allows for curbit to be located
	@ at the left end of each 4 bit nibbles in the division loop
	@ to save one loop in most cases.
	tst	r1, #0xe0000000
	moveq	r1, r1, lsl #3
	moveq	r2, #8
	movne	r2, #1

	@ Unless the divisor is very big, shift it up in multiples of
	@ four bits, since this is the amount of unwinding in the main
	@ division loop.  Continue shifting until the divisor is 
	@ larger than the dividend.
.adb1:	cmp	r1, #0x10000000 ; 1
	cmplo	r1, r3
	movlo	r1, r1, lsl #4
	movlo	r2, r2, lsl #4
	blo	.adb1

	@ For very big divisors, we must shift it a bit at a time, or
	@ we will be in danger of overflowing.
.adb2:	cmp	r1, #0x80000000 ; 1
	cmplo	r1, r3
	movlo	r1, r1, lsl #1
	movlo	r2, r2, lsl #1
	blo	.adb2

	mov	r0, #0

	@ Division loop
.adb3:	cmp	r3, r1 ; 1
	subhs	r3, r3, r1
	orrhs	r0,   r0,   r2
	cmp	r3, r1,  lsr #1
	subhs	r3, r3, r1, lsr #1
	orrhs	r0,   r0,   r2,  lsr #1
	cmp	r3, r1,  lsr #2
	subhs	r3, r3, r1, lsr #2
	orrhs	r0,   r0,   r2,  lsr #2
	cmp	r3, r1,  lsr #3
	subhs	r3, r3, r1, lsr #3
	orrhs	r0,   r0,   r2,  lsr #3
	cmp	r3, #0			@ Early termination?
	movnes	r2,   r2,  lsr #4	@ No, any more bits to do?
	movne	r1,  r1, lsr #4
	bne	.adb3
	mov r15, r14
.endm

;* ------------------------------------------------------------------------ */
.arm_div2_order:
	cmp	r1, #0x00010000
	movhs	r1, r1, lsr #16
	movhs	r2, #16
	movlo	r2, #0

	cmp	r1, #0x00000100
	movhs	r1, r1, lsr #8
	addhs	r2, r2, #8

	cmp	r1, #0x00000010
	movhs	r1, r1, lsr #4
	addhs	r2, r2, #4

	cmp	r1, #0x00000004
	addhi	r2, r2, #3
	addls	r2, r2, r1, lsr #1
	mov r15, r14
	
;* ------------------------------------------------------------------------ */
.rvt:	DCW #0
__modsi3: ; MOD
	cmp	r1, #0
	beq	.Ldiv0
	rsbmi	r1, r1, #0			@ loops below use unsigned.
	movs	ip, r0				@ preserve sign of dividend
	rsbmi	r0, r0, #0			@ if negative make positive
	subs	r2, r1, #1			@ compare divisor with 1
	cmpne	r0, r1				@ compare dividend with divisor
	moveq	r0, #0
	tsthi	r1, r2				@ see if divisor is power of 2
	andeq	r0, r0, r2
	bls	.msil

	str r14, .rvt
	BL arm_mod_body
	ldr r14, .rvt

.msil:	cmp	ip, #0
	rsbmi	r0, r0, #0
	mov	pc, lr

.Ldiv0: ;Divide by zero handler?
	die
;	str	lr, [sp, #-4]!
;	bl	SYM (__div0) __PLT__
;	mov	r0, #0			@ About as wrong as it could be.
;	ldr	pc, [sp], #4

;* ------------------------------------------------------------------------ */
__divsi3:
	cmp	r1, #0
	eor	ip, r0, r1			@ save the sign of the result.
	beq	.Ldiv0
	rsbmi	r1, r1, #0			@ loops below use unsigned.
	subs	r2, r1, #1			@ division by 1 or -1 ?
	beq	.di10
	movs	r3, r0
	rsbmi	r3, r0, #0			@ positive dividend value
	cmp	r3, r1
	bls	.di11
	tst	r1, r2				@ divisor is power of 2 ?
	beq	.di12

	str r14, .rvt
	bl arm_div_body ; r3, r1, r0, r2
	ldr r14, .rvt
	
	cmp	ip, #0
	rsbmi	r0, r0, #0
	mov	pc, lr

.di10:	teq	ip, r0				@ same sign ?
	rsbmi	r0, r0, #0
	mov	pc, lr

.di11:	movlo	r0, #0
	moveq	r0, ip, asr #31
	orreq	r0, r0, #1
	mov	pc, lr

.di12:	
	str r14, .rvt
	bl .arm_div2_order
	ldr r14, .rvt

	cmp	ip, #0
	mov	r0, r3, lsr r2
	rsbmi	r0, r0, #0
	mov	pc, lr
	b .Ldiv0

__umodsi3: ; MOD
	subs	r2, r1, #1			@ compare divisor with 1
	bcc	.Ldiv0
	cmpne	r0, r1				@ compare dividend with divisor
	moveq   r0, #0
	tsthi	r1, r2				@ see if divisor is power of 2
	andeq	r0, r0, r2
	cmp	r1, #0
	movls	pc,lr

	str r14, .rvt
	BL arm_mod_body
	ldr r14, .rvt
	mov r15, r14
	b .Ldiv0

;* ------------------------------------------------------------------------ */
.swar:	dcw #0
.swbr:	dcw #0
__udivsi3:
	subs	r2, r1, #1
	moveq	r15, r14
	bcc	.Ldiv0
	cmp	r0, r1
	bls	.ud11
	tst	r1, r2
	beq	.ud12
	
	; have r0, r1, r2, r3
	; want r3, r1, r0, r2
	str r0, .rvt
	str r2, .swar
	str r3, .swbr
	ldr r3, .rvt
	ldr r0, .swar
	ldr r2, .swbr

	str r14, .rvt
	bl arm_div_body
	ldr r14, .rvt

	str r3, .rvt
	str r0, .swar
	str r2, .swbr
	ldr r0, .rvt
	ldr r2, .swar
	ldr r3, .swbr
	
	mov	r0, r2
	mov	pc, lr


.ud11:	moveq	r0, #1
	movne	r0, #0
	mov	pc, lr

.ud12:	str r14, .rvt
	bl .arm_div2_order ; r1, r2
	mov	r0, r0, lsr r2
	ldr r14, .rvt	
	mov	pc, lr
	b .Ldiv0
