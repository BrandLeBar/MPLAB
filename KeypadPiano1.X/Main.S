
;Brandon Barrera
;RCET 3375
;Tim Rossiter
;Keypad Piano
;09/26/2025
    
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

// config statements should precede project file includes.
#include <xc.inc>

;Reset Vector
PSECT resetVect,class=CODE,delta=2  ;-Wl,-presetVect=00h
  GOTO Start

;PSECT isrVect     ;-Wl,-pisrVect=04h
  
;Start of program 
PSECT code,class=CODE,delta=2	;-Wl,-pcode=08h

 
Start:
    BSF STATUS, 5   ;Bank 3 select
    BSF STATUS, 6
    CLRF ANSEL	     ;Configures analog, Port A
    CLRF ANSELH      ;Configures analog, Port B
    CLRF INTCON      ;Configures interupts, Port B
    MOVLW 0x80       
    MOVWF OPTION_REG ;Allow Port B pullups, Port A & Port B 
    ;--------------------------------------
    BCF STATUS, 5   ;Bank 2 select
    CLRF CM1CON0    ;Comparator 1, Port A
    CLRF CM2CON0    ;Comparator 2, Port A
    CLRF CM2CON1    ;Comparator and Timer1 config, Port A & Port B
    ;--------------------------------------
    BSF STATUS, 5   ;Bank 1 select
    BCF STATUS, 6
    CLRF PCON	    ;Power Config, Port A
    MOVLW 0x00	    
    MOVWF WPUB      ;Control Weak pull ups, Port B
    CLRF IOCB       ;Inturruption when changing bits, Port B
    CLRF PSTRCON    ;pulse timer control, Port C
    MOVLW 0x01
    MOVWF TRISA	    ;Configure associated port I/O, Port A
    MOVLW 0x0F
    MOVWF TRISB	    ;Same, Port B
    MOVLW 0x00
    MOVWF TRISC	    ;Same, Port C
    ;--------------------------------------
    BCF STATUS, 5   ;Bank 0 select
    CLRF ADCON0	    ;Controls Analog to Digital converter, Port A
    CLRF CCP1CON    ;PWM1 Control, Port B & Port C
    CLRF CCP2CON    ;PWM2 Control, Port C
    CLRF RCSTA      ;Recieve Serial Data, Port C
    CLRF SSPCON	    ;Serial Write, Port A & Port C
    CLRF T1CON	    ;Timer 1 control, Port C
    MOVLW 0x00
    MOVWF PORTA	    ;Put port in known state
    MOVLW 0x00
    MOVWF PORTB	    ;Same
    MOVLW 0x01
    MOVWF PORTC	    ;Same
    COUNT1 EQU 0x20	;Holds loop1 repeat count
    COUNT2 EQU 0x21	;Holds loop2 repeat count
    COUNT2TEMP EQU 0x22 ;Holds loop2 repeat count tempararily
    CLRF COUNT1		;Puts into Known State
    CLRF COUNT2		;Same
    CLRF COUNT2TEMP	;Same
    ;--------------------------------------
    
Main:
    ;Enable the first row--------------------------------
    MOVLW 0x10       
    MOVWF PORTB      ;Choose Row C-D-E-F 
    MOVLW 0x30       ;Preload value for Look up table
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or F on keypad
    GOTO LookUpTable 
    MOVLW 0x2D       ;Preload value for Look up table
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or E on keypad
    GOTO LookUpTable 
    MOVLW 0x2A       ;Preload value for Look up table
    BTFSC PORTB, 2   ;Check bit 2 of PORTB or D on keypad
    GOTO LookUpTable 
    MOVLW 0x27       ;Preload value for Look up table 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or C on keypad
    GOTO LookUpTable 
    ;Enable the second row--------------------------------
    MOVLW 0x20       
    MOVWF PORTB      ;Choose Row 8-9-A-B
    MOVLW 0x24       ;Preload value for Look up table
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or B on keypad
    GOTO LookUpTable      
    MOVLW 0x21       ;Preload value for Look up table
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or A on keypad
    GOTO LookUpTable      
    MOVLW 0x1E       ;Preload value for Look up table
    BTFSC PORTB, 2   ;Check bit 2 of PORTB or 9 on keypad
    GOTO LookUpTable      
    MOVLW 0x1B       ;Preload value for Look up table 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or 8 on keypad
    GOTO LookUpTable      
    ;Enable the third row-------------------------------
    MOVLW 0x40       
    MOVWF PORTB      ;Choose Row 4-5-6-7
    MOVLW 0x18       ;Preload value for Look up table
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or 7 on keypad
    GOTO LookUpTable      
    MOVLW 0x15	     ;Preload value for Look up table
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or 6 on keypad
    GOTO LookUpTable      
    MOVLW 0x12       ;Preload value for Look up table
    BTFSC PORTB, 2   ;Check bit 2 of PORTB or 5 on keypad
    GOTO LookUpTable      
    MOVLW 0x0C       ;Preload value for Look up table 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or 4 on keypad
    GOTO LookUpTable      
    ;Enable the fourth row-------------------------------
    MOVLW 0x80       
    MOVWF PORTB      ;Choose Row 0-1-2-3
    MOVLW 0x09       ;Preload value for Look up table
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or 3 on keypad
    GOTO LookUpTable      
    MOVLW 0x06	     ;Preload value for Look up table
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or 2 on keypad
    GOTO LookUpTable      
    MOVLW 0x03       ;Preload value for Look up table
    BTFSC PORTB, 2   ;Check bit 2 of PORTB or 1 on keypad
    GOTO LookUpTable      
    MOVLW 0x00       ;Preload value for Look up table 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or 0 on keypad
    GOTO LookUpTable      
    
    CLRF PORTC
    
    GOTO Main

Delay:
    ;0x01
    ;MOVWF COUNT2
Loop2:
    MOVLW 0x51	     ;decimal 163 A3
    MOVWF COUNT1     ;Move to register to be looped
    NOP		     ;To make a perfect 500uS
Loop1:
    DECFSZ COUNT1    ;Decrement until zero
    GOTO Loop1	     ;Skip if zero
    DECFSZ COUNT2    ;Decrement until zero
    GOTO Loop2	     ;Skip if zero
    Return	     ;Returns to line where called

Toggle:
    CALL  Delay      ;This is for 1KHz square wave
    MOVLW 0x01	     ;decimal 1
    XORWF PORTA, 0   ;Flips any bits Xor'ed with W
    MOVWF PORTC	     ;Sends result to be output
    GOTO Main
    
LookUpTable:
    BCF STATUS, 5
    BCF STATUS, 6
    ADDWF PCL, 1
    MOVLW 0x11
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x10
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x0F
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x0E
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x0D
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x0C
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x0B
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x0A
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x09
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x08
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x07
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x06
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x05
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x04
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x03
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x02
    MOVWF COUNT2
    GOTO Toggle
    MOVLW 0x01
    MOVWF COUNT2
    GOTO Toggle
END