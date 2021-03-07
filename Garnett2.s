@ Filename: Garnett.s
@ Author:   Trevor Garnett
@ Class: <CS 214-01><Spring, 2021>
@ Objective:  The purpose of this lab is to provide students experience with the ARM Thumb mode
@ 	with assembly programming.
@ History:
@	Created 02/18, adding comments when necessary
@	Copied on 3/06, editing the file to conform to the specifications of Lab3.
@
@ Use these commands to assemble, link, run and debug this program:
@    as -o Garnett2.o Garnett2.s
@    gcc -o Garnett2 Garnett2.o
@    ./Garnett2 ;echo $?
@    gdb --args ./Garnett2 

@ ****************************************************
@ The = (equal sign) is used in the ARM Assembler to get the address of a
@ label declared in the .data section. This takes the place of the ADR
@ instruction used in the textbook. 
@ ****************************************************

.equ READERROR, 0 @Used to check for scanf read error. 

.global main @ Have to use main because of C library uses. 

main:
   ldr r0, =startthumb + 1
   bx r0
   .code 16 @Make all this code thumb mode. Will not exit back out.
startthumb:
@*******************
prompt:
@*******************

@ Ask the user to enter a number.
   ldr r0, =welcome		@ Put the address of my string into the first parameter
   bl  printf			@ Call the C printf to display input prompt.

@*******************
get_input:
@*******************

@ Set up r0 with the address of input pattern
@ scanf puts the input value at the address stored in r1. We are going
@ to use the address for our declared variable in the data section - intInput. 
@ After the call to scanf the input is at the address pointed to by r1 which in this
@ case will be intInput. 

   ldr r0, =hexInputPattern	@ Setup to read in one number.
   ldr r1, =hexInput1       	@ load r1 with the address of where the
                           	@ input value will be stored.
   bl  scanf               	@ scan the keyboard.
   cmp r0, #READERROR      	@ Check for a read error.
   beq readerror           	@ If there was a read error go handle it.
   
   ldr r0, =operand2
   bl printf 
   
   ldr r0, =hexInputPattern	@ Setup to read in 32-bit hexadecimal word.
   ldr r1, =hexInput2       	@ load r1 with the address of where the
                           	@ input value will be stored.
   bl scanf
   cmp r0, #READERROR      	@ Check for a read error.
   beq readerror           	@ If there was a read error go handle it. 

   ldr r0, =operator
   bl printf

   ldr r0, =opInputPattern	@ setup to read the operator
   ldr r1, =operation		@ laod r1 with the address of where the input will be stored
   bl scanf			@ scan the keyboard
   cmp r0, #READERROR		@ Check for a readerror
   beq readerror		@ If there was a read error, go handle it.

   ldr r6, =hexInput1		@ Load the address of where the first operand will be stored
   ldr r6, [r6]			@ Load the value located at this address into the same register
   ldr r7, =hexInput2 		@ Load the address of where the second operand will be stored
   ldr r7, [r7]			@ Load the value located at this address into the same register
   push {r6, r7}		@ Push these two values onto the stack

@*********************
@ THIS IS THE START OF A BUNCH OF IF-ELSE STATEMENTS
@*********************
   ldr r0, =operation		@ Load the address for the operation into r0
   ldr r0, [r0]			@ Load value located at this address into the same register

CASE_1:
   ldr r1, =and			@ Load the address of the string "AND" into r1
   ldr r1, [r1]			@ Load "AND" into r1
   cmp r1, r0			@ Compare the user's input operation to AND
   bne CASE_2			@ If the operation is not AND, check to see if it is ORR
   bl switch_and		@ If equal, let switch_and handle
   b printResults		@ After it is handled, come back and then branch to printResults

CASE_2:
   ldr r1, =orr			@ Load the address of the string "ORR" into r1
   ldr r1, [r1]			@ Load "ORR" into r1
   cmp r1, r0			@ Compare the user's input operation to ORR
   bne CASE_3			@ If the operation is not ORR, check to see if it is XOR
   bl switch_orr		@ If equal, let switch_orr handle
   b printResults		@ After it is handled, come back and then branch to printResults

CASE_3:
   ldr r1, =xor			@ Load the address of the string "XOR" into r1
   ldr r1, [r1]			@ Load "XOR" into r1
   cmp r1, r0			@ Compare the user's input operation to XOR
   bne CASE_4			@ If the operation is not XOR, check to see if it is BIC
   bl switch_xor		@ If equal, let switch_xor handle
   b printResults		@ After it is handled, come back and then branch to printResults

