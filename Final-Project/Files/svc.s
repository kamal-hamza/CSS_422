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
	
	LDR R0,=SYSTEMCALLTBL ; Load the base address of the system call table (originally 0x20007500)
	LDR R1,=0x0 ; Load the system call handler index 0 (SYS_EXIT), address 20007B00
	STR R1,[R0,#SYS_EXIT*4] ; Store the handler index at the corresponding system call table entry
	LDR R1,=0x1 ; Load the system call handler index 1 (SYS_ALARM), address 20007B04
	STR R1,[R0,#SYS_ALARM*4] ; Store the handler index at the corresponding system call table entry
	LDR R1,=0x2 ; Load the system call handler index 2 (SYS_SIGNAL), address 20007B08
	STR R1,[R0,#SYS_SIGNAL*4] ; Store the handler index at the corresponding system call table entry
	LDR R1,=0x3 ; Load the system call handler index 3 (SYS_MEMCPY), address 20007B0C
	STR R1,[R0,#SYS_MEMCPY*4] ; Store the handler index at the corresponding system call table entry
	LDR R1,=0x4 ; Load the system call handler index 4 (SYS_MALLOC), address 20007B10
	STR R1,[R0,#SYS_MALLOC*4] ; Store the handler index at the corresponding system call table entry
	LDR R1,=0x5 ; Load the system call handler index 5 (SYS_FREE), address 20007B14
	STR R1,[R0,#SYS_FREE*4] ; Store the handler index at the corresponding system call table entry	
	MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
	EXPORT	_syscall_table_jump
	IMPORT _kfree
	IMPORT _kalloc
	IMPORT _signal_handler
	IMPORT _timer_start
		
_syscall_table_jump
	;; Implement by yourself
		
	CMP R7,#1 ; Compare R7 with 1 (check if it corresponds to _timer_start)
	BEQ _timer_start ; If R7 == 1, branch to _timer_start
	CMP R7,#2 ; Compare R7 with 2 (check if it corresponds to _signal_handler)
	BEQ _signal_handler ; If R7 == 2, branch to _signal_handler
	CMP R7,#3 ; Compare R7 with 3 (check if it corresponds to _kalloc)
	BEQ _kalloc ; If R7 == 3, branch to _kalloc
	CMP R7,#4 ; Compare R7 with 4 (check if it corresponds to _kfree)
	BEQ _kfree ; If R7 == 4, branch to _kfree
	MOV		pc, lr			
		
	END


		
