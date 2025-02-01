src		DCB		'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 0
dst		DCB		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		
begin
		LDR		R0, =src ; load R0 as src
		LDR		R1, =dst ; load R1 as dst
		
loop
		LDRB		R2, [R0], #1 ; load the first char of R0 into R2
		CMP		R2, #0 ; compare R2 to 0
		BEQ		done ; if R2 is 0 then end program
		CMP		R2, #'a' ; compare R2 with 'a'
		BLT		store ; if R2 < 'a' character is not lowercase
		CMP		R2, #'z' ; compare R2 with 'z'
		BGT		store ; if R2 > 'z' character is not lowercase
		SUB		R2, R2, #32 ; subtract 32 to convert to uppercase
		
store
		STRB		R2, [R1], #1 ; store the character in the correct address in R2
		B		loop ; loop again
		
done
		END
