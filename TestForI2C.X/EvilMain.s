;Brandon Barrera
;RCET 3375
;Test code for I2C
;12/11/2025
    
; PIC16F1788 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTOSC         ; Oscillator Selection (INTOSC oscillator: I/O function on CLKIN pin)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable (WDT disabled)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable (PWRT disabled)
  CONFIG  MCLRE = ON            ; MCLR Pin Function Select (MCLR/VPP pin function is MCLR)
  CONFIG  CP = OFF              ; Flash Program Memory Code Protection (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Memory Code Protection (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown-out Reset Enable (Brown-out Reset disabled)
  CONFIG  CLKOUTEN = ON         ; Clock Out Enable (CLKOUT function is enabled on the CLKOUT pin)
  CONFIG  IESO = OFF            ; Internal/External Switchover (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enable (Fail-Safe Clock Monitor is disabled)

; CONFIG2
  CONFIG  WRT = OFF             ; Flash Memory Self-Write Protection (Write protection off)
  CONFIG  VCAPEN = OFF          ; Voltage Regulator Capacitor Enable bit (Vcap functionality is disabled on RA6.)
  CONFIG  PLLEN = OFF            ; PLL Enable (4x PLL enabled)
  CONFIG  STVREN = OFF          ; Stack Overflow/Underflow Reset Enable (Stack Overflow or Underflow will not cause a Reset)
  CONFIG  BORV = HI             ; Brown-out Reset Voltage Selection (Brown-out Reset Voltage (Vbor), high trip point selected.)
  CONFIG  LPBOR = OFF           ; Low Power Brown-Out Reset Enable Bit (Low power brown-out is disabled)
  CONFIG  DEBUG = OFF           ; In-Circuit Debugger Mode (In-Circuit Debugger disabled, ICSPCLK and ICSPDAT are general purpose I/O pins)
  CONFIG  LVP = OFF             ; Low-Voltage Programming Enable (High-voltage on MCLR/VPP must be used for programming)

; config statements should precede project file includes.
#include <xc.inc>
#include <pic16f1788.inc>

BANK_SAVE EQU 0x020
W_SAVE EQU 0x021
DATA_BYTE EQU 0x070
DATA_RX_1 EQU 0x071
DATA_RX_2 EQU 0x072
DATA_RX_3 EQU 0x073
DATA_RX_4 EQU 0x074
DATA_RX_5 EQU 0x075
DATA_RX_6 EQU 0x076
;DATA_RX_OFF1 EQU 0x077
;DATA_RX_OFF2 EQU 0x078
;DATA_RX_OFF3 EQU 0x079
;DATA_RX_OFF4 EQU 0x07A
;DATA_RX_OFF5 EQU 0x07B
;DATA_RX_OFF6 EQU 0x07C
EVIL_TEMP EQU 0x07D


;Reset Vector
PSECT resetVect,class=CODE,delta=2  ;-Wl,-presetVect=00h
  GOTO Setup

;Interrupt Vector
PSECT isrVect,class=CODE,delta=2     ;-Wl,-pisrVect=04h
  GOTO InterruptHandler
  
;Start of program 
PSECT code,class=CODE,delta=2	;-Wl,-pcode=08h
 
Setup:
    MOVLB 0x07		;Bank 7
    CLRF INLVLC		;Configures voltage level to trigger IOC, Port C
    
    ;----------------------------------------------------------
    MOVLB 0x06		;Bank 6
    CLRF SLRCONC	;Configures Slew Rate Limit, Port C
    
    ;----------------------------------------------------------
    MOVLB 0x05		;Bank 5
    MOVLW 0x18
    MOVWF ODCONC	;Configures Sink Source Current, Port C
    
    ;----------------------------------------------------------
    MOVLB 0x04		;Bank 4
    CLRF WPUC		;Configures Internal Pull-ups, Port C
    MOVLW 0x20
    MOVWF SSP1ADD	;Configures I2C address
    MOVLW 0X36
    MOVWF SSP1CON1	;Enable SDA SCL Pins, Clock, & Set as 7 bit address Slave
    MOVLW 0X81
    MOVWF SSP1CON2	;Enable General Call & Clock Strechting
    MOVLW 0X0B
    MOVWF SSP1CON3	;Disable Slave Interrupts, SDA Hold Time of 300nS, Auto Enable Address & Data Clock Stretching
    MOVLW 0X80
    MOVWF SSP1STAT	;Disable Slew Rate Control & flags
    MOVLW 0XFE
    MOVWF SSP1MSK	;Enable address matching
    CLRF APFCON1
    
    ;----------------------------------------------------------
    MOVLB 0x03		;Bank 3
    CLRF ANSELC		;Configures Analog Inputs, Port C
    
    ;----------------------------------------------------------
    MOVLB 0x02		;Bank 2
    
    ;----------------------------------------------------------
    MOVLB 0x01		;Bank 1
    MOVLW 0x18
    MOVWF TRISC		;Configures I 0, Port C
    MOVLW 0x80
    MOVWF OPTION_REG	;Settings for TMR0, INT edge, and Pullup control, All Ports
    BTFSC OSCSTAT, 6	;Is PLL ready?
    GOTO $-1		;No
    MOVLW 0X78		;Configures Oscillator, Internal, 16MHz
    MOVWF OSCCON
    BTFSC OSCSTAT, 5	;Is Osc ready?
    GOTO $-1		;No
    MOVLW 0x08
    MOVWF PIE1		;Enable I2C Interrupts
    
    ;----------------------------------------------------------
    MOVLB 0x00		;Bank 0
    MOVLW 0xF9
    MOVWF PORTC		;Clears port to ensure known state, Port C
    CLRF BANK_SAVE
    CLRF W_SAVE
    CLRF DATA_BYTE
    CLRF DATA_RX_1
    CLRF DATA_RX_2
    CLRF DATA_RX_3
    CLRF DATA_RX_4
    CLRF DATA_RX_5
    CLRF DATA_RX_6
    ;CLRF DATA_RX_OFF1
    ;CLRF DATA_RX_OFF2
    ;CLRF DATA_RX_OFF3
    ;CLRF DATA_RX_OFF4
    ;CLRF DATA_RX_OFF5
    ;CLRF DATA_RX_OFF6
    BCF PIR1, 3		;Clears I2C flag to ensure known state
    MOVLW 0xC0
    MOVWF INTCON	;Configures Allowed interrupts, Globals & Preriphrials
    
    ;----------------------------------------------------------
    BSF PORTC, 1	;Indicate power on
    
Main:
    MOVLB 0x00		;Bank 0
    BCF PORTC, 2	;Status: Main
    GOTO Main
    
InterruptHandler:
    MOVWF W_SAVE		
    MOVF BSR, 0		;Save Bank & W
    MOVWF BANK_SAVE
    BTFSC PIR1, 3	;Is I2C flag set?
    GOTO Recieve 	;Yes
Restore:
    MOVLB 0x00		;Bank 0
    BCF PIR1, 3		;Clear I2C flag
    MOVLB 0x04		;Bank 4
    BSF SSP1CON1, 4	;Hold clock Low
    MOVF BANK_SAVE, 0	
    MOVWF BSR		;Restore Bank & W
    MOVF W_SAVE, 0	
    RETFIE

Recieve:
    BSF PORTC, 2	;Status: Revieving
    MOVLB 0x04		;Bank 4
    MOVF SSP1BUF, 0	;Recieve I2C
    BTFSC SSP1STAT, 0	;Is it done?
    GOTO $-1		;No, wait
    BTFSS SSP1STAT, 5	;Is it address or data?
    GOTO Restore	;Address, Disregard
    MOVLB 0x00		;Bank 0
    MOVWF EVIL_TEMP	;Data, Save
    MOVLW 0x05		
    XORWF DATA_BYTE, 0	
    BTFSC STATUS, 2	;Is it byte 6?
    GOTO Byte6		;Yes
    MOVLW 0x04		
    XORWF DATA_BYTE, 0	
    BTFSC STATUS, 2	;Is it byte 5?
    GOTO Byte5		;Yes
    MOVLW 0x03		
    XORWF DATA_BYTE, 0	
    BTFSC STATUS, 2	;Is it byte 4?
    GOTO Byte4		;Yes
    MOVLW 0x02		
    XORWF DATA_BYTE, 0	
    BTFSC STATUS, 2	;Is it byte 3?
    GOTO Byte3		;Yes
    MOVLW 0x01		
    XORWF DATA_BYTE, 0	
    BTFSC STATUS, 2	;Is it byte 2?
    GOTO Byte2		;Yes
    MOVLW 0x00		
    XORWF DATA_BYTE	
    BTFSC STATUS, 2	;Is it byte 1?
    GOTO Byte1		;Yes
    GOTO Restore
    
Byte1:
    MOVF EVIL_TEMP, 0	;Move data to W
    MOVWF DATA_RX_1	;Save first Byte
    INCF DATA_BYTE, 1	;Increament for next byte
    GOTO Restore	;Return
    
Byte2:
    MOVF EVIL_TEMP, 0	;Move data to W
    MOVWF DATA_RX_2	;Save second Byte
    INCF DATA_BYTE, 1	;Increament for next byte
    GOTO Restore	;Return
    
Byte3:
    MOVF EVIL_TEMP, 0	;Move data to W
    MOVWF DATA_RX_3	;Save third Byte
    INCF DATA_BYTE, 1	;Reset
    GOTO Restore	;Return
    
Byte4:
    MOVF EVIL_TEMP, 0	;Move data to W
    MOVWF DATA_RX_4	;Save fourth Byte
    INCF DATA_BYTE, 1	;Reset
    GOTO Restore	;Return
    
Byte5:
    MOVF EVIL_TEMP, 0	;Move data to W
    MOVWF DATA_RX_5	;Save fith Byte
    INCF DATA_BYTE, 1	;Reset
    GOTO Restore	;Return
    
Byte6:
    MOVF EVIL_TEMP, 0	;Move data to W
    MOVWF DATA_RX_6	;Save sixth Byte
    CLRF DATA_BYTE	;Reset
    GOTO Restore	;Return
    
END