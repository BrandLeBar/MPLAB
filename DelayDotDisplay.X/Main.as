

; PIC16F883 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = XT		; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = ON            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>

;Reset Vector
PSECT resetVect,class=CODE,delta=2  
  GOTO Start
  
; Start of program 
PSECT code,class=CODE,delta=2

  
  
Start:
    ;Bank 3-----------------------------------------------------
    BSF STATUS, 5    ;Go to bank 3
    BSF STATUS, 6    ;Go to bank 3
    MOVLW 0x00       ;Move all 0's to W
    MOVWF TRISB      ;Sets Pin Function, Digital 0
    CLRF ANSELH      ;Configures pin to I/O in digital or analog
    CLRF INTCON      ;Configures interupts
    MOVLW 0x80	     ;1000 0000
    CLRF OPTION_REG  ;Disables PORTB to use pullups 
    ;Bank 2-----------------------------------------------------
    BCF STATUS, 5    ;Chang to bank 2
    CLRF CM2CON1     ;Disable
    ;Bank 1-----------------------------------------------------
    BSF STATUS, 5    ;Change to bank 1
    BCF STATUS, 6    ;Change to bank 1
    MOVLW 0x00	     ;Sets W to all 0's
    MOVWF WPUB       ;Disables Weak pull ups
    CLRF IOCB        ;Disables Inturruption when changing bits
    CLRF PSTRCON     ;Disables pulse timer control
    CLRF TRISC       ;Sets Pin Function, Digital O
    ;Bank 0-----------------------------------------------------
    BCF STATUS, 5    ;Change to bank 0
    CLRF CCP1CON 
    CLRF CCP2CON
    CLRF SSPCON
    CLRF T1CON
    CLRF PORTB       ;This is last so port b is known when powered on
    CLRF PORTC       ;Same for this port
    COUNT1 EQU 0x20  ;Sets this address as a register
    COUNT2 EQU 0x21  ;Sets this address as a register
    COUNT3 EQU 0x22  ;Sets this address as a register

Initilize:
   MOVLW 0xF9
   MOVWF COUNT3      ;Loads amount of times loop3 is repeated
Loop3:
    MOVLW 0x08
    MOVWF COUNT2     ;Loads amount of times loop2 is repeated
Loop2:
    MOVLW 0x52
    MOVWF COUNT1     ;Loads amount of times loop1 is repeated
Loop1:
    DECFSZ COUNT1
    GOTO Loop1
    DECFSZ COUNT2
    GOTO Loop2
    NOP
    NOP
    NOP
    NOP
    DECFSZ COUNT3
    GOTO Loop3
Display5:
    NOP
    NOP
    NOP
    MOVLW 0x35
    MOVWF PORTC
    
Initilize1:
    NOP
    NOP
    MOVLW 0xF9
    MOVWF COUNT3      ;Loads amount of times loop6 is repeated
Loop6:
    MOVLW 0x08
    MOVWF COUNT2     ;Loads amount of times loop5 is repeated
Loop5:
    MOVLW 0x52
    MOVWF COUNT1     ;Loads amount of times loop4 is repeated
Loop4:
    DECFSZ COUNT1
    GOTO Loop4
    DECFSZ COUNT2
    GOTO Loop5
    NOP
    NOP
    NOP
    NOP
    DECFSZ COUNT3
    GOTO Loop6
Display0:
    NOP
    NOP
    NOP
    MOVLW 0x30
    MOVWF PORTC
GOTO Initilize
END
    