node1	DCD		0x10C, 0x130, 4  ; Node 1: left = 0x10C, right = 0x130, value = 4
node2	DCD		0x118, 0x124, 2  ; Node 2: left = 0x118, right = 0x124, value = 2
node3	DCD		0,     0,     1  ; Node 3: left = 0 (null), right = 0 (null), value = 1 (leaf node)
node4	DCD		0,     0,     3  ; Node 4: left = 0 (null), right = 0 (null), value = 3 (leaf node)
node5	DCD		0x13C, 0x148, 6  ; Node 5: left = 0x13C, right = 0x148, value = 6
node6	DCD		0,     0,     5  ; Node 6: left = 0 (null), right = 0 (null), value = 5 (leaf node)
node7	DCD		0,     0,     7  ; Node 7: left = 0 (null), right = 0 (null), value = 7 (leaf node)
		
		;		Initialize registers
		MOV		R0, #8         ; R0 = target value to search for (5)
		MOV		R2, #0x100       ; R2 = pointer to the root node (node1 at address 0x100)
		
		;		Main loop to traverse the binary tree
loop
		CMP		R2, #0         ; Check if the current node pointer (R2) is null
		BEQ		stop             ; If null, the target value is not found, so stop
		
		LDR		R3, [R2, #8]   ; Load the value of the current node (R3 = R2->value)
		CMP		R3, R0           ; Compare the node's value (R3) with the target value (R0)
		BEQ		found            ; If equal, the target value is found
		BGT		greater          ; If the node's value is greater than the target, go to the left subtree
		BLT		less             ; If the node's value is less than the target, go to the right subtree
		
		;		Handle the case where the node's value is greater than the target
greater
		LDR		R2, [R2]         ; Move to the left child (R2 = R2->left)
		B		loop             ; Continue the loop
		
		;		Handle the case where the node's value is less than the target
less
		LDR		R2, [R2, #4]   ; Move to the right child (R2 = R2->right)
		B		loop             ; Continue the loop
		
		;		Handle the case where the target value is found
found
		ADD		R1, R2, #8     ; R1 = address of the value field of the found node (R2 + 8)
		B		stop             ; Stop the program
		
		;		Stop the program
stop
		END		; End of the program
