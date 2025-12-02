
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
DATASAVE EQU 0x22
PW1 EQU 0x23
PW2 EQU 0x24
PW3 EQU 0x25
SERVO EQU 0x26

Start:
    BSF	    STATUS, 5	    ;Bank 3 select
    BSF	    STATUS, 6
    CLRF    ANSEL
    CLRF    ANSELH	    ;Configures analog, Port A
    ;--------------------------------------
    BCF	    STATUS, 5	    ;Bank 2 select
    CLRF    CM1CON0	    ;Comparator 1, Port A
    CLRF    CM2CON0	    ;Comparator 2, Port A
    CLRF    CM2CON1	    ;Comparator and Timer1 config, Port A & Port B
    ;--------------------------------------
    BSF	    STATUS, 5	    ;Bank 1 select
    BCF	    STATUS, 6	    ;Bank 1 select
    MOVLW   0x02    
    MOVWF   SSPADD	    ;Sets address for slave, baud rate for master I2C
    MOVLW   0x64
    MOVWF   PR2		    ;Makes TMR2 flag at 100
    CLRF    PSTRCON	    ;pulse timer control, Port C
    CLRF    ADCON1	    ;Sets reference voltage for ADC
    CLRF    PCON	    ;Power Config, Port A
    MOVLW   0x0A
    MOVWF   PIE1
    MOVLW   0x00
    MOVWF   TRISA	    ;Same, Port A
    MOVLW   0xFF
    MOVWF   TRISC	    ;Same, Port C
    ;--------------------------------------
    BCF	    STATUS, 5	    ;Bank 0 select
    MOVLW   0x04
    MOVWF   T2CON	    ;Sets Post Scaler to 1:1, turns TMR2 on, and sets pre scaler to 1:1
    CLRF    CCP1CON	    ;PWM1 Control, Port B & Port C
    CLRF    CCP2CON	    ;PWM2 Control, Port C
    MOVLW   0x26
    MOVWF   SSPCON	    ;Serial Write/Read I2C, Port A & Port C
    CLRF    ADCON0	    ;Controls Analog to Digital converter, Port A
    CLRF    T1CON	    ;Timer 1 control, Port C
    MOVLW   0x00
    MOVWF   PORTA	    ;Same
    MOVLW   0x00
    MOVWF   PORTC	    ;Same
    CLRF    PW1
    CLRF    PW2
    CLRF    PW3
    CLRF    SERVO
    BCF	    PIR1, 1	    ;Clears TMR2 flag
    BCF	    PIR1, 3	    ;Clears MSSP flag
    MOVLW   0xC0
    MOVWF   INTCON
    ;--------------------------------------
    
Main:
    GOTO Main		;loop

InterruptHandler:
    //<editor-fold defaultstate="collapsed" desc="Save Bank & W">
    MOVWF WSAVE		;"
    MOVF STATUS, 0	;Save Bank & W
    MOVWF BANKSAVE	;"//</editor-fold>
    BTFSC PIR1, 3	;Is it Recieving?
    GOTO Recieving
    BTFSC PIR1, 1	;Is it timer 2?
    GOTO Timer
    //<editor-fold defaultstate="collapsed" desc="Restore Bank & W and Retfie">
Restore:
    MOVF BANKSAVE, 0	;"
    MOVWF STATUS	;Restore Bank & W
    MOVF WSAVE, 0	;"
    RETFIE//</editor-fold>
    
//<editor-fold defaultstate="collapsed" desc="Recieving: Moves data to W and handles Read/Write">
Recieving:
    MOVF SSPBUF, 0	;Clear the I2C Buffer, and move its contents to W
    BCF PIR1, 3		;Clear the I2C Flag
    BTFSC SSPBUF, 0	;Is it Reading?
    GOTO Restore	;Yes, Don't care
    GOTO Write		;No
    GOTO Restore	;Redunandt exit//</editor-fold>
    
//<editor-fold defaultstate="collapsed" desc="Recieve logic">
Write:
    BSF STATUS, 5	    ;Bank 1
