		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero 
_bzero
		; Save registers to the stack (non-volatile registers and LR)
        ; This ensures that the function doesn't clobber registers used by the caller 
		STMFD	sp!, {r1-r12,lr}	; Save r1-r12 and LR (link register) to the stack
		; Save the original destination pointer (s) in r3
        ; This is necessary because r0 will be modified during the loop 
		MOV		r3, r0				; r3 = s (save the original pointer)
		MOV		r2, #0				; r2 = 0 (value to store in memory) 
_bzero_loop							; Start of the loop: 
		SUBS	r1, r1, #1			; n-- (decrement the byte counter) 
		BMI		_bzero_return		; If n < 0, exit the loop (all bytes initialized) 	
		STRB	r2, [r0], #0x1		; [s++] = 0 (store 0 at [r0], then increment r0 by 1) 
		; Repeat the loop until all bytes are initialized
		B		_bzero_loop			; Continue looping 
_bzero_return
		; Restore the original destination pointer (s) to r0
        ; This ensures the function returns the correct value (though _bzero doesn't return anything).
		MOV		r0, r3				; r0 = s (restore the original pointer)
		; Restore registers from the stack
        ; This ensures the caller's registers are preserved 
		LDMFD	sp!, {r1-r12,lr}	; Restore r1-r12 and LR from the stack 
		MOV		pc, lr 				; Return to the address in LR (link register) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the buffer to copy to
;	src		- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; r0 = destination buffer (dest)
        ; r1 = source string (src)
        ; r2 = number of bytes to copy (size)
        ; r3 = original pointer to 'dest' (used for return)
        ; r4 = temporary storage for the character being copied 
		STMFD	sp!, {r1-r12,lr}	; Save registers on stack 
		MOV		r3, r0				; Store original 'dest' pointer in r3 
_strncpy_loop						; while( ) {
		SUBS	r2, r2, #1			; Decrement size counter 
		BMI		_strncpy_return		; If size < 0, exit function	
		LDRB	r4, [r1], #0x1		; Load next byte from 'src' and increment 'src' pointer 
		STRB	r4, [r0], #0x1		; Store byte into 'dest' and increment 'dest' pointer 
		CMP		r4, #0				; Check if byte is null terminator ('\0')
		BEQ		_strncpy_return		; If null terminator found, exit function 
		B		_strncpy_loop		; Repeat loop 
_strncpy_return
		MOV		r0, r3				; Return original 'dest' pointer 
		LDMFD	sp!, {r1-r12,lr}	; Restore registers from stack 
		MOV		pc, lr 				; Return to caller 
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		STMFD	sp!, {r1-r12,lr}	; Save registers on stack 
		MOV 	R7, #3				; System call number for memory allocation 
		; Argument: size is already in r0
		SVC     #0x0				; Trigger system call
		LDMFD	sp!, {r1-r12,lr}	; Restore registers from stack 
		MOV		pc, lr 				; Return to caller 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT	_free
_free
		STMFD	sp!, {r1-r12,lr}	; Save registers on stack
		MOV 	R7, #4				; System call number for freeing memory
		; Argument: address is already in r0 
		SVC     #0x0				; Trigger system call 
		LDMFD	sp!, {r1-r12,lr}	; Restore registers from stack 
		MOV		pc, lr 				; Return to caller 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		STMFD	sp!, {r1-r12,lr}	; Save registers on stack
		MOV 	R7, #1 				; System call number for setting an alarm 
		; Argument: seconds is already in r0 
		SVC     #0x0				; Trigger system call
		LDMFD	sp!, {r1-r12,lr}	; Restore registers from stack 
		MOV		pc, lr				; Return to caller 
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		STMFD	sp!, {r2-r12,lr}	; Save registers on stack
		MOV 	R7, #2				; System call number for setting a signal handler 
		; Arguments: 
		; r0 = signal number (should be 14 for SIGALRM)
        ; r1 = function pointer to handler
		SVC     #0x0				; Trigger system call 
		LDMFD	sp!, {r2-r12,lr}	; Restore registers from stack
		MOV		pc, lr				; Return to caller 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
