
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
PERIOD EQU 0x22
PULSESPACE1 EQU 0x23
PULSESPACE2 EQU 0x24
PULSESPACE3 EQU 0x25
DATASAVE EQU 0x26

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
    BCF	    PIR1, 1	    ;Clears TMR2 flag
    BCF	    PIR1, 3	    ;Clears MSSP flag
    MOVLW   0xC0
    MOVWF   INTCON
    ;--------------------------------------
    
Main:
    GOTO Main
    
InterruptHandler:
    //<editor-fold defaultstate="collapsed" desc="Save Bank & W">
    MOVWF WSAVE		;"
    MOVF STATUS, 0	;Save Bank & W
    MOVWF BANKSAVE	;"//</editor-fold>
    BTFSC PIR1, 3	;Is it Recieving?
    GOTO Recieving	;Yes 
    BTFSC PIR1, 1	;Is it timer 2?
    GOTO Timer		;Yes
    //<editor-fold defaultstate="collapsed" desc="Restore Bank & W and Retfie">
Restore:
    MOVF BANKSAVE, 0	;"
    MOVWF STATUS	;Restore Bank & W
    MOVF WSAVE, 0	;"
    RETFIE//</editor-fold>
    
//<editor-fold defaultstate="collapsed" desc="Timer: Resets timer/Period and sets Servos high">
Timer:
    BCF	PIR1, 1		;Clear TMR2 flag
    DECFSZ PERIOD	;Wait a Period
    GOTO FindPW
    MOVLW 0xC8		;Reset Period
    MOVWF PERIOD
    BSF	PORTA, 0
    BSF	PORTA, 1
    BSF	PORTA, 2
    GOTO Restore//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="FindPW: Finds PW and clears if Zero">
FindPW:
    MOVF    PERIOD, 0
    SUBWF   PULSESPACE1, 0
    BTFSC   STATUS, 2	;Is it zero?
    BCF	    PORTA, 0	;Yes
    MOVF    PERIOD, 0	;No
    SUBWF   PULSESPACE2, 0
    BTFSC   STATUS, 2	;Is it zero?
    BCF	    PORTA, 1	;Yes
    MOVF    PERIOD, 0	;No
    SUBWF   PULSESPACE3, 0
    BTFSC   STATUS, 2	;Is it zero?
    BCF	    PORTA, 2	;Yes
    GOTO    Restore	;No
    //</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Recieving: Moves data to W and handles Read/Write">
Recieving:
    MOVF SSPBUF, 0	;Clear the I2C Buffer, and move its contents to W
    BCF PIR1, 3		;Clear the I2C Flag
    BTFSC SSPBUF, 0	;Is it Reading?
    GOTO Restore	;Yes, Don't care
    GOTO Write		;No
    GOTO Restore	;Redunandt exit//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Write: Handles Address/Data">
Write:
    BSF	STATUS,5	;Bank 1
    BTFSS SSPSTAT, 5	;Is it the Address?
    GOTO Restore	;Yes
    BCF	STATUS, 5	;No, Bank 0
    MOVWF DATASAVE	;Move W from Recieving into a Save
    BTFSC DATASAVE, 7	;Is it servo1 address? 
    CALL Servo1		;Yes
    BTFSC DATASAVE, 6	;Is it servo2 address?
    CALL Servo2		;Yes
    BTFSC DATASAVE, 5	;Is it servo3 address?
    CALL Servo3		;Yes
    BSF STATUS, 5	;Bank 1
    BTFSC SSPSTAT, 4	;Is there a stop bit?
    GOTO Restore	;Yes
    BCF	SSPCON2, 5	;No, Initiate ACK sequence
    BSF	SSPCON2, 4
    GOTO Restore//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Servo1-3: sets respective PS's">
Servo1:
    CALL WeighBits
    MOVWF PULSESPACE1
    RETURN
    
Servo2:
    CALL WeighBits
    MOVWF PULSESPACE2
    RETURN
    
Servo3:
    CALL WeighBits
    MOVWF PULSESPACE3
    RETURN//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="WeightBits: Takes data weights it and finds a value within a look up table">
WeighBits:
    MOVLW 0x00
    BTFSC DATASAVE, 0	;Weight bit 0
    ADDLW 0x02	
    BTFSC DATASAVE, 1	;Weight bit 1
    ADDLW 0x04
    BTFSC DATASAVE, 2	;Weight bit 2
    ADDLW 0x08
    BTFSC DATASAVE, 3	;Weight bit 3
    ADDLW 0x10
    BTFSC DATASAVE, 4	;Weight bit 4
    ADDLW 0x20
    ADDWF PCL, 1	;Use weighted bits to find a value in look-up table below
    MOVLW   170
    RETURN
    MOVLW   170
    RETURN
    MOVLW   171
    RETURN
    MOVLW   171
    RETURN
    MOVLW   172
    RETURN
    MOVLW   172
    RETURN
    MOVLW   173
    RETURN
    MOVLW   173
    RETURN
    MOVLW   174
    RETURN
    MOVLW   174
    RETURN
    MOVLW   175
    RETURN
    MOVLW   176
    RETURN
    MOVLW   177
    RETURN
    MOVLW   178
    RETURN
    MOVLW   179
    RETURN
    MOVLW   180
    RETURN
    MOVLW   181
    RETURN
    MOVLW   182
    RETURN
    MOVLW   183
    RETURN
    MOVLW   184
    RETURN
    MOVLW   185
    RETURN
    MOVLW   186
    RETURN
    MOVLW   187
    RETURN
    MOVLW   188
    RETURN
    MOVLW   189
    RETURN
    MOVLW   190
    RETURN
    MOVLW   191
    RETURN
    MOVLW   192
    RETURN
    MOVLW   193
    RETURN
    MOVLW   194
    RETURN
    MOVLW   195
    RETURN
    MOVLW   195
    RETURN
    MOVLW   195
    RETURN
    MOVLW   195
    RETURN
    MOVLW   195
    RETURN//</editor-fold>
    
END