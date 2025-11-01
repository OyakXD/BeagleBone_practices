.equ BASE_PRCM, 0x44E00000
.equ MODULEMODE_ENABLE, 0x00000002
.equ BASE_GPIO1, 0x4804C000
.equ GPIO_OE, 0x4804C000 + 0x134
.equ GPIO_SETDATAOUT, 0x4804C000 + 0x194
.equ GPIO_CLEARDATAOUT, 0x4804C000 + 0x190
.equ GPIO_DATAIN, 0x4804C000 + 0x138
.equ CONTROL_MODULE, 0x44E10000
.equ CONF_GPMC_AD6, 0x818

.global main
main:

    @ CONFIGURAR PINMUX DO BOTAO (gpmc_ad6) do GPIO1_6 com entrada habilitada
    LDR R0, =CONTROL_MODULE
    LDR R1, =CONF_GPMC_AD6
    ADD R0, R0, R1


    // CONFIGURAÇÕES: MODE 7 (GPIO) | RX ENABLE
    @ BIT 5: RX ENABLE(1)
    @ BIT 4: PULL-UP(1)
    @ BIT 3: PULL-ENABLE(1)
    @ BIT 2-0: MODE 7 (111)

    MOV R1, #0x27     @ 0010 0111
    STR R1, [R0]
    
    // CONFIGURAR GPIO1
    LDR R3, =GPIO_OE

    @ CONFIGURAR GPIO1_12 COMO SAÍDA (LED) EXTERNO (P8_12)
    LDR R4, [R3]
    BIC R4, R4, #(1 << 12) @ BIT 12 = 0 -> saída (LED)
    STR R4, [R3]

    @ CONFIGURAR GPIO1_6 COMO ENTRADA (BOTÃO - P8 Pino 3)
    LDR R4, [R3]
    ORR R4, R4, #(1 << 6) @ BIT 6 = 1 -> ENTRADA (BOTÃO)
    STR R4, [R3]

loop:
    @ LER BOTÃO GPIO1[6]
    LDR R3, =GPIO_DATAIN
    LDR R5, [R3]            
    AND R5, R5, #0x00000040  
    LSR R5, #6

    @ CONTROLA O LED
    CMP R5, #1
    BEQ acende_led

apaga_led:
    LDR R3, =GPIO_CLEARDATAOUT
    MOV R10, #(1 << 12)
    STR R10, [R3]   @ CLEARDATAOUT -> LED OFF
    B loop

acende_led:
    LDR R3, =GPIO_SETDATAOUT
    MOV R10, #(1 << 12)
    STR R10, [R3]   @ SETDATAOUT -> LED ON
    B loop




