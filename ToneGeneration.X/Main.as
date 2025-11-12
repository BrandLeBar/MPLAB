

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
    BSF   STATUS, 5  ;Go to bank 3
    BSF   STATUS, 6  ;Go to bank 3
    CLRF  ANSELH     ;Configures pin to I/O in digital or analog 
    CLRF  ANSEL      ;Configures pin to I/O in analog for port A
    CLRF  INTCON     ;Configures interupts
    MOVLW 0x00	     ;0000 0000
    MOVWF OPTION_REG ;Disables PORTB to use pullups 
    ;Bank 2-----------------------------------------------------
    BCF   STATUS, 5  ;Chang to bank 2
    CLRF  CM2CON1    ;Disable
    CLRF  CM1CON0    ;Disable
    CLRF  CM2CON0    ;Disable
    ;Bank 1-----------------------------------------------------
    BSF   STATUS, 5  ;Change to bank 1
    BCF   STATUS, 6  ;Change to bank 1
    MOVLW 0x00	     ;Sets W to all 0's
    MOVWF WPUB       ;Disables Weak pull ups
    CLRF  IOCB       ;Disables Inturruption when changing bits
    CLRF  PSTRCON    ;Disables pulse timer control
    MOVLW 0x01	     ;
    MOVWF TRISA	     ;Sets PORTA pin function
    MOVLW 0x00	     ;
    MOVWF TRISB	     ;Sets PORTB pin function
    MOVLW 0x00	     ;
    MOVWF TRISC      ;Sets PORTC pin function
    CLRF  PCON       ;Power control for Brown out and on reset
    ;Bank 0-----------------------------------------------------
    BCF   STATUS, 5  ;Change to bank 0
    CLRF  CCP1CON    ;
    CLRF  CCP2CON    ;
    CLRF  SSPCON     ;
    CLRF  T1CON	     ;
    CLRF  ADCON0     ;Controls if analog to digital converter is on
    MOVLW 0x00	     ;
    MOVWF PORTA	     ;This is last so PORTA is known when powered on
    MOVLW 0x00	     ;
    MOVWF PORTB      ;Same for this port
    MOVLW 0x01	     ;
    MOVWF PORTC      ;Same for this port

    COUNT1 EQU 0x20  ;Declare this register as COUNT1
 
Main:
    BCF STATUS, 5
    BCF STATUS, 6
    MOVLW 0x01
    XORWF PORTA, 0   ;Flips any bits Xor'ed with W
    MOVWF PORTC	     ;Sends result to be output
    CALL  Delay      ;This is for 1KHz square wave
    GOTO  Main	     ;Now do it again

Delay:
    MOVLW 0xA3	     ;decimal 163
    MOVWF COUNT1     ;Move to register to be looped
    NOP		     ;To make a perfect 500uS
InnerLoop:
    DECFSZ COUNT1    ;Decrement until zero
    GOTO InnerLoop   ;Skip if zero
    RETURN	     ;Returns to line where called
    
END
    