CASE_4:
   ldr r1, =bic			@ Load the address of the string "BIC" into r1
   ldr r1, [r1]			@ Load "BIC" into r1
   cmp r1, r0			@ Compare the user's input operation to BIC
   bne DEFAULT			@ If the operation is not BIC, the user enter something other than the supported function.
				@ let DEFAULT handle
   bl switch_bic		@ If equal, let switch_bic handle
   b printResults		@ After it is handled, come back and then branch to printResults

DEFAULT:
   ldr r0, =notFound		@ If none of the above comparisons were true, load string notFound into R0
   bl printf			@ then print. If this happens, the user entered the operator wrong.
   b onceMore


@*********************
printResults:			@ This is where the above cases go to after they are selected.
@*********************
   pop {r1}			@ Pop the result the switch_*** subroutines called above
   ldr r0, =results		@ Load the string format for which results will be printed
   bl printf			@ Print results, in '\t = 0x00000000' form. Leading 0's may not be printed.

@*********************
onceMore:			@ This section is asks the user if they are done with the program
@*********************
   ldr r0, =question		@ Load question into r0
   bl printf			@ Print question
   ldr r0, =opInputPattern	@ Prepare input for a character
   ldr r1, =answer		@ Set input address in r1
   bl scanf			@ Scan the keyboard
   cmp r0, #READERROR		@ Check for a readerror
   beq readerror		@ If there was a read error, go handle it.
   ldr r1, =answer		@ Reload the address, as it was cleared in the process
   ldr r1, [r1]			@ Load the value located at the address
   cmp r1, #'y'			@ Compare this to the character 'y'.
   beq prompt			@ If response is 'y', go to beginning; the user isn't done
   cmp r1, #'Y'			@ If not 'y', check if it is 'Y'
   beq prompt			@ If response is 'Y', go to beginning; the user isn't done.
   b myexit			@ The user did not enter 'y' or 'Y'. End program

switch_and:	@ This is responsible for the AND function
   pop {r1, r3}			@ Pop r1 and r3, which were original r6 and r7 on line 78
   mov r2, r3			@ Store a copy of r3 in r2
   ldr r0, =print_AND		@ Loading in the print format into r0 "[r1] AND [r2]"
   and r3, r1, r3		@ [r3] <- [r1] AND [r3] 
   push {r3}			@ Store r3, the result, on the stack
   push {lr}			@ Then, store the link register on the stack.
   bl printf			@ Call printf
   pop {pc}			@ Pop the link register to the program counter (goes up to if/else)

switch_orr:	@ This is responsible for the ORR function
   pop {r1, r3}			@ Pop r1 and r2, which were original r6 and r7 on line 78
   mov r2, r3			@ Store a copy of r3 in r2
   ldr r0, =print_ORR		@ Loading in the print format into r0 "[r1] ORR [r2]"
   orr r3, r1, r3		@ [r3] <- [r1] ORR [r3] 
   push {r3}			@ Store r3, the result, on the stack
   push {lr}			@ Then, store the link register on the stack.=
   bl printf			@ Call printf
   pop {pc}			@ Pop the link register to the program counter (goes up to if/else)

switch_xor:	@ This is responsible for the XOR function
   pop {r1, r3}			@ Pop r1 and r3, which were original r6 and r7 on line 78
   mov r2,r3			@ Store a copy of r3 in r2
   ldr r0, =print_XOR		@ Loading in the print format into r0 "[r1] XOR [r2]"
   eor r3, r1, r3		@ [r3] <- [r1] XOR [r3] 
   push {r3}			@ Store r2, the result, on the stack
   push {lr}			@ Then, store the link register on the stack.
   bl printf			@ Call printf
   pop {pc}			@ Pop the link register to the program counter (goes up to if/else)

switch_bic:	@ This is responsible for the BIC function
   pop {r1, r3}			@ Pop r1 and r3, which were original r6 and r7 on line 78
   mov r2, r3			@ Store a copy of r3 in r2
   ldr r0, =print_BIC		@ Loading in the print format into r0 "[r1] BIC [r2]"
   neg r3, r3			@ Take the 2's complement of the hexcode value in r2
   sub r3, r3, #1		@ Subtract 1, since we want the 1's complement and not the 2's complement
   and r3, r3, r1		@ [r1] <- [r1] BIC [r2]
   push {r3}			@ Store r2, the result, on the stack
   push {lr}			@ Then, store the link register on the stack.
   bl printf			@ Call printf
   pop {pc}			@ Pop the link register to the program counter (goes up to if/else)

