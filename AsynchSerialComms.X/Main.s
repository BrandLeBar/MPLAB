
;Brandon Barrera
;RCET 3375
;Tim Rossiter
;EEPROM
;11/04/2025
    
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

PERIOD EQU 0x20 
WSAVE EQU 0x21
BANKSAVE EQU 0x22
WRITETRACKER EQU 0x23
CURRENTADRESS EQU 0x24
MODESEL EQU 0x25
COUNT1 EQU 0x26
COUNT2 EQU 0x27
COUNT3 EQU 0x28
 
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
    MOVLW 0x00	    
    MOVWF WPUB      ;Control Weak pull ups, Port B
    MOVLW 0x00
    MOVWF IOCB      ;Inturruption when changing bits, Port B
    CLRF PSTRCON    ;pulse timer control, Port C
    MOVLW 0x02
    MOVWF PIE1	    ;Preriphrial interrupt enables
    MOVLW 0x07
    MOVWF TRISA	    ;Configure associated port I/O, Port A
    MOVLW 0x0F
    MOVWF TRISB	    ;Same, Port B
    MOVLW 0x00
    MOVWF TRISC	    ;Same, Port C
    ;--------------------------------------
    BCF STATUS, 5   ;Bank 0 select
    MOVLW 0xFA
    MOVWF PR2	    ;Makes TMR2 flag at 250
    MOVLW 0x4E
    MOVWF T2CON	    ;Sets Post Scaler to 1:10, turns TMR2 on, and sets pre scaler to 1:1
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
    MOVLW 0x19
    MOVWF PERIOD
    BCF PIR1, 1	    ;Clears TMR2 flag
    MOVLW 0x0B
    MOVWF CURRENTADRESS
    CLRF WRITETRACKER
    MOVLW 0xC0
    MOVWF INTCON    ;Configures interupts, Port B
    ;--------------------------------------
    
Main:		
    BTFSS PORTA, 0	;Is Start pressed?
    CALL BeginRecord	;Yes start recording 
    BTFSS PORTA, 2	;Is review pressed?
    BSF MODESEL, 0	;Set interrupt mode: Review
    ;GOTO Display	;Yes display
    GOTO Main		;No scan again
    
Display:
    CALL Read		;Read value from EEPROM
    MOVWF PORTC		;Display value on Dot matrix
    GOTO Main		;Do it again
    
;<editor-fold defaultstate="collapsed" desc="Begin Recording">
BeginRecord:
    BCF INTCON, 7	;Disables interrupts
    BCF T2CON, 2	;Disables Timer 2
    MOVLW 0x0B
    MOVWF WRITETRACKER	;Sets Ability to write at 10
OUTPUT:
    MOVWF PORTC
    MOVF PORTC, 0
    CALL Write		;Write W to EEPROM
    MOVF WRITETRACKER, 0
    CALL Read
    
Recording:
    BTFSS PORTA, 1	;Is stop pressed?
    GOTO ReturnTime	;Yes, return
    //<editor-fold defaultstate="collapsed" desc="Scan Keypad">
