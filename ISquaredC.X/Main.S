
;Brandon Barrera
;RCET 3375
;Tim Rossiter
;I^2C
;11/17/2025
    
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
 
WSAVE EQU 0x20
BANKSAVE EQU 0x21
TXDATAPOT1 EQU 0x22
TXDATAPOT2 EQU 0x23
TXDATAPOT3 EQU 0x24
HIGHADC EQU 0x26
ADCNUMBER EQU 0x27
 
Start:
    BSF	    STATUS, 5	    ;Bank 3 select
    BSF	    STATUS, 6
    MOVLW   0x01
    MOVWF   ANSEL
    CLRF    ANSELH	    ;Configures analog, Port A
    ;--------------------------------------
    BCF	    STATUS, 5	    ;Bank 2 select
    CLRF    CM1CON0	    ;Comparator 1, Port A
    CLRF    CM2CON0	    ;Comparator 2, Port A
    CLRF    CM2CON1	    ;Comparator and Timer1 config, Port A & Port B
    ;--------------------------------------
    BSF	    STATUS, 5	    ;Bank 1 select
    BCF	    STATUS, 6	    ;Bank 1 select
    MOVLW   0x09    
    MOVWF   SSPADD
    CLRF    PSTRCON	    ;pulse timer control, Port C
    CLRF    ADCON1	    ;Sets reference voltage for ADC
    CLRF    PCON	    ;Power Config, Port A
    MOVLW   0x40
    MOVWF   PIE1
    MOVLW   0x07
    MOVWF   TRISA	    ;Same, Port A
    MOVLW   0xFF
    MOVWF   TRISC	    ;Same, Port C
    ;--------------------------------------
    BCF	    STATUS, 5	    ;Bank 0 select
    CLRF    CCP1CON	    ;PWM1 Control, Port B & Port C
    CLRF    CCP2CON	    ;PWM2 Control, Port C
    MOVLW   0x28
    MOVWF   SSPCON	    ;Serial Write, Port A & Port C
    MOVLW   0x41
    MOVWF   ADCON0	    ;Controls Analog to Digital converter, Port A
    CLRF    T1CON	    ;Timer 1 control, Port C
    MOVLW   0x00
    MOVWF   PORTA	    ;Same
    MOVLW   0x00
    MOVWF   PORTC	    ;Same
    BCF	    PIR1, 6	    ;Clears ADC flag
    CLRF    ADCNUMBER
    MOVLW   0xC0
    MOVWF   INTCON
    ;--------------------------------------
    
Main:
    BSF ADCON0, 1	;Enables Conversion to begin
    GOTO Main		;loop

InterruptHandler:
    //<editor-fold defaultstate="collapsed" desc="Save Bank & W">
    MOVWF WSAVE		;"
    MOVF STATUS, 0	;Save Bank & W
    MOVWF BANKSAVE	;"//</editor-fold>
    BTFSC PIR1, 6	;if ADC flag wait till set
    GOTO WhichADC	;Set current pot to read
    //<editor-fold defaultstate="collapsed" desc="Restore Bank & W">
Restore:
    MOVF BANKSAVE, 0	;"
    MOVWF STATUS	;Restore Bank & W
    MOVF WSAVE, 0	;"
    RETFIE//</editor-fold>
    
//<editor-fold defaultstate="collapsed" desc="Wait for ADC">
WaitADC:
    BTFSC ADCON0, 1	;Check if done
    GOTO WaitADC	;No, wait
    MOVF ADRESH, 0	;Yes, move to W
    BCF PIR1, 6		;Clear ADC flag
    RETURN//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Which ADC is being Scanned">
WhichADC:
    MOVLW 0x00
    XORWF ADCNUMBER, 0
    BTFSC STATUS, 2	    ;Is it pot 1?
    GOTO Pot1		    ;Yes
    MOVLW 0x01		    ;No
    XORWF ADCNUMBER, 0
    BTFSC STATUS, 2	    ;Is it pot 2?
    GOTO Pot2		    ;Yes
    MOVLW 0x02		    ;No
    XORWF ADCNUMBER, 0
    BTFSC STATUS, 2	    ;Is it pot 3?
    GOTO Pot3		    ;Yes
    MOVLW 0x00		    ;No
    MOVWF ADCNUMBER	    ;Reset counter
    GOTO Restore//</editor-fold>
    
