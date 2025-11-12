
; PIC16F883 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = XT             ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
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
  
PROCESSOR 16f883
    
RADIX dec
    
#include <xc.inc>
#include <pic16f883.inc>
    
; --- Reset and Interrupt Vectors ---
PSECT resetVect,class=CODE,delta=2
    GOTO Start
    
PSECT isrVect,class=CODE,delta=2
    CALL Interrupt
    
; --- Main Code Section ---
PSECT code,class=CODE,delta=2
 
 
Start:
    BANKSEL INTCON
    CLRF    INTCON
    
    BANKSEL OPTION_REG
    CLRF    OPTION_REG
    
    BANKSEL ANSELH
    CLRF    ANSELH
    
    BANKSEL IOCB
    CLRF    IOCB
    
    BANKSEL PORTB
    CLRF    PORTB
    
    BANKSEL TRISB
    CLRF    TRISB
    
    BANKSEL PIE1
    MOVLW 0x20
    MOVWF PIE1
    
    BANKSEL PORTB ;end in bank 0
    
    MOVLW 0xC0
    MOVWF INTCON
    
    CLRF RCREG
    
    RCSAVE EQU 0x20
    WSAVE  EQU 0x21
    STATUSSAVE EQU 0x22
    
PSECT code
 ; --- Main Program Loop (Loops forever) ---
Main:
    MOVF RCSAVE, 0
    MOVWF PORTB
    GOTO Main

Interrupt:
    MOVWF WSAVE
    MOVF STATUS, 0
    MOVWF STATUSSAVE
    MOVF RCREG, 0
    MOVWF RCSAVE
    MOVF STATUSSAVE, 0
    MOVWF STATUS
    MOVF WSAVE, 0
    RETFIE
    
END ;Required by assembler