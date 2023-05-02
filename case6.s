NUM_LOOPS = 100

.bss

i32_a:    .space 4
i32_b:    .space 4
i32_c:    .space 4
i16_d:    .space 2
u8_e:    .space 1


.text                           ; Start of Code section.

.global _main                   ; Therefore, it must be visible outside this file.
_main:                          ; _main is called after C startup code runs.

    ;; int32_t  i32_a = 0xB3E83894
    mov #0x3894, W0
    mov #0xB3E8, W1
    mov W0, i32_a
    mov W1, i32_a + 2
    ;; int32_t  i32_b = 0x348AC297
    mov #0xC297, W0
    mov #0x348A, W1
    mov W0, i32_b
    mov W1, i32_b + 2
    ;; int32_t  i32_c = 0xA55A93CD
    mov #0x93CD, W0
    mov #0xA55A, W1
    mov W0, i32_c
    mov W1, i32_c + 2
    ;; int16_t  i16_d = 0xA4F5
    mov #0xA4F5, W0
    mov W0, i16_d

    ; u8_e = 0;
    clr.b u8_e

    ; do {
    do_top:

        mov.b u8_e, WREG
        mov.b W0, W7
        
        ; W3:W2 = i32_b
	mov i32_b, W2
	mov i32_b + 2, W3
        ; W5:W4 = i32_c
	mov i32_c, W4
	mov i32_c + 2, W5
        ; W6 = i16_d
	mov i16_d, W6
        ; W7 = u8_e
	mov.b u8_e, WREG
	mov.b W0, W7
	; W1:W0 = i32_a
	mov i32_a, W0
	mov i32_a + 2, W1

        call _check

        ;; if (i32_c & 0x00400000) {
        ;;     i16_d = ~i16_d - 0xA045;
        ;;     i32_a = i32_b | i32_c;
        ;;     i32_b = i32_b - i32_c;
        ;; } else {
        ;;    if (i32_a <= i32_b) {
        ;;         i32_a = (i32_a << 2) +  (int32_t) i16_d;
        ;;     } else {
        ;;         i32_a = i32_a - i32_b;
        ;;     }
        ;; }
        ;; i32_c = ~( (i32_c >> 1) - i32_a);

        ;      W5:W4       W3:W2
        ; if (i32_c & 0x00400000)  {
        ; Input
	mov i32_c, W4
	mov i32_c + 2, W5
	mov #0x0000, W2
	mov #0x0040, W3
        ; Process
	and W2, W4, W6
	and W3, W5, W7
	cp W6, #0
	cpb W7, #0
        ; Output
	bra Z, else
	bra NZ, if

	if:
            ;   W6      W5       W4
            ; i16_d = ~i16_d - 0xA045;
            ; Input
	    mov #0xA045, W4
	    mov i16_d, W5    
            ; Process
	    com W5, W5
	    sub W5, W4, W6
            ; Output
	    mov W6, i16_d

            ; W1:W0    W3:W2  W5:W4
            ; i32_a = i32_b | i32_c;
            ; Input
	    mov i32_c, W4
	    mov i32_c + 2, W5
	    mov i32_b, W2
	    mov i32_b + 2, W3
	    mov i32_a, W0
	    mov i32_a + 2, W1
            ; Process
	    ior W2, W4, W0
	    ior W3, W5, W1
            ; Output
	    mov W0, i32_a
	    mov W1, i32_a + 2

            ;   W3:W2  W1:W0     W5:W4
            ;  i32_b = i32_b - i32_c;
            ; Input
	    mov i32_c, W4
	    mov i32_c + 2, W5
	    mov i32_b, W0
	    mov i32_b + 2, W1
            ; Process
	    sub W0, W4, W2
	    subb W1, W5, W3
	    
            ; Output
	    mov W2, i32_b
	    mov W3, i32_b + 2



	bra if_end

	else:


            ;      W1:W0   W3:W2
            ; if (i32_a <= i32_b) {
            ; Input
	    mov i32_a, W0
	    mov i32_a + 2, W1
	    mov i32_b, W2
	    mov i32_b + 2, W3
            ; Process
	    cp W0, W2
	    cpb W1, W3
            ; Output
	    bra LE, if1
	    bra GT, else1
	    
	    if1:

                ;  W1:W0      W3:W2               W7:W6
                ; i32_a = (i32_a << 2) +  (int32_t) i16_d;
                ; Input
		mov i16_d, W6
		mov i32_a, W2
		mov i32_a + 2, W3
		cp W6, #0
		bra GE, pos
		bra LT, neg
		pos:
		    mov #0x0000, W7
		    bra end
		neg:
		    mov #0xFFFF, W7
		end:
                ; Process
		sl W2, W2
		rlc W3, W3
		sl W2, W2
		rlc W3, W3
		add W2, W6, W0
		addc W3, W7, W1
                ; Output
		mov W0, i32_a
		mov W1, i32_a + 2


	    bra if_end1

	    else1:


                ;  W1:W0   W5:W4    W3:W2
                ; i32_a = i32_a - i32_b;
                ; Input
		mov i32_b, W2
		mov i32_b + 2, W3
		mov i32_a, W4
		mov i32_a + 2, W5
                ; Process
		sub W4, W2, W0
		subb W5, W3, W1
                ; Output
		mov W0, i32_a
		mov W1, i32_a + 2

	    if_end1:



	if_end:


        ;    W5:W4      W3:W2         W1:W0
        ;  i32_c = ~( (i32_c >> 1) - i32_a);
        ; Input
	mov i32_a, W0
	mov i32_a + 2, W1
	mov i32_c, W2
	mov i32_c + 2, W3
        ; Process
	asr W3, W3
	rrc W2, W2
	sub W2, W0, W4
	subb W3, W1, W5
	
	com W5, W5
	com W4, W4
        ; Output
	mov W4, i32_c
	mov W5, i32_c + 2




        ; u8_e++
        inc.b u8_e
        ;        WREG       W1
        ; } while (u8_e < NUM_LOOPS);
        mov.b u8_e, WREG
        mov.b #NUM_LOOPS, W1
        cp.b W0, W1
        bra LTU, do_top
        bra GEU, do_end
    do_end:

done:
    goto    done

.end       ;End of program code in this file

/** \endcond */
