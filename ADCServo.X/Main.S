
;Brandon Barrera
;RCET 3375
;Tim Rossiter
;Servo Controller
;10/15/2025
    
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
 
ADCRESULT EQU 0x20
ENABLEPULSE EQU 0x21
PW EQU 0x22
PS EQU 0x23
PERIOD EQU 0x24
 
Start:
    BSF STATUS, 5    ;Bank 3 select
    BSF STATUS, 6
    MOVLW 0x01
    MOVWF ANSEL	     ;Configures analog, Port A
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
    MOVLW 0x64
    MOVWF PR2	    ;Makes TMR2 flag at 100
    CLRF ADCON1	    ;Sets reference voltage for ADC
    CLRF PCON	    ;Power Config, Port A
    MOVLW 0x02
    MOVWF PIE1	    ;Preriphrial interrupt enables
    MOVLW 0x00	    
    MOVWF WPUB      ;Control Weak pull ups, Port B
    MOVLW 0x00
    MOVWF IOCB      ;Inturruption when changing bits, Port B
    CLRF PSTRCON    ;pulse timer control, Port C
    MOVLW 0x01
    MOVWF TRISA	    ;Configure associated port I/O, Port A
    MOVLW 0x00
    MOVWF TRISB	    ;Same, Port B
    MOVLW 0x00
    MOVWF TRISC	    ;Same, Port C
    ;--------------------------------------
    BCF STATUS, 5   ;Bank 0 select
    MOVLW 0x04
    MOVWF T2CON	    ;Sets Post Scaler to 1:1, turns TMR2 on, and sets pre scaler to 1:1
    MOVLW 0x41
    MOVF ADCON0	    ;Controls Analog to Digital converter, Port A
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
    MOVLW 0xC8
    MOVWF PERIOD    ;sets period time 20mS
    MOVLW 0xC0
    MOVWF INTCON    ;Configures interupts, Port B
    ;--------------------------------------
    
;Main loop code
Main:
    BCF STATUS, 5   ;Bank 0
    BCF STATUS, 6   
    BSF ADCON0, 1   ;Enables Conversion to begin
    BSF ADCON0, 0
Test:
    BTFSC ADCON0,1  ;Check To see if done
    GOTO Test	    ;No? wait
    MOVF ADRESH, 0  ;Yes display result
    MOVWF ADCRESULT
    GOTO Main	    ;do it again

InterruptHandler:
    BCF PIR1, 1		    ;Clear Timer 2 flag
    BTFSC ENABLEPULSE, 0    ;Test to see if enabel (PW)
    GOTO WaitPW
    BTFSC ENABLEPULSE, 1    ;Test to see if enable (PS)
    GOTO WaitPS
    MOVLW 0x01	
    MOVWF ENABLEPULSE	    ;Enable PW
    CLRF ADCRESULT
    BTFSC ADRESH,3
    CALL PLUS0
    BTFSC ADRESH,4
    CALL PLUS1
    BTFSC ADRESH,5
    CALL PLUS2
    BTFSC ADRESH,6
    CALL PLUS3
    BTFSC ADRESH,7
    CALL PLUS4
    MOVF ADCRESULT, 0	    ;Load value for Table
    GOTO LookUpTable	   
    RETFIE		    ;Should never reach here but Safety
    
PLUS0:
    MOVLW 0x03
    ADDWF ADCRESULT,1
    RETURN
    
PLUS1:
    MOVLW 0x06
    ADDWF ADCRESULT,1
    RETURN
    
PLUS2:
    MOVLW 0x0C
    ADDWF ADCRESULT,1
    RETURN
    
PLUS3:
    MOVLW 0x18
    ADDWF ADCRESULT,1
    RETURN
    
PLUS4:
    MOVLW 0x30
    ADDWF ADCRESULT,1
    RETURN
    
WaitPW:
    BSF PORTC, 0
    DECFSZ PW		    ;Wait for its alloted time
    RETFIE
    MOVLW 0x02
    MOVWF ENABLEPULSE	    ;Enable PS
    RETFIE
    
WaitPS:
    BCF PORTC, 0
    DECFSZ PS
    RETFIE
    CLRF ENABLEPULSE
    CLRF PORTC
    RETFIE
    
LookUpTable:
    CLRF ADCRESULT
    ADDWF PCL, 1
    MOVLW 0x05
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x05
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x06
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x07
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x07
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x08
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x09
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x09
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x0A
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x0B
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x0B
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x0C
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x0D
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x0D
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x0E
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x0F
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x0F
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x10
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x11
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x11
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x12
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x13
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x13
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x14
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x15
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x15
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x16
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x17
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x17
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x18
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x19
    CALL TIMERADJ
    GOTO InterruptHandler
    MOVLW 0x19
    CALL TIMERADJ
    GOTO InterruptHandler
    
TIMERADJ:
    MOVWF PW		    ;Set to 2.5mS
    MOVF PW, 0
    SUBWF PERIOD, 0	    ;Takes 20mS - PW and makes it PS
    MOVWF PS
    RETURN
    
END