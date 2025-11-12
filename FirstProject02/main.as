
; PIC16F883 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_CLKOUT   ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
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
    MOVLW 0xFF       ;Move all 1's to W
    MOVWF TRISB      ;Sets Pin Function, Digital I
    CLRF ANSELH      ;Configures pin to I/O in digital or analog
    CLRF INTCON      ;Configures interupts
    CLRF OPTION_REG  ;Enables PORTB to use pullups 
    ;Bank 2-----------------------------------------------------
    BCF STATUS, 5    ;Chang to bank 2
    CLRF CM2CON1     ;Disable
    ;Bank 1-----------------------------------------------------
    BSF STATUS, 5    ;Change to bank 1
    BCF STATUS, 6    ;Change to bank 1
    MOVLW 0xFF	     ;Sets W to all 1's
    MOVWF WPUB       ;Enables Weak pull ups
    CLRF IOCB        ;Disables Inturruption when changing bits
    CLRF PSTRCON     ;Disables pulse timer control
    CLRF TRISC       ;Sets Pin Function, Digital O
    MOVLW 0x61       ;Write number to W
    MOVWF OSCCON     ;Configures Internal oscillator to 4MHz
    ;Bank 0-----------------------------------------------------
    BCF STATUS, 5    ;Change to bank 0
    CLRF CCP1CON 
    CLRF CCP2CON
    
    CLRF SSPCON
    CLRF T1CON
    CLRF PORTB       ;This is last so port b is known when powered on
    CLRF PORTC       ;Same for this port
    
OUTPUT:
    MOVWF PORTC      ;outputs the value in W on PORTC
    GOTO Main
    
Main:
    BCF STATUS, 5
    BCF STATUS, 6    ;Ensure current bank is 0
        
    MOVLW 0x08
    BTFSC PORTB,7
    GOTO OUTPUT
    
    MOVLW 0x07
    BTFSC PORTB,6
    GOTO OUTPUT
    
    MOVLW 0x06
    BTFSC PORTB,5
    GOTO OUTPUT
    
    MOVLW 0x05
    BTFSC PORTB,4
    GOTO OUTPUT
    
    MOVLW 0x04
    BTFSC PORTB,3
    GOTO OUTPUT
    
    MOVLW 0x03
    BTFSC PORTB,2
    GOTO OUTPUT
    
    MOVLW 0x02
    BTFSC PORTB,1
    GOTO OUTPUT
    
    MOVLW 0x01
    BTFSC PORTB,0
    GOTO OUTPUT
    
    CLRF PORTC
    
    GOTO Main
    
  END