/*
 * =====================================================================================
 *
 *       Filename:  start.s
 *
 *    Description: TURNING ON THE LED WITH THE BUTTON USING THE RISING EDGE INTERRUPT ACCORDING TO THE ARM335x MANUAL
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
/* ============ EXCEPTIONS ADDRESS ============ */
.equ INTC_BASE,              0x48200000
.equ INTC_MIR_CLEAR3,        0x48200000 + 0xE8
.equ INTC_SIR_IRQ,           0x48200000 + 0x40
.equ INTC_CONTROL,           0x48200000 + 0x48

/* ============ CONTROL MODULE ============ */
.equ CONTROL_MODULE_BASE,    0x44E10000
.equ CONF_GPMC_AD6,          0x44E10000 + 0x818
.equ CONF_GPMC_AD12,         0x44E10000 + 0x830

/* ============ CLOCK CONTROL ============ */
.equ BASE_PRCM_GPIO1,        0x44E00000 + 0xAC
.equ MODULEMODE_ENABLE,      0x00000002

/* ============ GPIO REGISTERS ============ */
.equ GPIO1_BASE,             0x4804C000
.equ GPIO1_IRQSTATUS_0,      0x4804C000 + 0x2C
.equ GPIO1_IRQSTATUS_SET_0,  0x4804C000 + 0x34
.equ GPIO1_OE,               0x4804C000 + 0x134
.equ GPIO1_CLEARDATAOUT,     0x4804C000 + 0x190
.equ GPIO1_SETDATAOUT,       0x4804C000 + 0x194
.equ GPIO1_RISINGDETECT,     0x4804C000 + 0x148
.equ GPIO1_DATAIN,           0x4804C000 + 0x138

/* ============ PIN MASKS ============ */
.equ LED_PIN,                (1 << 12)
.equ BUTTON_PIN,             (1 << 6)

/* ============ CPSR MODES ============ */
.equ CPSR_I,   0x80
.equ CPSR_F,   0x40
.equ CPSR_IRQ, 0x12
.equ CPSR_USR, 0x10
.equ CPSR_FIQ, 0x11
.equ CPSR_SVC, 0x13
.equ CPSR_ABT, 0x17
.equ CPSR_UND, 0x1B
.equ CPSR_SYS, 0x1F

.section .data
led_state: .word 0  

.section .text, "ax"
          .code 32
          .align 4
 /* ============ VECTOR TABLE ============ */
 _vector_table:
     ldr pc, _reset     /* reset - _start */
     ldr pc, _undf      /* undefined */
     ldr pc, _swi       /* SWI */
     ldr pc, _pabt      /* prefetch abort */
     ldr pc, _dabt      /* data abort */
     nop
     ldr pc, _irq       /* IRQ */
     ldr pc, _fiq       /* FIQ */
 _reset: .word _start
 _undf:  .word 0x4030CE24
 _swi:   .word 0x4030CE28
 _pabt:  .word 0x4030CE2C
 _dabt:  .word 0x4030CE30
 _irq:   .word 0x4030CE38
 _fiq:   .word 0x4030CE3C


.global _start
_start:

    /* MANUAL */
    /* Set V=0 in CP15 SCTRL register - for VBAR to point to vector */
    mrc    p15, 0, r0, c1, c0, 0    // Read CP15 SCTRL Register
    bic    r0, #(1 << 13)           // V = 0
    mcr    p15, 0, r0, c1, c0, 0    // Write CP15 SCTRL Register

    /* Set vector address in CP15 VBAR register */
    ldr     r0, =_vector_table
    mcr     p15, 0, r0, c12, c0, 0  //Set VBAR

    /* init */
    mrs r0, cpsr
    bic r0, r0, #0x1F            // clear mode bits
    orr r0, r0, #CPSR_SVC        // set SVC mode
    orr r0, r0, #(CPSR_F)        // disable FIQ
    bic r0, r0, #(CPSR_I)                 // enable IRQ
    msr cpsr, r0
    
    /* ============ IRQ HANDLER CONFIG ============ */
    LDR R0, =_irq
    LDR R1, =irq_handler
    STR R1, [R0]

    /* ============ ENABLE CLOCK GPIO1 ============ */
    LDR R0, =BASE_PRCM_GPIO1
    LDR R1, =MODULEMODE_ENABLE
    ORR R1, R1, #(1 << 18)
    STR R1, [R0]     @CM_PER_GPIO1_CLKCTRL

    /* ============ PINMUX CONFIG ============ */
    LDR R0, =CONF_GPMC_AD6       
    MOV R1, #0x2F   // 0010 1111
    STR R1, [R0]

    LDR R0, =CONF_GPMC_AD12      
    MOV R1, #0x07
    STR R1, [R0]

    /* ============ GPIO DIRECTION ============ */
    LDR R0, =GPIO1_OE
    LDR R1, [R0]
    ORR R1, R1, #BUTTON_PIN      
    BIC R1, R1, #LED_PIN         
    STR R1, [R0]

    /* ============ EXCEPTION CONFIG ============ */
    LDR R0, =GPIO1_RISINGDETECT
    MOV R1, #BUTTON_PIN
    STR R1, [R0]

    /*  Limpando as flags pendentes */
    LDR R0, =GPIO1_IRQSTATUS_0
    MOV R1, #BUTTON_PIN
    STR R1, [R0]

    /* Habilitando as interrupções */
    LDR R0, =GPIO1_IRQSTATUS_SET_0
    MOV R1, #BUTTON_PIN
    STR R1, [R0]

    /* ============ ENABLE IRQ98 (GPIO1) ============ */
    LDR R0, =INTC_MIR_CLEAR3
    MOV R1, #(1 << 2)
    STR R1, [R0]

    /* ============ ENABLE GLOBAL IRQ ============ */
    MRS R1, CPSR
    BIC R1, R1, #0x80
    MSR CPSR_c, R1

halt:
    b halt

 /* ============ INTERRUPTION ROUTINE ============ */
irq_handler:
    stmfd sp!, {r0-r12, lr}
    MRS R11, spsr
    BL isr_handler
    dsb
    MSR SPSR, R11
    ldmfd sp!, {r0-r12, lr}
    subs pc, lr, #4

 /* ============ ISR (INTERRUPTION SERVICE ROUTINE) (BUTTON) ============ */
isr_handler:

    LDR R0, =GPIO1_IRQSTATUS_0
    LDR R1, [R0]
    MOV R2, #BUTTON_PIN
    AND R3, R1, R2

    STR R2, [R0]

    LDR R0, =led_state
    LDR R1, [R0]

    EOR R1, R1, #1

    CMP R1, #0
    BNE acende_led


apaga_led:
    LDR R2, =GPIO1_CLEARDATAOUT
    MOV R3, #LED_PIN
    STR R3, [R2]
    STR R1, [R0]
    B end_isr

acende_led:
    LDR R2, =GPIO1_SETDATAOUT
    MOV R3, #LED_PIN
    STR R3, [R2] 
    STR R1, [R0]

end_isr:
    LDR R0, =INTC_CONTROL
    MOV R1, #1
    LDR R2, [R0]
    STR R1, [R0]
    BX LR
