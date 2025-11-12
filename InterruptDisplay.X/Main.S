
;Brandon Barrera
;RCET 3375
;Tim Rossiter
;Interrupt 671 display
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
  GOTO InterrtuptHandler
  
;Start of program 
PSECT code,class=CODE,delta=2	;-Wl,-pcode=08h

 
Start:
    BSF STATUS, 5    ;Bank 3 select
    BSF STATUS, 6
    CLRF ANSEL	     ;Configures analog, Port A
    CLRF ANSELH      ;Configures analog, Port B
    MOVLW 0x00       
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
    MOVLW 0x81	    
    MOVWF WPUB      ;Control Weak pull ups, Port B
    MOVLW 0x81
    MOVWF IOCB       ;Inturruption when changing bits, Port B
    CLRF PSTRCON    ;pulse timer control, Port C
    MOVLW 0x00
    MOVWF TRISA	    ;Configure associated port I/O, Port A
    MOVLW 0x81
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
    MOVLW 0x00
    MOVWF PORTC	    ;Same
    COUNT1 EQU 0x20	;Holds loop1 repeat count
    COUNT2 EQU 0x21	;Holds loop2 repeat count
    COUNT3 EQU 0x22	;Holds loop3 repeat count
    COUNT1_TEMP EQU 0x23
    COUNT2_TEMP EQU 0x24
    COUNT3_TEMP EQU 0x25
    WSAVE  EQU 0x26	;Saves W 
    WSAVE1 EQU 0x27
    BANKSAVE EQU 0x28   ;Saves current bank data
    BANKSAVE1 EQU 0x29   ;Saves current bank data
    PCLATHSAVE EQU 0x2A
    PCLATHSAVE1 EQU 0x2B
    CLRF COUNT1		;Puts into Known State
    CLRF COUNT2		;Same
    CLRF COUNT3   	;Same
    BCF INTCON, 0
    MOVLW 0x88
    MOVWF INTCON      ;Configures interupts, Port B
    ;--------------------------------------
    
;Main loop code
Main:
    CLRF COUNT1_TEMP
    CLRF COUNT2_TEMP
    CLRF COUNT3_TEMP
    MOVLW 0x31
    MOVWF PORTC
    GOTO Main

InterrtuptHandler:
    BCF INTCON, 7
    MOVWF WSAVE
    MOVF  STATUS,0
    MOVWF BANKSAVE
    MOVF PCLATH, 0
    MOVWF PCLATHSAVE
    
    MOVF COUNT1, 0
    MOVWF COUNT1_TEMP
    MOVF COUNT2, 0 
    MOVWF COUNT2_TEMP
    MOVF COUNT3, 0
    MOVWF COUNT3_TEMP
    
    BCF INTCON, 0
    
    BTFSS PORTB, 7
    GOTO Interrupt7
    BTFSS PORTB, 0
    GOTO Interrupt6
    
    MOVF BANKSAVE,0
    MOVWF STATUS
    MOVF PCLATHSAVE, 0
    MOVWF PCLATH
    MOVF WSAVE,0
    BCF INTCON, 0
    RETFIE
        
Interrupt7:
    BCF INTCON, 7
    MOVWF WSAVE
    MOVF PCLATH, 0
    MOVWF PCLATHSAVE
    MOVF STATUS, 0
    MOVWF BANKSAVE
    
    BSF STATUS, 5	;Bank 1 
    BCF STATUS, 6
    BCF IOCB, 7	        ;Turn off 7 interrupts
    BCF STATUS, 5	;Bank 0
    BCF STATUS, 6
        
    MOVLW 0x37
    MOVWF PORTC
    
    CALL Delay
    
    BSF STATUS, 5	;Bank 1 
    BCF STATUS, 6
    BSF IOCB, 7		;Restore 7 interrupts
    BCF STATUS, 5	;Bank 0
    BCF STATUS, 6
    
    MOVLW 0x36
    MOVWF PORTC		;Display 6
    
    MOVF BANKSAVE, 0
    MOVWF STATUS
    MOVF PCLATHSAVE, 0
    MOVWF PCLATH
    BCF INTCON, 0
    MOVF COUNT1_TEMP, 0 
    MOVWF COUNT1
    MOVF COUNT2_TEMP, 0
    MOVWF COUNT2
    MOVF COUNT3_TEMP, 0
    MOVWF COUNT3
    MOVF WSAVE, 0
    RETFIE
    
Interrupt6:
    MOVWF WSAVE1	;Save W seperately from 7
    MOVF PCLATH, 0	
    MOVWF PCLATHSAVE1	;Save PCLATCH seperately from 7
    MOVF STATUS, 0
    MOVWF BANKSAVE1	;Save STATUS seperately from 7
    
    BCF INTCON, 0	;clear flag
    BSF STATUS, 5	;Bank 1 
    BCF STATUS, 6
    BCF IOCB, 0	        ;Turn off 6 interrupts
    BCF STATUS, 5	;Bank 0
    BCF STATUS, 6
    BSF INTCON, 7	;re-enable interrupts
    
    MOVLW 0x36
    MOVWF PORTC		;Display 6
    
    CALL Delay		;For 2 sec
    
    MOVLW 0x31
    MOVWF PORTC		;Display 1
    
    BCF INTCON, 7
    BSF STATUS, 5	;Bank 1 
    BCF STATUS, 6
    BSF IOCB, 0		;Restore 6 interrupts
    BCF STATUS, 5	;Bank 0
    BCF STATUS, 6
    MOVF BANKSAVE1, 0	;Restore STATUS
    MOVWF STATUS
    MOVF PCLATHSAVE1, 0	;Restore PCLATH
    MOVWF PCLATH
    MOVF WSAVE1, 0	;Restore W
    BCF INTCON, 0	;Clear Flag
    RETFIE
    
Delay:
    MOVLW 0x14
    MOVWF COUNT3
Loop3:
    MOVLW 0xCF
    MOVWF COUNT2
Loop2:
    MOVLW 0xA0
    MOVWF COUNT1
Loop1:
    DECFSZ COUNT1
    GOTO Loop1
    DECFSZ COUNT2
    GOTO Loop2
    DECFSZ COUNT3
    GOTO Loop3
    RETURN
    
END