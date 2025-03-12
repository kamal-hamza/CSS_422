		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT _heap_init
_heap_init
	;; Implement by yourself

	LDR R0, =MCB_TOP ; initialize R0 to the top of the entries
	LDR R1, =0x0 ; load R1 as default 0 value
	LDR R2, =MCB_BOT ; initialize R2 to the bottom address

loop
	CMP R0, R2 ; check if the address is at the end
	BGT done ; check if we are at the end
	STRH R0, [R1] ; initialize the address by setting the value to 0
	ADD R0, R0, #MCB_ENT_SZ ; move to the next entry
	B loop ; repeat the loop

done
	MOV		pc, lr
	END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
	;; Implement by yourself
	
	PUSH {lr} ; save the return address
	
	; R0 already has the size
	LDR R1, =MIN_SIZE ; set R1 to MIN_SIZE
	LDR R2, =MAX_SIZE ; set R2 to MAX_SIZE
	CMP R0, R1 ; compare R0 (size) to min_size
	BLT invalid_size; invalid size less than min size
	CMP R0, R2 ; compare R0 (size) to max_size
	BGT invalid_size ; invalid size greater than max size
	
	; we only get here if the size is valid
	LDR R1, =MCB_TOP ; set R1 to MCB_TOP
	LDR R2, =MCB_BOT ; set R2 to MCB_BOT
	LDR R3, =MCB_ENT_SZ ; set R3 to MCB_ENT_SZ
	BL alloc_mem ; branch to find valid memory spot
	
alloc_mem
	PUSH {lr} ; save the return address
	SUB R4, R2, R1 ; get the total size of the memory block
	ADD R4, R4, R3 ; add the size of the entry
	ASR R5, R4, #1 ; get half of the memory size in R5
	ADD R6, R1, R5; get the midpoint in R6
	LSL R7, R4, #4 ; actual size of entire block
	LSL R8, R5, #4 ; actual size of half the block
	MOV R12, #0 ; initialize the the answer
	CMP R0, R8 ; check if size fits in half the block
	BGT no_alloc ; if size is greater than half then dont alloc
	PUSH {r0-r8} ; save registers
	SUB R2, R6, R3 ; move right bound to the midpoint
	BL alloc_mem ; recurse back to the function
	POP {r0-r8} ; restore registers
	CMP R12, #0 ; check if we found a spot
	BEQ alloc_right ; if we did not then try the right side
	LDR R9, [R6] ; load value at midpoint
	AND R9, R9, #0x01 ; check if flag is set
	CMP R9, #0 ; if not then
	BEQ return ; return allocated memory
	B done ; return

alloc_right
	PUSH {r0-r8} ; save registers
	MOV R1, R6 ; move left bound to the midpoint
	BL alloc_mem ; recurse back to the function
	POP {r0-r8} ; restore registers
	B done ; return

return
	STR R8, [R6] ; store the allocated block size
	B done ; return

no_alloc
	LDR R9, [R1] ; load leftmost block
	AND R9, R9, #0x01 ; check allocated flag
	CMP R9, #0 ; if allocated
	BNE invalid_return ; go to invalid return
	LDR R9, [R1] ; load leftmost block again
	CMP R9, R7 ; compare with block size
	BLT invalid_return; if not enough space then return not valid
	ORR R9, R7, #0x01 ; set flag
	STR R9, [R1] ; store updated info
	LDR R9, =MCB_TOP ; load MCB_TOP
	LDR R10, =HEAP_TOP ; load HEAP_TOP
	SUB R1, R1, R9 ; compute the offset
	LSL R1, R1, #4 ; convert to addressable units
	ADD R10, R10, R1 ; compute heap address
	MOV R12, R10 ; store heap address
	B done ; return
	
invalid_return
	MOV R12, #0 ; return 0
	B done ; return

invalid_size
	MOV R0, #0 ; return 0
	B done;
	
