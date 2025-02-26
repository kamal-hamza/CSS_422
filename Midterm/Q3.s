node0     DCD     0x108, 0x1125 ; node0’s address = 0x100
node1     DCD     0x110, 0x2345 ; node1’s address = 0x108
node2     DCD     0x118, 0x12FC ; node2’s address = 0x110
node3     DCD     0x120, 0x1234 ; node3’s address = 0x118
node4     DCD     0x0, 0xABCF ; node4’s address = 0x120
newItem   DCD     0x0, 0xAAAA ;to be inserted before 1234
          LDR     R0, =0x1234 ; item to look for
          LDR     R1, =0x100 ; struct node *R1 = node0;
          MOV     R2, #0 ; for previous nodes
for_loop  
          CMP     R1, #0
          BEQ     not_found ; reached the end
          LDR     R3, [R1, #4] ; load the value in R1 into R3
          CMP     R3, R0 ; compare the values
          BEQ     found ; value was found
          MOV     R2, R1 ; move R2 into R1
          LDR     R1, [R1] ; increment R1
          B       for_loop ; loop again

found     
          CMP     R2, #0 ; if previous node is null
          BEQ     not_found ; dont insert if previous node is null
          LDR     R4, =newItem; load the new item into R4
          LDR     R5, [R2] ; load previous nodes next pointer
          STR     R4, [R2] ; point the next pointer to the new item
          STR     R5, [R4] ; point the next pointer of new item to the orignal value

not_found END