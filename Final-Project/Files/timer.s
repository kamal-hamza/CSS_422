		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14				; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( ) 
USR_HANDLER     EQU		0x20007B84	; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
	;; Implement by yourself 
		; (1) Stop SysTick:
		;     - Set SYST_CSR’s Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
		LDR		R0, =STCTRL_STOP		; Load stop configuration for SysTick
		LDR		R1, =STCTRL				; Load address of SysTick control register
		STR		R0, [R1]				; Stop SysTick timer

		; (2) Load the maximum countdown value (1 second) into SysTick Reload Register
		LDR		R0, =STRELOAD_MX		; Load maximum reload value (0x00FFFFFF)
		LDR		R1, =STRELOAD			; Load address of SysTick Reload Register
		STR		R0, [R1]				; Store the reload value

		; (3) Clear the SysTick Current Value Register to reset timer state
		LDR		r0, =STCURRENT			; Load address of SysTick Current Register
		LDR		r1, =0x00000000			; Zero out any remaining count
		STR		r1, [r0]				; Reset current value register
	
		MOV		pc, lr					; Return to caller (Reset_Handler) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
	;; Implement by yourself		
		; (1) Retrieve previous timer value stored at 0x20007B80
		LDR 	R1, =SECOND_LEFT		; Load address where remaining time is stored
		LDR		R2, [R1]				; Load previous seconds value into R2
		STR 	R0, [R1]				; Store new seconds value from alarm( ) in R1

		; (2) Enable SysTick timer:
		;     - Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
		LDR		R3, =STCTRL			; Load address of SysTick Control Register
		LDR		R4, =STCTRL_GO		; Load value to enable SysTick with interrupts
		STR		R4, [R3]			; Enable SysTick

		; (3) Clear SysTick Current Value Register to reset countdown
		LDR		R5, =STCURRENT
		MOV 	R6, #0x00000000			
		STR		R6, [R5]			; Clear current value register

		MOV 	R0, R2				; Return previous seconds value to caller
		MOV		pc, lr				; Return to SVC_Handler 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
	;; Implement by yourself
	; (1) Decrement remaining time stored at 0x20007B80
		LDR		R1, =SECOND_LEFT	; Load address where seconds left is stored
		LDR		R2, [R1] 			; Load remaining seconds into R2
		SUB 	R2, R2, #1			; Decrease remaining time by 1
		STR 	R2, [R1]			; Store updated time back

		; (2) If seconds != 0, exit function
		CMP 	R2, #0
		BNE		_timer_update_done	; If timer is not zero, return

		; (3) Stop the SysTick timer
		LDR		R3, =STCTRL
		LDR		R4, =STCTRL_STOP
		STR		R4, [R3]

		; (4) Invoke the user-defined signal handler stored at 0x20007B84
		LDR 	R5, =USR_HANDLER	; Load address where handler function pointer is stored
		LDR		R6, [R5]			; Load function pointer into R6

		STMFD	sp!, {r1-r12,lr}	; Save registers before function call
		BLX 	R6					; Call the signal handler function
		LDMFD	sp!, {r1-r12,lr}	; Restore registers after function call

_timer_update_done 
		MOV		pc, lr				; return to SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
	;; Implement by yourself
		; (1) Check if signal number is SIGALRM (14)
		CMP		R0, #SIGALRM
		BNE		return_Res			; If not SIGALRM, return

		; (2) Store the new handler function pointer at 0x20007B84
		LDR		R2, =USR_HANDLER	; Load address where handler function pointer is stored
		LDR		R3, [R2]			; Load previous handler into R3
		STR		R1, [R2]			; Store new handler function pointer at USR_HANDLER
		MOV 	R0, R3 				; Return previous handler in R0

return_Res 
		MOV		pc, lr				; return to Reset_Handler
		
		END		