//    BTFSS SSPSTAT, 5	    ;Is it the address or data
//    GOTO Restore	    ;Address 
    BCF STATUS, 5	    ;Bank 0
    MOVWF DATASAVE	    ;Save Data
    BTFSC DATASAVE, 7	    ;What Servo was it for, Servo 3?
    CALL Servo3
    BTFSC DATASAVE, 6	    ;Servo 2?
    CALL Servo2
    BTFSC DATASAVE, 5	    ;Servo 1?
    CALL Servo1
    GOTO Restore	    ;None/error//</editor-fold>
    
Timer:
    BCF STATUS, 5	    ;Bank 0
    BCF PIR1, 1		    ;Clear TMR2 flag
    BTFSC SERVO, 0	    ;Is it for Servo 1?
    CALL ServoTimer1	    ;Yes
    BTFSC SERVO, 1	    ;Is it for Servo 2?
    CALL ServoTimer2	    ;Yes
    BTFSC SERVO, 2	    ;Is it for Servo 3?
    CALL ServoTimer3	    ;Yes
    GOTO Restore	
    
//<editor-fold defaultstate="collapsed" desc="Servo Timer logic">
ServoTimer1:
    BSF PORTA, 0	    ;Set Servo1 High
    DECFSZ PW1, 1	    ;Dec until PW = 0x00
    RETURN		    ;Keep Waiting
    MOVLW 0x01
    MOVWF PW1
    BCF SERVO, 0	    ;Reset
    BCF PORTA, 0	    ;Disable Servo1
    RETURN
ServoTimer2:
    BSF PORTA, 1	    ;Set Servo2 High
    DECFSZ PW2, 1	    ;Dec until PW = 0x00
    RETURN		    ;Keep Waiting
    MOVLW 0x01
    MOVWF PW2
    BCF SERVO, 1	    ;Reset
    BCF PORTA, 1	    ;Disable Servo2
    RETURN
ServoTimer3:
    BSF PORTA, 2	    ;Set Servo3 High
    DECFSZ PW3, 1	    ;Dec until PW = 0x00
    RETURN		    ;Keep Waiting
    MOVLW 0x01
    MOVWF PW3
    BCF SERVO, 2	    ;Reset
    BCF PORTA, 2	    ;Disable Servo3
    RETURN//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Servos 1-3">
Servo1:
    BSF SERVO, 0	    ;Set for Timer
    BCF DATASAVE, 5	    ;Wipe address
    MOVF DATASAVE, 0	    ;Load value for table
    CALL LookUpTable	    ;Find value for Timer
    MOVWF PW1		    ;Load value for Timer
    RETURN
Servo2:
    BSF SERVO, 1	    ;Set for Timer
    BCF DATASAVE, 6	    ;Wipe address
    MOVF DATASAVE, 0	    ;Load value for table
    CALL LookUpTable	    ;Find value for Timer
    MOVWF PW2		    ;Load value for Timer
    RETURN
Servo3:
    BSF SERVO, 2	    ;Set for Timer
    BCF DATASAVE, 7	    ;Wipe address
    MOVF DATASAVE, 0	    ;Load value for table
    CALL LookUpTable	    ;Find value for Timer
    MOVWF PW3		    ;Load value for Timer
    RETURN//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Table value for Timer wait time">
LookUpTable:
    ADDWF PCL, 1
    RETLW 0x05
    RETLW 0x05
    RETLW 0x06
    RETLW 0x06
    RETLW 0x07
    RETLW 0x07
    RETLW 0x08
    RETLW 0x08
    RETLW 0x09
    RETLW 0x09
    RETLW 0x0A
    RETLW 0x0A
    RETLW 0x0B
    RETLW 0x0B
    RETLW 0x0C
    RETLW 0x0C
    RETLW 0x0D
    RETLW 0x0D
    RETLW 0x0E
    RETLW 0x0E
    RETLW 0x0F
    RETLW 0x0F
    RETLW 0x10
    RETLW 0x11
    RETLW 0x12
    RETLW 0x13
    RETLW 0x14
    RETLW 0x15
    RETLW 0x16
    RETLW 0x17
    RETLW 0x18
    RETLW 0x19//</editor-fold>

END