
;Brandon Barrera
;RCET 3375
;Tim Rossiter
;Servo Controller With VB integration
;10/22/2025
    
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
#include <pic16f883.inc>
  
;Reset Vector
PSECT resetVect,class=CODE,delta=2  ;-Wl,-presetVect=00h
  GOTO Start

;Interrupt Vector
PSECT isrVect,class=CODE,delta=2     ;-Wl,-pisrVect=04h
  GOTO InterruptHandler
  
;Start of program 
PSECT code,class=CODE,delta=2	;-Wl,-pcode=08h
 
RCSAVE	    EQU 0x20
ENABLEPULSE EQU 0x21
PW	    EQU 0x22
PS	    EQU 0x23
PERIOD	    EQU 0x24
SAVEW	    EQU 0x25
BANKSAVE    EQU 0x26
RCSAVE1	    EQU 0x27
HIGHADC	    EQU 0x28
LOWADC	    EQU 0x29
 
Start:
    BSF	    STATUS, 5	;Bank 3 select
    BSF	    STATUS, 6
    MOVLW   0x00
    MOVWF   BAUDCTL	;Controls the baud settings
    MOVLW   0x01
    MOVWF   ANSEL	;Configures analog, Port A
    CLRF    ANSELH      ;Configures analog, Port B
    MOVLW   0x80       
    MOVWF   OPTION_REG	;Allow Port B pullups, Port A & Port B
    ;--------------------------------------
    BCF	    STATUS, 5   ;Bank 2 select
    CLRF    CM1CON0	;Comparator 1, Port A
    CLRF    CM2CON0	;Comparator 2, Port A
    CLRF    CM2CON1	;Comparator and Timer1 config, Port A & Port B
    ;--------------------------------------
    BSF	    STATUS, 5   ;Bank 1 select
    BCF	    STATUS, 6   ;Bank 1 select
    MOVLW   0x64
    MOVWF   PR2		;Makes TMR2 flag at 100
    MOVLW   0x24
    MOVWF   TXSTA	;Configures transmit EUSART
    MOVLW   0x19
    MOVWF   SPBRG	;This is the desired Speilbergh
    MOVLW   0x19
    MOVWF   SPBRGH	;This is the desired Speilbergh
    CLRF    PSTRCON	;pulse timer control, Port C
    CLRF    ADCON1	;Sets reference voltage for ADC
    CLRF    PCON	;Power Config, Port A
    MOVLW   0x62
    MOVWF   PIE1
    MOVLW   0x01
    MOVWF   TRISA	;Same, Port A
    MOVLW   0x80
    MOVWF   TRISC	;Same, Port C
    ;--------------------------------------
    BCF	    STATUS, 5   ;Bank 0 select
    MOVLW   0x04
    MOVWF   T2CON	;Sets Post Scaler to 1:1, turns TMR2 on, and sets pre scaler to 1:1
    CLRF    CCP1CON	;PWM1 Control, Port B & Port C
    CLRF    CCP2CON	;PWM2 Control, Port C
    MOVLW   0x90
    MOVWF   RCSTA	;Recieve Serial Data, Port C
    CLRF    SSPCON	;Serial Write, Port A & Port C
    MOVLW   0x41
    MOVWF   ADCON0	;Controls Analog to Digital converter, Port A
    CLRF    T1CON       ;Timer 1 control, Port C
    MOVLW   0x00
    MOVWF   PORTA	;Same
    MOVLW   0x00
    MOVWF   PORTC	;Same
    BCF	    PIR1, 6	;Clears ADC flag
    BCF	    PIR1, 5	;Clears RC flag
    BCF	    PIR1,1	;Clears TMR2 flag
    MOVLW   0xC8
    MOVWF   PERIOD	;sets period time 20mS
    CLRF    PW
    CLRF    PS
    CLRF    HIGHADC
    CLRF    LOWADC
    MOVLW   0xC0
    MOVWF   INTCON
    ;--------------------------------------
    
;Main loop code
Main:
    BCF STATUS, 5   ;Bank 0
    BCF STATUS, 6   
    BSF ADCON0, 1   ;Enables Conversion to begin
    BSF ADCON0, 0
    GOTO Main	    ;do it again
    
