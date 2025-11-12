
; PIC16F883 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = XT		; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
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
PSECT resetVect,class=CODE,delta=2  
  GOTO Start
  
; Start of program 
PSECT code,class=CODE,delta=2

  
  
Start:
    ;Bank 3-----------------------------------------------------
    BSF   STATUS, 5  ;Go to bank 3
    BSF   STATUS, 6  ;Go to bank 3
    CLRF  ANSELH     ;Configures pin to I/O in digital or analog 
    CLRF  ANSEL      ;Configures pin to I/O in analog for port A
    CLRF  INTCON     ;Configures interupts
    MOVLW 0x80	     ;0000 0000
    MOVWF OPTION_REG ;Disables PORTB to use pullups 
    ;Bank 2-----------------------------------------------------
    BCF   STATUS, 5  ;Chang to bank 2
    CLRF  CM2CON1    ;Disable
    CLRF  CM1CON0    ;Disable
    CLRF  CM2CON0    ;Disable
    ;Bank 1-----------------------------------------------------
    BSF   STATUS, 5  ;Change to bank 1
    BCF   STATUS, 6  ;Change to bank 1
    MOVLW 0x00	     ;Sets W to all 0's
    MOVWF WPUB       ;Disables Weak pull ups
    CLRF  IOCB       ;Disables Inturruption when changing bits
    CLRF  PSTRCON    ;Disables pulse timer control
    MOVLW 0x01	     ;
    MOVWF TRISA	     ;Sets PORTA pin function
    MOVLW 0x0F	     ;
    MOVWF TRISB	     ;Sets PORTB pin function
    MOVLW 0x00	     ;
    MOVWF TRISC      ;Sets PORTC pin function
    CLRF  PCON       ;Power control for Brown out and on reset
    ;Bank 0-----------------------------------------------------
    BCF   STATUS, 5  ;Change to bank 0
    CLRF  CCP1CON    ;
    CLRF  CCP2CON    ;
    CLRF  SSPCON     ;
    CLRF  T1CON	     ;
    CLRF  ADCON0     ;Controls if analog to digital converter is on
    MOVLW 0x00	     ;
    MOVWF PORTA	     ;This is last so PORTA is known when powered on
    MOVLW 0x00	     ;
    MOVWF PORTB      ;Same for this port
    MOVLW 0x01	     ;
    MOVWF PORTC      ;Same for this port

    COUNT1 EQU 0x20  ;Holds loop1 repeat count
    COUNT2 EQU 0x21  ;Holds loop2 repeat count
    COUNT2TEMP EQU 0x22 ;Holds loop2 repeat count tempararily
    
