MAX		EQU		10          ; Define the maximum value (10)
SUM		DCD		0           ; Reserve 4 bytes for the sum variable at address 0x0100
		
		MOV		R0, #0      ; Initialize R0 (sum register) to 0
		MOV		R1, #MAX    ; Initialize R1 (counter) to MAX (10)
		
LOOP
		ADD		R0, R0, R1  ; Add the current value of R1 to R0 (sum)
		SUBS		R1, R1, #1  ; Decrement R1 (counter) by 1 and update flags
		BNE		LOOP        ; If R1 is not zero, branch back to LOOP
		
DONE
		LDR		R2, =SUM    ; Load the address of SUM into R2
		STR		R0, [R2]    ; Store the value of R0 (sum) into the memory location of SUM
		END		; End of program
