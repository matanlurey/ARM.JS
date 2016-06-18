.arm
.section .data
hello:
    .asciz "Hello World from ARMv4T!"
.section .text
.equ   PCON,          0xE01FC000 @ Power Control Register
.equ   LCDIOCTL,      0xE000C000 @ LCD I/O Control
.equ   LCDDATA,       0xE000C004 @ LCD Data Transfer
.equ   LEDSTAT,       0xE0008000 @ LED Status Register
.equ   RAM_SIZE,      0x00008000 @ 32kb
.equ   RAM_BASE,      0x00400000
.equ   TOPSTACK,      RAM_BASE + RAM_SIZE

@ LCD initialization commands
.equ   LCD_CMD_DISP_CLEAR,    0x01
.equ   LCD_CMD_FUNCTION_SET,  0x3C
.equ   LCD_CMD_DISP_CONTROL,  0x0F
.equ   LCD_CMD_ENTRY_MODE,    0x06

@ R13 acts as stack pointer by convention
ldr  r0,  =TOPSTACK
mov  r13, r0

@ initialize LCD
bl lcd_init

loop:
  @ output string to LCD
  ldr r1, =hello
  write_char:
    ldrb r0, [r1], #1
    cmp r0, #0
    beq done
    bl lcd_write_char
    bl delay
    b write_char
done:
  @ flash LCD and LEDs
  bl flash_display
  bl flash_leds
  @ then start over again
  bl lcd_clear
  b loop

@ exit simulator
bl _exit

@ sets up the LCD display
lcd_init:
  stmfd sp!, {r0-r2,lr}
  ldr r0, =LCD_CMD_DISP_CLEAR
  bl lcd_command
  @ 2-line 5x10 dots format display mode.
  ldr r0, =LCD_CMD_FUNCTION_SET
  bl lcd_command
  @ turn display on, cursor on, blink-mode on.
  ldr r0, =LCD_CMD_DISP_CONTROL
  bl lcd_command
  @ enable cursor increment mode
  ldr r0, =LCD_CMD_ENTRY_MODE
  bl lcd_command
  ldmfd sp!, {r0-r2,lr}
  bx lr

lcd_command:
  stmfd sp!, {r1-r2,lr}
  ldr r1, =LCDIOCTL
  strb r0, [r1], #0
  mov r2, #0x80
  @ pulse enable
  strb r2, [r1], #0
  @ delay for a couple of cycles
  ldmfd sp!, {r1-r2,lr}
  bx lr

@ clears display and resets cursor
lcd_clear:
  stmfd sp!, {r0,lr}
  ldr r0, =LCD_CMD_DISP_CLEAR
  bl lcd_command
  ldmfd sp!, {r0,lr}
  bx lr

@ writes a single character to the current
@ position of the LCD cursor
lcd_write_char:
  stmfd sp!, {r1,lr}
  ldr r1, =LCDDATA
  strb r0, [r1], #0
  ldmfd sp!, {r1,lr}
  bx lr

@ writes a null-terminated string to the LCD
lcd_write_string:
  stmfd sp!, {r0-r1,lr}
  mov r1, r0
char_loop:
  ldrb r0, [r1], #1
  cmp r0, #0
  beq char_loop_end
  bl lcd_write_char
  b char_loop
char_loop_end:
  ldmfd sp!, {r0-r1,lr}
  bx lr

@ delays execution
delay:
  stmfd sp!, {r0,lr}
  ldr r0, =#200
delay_loop:
  subs r0, r0, #1
  beq delay_end
  b delay_loop
delay_end:
  ldmfd sp!, {r0,lr}
  bx lr

@ turns the display on and off a couple of times
flash_display:
  stmfd sp!, {r0-r1,lr}
  mov r1, #10
  ldr r0, =LCD_CMD_DISP_CONTROL
flash_display_loop:
    bl lcd_command
    eor r0, r0, #4
    bl delay
    subs r1, r1, #1
    bne flash_display_loop
  ldr r0, =LCD_CMD_DISP_CONTROL
  bl lcd_command
  ldmfd sp!, {r0-r1,lr}
  bx lr

@ flashes the LEDs and runs a little LED animation
flash_leds:
  stmfd sp!, {r0-r3,lr}
  mov r1, #1
  ldr r0, =LEDSTAT
flash_leds_loop:
    strb r1, [r0], #0
    movs r1, r1, LSL #1
    add r1, r1, #1
    bl delay
    cmp r1, #0xff
    ble flash_leds_loop
  mov r2, #0xff
  mov r1, #0
  mov r3, #8
toggle_all_loop:
   strb r1, [r0], #0
   eor r1, r1, r2
   bl delay
   subs r3, r3, #1
   bne toggle_all_loop
  mov r1, #0
  strb r1, [r0], #0
  ldmfd sp!, {r0-r3,lr}
  bx lr

@ halts execution
_exit:
  @ power is turned off by setting bit 1
  ldr r0, =PCON
  mov r1, #1
  strb r1, [r0]
.end