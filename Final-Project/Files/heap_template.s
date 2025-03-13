		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Heap Memory Configuration
; Defines memory addresses and parameters for the buddy memory allocation system.

HEAP_TOP	EQU		0x20001000		; Start address of the heap space
HEAP_BOT	EQU		0x20004FE0		; End address of the heap space
MAX_SIZE	EQU		0x00004000		; Maximum allocatable size (16KB = 2^14)
MIN_SIZE	EQU		0x00000020		; Minimum allocatable size (32B  = 2^5)

; Memory Control Block (MCB) Definitions
MCB_TOP		EQU		0x20006800      ; Start address of the MCB (1KB space for tracking allocations)
MCB_BOT		EQU		0x20006BFE      ; End address of the MCB
MCB_ENT_SZ	EQU		0x00000002		; Each MCB entry is 2 bytes
MCB_TOTAL	EQU		512			    ; Total number of MCB entries (2^9 = 512)

INVALID		EQU		-1			    ; Invalid memory block ID

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Heap Initialization
; void _heap_init()
; Initializes the Memory Control Block (MCB) by setting the first entry to MAX_SIZE
; and zeroing out all remaining MCB entries.

		EXPORT	_heap_init
_heap_init
		; Initialize the first MCB entry with MAX_SIZE
		LDR		R0, =MCB_TOP
		LDR 	R1, =MAX_SIZE
		STR		R1, [R0]
		
		; Zero out the remaining MCB entries
		LDR 	R0, =MCB_TOP+0x4		; Start from the second entry
		LDR		R1, =0x20006C00			; End of MCB space
		MOV		R2, #0x0				; Value to store (zero)

_heap_mcb_init
		CMP 	R0, R1					; Check if end of MCB is reached
		BGE		_heap_init_done			; If so, exit loop

		STR		R2, [R0]				; Zero out current MCB entry
		ADD		R0, R0, #1				; Move to the next byte
		STR		R2, [R0]				; Zero out next byte
		ADD		R0, R0, #2				; Move to the next MCB entry
		B 		_heap_mcb_init			; Repeat until all entries are cleared
	
_heap_init_done
		MOV		pc, lr					; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _kalloc(int size)
; Allocates memory of at least 'size' bytes using the buddy system.
; Returns a pointer to the allocated memory or NULL if allocation fails.

		EXPORT	_kalloc
_kalloc
		PUSH	{lr}					; Save return address

		; Ensure minimum allocation size is at least 32 bytes
		CMP		R0, #32
		BGE		_ralloc_init
		MOV		R0, #32

_ralloc_init
		; Prepare parameters for _ralloc recursive allocation
		LDR		R1, =MCB_TOP			; Left boundary (start of MCB)
		LDR		R2, =MCB_BOT			; Right boundary (end of MCB)
		LDR		R3, =MCB_ENT_SZ			; MCB entry size (2 bytes per entry)
		BL		_ralloc					; Call recursive allocation function

		POP		{lr}					; Restore return address
		MOV		R0, R12					; Return allocated memory address
		MOV		pc, lr					; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Recursive Memory Allocation
; This function attempts to allocate memory by dividing available blocks recursively.
_ralloc		
		PUSH	{lr}					; Save return address
		
		SUB		R4, R2, R1				; Calculate total size of the current memory block
		ADD		R4, R4, R3				; Adjust for MCB entry size
		ASR		R5, R4, #1				; Compute half of the block size
		ADD		R6, R1, R5				; Compute midpoint of the block
		LSL		R7, R4, #4				; Compute actual entire size (aligned)
		LSL		R8, R5, #4				; Compute actual half size (aligned)
		MOV		R12, #0x0				; Initialize allocated heap address to NULL
		
		; If requested size is larger than half size, allocation is not possible
		CMP		R0, R8
		BGT		_no_alloc
		
		; Try allocating in the left half
		PUSH	{r0-r8}
		SUB		R2, R6, R3
		BL		_ralloc
		POP		{r0-r8}

		; If left allocation was successful, return the address
		CMP		R12, #0x0
		BEQ		_ralloc_right

		; Ensure the right half is available
		LDR		R9, [R6]
		AND 	R9, R9, #0x01
		CMP		R9, #0
		BEQ		_return_heap_addr
		B		_ralloc_done
		
_ralloc_right
		; Try allocating in the right half
		PUSH	{r0-r8}
		MOV		R1, R6
		BL		_ralloc
		POP		{r0-r8}
		B 		_ralloc_done
		
_return_heap_addr
		; Mark this MCB entry as allocated
		STR		R8, [R6]
		B		_ralloc_done
		
_no_alloc
		; Check if the current block is free and big enough
		LDR 	R9, [R1]
		AND 	R9, R9, #0x01
		CMP		R9, #0
		BNE		_return_invalid

		LDR		R9, [R1]
		CMP		R9, R7
		BLT		_return_invalid

		; Mark the block as allocated
		ORR		R9, R7, #0x01
		STR		R9, [R1]

		; Calculate heap address corresponding to this MCB entry
		LDR		R9, =MCB_TOP
		LDR		R10, =HEAP_TOP
		SUB		R1, R1, R9
		LSL		R1, R1, #4
		ADD		R10, R10, R1
		MOV		R12, R10				; Store allocated heap address

		B		_ralloc_done

