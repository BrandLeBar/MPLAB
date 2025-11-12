
;Brandon Barrera
;RCET 3375
;Tim Rossiter
;Stoplight
;09/29/2025
    
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

NSCAR EQU 0x20
EWCAR EQU 0x21
BOTHCAR EQU 0x22
DISPLAY EQU 0x23
WAIT55 EQU 0x24
WAIT5 EQU 0x25
WAIT1 EQU 0x26
CONTINUE EQU 0x27
ACTIVE EQU 0x28

Start:
    BSF STATUS, 5    ;Bank 3 select
    BSF STATUS, 6
    CLRF ANSEL	     ;Configures analog, Port A
    CLRF ANSELH      ;Configures analog, Port B
    MOVLW 0x80       
    MOVWF OPTION_REG ;Allow Port B pullups, Port A & Port B 
    ;--------------------------------------
    BCF STATUS, 5   ;Bank 2 select
    CLRF CM1CON0    ;Comparator 1, Port A
    CLRF CM2CON0    ;Comparator 2, Port A
    CLRF CM2CON1    ;Comparator and Timer1 config, Port A & Port B
    ;--------------------------------------
    BSF STATUS, 5   ;Bank 1 select
    BCF STATUS, 6   ;Bank 1 select
    CLRF PCON	    ;Power Config, Port A
    MOVLW 0x02
    MOVWF PIE1	    ;Preriphrial interrupt enables
    MOVLW 0x00	    
    MOVWF WPUB      ;Control Weak pull ups, Port B
    MOVLW 0x00
    MOVWF IOCB       ;Inturruption when changing bits, Port B
    CLRF PSTRCON    ;pulse timer control, Port C
    MOVLW 0x00
    MOVWF TRISA	    ;Configure associated port I/O, Port A
    MOVLW 0x03
    MOVWF TRISB	    ;Same, Port B
    MOVLW 0x00
    MOVWF TRISC	    ;Same, Port C
    ;--------------------------------------
    BCF STATUS, 5   ;Bank 0 select
    MOVLW 0xFF
    MOVWF PR2	    ;Makes TMR2 flag at 255
    MOVLW 0x56
    MOVWF T2CON	    ;Sets Post Scaler to 1:11, turns TMR2 on, and sets pre scaler to 1:16
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
    MOVLW 0x00
    MOVWF PORTC	    ;Same
    BCF PIR1, 1	    ;Clears TMR2 flag bit
    MOVLW 0xC0
    MOVWF INTCON      ;Configures interupts, Port B
    ;--------------------------------------
    
;Main loop code
Main:
    BTFSC PORTB, 1	;check N/S is clear
    GOTO BothTestEW
    BTFSC PORTB, 0	;check E/W is clear
    GOTO BothTestNS
    INCF BOTHCAR	;No cars so Normal operation ensues
    GOTO Main
BothTestNS:
    BTFSC PORTB, 1	;check if N/S is clear
    INCF BOTHCAR
    BTFSS PORTB, 1	;check if N/S is set
    INCF EWCAR
    GOTO Main		;Return
BothTestEW:
    BTFSC PORTB, 0	;check if E/W is clear
    INCF BOTHCAR    
    BTFSS PORTB, 0	;check if E/W is set 
    INCF EWCAR
    GOTO Main		;Return
    
InterruptHandler:
    BCF PIR1, 1
    BTFSC DISPLAY, 0	;Should I wait 5 sec
    GOTO DisplayG0R1
    BTFSC DISPLAY, 1	;Should I wait 1 sec
    GOTO DisplayY0R1
    BTFSC DISPLAY, 2	;Should I wait 5 sec... again
    GOTO DisplayR0G1
    BTFSC DISPLAY, 3	;Should I wait 1 sec... again
    GOTO DisplayR0Y1
    BTFSC PORTB, 1	;Are there cars going N/S
    GOTO Test		;Are you sure?
    BTFSC PORTB, 0	;Are there cars going E/W
    GOTO Test1		;Are you sure?
    CLRF ACTIVE
Normal:
    MOVLW 0x70		;112 for a 5 sec wait
    MOVWF WAIT5
    MOVLW 0x01
    MOVWF DISPLAY	;enables the wait for 5
    BTFSS CONTINUE, 0	;Are we ready to continue?
    RETFIE		;no
    MOVLW 0x16
    MOVWF WAIT1		;22 for a 1 sec wait
    MOVLW 0x02
    MOVWF DISPLAY	;enables the wait for 1
    BTFSS CONTINUE, 1	;Are we ready to continue?
    RETFIE		;no
    MOVLW 0x70
    MOVWF WAIT5		;for a 5 sec wait
    MOVLW 0x04
    MOVWF DISPLAY	;enables the wait for 5
    BTFSS CONTINUE, 2	;Are we ready to continue?
    RETFIE
    MOVLW 0x16
    MOVWF WAIT1		;22 for a 1 sec wait
    MOVLW 0x08
    MOVWF DISPLAY	;enables the wait for 1
    DECF BOTHCAR
    BTFSS CONTINUE,3
    RETFIE
    CLRF DISPLAY
    CLRF CONTINUE
    RETFIE
    
Test:
    BTFSC PORTB, 0
    GOTO Normal
    GOTO NorthSouth
Test1:
    BTFSC PORTB, 1
    GOTO Normal
    GOTO EastWest
    
DisplayG0R1:
    MOVLW 0x24
    MOVWF PORTC
    DECF NSCAR
    DECFSZ WAIT5
    RETFIE
    MOVLW 0x01
    MOVWF CONTINUE
    CLRF DISPLAY
    BSF ACTIVE, 0
    RETFIE
    
DisplayY0R1:
    MOVLW 0x22
    MOVWF PORTC
    DECFSZ WAIT1
    RETFIE
    
    MOVLW 0x03
    MOVWF CONTINUE
    CLRF DISPLAY
    RETFIE
    
DisplayR0G1:
    MOVLW 0x81
    MOVWF PORTC
    DECF EWCAR
    DECFSZ WAIT5
    RETFIE
    MOVLW 0x07
    MOVWF CONTINUE
    CLRF DISPLAY
    BSF ACTIVE, 1
    RETFIE
    
DisplayR0Y1:
    MOVLW 0x41
    MOVWF PORTC
    DECF EWCAR
    DECFSZ WAIT1
    RETFIE
    MOVLW 0x0F
    MOVWF CONTINUE
    CLRF DISPLAY
    RETFIE
    
NorthSouth:
    BTFSS ACTIVE, 0
    GOTO Normal
    GOTO DisplayG0R1
EastWest:
    BTFSS ACTIVE, 1
    GOTO Normal
    GOTO DisplayR0G1
    
END