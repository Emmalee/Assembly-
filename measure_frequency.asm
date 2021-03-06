$modde2

org 0000H
	CSEG at 0
	ljmp mycode

INT_FREQ equ 33333333
FREQ equ 50 ;1/50Hz=20ms
RELOAD_TIME equ 65536-(INT_FREQ/(12*FREQ)) ;9980

dseg at 30H
x:	ds 3
bcd: ds 4


$include (math16_freq.asm)

CSEG

myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9
    DB 088H, 083H, 0C6H, 0A1H, 086H, 08EH	; A to F

no_leading_zero:
	mov A, bcd+3; hex 7
	swap A
	anl a, #0FH
	cjne a, #00H, L1
	
	mov A, bcd+3; hex 6
	anl a, #0FH
	cjne a, #00H, L2
	
	mov A, bcd+2; hex 5
	swap A
	anl a, #0FH
	cjne a, #00H, L3
	
	mov A, bcd+2; hex 4
	anl a, #0FH
	cjne a, #00H, L4
	
	mov A, bcd+1; hex 3
	swap A
	anl a, #0FH
	cjne a, #00H, L5
	
	mov A, bcd+1; hex 2
	anl a, #0FH
	cjne a, #00H, L6
	
	mov A, bcd+0; hex 1
	swap A
	anl a, #0FH
	cjne a, #00H, L7
	
	mov A, bcd+0; hex 0
	anl a, #0FH
	cjne a, #00H, L8
	
ret

clear: 
	 MOV HEX0, #0FFH
	 MOV HEX1, #0FFH
	 MOV HEX2, #0FFH
	 MOV HEX3, #0FFH
	 MOV HEX4, #0FFH
	 MOV HEX5, #0FFH
	 MOV HEX6, #0FFH
	 MOV HEX7, #0FFH
ret


Display:

	
	lcall clear
		mov dptr, #myLUT
	ljmp no_leading_zero

    
L1:
	;Display Digit 7
    mov A, bcd+3
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov HEX7, A
L2:
	;Display Digit 6
    mov A, bcd+3
    anl a, #0fh
    movc A, @A+dptr
    mov HEX6, A
L3:
    ;Display Digit 5
    mov A, bcd+2
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov HEX5, A
L4:
    ;Display Digit 4
    mov A, bcd+2
    anl a, #0fh
    movc A, @A+dptr
    mov HEX4, A
L5:
    ;Display Digit 3
    mov A, bcd+1
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov HEX3, A
L6:
    ;Display Digit 2
    mov A, bcd+1
    anl a, #0fh
    movc A, @A+dptr
    mov HEX2, A
L7:
    ;Display Digit 1
    mov A, bcd+0
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov HEX1, A
L8:
	;Display Digit 0
    mov A, bcd+0
    anl a, #0fh
    movc A, @A+dptr
    mov HEX0, A

    ret
	
init:
	mov a, #15H
	mov TMOD, a
	ret
		
mycode:
	;turn off LEDs
	mov SP, #7FH
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov LEDRC, a
	mov LEDG, a
	
freq_find:

	;50*0.02= 1 second 
	mov R1, #50
	;R0 holds the over flow flag for the counter
	mov R0, #0
	setb T0 ;p3.4
	clr TR0
	lcall init
	mov TL0, #0
	mov TH0, #0
	clr TF0

	setb TR0
	setb TR1
	
repeat:
	clr TF1
	;reload with 50ms
	mov TL1, #low(RELOAD_TIME)
	mov TH1, #high(RELOAD_TIME)
wait:
	;if timer 0 flag on then there is an overflow
	jb TF0, oflow
	;wait until timer is done 50ms
	jnb TF1, wait
	djnz R1, repeat
	;stop timer and counter
	clr TR1
	clr TR0
	
	sjmp have_it
	
oflow: 
	inc R0
	clr TF0
	sjmp wait
	
have_it: 
	;frequency in TH0, TL0 and R0
	
	mov x+0, TL0
	mov x+1, TH0
	mov x+2, R0
	
	lcall hex2bcd
	lcall display
	
	ljmp freq_find
	
	
end