InterruptHandler:
    MOVWF SAVEW
    MOVF STATUS, 0
    MOVWF BANKSAVE
    BTFSC PIR1, 5	;if Receive flag goto $
    GOTO IsDollar
    BTFSC PIR1, 6	;if ADC flag wait till set
    GOTO WaitADC
    BTFSC PIR1, 1	;if Timer flag goto tmr2
    GOTO Timer2
Restore:
    MOVF BANKSAVE, 0
    MOVWF STATUS
    MOVF SAVEW, 0
    RETFIE
       
WaitADC:
    BTFSC ADCON0, 1
    GOTO WaitADC
    MOVF ADRESH, 0
    MOVWF HIGHADC
    BSF STATUS, 5	;Bank 1
    MOVF ADRESL, 0
    BCF STATUS, 5	;Bank 0
    MOVWF LOWADC
    BCF PIR1, 6		;Clear ADC flag
    GOTO Restore
    
SendADC:
    MOVLW 0x21
    CALL Transmit	;Send ! to begin ADC
    NOP
    NOP
    NOP
    MOVF HIGHADC, 0
    CALL Transmit	;Send upper bits of ADC
    NOP
    NOP
    NOP
    NOP
    NOP
    MOVLW 0x21
    CALL Transmit	;Send ! to begin ADC
    NOP
    NOP
    NOP
    MOVF LOWADC, 0
    CALL Transmit	;Send lower bits of ADC
    GOTO Restore
    
IsDollar:
    CALL Recieve
    CALL ObtainData
    MOVLW 0x21
    XORWF RCSAVE, 0
    BTFSC STATUS, 2	;Checks for !
    GOTO SendADC
    MOVLW 0x24
    XORWF RCSAVE, 0
    BTFSS STATUS, 2	;Checks for $
    GOTO Restore
    BCF STATUS, 2
    MOVF RCSAVE, 0
    CALL Transmit
    MOVF RCSAVE1, 0
    CLRF RCSAVE1
    GOTO TimerAdj

Transmit:
    MOVWF TXREG
WaitTX:
    BSF STATUS, 5   ;Bank 1
    BTFSS TXSTA, 1  ;Check to see if done TX
    GOTO WaitTX
    BCF STATUS, 5   ;Bank 0
    RETURN
    
Recieve:
    MOVF RCREG, 0
    MOVWF RCSAVE
    RETURN
    
ObtainData:
    MOVLW 0x24
    XORWF RCSAVE, 0
    BTFSC STATUS, 2
    RETURN
    BCF STATUS, 2
    MOVLW 0x21		    ;W = 1A
    SUBWF RCSAVE, 0	    ;W = RCSAVE - 1A
    BTFSC STATUS, 0	    ;RCSAVE >= 1A
    RETURN		    ;Greater than or equal to
    MOVLW 0x01		    ;else
    MOVWF ENABLEPULSE	    ;Enable PW
    MOVF RCSAVE, 0
    MOVWF RCSAVE1
    MOVF RCSAVE1, 0
    CALL Transmit
    RETURN
    
Timer2:
    BCF PIR1, 1		    ;Clears tmr2 flag
    BTFSC ENABLEPULSE, 0    ;Test to see if enabel (PW)
    GOTO WaitPW
    BTFSC ENABLEPULSE, 1    ;Test to see if enable (PS)
    GOTO WaitPS
    GOTO Restore
    
WaitPW:
    BSF PORTC, 0
    DECFSZ PW		    ;Wait for its alloted time
    GOTO Restore
    MOVLW 0x02
    MOVWF ENABLEPULSE	    ;Enable PS
    GOTO Restore
    
WaitPS:
    BCF PORTC, 0
    DECFSZ PS
    GOTO Restore
    MOVLW 0x67
    CALL Transmits
    CLRF ENABLEPULSE
    CLRF PORTC
    GOTO Restore
    
TimerAdj:
    MOVWF PW		    ;Set to W in increments of 100µS
    MOVF PW, 0
    SUBWF PERIOD, 0	    ;Takes 20mS - PW and makes it PS
    MOVWF PS
    GOTO Timer2
    
END