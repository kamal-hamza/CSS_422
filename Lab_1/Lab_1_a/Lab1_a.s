START  LDR     R0, =0; Load R0 as 0
       LDR     R1, =10; Load R1 as 10
       LDR     R2, =0x0100; Load R2 as memory adress 0x0100
LOOP   ADD     R0, R1, R0; Add R1 to R0
       SUB     R1, R1, #1; Subtract 1 from R1
       CMP     R1, #0; Compare R1 to 0
       BNE     LOOP
       STR     R0, [R2]; Store the result in 0x0100
       END