               MOV     R0, #0 ; sum as 0
               MOV     R1, #1 ; c as 1
               MOV     R2, #0 ; i as 0

loop_condition 
               CMP     R2, #11 ; compare i with 11
               BEQ     end_program ; it is greater than 10 (invalid loop condition)
               BLT     loop ; it is equal to or less than 10 (valid loop condition)

loop           
               CMP     R1, #1 ; check if c equals 1
               BEQ     if_block ; if condition is right
               B       else_block ; if condition is not met

if_block       
               ADD     R0, R0, R2 ; add i to sum
               MOV     R1, #0 ; set c to equal 0
               ADD     R2, R2, #1 ; increment i
               B       loop_condition

else_block     
               MOV     R1, #1 ; set c to equal 1
               ADD     R2, R2, #1 ; increment i
               B       loop_condition

end_program    
               END