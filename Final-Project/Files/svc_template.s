		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MEMCPY		EQU		0x3		; address 20007B0C
SYS_MALLOC		EQU		0x4		; address 20007B10
SYS_FREE		EQU		0x5		; address 20007B14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init 
_syscall_table_init
	;; Implement by yourself
		LDR		R0, =SYSTEMCALLTBL		; Load base address of the system call table
		
		LDR		R1, =0x0				; Entry for SYS_EXIT (Unused)
		STR		R1, [R0, #SYS_EXIT*4]
		
		LDR		R1, =0x1				; Entry for SYS_ALARM
		STR		R1, [R0, #SYS_ALARM*4]
		
		LDR		R1, =0x2				; Entry for SYS_SIGNAL
		STR		R1, [R0, #SYS_SIGNAL*4]
		
		LDR		R1, =0x3				; Entry for SYS_MEMCPY (Unused) 
		STR		R1, [R0, #SYS_MEMCPY*4]
		
		LDR		R1, =0x4				; Entry for SYS_MALLOC
		STR		R1, [R0, #SYS_MALLOC*4]
		
		LDR		R1, =0x5				; Entry for SYS_FREE
		STR		R1, [R0, #SYS_FREE*4]
	
		MOV		pc, lr					; Return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
		IMPORT _kfree
		IMPORT _kalloc
		IMPORT _signal_handler
		IMPORT _timer_start
_syscall_table_jump
	;; Implement by yourself
		CMP 	R7, #1					; Check if system call is ALARM
		BEQ 	_timer_start 			; Jump to _timer_start if matched
		CMP 	R7, #2					; Check if system call is SIGNAL
		BEQ 	_signal_handler			; Jump to _signal_handler if matched
		CMP 	R7, #3					; Check if system call is MALLOC
		BEQ 	_kalloc					; Jump to _kalloc if matched
		CMP 	R7, #4					; Check if system call is FREE
		BEQ 	_kfree					; Jump to _kfree if matched
		
		MOV		pc, lr					; Return to caller if no match
		
		END


		