Main:
    
    ;Enable the first row--------------------------------
    MOVLW 0x10       ;Choose Row *-0-#-D
    MOVWF PORTB      ;Enable Row 4
    MOVLW 0x2D       ;Preload F for display
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or F on keypad
    CALL LookUpTable      ;Display F
    MOVLW 0x2A       ;Preload E for display
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or E on keypad
    CALL LookUpTable      ;Display E
    MOVLW 0x27       ;Preload D for display
    BTFSC PORTB, 2   ;Check bit 2 of PORTB or D on keypad
    CALL LookUpTable      ;Display D
    MOVLW 0x24       ;Preload C for display 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or C on keypad
    CALL LookUpTable      ;Display C
    ;Enable the second row--------------------------------
    MOVLW 0x20       ;Choose Row 7-8-9-C
    MOVWF PORTB      ;Enable Row 3
    MOVLW 0x21       ;Preload B for display
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or B on keypad
    CALL LookUpTable      ;Display B
    MOVLW 0x1E       ;Preload A for display
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or A on keypad
    CALL LookUpTable      ;Display A
    MOVLW 0x1B       ;Preload 9 for display
    BTFSC PORTB, 2   ;Check bit 2 of PORTB or 9 on keypad
    CALL LookUpTable      ;Display 9
    MOVLW 0x18       ;Preload 8 for display 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or 8 on keypad
    CALL LookUpTable      ;Display 8
    ;Enable the third row-------------------------------
    MOVLW 0x40       ;Choose Row 4-5-6
    MOVWF PORTB      ;Enable Row 2
    MOVLW 0x15       ;Preload 7 for display
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or 7 on keypad
    CALL LookUpTable      ;Display 7
    MOVLW 0x12	     ;Preload 6 for display
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or 6 on keypad
    CALL LookUpTable      ;Diplay 6
    MOVLW 0x0F       ;Preload 5 for display
    BTFSC PORTB, 2   ;Check bit 2 of PORTB or 5 on keypad
    CALL LookUpTable      ;Display 5
    MOVLW 0x0C       ;Preload 4 for display 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or 4 on keypad
    CALL LookUpTable      ;Display 4
    ;Enable the fourth row-------------------------------
    MOVLW 0x80       ;Choose Row 1-2-3
    MOVWF PORTB      ;Enable Row 3
    MOVLW 0x09       ;Preload 3 for display
    BTFSC PORTB, 0   ;Check Bit 0 of PORTB or 3 on keypad
    CALL LookUpTable      ;Display 3
    MOVLW 0x06	     ;Preload 2 for display
    BTFSC PORTB, 1   ;Check Bit 1 of PORTB or 2 on keypad
    CALL LookUpTable      ;Diplay 2
    MOVLW 0x03       ;Preload 1 for display
    BTFSC PORTB, 2   ;Check bit 2 of PORTB or 1 on keypad
    CALL LookUpTable      ;Display 1
    MOVLW 0x00       ;Preload 0 for display 
    BTFSC PORTB, 3   ;Check bit 3 of PORTB or 0 on keypad
    CALL LookUpTable      ;Display 0
    
    GOTO  Main	     ;Now do it again

Delay:
    MOVF COUNT2,0
    MOVWF COUNT2TEMP
Loop2:
    MOVLW 0xA3	     ;decimal 163 A3
    MOVWF COUNT1     ;Move to register to be looped
    NOP		     ;To make a perfect 500uS
Loop1:
    DECFSZ COUNT1    ;Decrement until zero
    GOTO Loop1	     ;Skip if zero
    DECFSZ COUNT2TEMP    ;Decrement until zero
    GOTO Loop2	     ;Skip if zero
    RETURN	     ;Returns to line where called

Toggle:
    MOVLW 0x01	     ;decimal 1
    XORWF PORTA, 0   ;Flips any bits Xor'ed with W
    CALL  Delay      ;This is for 1KHz square wave
    MOVWF PORTC	     ;Sends result to be output
    GOTO Main
    
LookUpTable:
    ADDWF PCL, 1
    MOVLW 0x0A
    MOVWF COUNT2
    Return
    MOVLW 0x0B
    MOVWF COUNT2
    Return
    MOVLW 0x0C
    MOVWF COUNT2
    Return
    MOVLW 0x0D
    MOVWF COUNT2
    Return
    MOVLW 0x0E
    MOVWF COUNT2
    Return
    MOVLW 0x0F
    MOVWF COUNT2
    Return
    MOVLW 0x10
    MOVWF COUNT2
    Return
    MOVLW 0x20
    MOVWF COUNT2
    Return
    MOVLW 0x30
    MOVWF COUNT2
    Return
    MOVLW 0x40
    MOVWF COUNT2
    Return
    MOVLW 0x50
    MOVWF COUNT2
    Return
    MOVLW 0x60
    MOVWF COUNT2
    Return
    MOVLW 0x70
    MOVWF COUNT2
    Return
    MOVLW 0x80
    MOVWF COUNT2
    Return
    MOVLW 0x90
    MOVWF COUNT2
    Return
    MOVLW 0xA0
    MOVWF COUNT2
    Return
END