_return_invalid
		MOV		R12, #0					; Allocation failed, return NULL

_ralloc_done
		POP		{lr}					; Restore return address
		BX		LR						; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void _kfree(void *ptr)
; Frees the memory allocated at 'ptr' and merges buddy blocks if possible.
		 
		EXPORT	_kfree
_kfree
		PUSH	{lr}					; Save return address

		; Validate the address
		MOV		R1, R0					; Store pointer in R1
		LDR		R2, =HEAP_TOP			; Load heap start
		LDR		R3, =HEAP_BOT			; Load heap end

		CMP  	R1, R2					; If pointer is below heap range, invalid
		BLT  	_invalid_address
		CMP  	R1, R3					; If pointer is above heap range, invalid
		BGT  	_invalid_address

		; Compute corresponding MCB address
		LDR  	R4, =MCB_TOP			; Load MCB start
		SUB  	R5, R1, R2				; Compute offset from heap start
		ASR  	R5, R5, #4				; Divide by 16 to get MCB index
		ADD  	R5, R4, R5				; Compute MCB address

		; Call _rfree to deallocate memory
		MOV		R0, R5
		BL   	_rfree
		
		POP		{LR}					; Restore return address
		MOV		pc, lr					; Return to caller

_invalid_address
		MOV  	R0, #0					; Return NULL if address is invalid
		POP		{LR}
		MOV		pc, lr
		
_rfree
		PUSH	{lr}					; Save return address on stack
		; Load the MCB entry for the memory being freed
		LDR		R1, [R0]				; R1 = Contents of the MCB entry at address R0
  		LDR 	R2, =MCB_TOP			; R2 = Base address of the Memory Control Block (MCB)
  		SUB		R3, R0, R2		 		; R3 = Offset of the current MCB entry from the base (MCB address - MCB_TOP)
		; Determine the size of the memory chunk associated with this MCB entry     
		ASR		R1, R1, #4		 		; Extract the size of the block from the MCB entry (shift right) 	
		MOV		R4, R1					; R4 = Chunk size 
		LSL		R1, R1, #4		 		; Convert chunk size back to a full-sized value 	
		MOV		R5, R1					; R5 = Actual size of allocated block 
		
		STR		R1, [R0]				; Mark this MCB entry as free by writing back the size without the allocated flag 
		; Check if this block is the first or second in its buddy pair
  		SDIV 	R6, R3, R4				; Divide MCB offset by chunk size 
    	AND 	R6, R6, #1				; R6 = (MCB offset / chunk size) % 2 (determines if even or odd) 	
      	CMP 	R6, #0			 		; If block is even, try to merge with the next one 
		BNE		_odd_case				; Otherwise, check the previous block instead 
		
		; Even case: Check the next buddy block  
		ADD 	R6, R0, R4				; R6 = Address of the next block (buddy)
  		LDR		R7, =MCB_BOT			; Load the address of the last MCB entry
  		CMP		R6, R7					; If buddy block is beyond MCB_BOT, merging is not possible 
		BGE		return_zero				
		
    	LDR		R7, [R6]				; Load the MCB entry of the buddy block 	
		
    	AND		R8, R7, #1				; Check if the buddy is allocated (bitwise AND with 1) 
      	CMP		R8, #0					; If allocated, no merging is possible 
		BNE		_free_done
		; Extract and normalize the buddy block size
  		ASR 	R7, R7, #5				; Extract buddy size (shift right) 
    	LSL		R7, R7, #5				; Normalize buddy size 
		CMP		R7, R5					; Compare buddy size with current block size 
  		BNE		_free_done				; If different, no merging is possible 
		; Merge with the buddy block 
      	STR		R8, [R6]				; Mark the buddy block as free (clear allocation bit)
		LSL		R5, #1					; Double the size of the merged block
  		STR		R5, [R0]				; Update the MCB entry with the new merged size 

		
		BL		_rfree					; Recursively attempt to merge further up the hierarchy 
		B		_free_done
	
_odd_case								
		; ODD CASE: Check the previous buddy block, line 183
     	SUB		R6, R0, R4				; R6 = Address of the previous block (buddy)
       	CMP		R2, R6					; If the buddy is before MCB_TOP, merging is not possible
	 	BGT		return_zero	
		
     	LDR		R7, [R6]				; Load the MCB entry of the previous buddy 
       	
		AND		R8, R7, #1				; Check if the buddy is allocated, line 195
  		CMP		R8, #0
    	BNE		_free_done
  		; Extract and normalize the buddy block size
  		ASR 	R7, R7, #5
    	LSL		R7, R7, #5				; Normalize buddy size
      	CMP		R7, R5					; Compare buddy size with current block size 
		BNE	 	_free_done				; If different, no merging is possible, line 200 
		; Merge with the buddy block 
		STR		R8, [R0]				; Mark current block as free
    	LSL		R5, #1					; Double the size of the merged block
		STR		R5, [R6]				; Store the updated block size in the previous MCB entry, line 207
		; Move back to the previous block and continue merging recursively
		MOV		R0, R6					
		BL		_rfree					; Recursion, line 216
		B		_free_done
		
return_zero
  		MOV 	R0, #0					; Return 0 if merging is not possible

_free_done
  		POP	{lr}						; Restore return address
		BX		lr						; Return from function 

		END 