/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file  min-max.S
 *  \brief  Min-Max calculation for array of values.
 *
 *  \author  Tat-Chee Wan (tcwan@usm.my)
 *  \copyright  See the LICENSE file.
 *
 * Pseudocode:
 *
 * do
 *    counter = counter - 1
 *    if (readings[counter] < min) then
 *      min = readings[counter]
 *    if (readings[counter] > max) then
 *      max = readings[counter]
 * while (counter <> 0)
 *
 * Store min and max in memory
 */

/*	Min-Max Routine
 * R0: Temporary value storage
 * R1: counter
 * R2: readings Array Pointer
 * R3: min value
 * R4: max value
 */
	.equiv	U32_MIN, 0x0
	.equiv	U32_MAX, 0xFFFFFFFF

	.code 32
	.text
	.align
/** min_max_u32
 *
 *    Min-Max for Array of Unsigned 32-bit integers
 *
 * Parameters:
 *   r0: Pointer to Array of 32-bit unsigned integers
 *   r1: Number of items
 *   r2: Address of Min variable
 *   r3: Address of Max variable
 * Returns:
 *   None
 *
 * r4: current min value
 * r5: current max value
 * r6: temporary value
 *
 **/

	.global min_max_u32
min_max_u32:
	push	{r4, r5, r6, lr}
    mov  	r5, #U32_MIN   /* Initialize max to smallest 32-bit unsigned value */
    mvn  	r4, #U32_MIN   /* Initialize min to largest 32-bit unsigned value */
min_max_loop:
    sub  	r1, r1, #1     /* counter = counter - 1 */
    /* If */
    ldr 	r6, [r0, r1, lsl #2]   /* Retrieve readings[counter] into r6 */
check_min:
    cmp  	r6, r4         /* check readings[counter] (in r6) < min */
    movlo  	r4, r6         /* Min = readings[counter] */
check_max:
    cmp  	r6, r5         /* check readings[counter] (in r6) > max */
    movhi  	r5, r6         /* Max = readings[counter] */
next_iter:
    teq  	r1, #0         /* Compare r1 against zero */
    bne  	min_max_loop   /* NE: r1 is non-zero */
exit_min_max_loop:
    str 	r4, [r2]       /* Store min into memory variable */
    str 	r5, [r3]       /* Store max into memory variable */
done_min_max:
	pop		{r4, r5, r6, pc}

.end