//<editor-fold defaultstate="collapsed" desc="Set ADC to read certain pot">
Pot1:
    BCF ADCON0, 5	;Enable AN0
    BCF	ADCON0, 4	;
    BCF	ADCON0, 3	;
    BCF ADCON0, 2	;
    CALL WaitADC	;Read data at pot 1
    MOVWF TXDATAPOT1	;Save
    RRF TXDATAPOT1, 1	;Shift bits right by one
    BCF STATUS, 0	;Clear carry bit
    RRF TXDATAPOT1, 1	;Repeat 2 times
    BCF STATUS, 0	;
    RRF TXDATAPOT1, 1	;
    BCF STATUS, 0	;
    BSF TXDATAPOT1, 5	;Set bit 5 as an address
    BCF TXDATAPOT1, 6
    BCF TXDATAPOT1, 7
    INCF ADCNUMBER, 1	;Continue to next pot
    MOVF TXDATAPOT1, 0
    CALL WriteToSlave
    GOTO Restore
Pot2:
    BCF ADCON0, 5	;Enable AN1
    BCF	ADCON0, 4	;
    BCF	ADCON0, 3	;
    BSF ADCON0, 2	;
    CALL WaitADC	;Read data at pot 2
    MOVWF TXDATAPOT2	;Save
    RRF TXDATAPOT2, 1	;Shift bits right by one
    BCF STATUS, 0	;Clear carry bit
    RRF TXDATAPOT2, 1	;Repeat 2 times
    BCF STATUS, 0	;
    RRF TXDATAPOT2, 1	;
    BCF STATUS, 0	;
    BCF TXDATAPOT2, 5
    BSF TXDATAPOT2, 6	;Set bit 6 as an address
    BCF TXDATAPOT2, 7
    INCF ADCNUMBER, 1	;Continue to next pot
    MOVF TXDATAPOT2, 0
    CALL WriteToSlave
    GOTO Restore
Pot3:
    BCF ADCON0, 5	;Enable AN2
    BCF	ADCON0, 4	;
    BSF	ADCON0, 3	;
    BCF ADCON0, 2	;
    CALL WaitADC	;Read data at pot 3
    MOVWF TXDATAPOT3	;Save
    RRF TXDATAPOT3, 1	;Shift bits right by one
    BCF STATUS, 0	;Clear carry bit
    RRF TXDATAPOT3, 1	;Repeat 2 times
    BCF STATUS, 0	;
    RRF TXDATAPOT3, 1	;
    BCF STATUS, 0	;
    BCF TXDATAPOT3, 5
    BCF TXDATAPOT3, 6
    BSF TXDATAPOT3, 7	;Set bit 7 as an address
    INCF ADCNUMBER, 1	;Continue to next pot
    MOVF TXDATAPOT3, 0
    CALL WriteToSlave
    GOTO Restore//</editor-fold>

WriteToSlave:
    MOVWF HIGHADC
    BSF STATUS, 5	;Bank 1
    BSF SSPCON2, 0	;Send Start Bit
    BTFSC SSPCON2, 0	;Is it done starting?
    GOTO $-1		;No, wait
    BCF SSPSTAT, 2	;Yes, Set to write
    BCF STATUS, 5	;Bank 0
    BCF PIR1, 3
    BTFSC PIR1, 3
    GOTO $-2
    MOVLW 0x02
    MOVWF SSPBUF	;Write Address to Data register
    BCF PIR1, 3
    BTFSC PIR1, 3
    GOTO $-2
    BSF STATUS, 5	;Bank 1
    BTFSC SSPSTAT, 0	;Is it done transmitting?
    GOTO $-1		;No, wait
    BSF SSPSTAT, 2	;Yes, set to read
    NOP
    NOP
    NOP
    NOP
    BTFSC SSPCON2, 6	;Was it acknowleged?
    GOTO Stop		;No
    BCF SSPSTAT, 2	;Yes, set to Write
    BCF STATUS, 5	;Bank 0
    BCF PIR1, 3
    BTFSC PIR1, 3
    GOTO $-2
    NOP
    NOP
    NOP
    NOP
    MOVF HIGHADC, 0
    MOVWF SSPBUF	;Write pot data to Data register
    BSF STATUS, 5	;Bank 1
    BTFSC SSPSTAT, 0	;Is it done transmitting?
    GOTO $-1		;No, wait
    NOP
    NOP
    NOP
    NOP
    BSF SSPSTAT, 2	;Yes, set to read
    BCF STATUS, 5	;Bank 0
    BCF PIR1, 3
    BTFSC PIR1, 3
    GOTO $-2
Stop:
    BSF STATUS, 5	;Bank 1
    BSF SSPSTAT, 2	;set to read
    BSF SSPCON2, 2	;Send stop bit
    BCF STATUS, 5	;Bank 0
    BCF PIR1, 3
    BTFSC PIR1, 3
    GOTO $-2
    BSF STATUS, 5	;Bank 1
    BTFSC SSPCON2, 2	;Is it done stopping?
    GOTO $-1		;No, wait
    BCF STATUS, 5	;Bank 0
    BCF PIR1, 3
    BTFSC PIR1, 3
    GOTO $-2
    RETURN		;Yes return
END