@***********
readerror:
@***********
@ Got a read error from the scanf routine. Clear out the input buffer then
@ branch back for the user to enter a value. 
@ Since an invalid entry was made we now have to clear out the input buffer by
@ reading with this format %[^\n] which will read the buffer until the user 
@ presses the CR. 

   ldr r0, =badInput		@ Load the address of the message stating that an input
   bl printf			@ error has occurred and then print this message.
   ldr r0, =strInputPattern
   ldr r1, =strInputError	@ Put address into r1 for read.
   bl scanf			@ scan the keyboard.
@  Not going to do anything with the input. This just cleans up the input buffer.  
@  The input buffer should now be clear so get another input.

   b prompt

@*******************
myexit:
@*******************
@ End of my code. Force the exit and return control to OS

   mov r7, #0x01 		@SVC call to exit
   svc 0         		@Make the system call.

.data

@ Declare the stings and data needed

.balign 4
and: .asciz "AND" @ String to be compared to

.balign 4
orr: .asciz "ORR" @ String to be compared to

.balign 4
xor: .asciz "XOR" @ String to be compared to

.balign 4
bic: .asciz "BIC" @ String to be compared to

.balign 4
question: .asciz "Would you like to do another operation? Enter 'y' or 'Y' for yes; else, the program will end. \n"

.balign 4
badInput: .asciz "This is an invalid input. Please start from the beginning. \n"

.balign 4
notFound: .asciz "The operator did not match those given. Try again. \n"

.balign 4
welcome: .asciz "Greetings. Please enter no more than 8 hex digits for your first operand. \n"

.balign 4
operand2: .asciz "Now, enter the second operand \n"

.balign 4
operator: .asciz "What operation would you like to perform on these operands? Options: 'AND', 'ORR', 'XOR', and 'BIC'\n"

@ Format pattern for scanf call.

.balign 4
intInput: .word 0   @ Location used to store the user input.

.balign 4
hexInput1: .word 0x0 @ Location used to store the user's input for the first operand.

.balign 4
hexInput2: .word 0x0 @ Location used to store the user's input for the second operand.

.balign 4
operation: .skip 24 @ This is the location where the three character operation is stored.

.balign 4
answer: .skip 8 @ This is the location where the user's response to wanting to do another operation is stored.

.balign 4
opInputPattern: .asciz "%s" @ String format for the read

.balign 4
numInputPattern: .asciz "%d"  @ integer format for read.

.balign 4
hexInputPattern: .asciz "%x" @ 32-bit hexadecimal digit

.balign 4
print_AND: .asciz "Operation: %x AND %x \n" @ 32-bit hexadecimal digit

.balign 4
print_ORR: .asciz "Operation: %x ORR %x \n" @ 32-bit hexadecimal digit

.balign 4
print_XOR: .asciz "Operation: %x XOR %x \n" @ 32-bit hexadecimal digit

.balign 4
print_BIC: .asciz "Operation: %x BIC %x \n" @ 32-bit hexadecimal digit

.balign 4
results: .asciz "\t = %x \n"

.balign 4
strInputPattern: .asciz "%[^\n]" @ Used to clear the input buffer for invalid input. 

.balign 4
strInputError: .skip 100*4  @ User to clear the input buffer for invalid input. 

@ Let the assembler know these are the C library functions. 

.global printf
@  To use printf:
@     r0 - Contains the starting address of the string to be printed. The string
@          must conform to the C coding standards.
@     r1 - If the string contains an output parameter i.e., %d, %c, etc. register
@          r1 must contain the value to be printed. 
@ When the call returns registers: r0, r1, r2, r3 and r12 are changed. 

.global scanf
@  To use scanf:
@      r0 - Contains the address of the input format string used to read the user
@           input value. In this example it is numInputPattern.  
@      r1 - Must contain the address where the input value is going to be stored.
@           In this example memory location intInput declared in the .data section
@           is being used.  
@ When the call returns registers: r0, r1, r2, r3 and r12 are changed.
@ Important Notes about scanf:
@   If the user entered an input that does NOT conform to the input pattern, 
@   then register r0 will contain a 0. If it is a valid format
@   then r0 will contain a 1. The input buffer will NOT be cleared of the invalid
@   input so that needs to be cleared out before attempting anything else. 
@

@end of code and end of file. Leave a blank line after this.