Keypad:
    ;Enable the first row--------------------------------
    CALL Delay
    MOVLW 0x10       ;Choose Row *-0-#-D
    MOVWF PORTB      ;Enable Row 4
    CALL Delay
    MOVLW 0x46       ;Preload F for display
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or F on keypad
    GOTO OUTPUT      ;Display F
    CALL Delay
    MOVLW 0x45       ;Preload E for display
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or E on keypad
    GOTO OUTPUT      ;Display E
    CALL Delay
    MOVLW 0x44       ;Preload D for display
    BTFSC PORTB, 2   ;Check bit 2 of PORTB or D on keypad
    GOTO OUTPUT      ;Display D
    CALL Delay
    MOVLW 0x43       ;Preload C for display 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or C on keypad
    GOTO OUTPUT      ;Display C
    CALL Delay
    ;Enable the second row--------------------------------
    MOVLW 0x20       ;Choose Row 7-8-9-C
    MOVWF PORTB      ;Enable Row 3
    CALL Delay
    MOVLW 0x42       ;Preload B for display
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or B on keypad
    GOTO OUTPUT      ;Display B
    CALL Delay
    MOVLW 0x41       ;Preload A for display
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or A on keypad
    GOTO OUTPUT      ;Display A
    CALL Delay
    MOVLW 0x39       ;Preload 9 for display
    BTFSC PORTB, 2   ;Check bit 2 of PORTB or 9 on keypad
    GOTO OUTPUT      ;Display 9
    CALL Delay
    MOVLW 0x38       ;Preload 8 for display 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or 8 on keypad
    GOTO OUTPUT      ;Display 8
    CALL Delay
    ;Enable the third row-------------------------------
    MOVLW 0x40       ;Choose Row 4-5-6
    MOVWF PORTB      ;Enable Row 2
    CALL Delay
    MOVLW 0x37       ;Preload 7 for display
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or 7 on keypad
    GOTO OUTPUT      ;Display 7
    CALL Delay
    MOVLW 0x36	     ;Preload 6 for display
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or 6 on keypad
    GOTO OUTPUT      ;Diplay 6
    CALL Delay
    MOVLW 0x35       ;Preload 5 for display
    BTFSC PORTB, 2   ;Check bit 2 of PORTB or 5 on keypad
    GOTO OUTPUT      ;Display 5
    CALL Delay
    MOVLW 0x34       ;Preload 4 for display 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or 4 on keypad
    GOTO OUTPUT      ;Display 4
    CALL Delay
    ;Enable the fourth row-------------------------------
    MOVLW 0x80       ;Choose Row 1-2-3
    MOVWF PORTB      ;Enable Row 3
    CALL Delay
    MOVLW 0x33       ;Preload 3 for display
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or 3 on keypad
    GOTO OUTPUT      ;Display 3
    CALL Delay
    MOVLW 0x32	     ;Preload 2 for display
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or 2 on keypad
    GOTO OUTPUT      ;Diplay 2
    CALL Delay
    MOVLW 0x31       ;Preload 1 for display
    BTFSC PORTB, 2  ;Check bit 2 of PORTB or 1 on keypad
    GOTO OUTPUT      ;Display 1
    CALL Delay
    MOVLW 0x30       ;Preload 0 for display 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or 0 on keypad
    GOTO OUTPUT      ;Display 0 
    CALL Delay//</editor-fold>		;No, scan keypad
    MOVLW 0x00		
    XORWF WRITETRACKER, 0 
    BTFSS STATUS, 2	;Are there any writes left?
    GOTO Recording	;Yes, continue recording
ReturnTime:		;No, return
    BSF INTCON, 7	;Enables interrupts
    BSF T2CON, 2	;Enables Timer 2
    BCF PIR1, 1		;Clears timer 2 flag
    RETURN		;Do it again</editor-fold>
    
//<editor-fold defaultstate="collapsed" desc="Read EEPROM">
Read:
    BCF	    INTCON, 7	     ; Disable Interrup
    MOVF    CURRENTADRESS, 0 ; (Optional) Load desired address into Wts
    BCF	    STATUS, 5        ; Select Bank 2 with EEADR
    BSF	    STATUS, 6
    MOVWF   EEADR            ; Store EEPROM address
    BSF	    STATUS, 5        ; Select Bank 3 with EECON1
    BSF	    STATUS, 6
    BCF     EECON1, 7	     ; Point to DATA memory (not Program memory)
    BSF     EECON1, 0        ; Initiate EEPROM read
WaitRead:
    BTFSC   EECON1, 0	     ; Checks RD
    GOTO    WaitRead
    BCF	    STATUS, 5        ; Select Bank 2 with EEDATA
    BSF	    STATUS, 6
    MOVF    EEDATA, 0        ; Move EEPROM data into W register
    BCF     STATUS, 6	     ; Return to Bank 0 (safe default)
    BSF	    INTCON, 7	     ; Re-Enable Interrupts
    RETURN//</editor-fold>
    
//<editor-fold defaultstate="collapsed" desc="Write EEPROM">
Write:
    BCF	    STATUS, 5        ; Select Bank 2 with EEADR
    BSF	    STATUS, 6
    MOVWF   EEDATA           ; Store data
    BCF	    STATUS, 6	     ; Bank 0
    MOVLW   0x00
    XORWF   CURRENTADRESS, 0
    BTFSC   STATUS, 2
    RETURN
    MOVF    WRITETRACKER, 0 ; Load EEPROM address
    BSF	    STATUS, 6	     ; Bank 2
    MOVWF   EEADR            ; Store address
    BSF	    STATUS, 5        ; Select Bank 3 with EECON1
    BSF	    STATUS, 6
    BCF     EECON1, 7        ; Point to Data memory (not Program)
    BSF     EECON1, 2	     ; Enable writes
    BCF     INTCON, 7	     ; Disable global interrupts
