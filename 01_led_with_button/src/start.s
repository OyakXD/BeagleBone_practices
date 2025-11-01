/*
 * =====================================================================================
 *
 *       Filename:  start.s
 *
 *    Description: TURNING ON THE LED WITH THE BUTTON
 *
 *        Version:  1.0.0
 *        Created:  29/10/25
 *       Revision:  none
 *       Compiler:  arm-none-eabi-gcc
 *
 *         Author:  Kayo Anderson, alveskayo2005@gmail.com
 *
 * =====================================================================================
 */
.equ BASE_PRCM, 0x44E00000
.equ BASE_PRCM_GPIO1, 0x44E00000 + 0xAC
.equ MODULEMODE_ENABLE, 0x00000002
.equ BASE_GPIO1, 0x4804C000


.global _start

_start:
    
    @ DISABLE FIQ AND IRQ
    MRS R0, cpsr
    AND R0,R0,#0xFFFFFFE0
    ORR R0, R0, #0x13
    ORR R0, R0, #0x40
    BIC R0, R0, #(1 << 7)
    MSR cpsr, R0


    enable_glock_gpio1:
    LDR R0, =BASE_PRCM_GPIO1
    LDR R1, =MODULEMODE_ENABLE
    ORR R1, R1, #(1 << 18)
    STR R1, [R0]     @CM_PER_GPIO1_CLKCTRL
    
    B main
