	.data
printstr:	.asciz "Hello, ARM World!\n"

	.code 32
	.text
	.align
	.global main

main:
	push		{lr}
	ldr		r0, =printstr
	b		printf
	pop		{pc}