WaitGIEClear:
    BTFSC   INTCON, 7	     ; Ensure interrupts are off
    GOTO    WaitGIEClear
    MOVLW   0x55
    MOVWF   EECON2
    MOVLW   0xAA
    MOVWF   EECON2
    BSF     EECON1, 1	     ; Begin write
    BSF     INTCON, 7        ; Enable global interrupts
Wait:
    BTFSC   EECON1, 1	     ; Checks WR
    GOTO    Wait 
    BCF     EECON1, 2	     ; Disable writes
Wait1:
    BTFSC   EECON1, 1	     ; Checks WR again...
    GOTO    Wait1
    BCF	    PIR2, 4	     ; Clear EEPROM write complete flag
    BCF     STATUS, 5	     ; Return to Bank 0
    BCF     STATUS, 6
    DECF    WRITETRACKER, 1
    RETURN//</editor-fold>
    
InterruptHandler:
    //<editor-fold defaultstate="collapsed" desc="Save Bank & W">
    MOVWF WSAVE		;"
    MOVF STATUS, 0	;Save Bank & W
    MOVWF BANKSAVE	;"//</editor-fold>
    BCF PIR1, 1		;Clear TMR2IF
    DECFSZ PERIOD	;Wait for 1 Sec
    GOTO Restore	;Leave
    MOVLW 0x19		
    MOVWF PERIOD	;Reset timer
    BTFSC MODESEL, 0	;Is it in review mode?
    GOTO Review		;Yes
    MOVLW 0x00		;No
    XORWF PORTC, 0
    BTFSS STATUS, 2	;Is port c 00?
    CALL Fix		;No
    BCF STATUS, 2	;Yes
    MOVLW 0x53	
    XORWF PORTC, 0	
    BTFSS STATUS, 2	;Is port c "S"?
    CALL FixS		;No
    MOVLW 0x53		;Yes
    XORWF PORTC, 1	;Toggle S
    //<editor-fold defaultstate="collapsed" desc="Restore Bank & W">
Restore:
    MOVF BANKSAVE, 0	;"
    MOVWF STATUS	;Restore Bank & W
    MOVF WSAVE, 0	;"
    RETFIE//</editor-fold>
    
;<editor-fold defaultstate="collapsed" desc="Fix only gets here if not 00 and returns if S">
Fix:

    BCF STATUS, 2	;Clear zero bit
    MOVLW 0x53	
    XORWF PORTC, 0	
    BTFSC STATUS, 2	;Is port c "S"
    RETURN		;Yes
    MOVLW 0x53		;No
    MOVWF PORTC		;Make it "S"
    RETURN;</editor-fold>
    
;<editor-fold defaultstate="collapsed" desc="FixS only gets here if not S and returns if 00">
FixS:;

    BCF STATUS, 2	;Clear zero bit
    MOVLW 0x00	
    XORWF PORTC, 0	
    BTFSC STATUS, 2	;Is port c 00
    RETURN		;Yes
    MOVLW 0x00		;No
    MOVWF PORTC		;Make it 00
    RETURN;</editor-fold>
    
;<editor-fold defaultstate="collapsed" desc="Review Mode">
Review:
    MOVF CURRENTADRESS, 0
    CALL Read
    MOVWF PORTC
    DECF CURRENTADRESS, 1
    MOVLW 0x00
    XORWF CURRENTADRESS, 0
    BTFSS STATUS, 2
    GOTO Restore
    MOVLW 0x0B
    MOVWF CURRENTADRESS
    CLRF MODESEL
    GOTO Restore;</editor-fold>
    
;<editor-fold defaultstate="collapsed" desc="Small Delay">
Delay:
    MOVLW 0x14
    MOVWF COUNT3      ;Loads amount of times loop3 is repeated
Loop3:
    MOVLW 0x14
    MOVWF COUNT2     ;Loads amount of times loop2 is repeated
Loop2:
    MOVLW 0x19
    MOVWF COUNT1     ;Loads amount of times loop1 is repeated
Loop1:
    DECFSZ COUNT1
    GOTO Loop1
    DECFSZ COUNT2
    GOTO Loop2
    DECFSZ COUNT3
    GOTO Loop3
    RETURN;</editor-fold>
    
END