done
		MOV		pc, lr
		END
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
	;; Implement by yourself
	
	PUSH {lr} ; Save the return address
	
	MOV R1, R0 ; copy ptr address from R0 to R1
	LDR R2, =HEAP_TOP ; Load HEAP_TOP into R2
	LDR R3, =HEAP_BOT ; Load HEAP_BOT into R3
	
	; Checking if the adderss is valid
	CMP R1, R2 ; If address is smaller than HEAP_TOP
	BLT invalid_address
	CMP R1, R3 ; If address is larger than HEAP_BOT
	BLT invalid_address
	
	; Get the MCB address
	LDR R4, =MCB_TOP ; Load the top of the Memory Control Block (MCB) into R4
    SUB R5, R1, R2 ; Compute offset: (pointer - HEAP_TOP)
    ASR R5, R5, #4 ; Divide offset by 16 (shift right by 4 bits)
    ADD R5, R4, R5 ; Add offset to MCB_TOP to get the corresponding MCB address
	
	; Call the _rfree function to free memory
	MOV R0, R5 ; Move computed MCB address into R0 (argument for _rfree)
    PUSH {R1-R12} ; Save registers R1 to R12 on the stack
    BL _rfree ; Call _rfree function
    POP {R1-R12} ; Restore registers R1 to R12 from the stack
	CMP R0, #0 ; Check if _rfree() returned 0 (failure)
    BEQ invalid_address ; If return value is 0, jump to _invalid_address
    POP {LR} ; Restore the link register
    MOV pc, lr ; Return from function by moving LR back into PC
	
invalid_address
	MOV R0, #0 ; Set the return value to NULL (0)
    POP {LR} ; Restore the link register
    MOV pc, lr ; Return from function

rfree
	PUSH {lr} ; Save the link register on the stack

	LDR R1,[R0] ; Load MCB contents (size & status) into R1
	LDR R2,=MCB_TOP ; Load MCB_TOP into R2
	SUB R3,R0,R2 ; Compute MCB offset: (mcb_addr - mcb_top)
	ASR R1,R1,#4 ; Extract the chunk size from MCB contents
	MOV R4,R1 ; Store chunk size in R4 (MCB_chunk)
	LSL R1,R1,#4 ; Compute block size in bytes (MCB_chunk * 16)
	MOV R5,R1 ; Store block size in R5 (my_size)
	STR R1,[R0] ; Store the computed size back in MCB
	SDIV R6,R3,R4 ; Compute (MCB_offset / MCB_chunk)
	AND R6,R6,#1 ; Extract the least significant bit (even or odd)
	CMP R6,#0 ; Check if index is even
	BNE odd ; If odd, handle separately

	; Even Case: Check the buddy block
	ADD R6,R0,R4 ; Compute buddy block address (MCB_addr + MCB_chunk)
	LDR R7,=MCB_BOT ; Load MCB_BOT into R7
	CMP R6,R7 ; Check if buddy block exceeds MCB_BOT
	BGE zero ; If out of range, return zero
	LDR R7,[R6] ; Load buddy block contents into R7
	AND R8,R7,#1 ; Check if buddy block is free
	CMP R8,#0 ; If not free, exit
	BNE _free_done ; If allocated, no merging
	ASR R7,R7,#5 ; Extract size from buddy block
	LSL R7,R7,#5 ; Align size to 32-byte boundary
	CMP R7,R5 ; Compare buddy size with current size
	BNE _free_done ; If different, cannot merge
	STR R8,[R6] ; Clear buddy block metadata
	LSL R5,#1 ; Double the size (my_size *= 2)
	STR R5,[R0] ; Store new merged size
	BL _rfree ; Recursively free the merged block
	B _free_done ; Done

odd
	SUB R6,R0,R4 ; Compute buddy block address (MCB_addr - MCB_chunk)
	CMP R2,R6 ; Check if buddy is before MCB_TOP
	BGT zero ; If out of range, return zero
	LDR R7,[R6] ; Load buddy block contents
	AND R8,R7,#1 ; Check if buddy block is free
	CMP R8,#0 ; If not free, exit
	BNE done ; If allocated, no merging
	ASR R7,R7,#5 ; Extract buddy size
	LSL R7,R7,#5 ; Align size to 32-byte boundary
	CMP R7,R5 ; Compare buddy size with current size
	BNE done ; If different, cannot merge
	STR R8,[R0] ; Clear current block metadata
	LSL R5,#1 ; Double the size (my_size *= 2)
	STR R5,[R6] ; Store new merged size in buddy block
	MOV R0,R6 ; Set R0 to new merged block
	BL rfree ; Recursively free the merged block
	B done ; Done

zero
	MOV R0, #0 ; set the ans to 0
	
done
	MOV		pc, lr					; return from rfree( )
	END
