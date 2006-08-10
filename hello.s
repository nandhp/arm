	.file	"hello.c"
	.text
	.align	2
	.global	printc
	.type	printc, %function
printc:
	@ args = 0, pretend = 0, frame = 4
	@ frame_needed = 1, uses_anonymous_args = 0
	mov	ip, sp
	stmfd	sp!, {fp, ip, lr, pc}
	sub	fp, ip, #4
	sub	sp, sp, #4
	mov	r3, r0
	strb	r3, [fp, #-13]
	ldrb	r3, [fp, #-13]
	 stmdb sp!, {r0}
 mov r0, r3
 swi #2
 ldmia sp!, {r0}
	ldmfd	sp, {r3, fp, sp, pc}
	.size	printc, .-printc
	.global	__umodsi3
	.global	__udivsi3
	.align	2
	.global	aprintf
	.type	aprintf, %function
aprintf:
	@ args = 4, pretend = 16, frame = 76
	@ frame_needed = 1, uses_anonymous_args = 1
	mov	ip, sp
	stmfd	sp!, {r0, r1, r2, r3}
	stmfd	sp!, {fp, ip, lr, pc}
	sub	fp, ip, #20
	sub	sp, sp, #76
	add	r3, fp, #8
	str	r3, [fp, #-16]
.L3:
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #0
	beq	.L2
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #37
	bne	.L5
	ldr	r3, [fp, #4]
	add	r3, r3, #1
	str	r3, [fp, #4]
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #37
	bne	.L6
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	bl	printc
	b	.L55
.L6:
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #98
	bne	.L8
	ldr	r2, [fp, #-16]
	ldr	r3, [fp, #-16]
	add	r3, r3, #4
	str	r3, [fp, #-16]
	ldr	r3, [r2, #0]
	str	r3, [fp, #-20]
	mov	r3, #0
	str	r3, [fp, #-56]
	mov	r3, #0
	str	r3, [fp, #-60]
.L9:
	ldr	r3, [fp, #-60]
	cmp	r3, #31
	bgt	.L10
	mvn	r2, #39
	ldr	r3, [fp, #-60]
	sub	r1, fp, #12
	add	r3, r1, r3
	add	r2, r3, r2
	mov	r3, #48
	strb	r3, [r2, #0]
	ldr	r3, [fp, #-60]
	add	r3, r3, #1
	str	r3, [fp, #-60]
	b	.L9
.L10:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bne	.L13
	ldr	r3, [fp, #-56]
	add	r3, r3, #1
	str	r3, [fp, #-56]
.L13:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	beq	.L14
	ldr	r3, [fp, #-20]
	and	r3, r3, #1
	str	r3, [fp, #-64]
	ldr	r3, [fp, #-64]
	cmp	r3, #0
	beq	.L15
	mvn	r2, #39
	ldr	r3, [fp, #-56]
	sub	r1, fp, #12
	add	r3, r1, r3
	add	r2, r3, r2
	mov	r3, #49
	strb	r3, [r2, #0]
.L15:
	ldr	r3, [fp, #-20]
	mov	r3, r3, lsr #1
	str	r3, [fp, #-20]
	ldr	r3, [fp, #-56]
	add	r3, r3, #1
	str	r3, [fp, #-56]
	b	.L13
.L14:
	ldr	r3, [fp, #-56]
	sub	r3, r3, #1
	str	r3, [fp, #-56]
.L16:
	ldr	r3, [fp, #-56]
	cmp	r3, #0
	blt	.L55
	mvn	r2, #39
	ldr	r3, [fp, #-56]
	sub	r1, fp, #12
	add	r3, r1, r3
	add	r3, r3, r2
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	bl	printc
	ldr	r3, [fp, #-56]
	sub	r3, r3, #1
	str	r3, [fp, #-56]
	b	.L16
.L8:
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #100
	beq	.L21
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #117
	beq	.L21
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #120
	beq	.L21
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #88
	beq	.L21
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #98
	beq	.L21
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #111
	beq	.L21
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #105
	beq	.L21
	b	.L20
.L21:
	mov	r2, #0
	str	r2, [fp, #-76]
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #100
	beq	.L23
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #105
	beq	.L23
	b	.L22
.L23:
	mov	r3, #1
	str	r3, [fp, #-76]
.L22:
	ldr	r1, [fp, #-76]
	str	r1, [fp, #-64]
	mov	r3, #10
	str	r3, [fp, #-60]
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #120
	beq	.L25
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #88
	beq	.L25
	b	.L24
.L25:
	mov	r3, #16
	str	r3, [fp, #-60]
.L24:
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #98
	bne	.L26
	mov	r3, #2
	str	r3, [fp, #-60]
.L26:
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #111
	bne	.L27
	mov	r3, #8
	str	r3, [fp, #-60]
.L27:
	ldr	r3, [fp, #-64]
	cmp	r3, #0
	beq	.L28
	ldr	r2, [fp, #-16]
	ldr	r3, [fp, #-16]
	add	r3, r3, #4
	str	r3, [fp, #-16]
	ldr	r3, [r2, #0]
	str	r3, [fp, #-20]
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L29
	mov	r0, #45
	bl	printc
	ldr	r3, [fp, #-20]
	rsb	r3, r3, #0
	str	r3, [fp, #-56]
	b	.L31
.L29:
	ldr	r3, [fp, #-20]
	str	r3, [fp, #-56]
	b	.L31
.L28:
	ldr	r2, [fp, #-16]
	ldr	r3, [fp, #-16]
	add	r3, r3, #4
	str	r3, [fp, #-16]
	ldr	r3, [r2, #0]
	str	r3, [fp, #-56]
.L31:
	mov	r3, #0
	str	r3, [fp, #-20]
	mov	r3, #0
	str	r3, [fp, #-68]
	mov	r3, #0
	str	r3, [fp, #-72]
.L32:
	ldr	r3, [fp, #-72]
	cmp	r3, #31
	bgt	.L33
	mvn	r2, #39
	ldr	r3, [fp, #-72]
	sub	r1, fp, #12
	add	r3, r1, r3
	add	r2, r3, r2
	mov	r3, #48
	strb	r3, [r2, #0]
	ldr	r3, [fp, #-72]
	add	r3, r3, #1
	str	r3, [fp, #-72]
	b	.L32
.L33:
	ldr	r3, [fp, #-56]
	cmp	r3, #0
	bne	.L35
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
.L35:
	
your_friendly_neighbourhood_spiderman:
.L36:
	ldr	r3, [fp, #-56]
	cmp	r3, #0
	beq	.L37
	ldr	r3, [fp, #-56]
	mov	r0, r3
	ldr	r1, [fp, #-60]
	bl	__umodsi3
	mov	r3, r0
	str	r3, [fp, #-68]
	ldr	r2, [fp, #-56]
	ldr	r3, [fp, #-68]
	rsb	r3, r3, r2
	str	r3, [fp, #-56]
	ldr	r3, [fp, #-68]
	cmp	r3, #0
	blt	.L39
	ldr	r2, [fp, #-68]
	ldr	r3, [fp, #-60]
	cmp	r2, r3
	bge	.L39
	b	.L38
.L39:
	mov	r0, #64
	bl	printc
.L38:
	mvn	r2, #39
	ldr	r3, [fp, #-20]
	sub	r1, fp, #12
	add	r3, r1, r3
	add	r2, r3, r2
	ldr	r3, [fp, #-68]
	add	r3, r3, #48
	strb	r3, [r2, #0]
	ldr	r3, [fp, #-68]
	cmp	r3, #9
	ble	.L40
	mvn	r2, #39
	ldr	r3, [fp, #-20]
	sub	r1, fp, #12
	add	r3, r1, r3
	add	r3, r3, r2
	str	r3, [fp, #-80]
	ldr	r3, [fp, #-68]
	sub	r3, r3, #10
	str	r3, [fp, #-84]
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #88
	bne	.L41
	ldr	r2, [fp, #-84]
	add	r3, r2, #65
	strb	r3, [fp, #-85]
	b	.L42
.L41:
	ldr	r1, [fp, #-84]
	add	r3, r1, #97
	strb	r3, [fp, #-85]
.L42:
	ldrb	r3, [fp, #-85]
	ldr	r2, [fp, #-80]
	strb	r3, [r2, #0]
.L40:
	mvn	r2, #39
	ldr	r3, [fp, #-20]
	sub	r1, fp, #12
	add	r3, r1, r3
	add	r3, r3, r2
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #70
	bls	.L43
	mvn	r2, #39
	ldr	r3, [fp, #-20]
	sub	r1, fp, #12
	add	r3, r1, r3
	add	r3, r3, r2
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #90
	bhi	.L43
	mov	r0, #33
	bl	printc
.L43:
	mvn	r2, #39
	ldr	r3, [fp, #-20]
	sub	r1, fp, #12
	add	r3, r1, r3
	add	r3, r3, r2
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #102
	bls	.L44
	mov	r0, #63
	bl	printc
.L44:
	ldr	r0, [fp, #-56]
	ldr	r1, [fp, #-60]
	bl	__udivsi3
	mov	r3, r0
	str	r3, [fp, #-56]
	mov	r3, #0
	str	r3, [fp, #-68]
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
	b	.L36
.L37:
	ldr	r3, [fp, #-20]
	sub	r3, r3, #1
	str	r3, [fp, #-20]
.L45:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	blt	.L55
	mvn	r2, #39
	ldr	r3, [fp, #-20]
	sub	r1, fp, #12
	add	r3, r1, r3
	add	r3, r3, r2
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	bl	printc
	ldr	r3, [fp, #-20]
	sub	r3, r3, #1
	str	r3, [fp, #-20]
	b	.L45
.L20:
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #99
	bne	.L49
	ldr	r2, [fp, #-16]
	ldr	r3, [fp, #-16]
	add	r3, r3, #4
	str	r3, [fp, #-16]
	ldr	r3, [r2, #0]
	str	r3, [fp, #-72]
	ldr	r3, [fp, #-72]
	and	r3, r3, #255
	mov	r0, r3
	bl	printc
	b	.L55
.L49:
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #115
	bne	.L51
	ldr	r2, [fp, #-16]
	ldr	r3, [fp, #-16]
	add	r3, r3, #4
	str	r3, [fp, #-16]
	ldr	r3, [r2, #0]
	str	r3, [fp, #-72]
.L52:
	ldr	r3, [fp, #-72]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	cmp	r3, #0
	beq	.L55
	ldr	r3, [fp, #-72]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	bl	printc
	ldr	r3, [fp, #-72]
	add	r3, r3, #1
	str	r3, [fp, #-72]
	b	.L52
.L51:
	mov	r0, #37
	bl	printc
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	bl	printc
	b	.L55
.L5:
	ldr	r3, [fp, #4]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	bl	printc
.L55:
	ldr	r3, [fp, #4]
	add	r3, r3, #1
	str	r3, [fp, #4]
	b	.L3
.L2:
	sub	sp, fp, #12
	ldmfd	sp, {fp, sp, pc}
	.size	aprintf, .-aprintf
	.section	.rodata
	.align	2
.LC0:
	.ascii	"%u\n\000"
	.align	2
.LC1:
	.ascii	"Testing aprintf now.\n"
	.ascii	"aprintf supports: d, i, u, x, X, o, b, s, c\n\n\000"
	.align	2
.LC2:
	.ascii	"Testing %%d:\t\000"
	.align	2
.LC3:
	.ascii	"%s=%d\n\000"
	.align	2
.LC4:
	.ascii	"1+2\000"
	.align	2
.LC5:
	.ascii	"Testing %%c:\t\000"
	.align	2
.LC6:
	.ascii	"%c%c%c\n\000"
	.align	2
.LC7:
	.ascii	"Testing <=0:\t\000"
	.align	2
.LC8:
	.ascii	"1-1=%u, 1-2u=%u, 1-3d=%d\n\000"
	.align	2
.LC9:
	.ascii	"1-1=0, 1-2=%d\n\000"
	.align	2
.LC10:
	.ascii	"Testing %%dxX:\t\000"
	.align	2
.LC11:
	.ascii	"  %d+ %d=  %d\n\000"
	.align	2
.LC12:
	.ascii	"\t\t0x%x+0x%x=0x%x\n\000"
	.align	2
.LC13:
	.ascii	"\t\t0x%X+0x%X=0x%X\n\n\000"
	.align	2
.LC14:
	.ascii	"Displaying ritual pointless message:\n"
	.ascii	"\t\000"
	.align	2
.LC15:
	.ascii	"Hello, world!\n\n\000"
	.align	2
.LC16:
	.ascii	"Counting in multiple bases:\n\000"
	.align	2
.LC17:
	.ascii	"%d\t%x\t%o\t%b\n\000"
	.align	2
.LC18:
	.ascii	"\n\n"
	.ascii	"Program complete.\n\000"
	.text
	.align	2
	.global	main
	.type	main, %function
main:
	@ args = 0, pretend = 0, frame = 12
	@ frame_needed = 1, uses_anonymous_args = 0
	mov	ip, sp
	stmfd	sp!, {fp, ip, lr, pc}
	sub	fp, ip, #4
	sub	sp, sp, #16
	ldr	r0, .L60
	mvn	r1, #0
	bl	aprintf
	ldr	r0, .L60+4
	bl	aprintf
	ldr	r0, .L60+8
	bl	aprintf
	ldr	r0, .L60+12
	ldr	r1, .L60+16
	mov	r2, #3
	bl	aprintf
	ldr	r0, .L60+20
	bl	aprintf
	ldr	r0, .L60+24
	mov	r1, #97
	mov	r2, #98
	mov	r3, #99
	bl	aprintf
	ldr	r0, .L60+28
	bl	aprintf
	ldr	r0, .L60+32
	mov	r1, #0
	mvn	r2, #0
	mvn	r3, #1
	bl	aprintf
	ldr	r0, .L60+36
	mvn	r1, #0
	bl	aprintf
	ldr	r0, .L60+40
	bl	aprintf
	mov	r3, #508
	add	r3, r3, #3
	str	r3, [fp, #-20]
	mov	r3, #65280
	add	r3, r3, #255
	str	r3, [fp, #-24]
	ldr	r2, [fp, #-20]
	ldr	r3, [fp, #-24]
	add	r3, r2, r3
	ldr	r0, .L60+44
	ldr	r1, [fp, #-20]
	ldr	r2, [fp, #-24]
	bl	aprintf
	ldr	r2, [fp, #-20]
	ldr	r3, [fp, #-24]
	add	r3, r2, r3
	ldr	r0, .L60+48
	ldr	r1, [fp, #-20]
	ldr	r2, [fp, #-24]
	bl	aprintf
	ldr	r2, [fp, #-20]
	ldr	r3, [fp, #-24]
	add	r3, r2, r3
	ldr	r0, .L60+52
	ldr	r1, [fp, #-20]
	ldr	r2, [fp, #-24]
	bl	aprintf
	ldr	r0, .L60+56
	bl	aprintf
	ldr	r0, .L60+60
	bl	aprintf
	ldr	r0, .L60+64
	bl	aprintf
	mov	r3, #0
	str	r3, [fp, #-16]
.L57:
	ldr	r3, [fp, #-16]
	cmp	r3, #16
	bgt	.L58
	ldr	r3, [fp, #-16]
	str	r3, [sp, #0]
	ldr	r0, .L60+68
	ldr	r1, [fp, #-16]
	ldr	r2, [fp, #-16]
	ldr	r3, [fp, #-16]
	bl	aprintf
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
	b	.L57
.L58:
	ldr	r0, .L60+72
	bl	aprintf
	mov	r3, #0
	mov	r0, r3
	sub	sp, fp, #12
	ldmfd	sp, {fp, sp, pc}
.L61:
	.align	2
.L60:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.word	.LC5
	.word	.LC6
	.word	.LC7
	.word	.LC8
	.word	.LC9
	.word	.LC10
	.word	.LC11
	.word	.LC12
	.word	.LC13
	.word	.LC14
	.word	.LC15
	.word	.LC16
	.word	.LC17
	.word	.LC18
	.size	main, .-main
	.ident	"GCC: (GNU) 3.4.3"
