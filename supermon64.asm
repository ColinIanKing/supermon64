; ********************************
; * SUPERMON+ 64 JIM BUTTERFIELD *
; * V1.2   AUGUST 20 1985        *
; *                              *
; * REFORMATTED FOR 64TASS       *
; * DEC 2016 BY J.B. LANGSTON    *
; ********************************

TMP0    =$C1
TMP2    =$C3
SATUS   =$90
FNLEN   =$B7
SADD    =$B9
FA      =$BA
FNADR   =$BB
NDX     =$C6
KEYD    =$0277
BKVEC   =$0316

        *= $0100

ACMD    .fill 1
LENGTH  .fill 1
MNEMW   .fill 3
SAVX    .fill 1
OPCODE  .fill 1
UPFLG   .fill 1
DIGCNT  .fill 1
INDIG   .fill 1
NUMBIT  .fill 1
STASH   .fill 2
U0AA0   .fill 10
U0AAE   =*
STAGE   .fill 30
ESTAGE  =*

        *= $0200

INBUFF  .fill 40
ENDIN   =*
PCH     .fill 1
PCL     .fill 1
SR      .fill 1
ACC     .fill 1
XR      .fill 1
YR      .fill 1
SP      .fill 1
STORE   .fill 2
CHRPNT  .fill 1
SAVY    .fill 1
U9F     .fill 1

SETMSG  =$FF90
SECOND  =$FF93
TKSA    =$FF96
LISTEN  =$FFB1
TALK    =$FFB4
SETLFS  =$FFBA
SETNAM  =$FFBD
ACPTR   =$FFA5
CIOUT   =$FFA8
UNTLK   =$FFAB
UNLSN   =$FFAE
CHKIN   =$FFC6
CLRCHN  =$FFCC
INPUT   =$FFCF
CHROUT  =$FFD2
LOAD    =$FFD5
SAVE    =$FFD8
STOP    =$FFE1
GETIN   =$FFE4

        *=$9519

SUPER   LDY #MSG4-MSGBAS
        JSR SNDMSG
        LDA SUPAD
        STA TMP0
        LDA SUPAD+1
        STA TMP0+1
        JSR CVTDEC
        LDA #0
        LDX #6
        LDY #3
        JSR NMPRNT
        JSR CRLF
        LDA LINKAD
        STA BKVEC
        LDA LINKAD+1
        STA BKVEC+1
        LDA #$80
        JSR SETMSG
        BRK

BREAK   LDX #$05
BSTACK  PLA   ;Y,X,A,SR,PCL,PCH
        STA PCH,X
        DEX 
        BPL BSTACK
        CLD
        TSX 
        STX SP
        CLI 

        ; [R]
DSPLYR  LDY #MSG2-MSGBAS
        JSR SNDCLR
        LDA #$3B
        JSR CHROUT
        LDA #$20
        JSR CHROUT
        LDA PCH
        JSR WRTWO
        LDY #1
DISJ    LDA PCH,Y
        JSR WRBYTE
        INY 
        CPY #7
        BCC DISJ

STRT    JSR CRLF
        LDX #0
        STX CHRPNT
SMOVE   JSR INPUT
        STA INBUFF,X
        INX 
        CPX #ENDIN-INBUFF
        BCS ERROR
        CMP #$0D
        BNE SMOVE
        LDA #0
        STA INBUFF-1,X
ST1     JSR GETCHR
        BEQ STRT
        CMP #$20
        BEQ ST1
S0      LDX #KEYTOP-KEYW
S1      CMP KEYW,X
        BEQ S2
        DEX
        BPL S1

        ; ERROR
ERROR   LDY #MSG3-MSGBAS
        JSR SNDMSG
        JMP STRT
S2      CPX #$13
        BCS LSV
        CPX #$0F
        BCS CNVLNK
        TXA
        ASL A
        TAX
        LDA KADDR+1,X
        PHA
        LDA KADDR,X
        PHA
        JMP GETPAR
LSV     STA SAVY
        JMP LD
CNVLNK  JMP CONVRT

        ; [X]
EXIT    JMP ($A002)

        ; [M]
DSPLYM  BCS DSPM11
        JSR COPY12
        JSR GETPAR
        BCC DSMNEW
DSPM11  LDA #$0B
        STA TMP0
        BNE DSPBYT
DSMNEW  JSR SUB12
        BCC MERROR
        LDX #3
DSPM01  LSR TMP0+1
        ROR TMP0
        DEX 
        BNE DSPM01
DSPBYT  JSR STOP
        BEQ DSPMX
        JSR DISPMEM
        LDA #8
        JSR BUMPAD2
        JSR SUBA1
        BCS DSPBYT
DSPMX   JMP STRT
MERROR  JMP ERROR

        ; [;]
ALTR    JSR COPY1P
        LDY #0
ALTR1   JSR GETPAR
        BCS ALTRX
        LDA TMP0
        STA SR,Y
        INY 
        CPY #$05
        BCC ALTR1
ALTRX   JMP STRT

        ; [>]
ALTM    BCS ALTMX
        JSR COPY12
        LDY #0
ALTM1   JSR GETPAR
        BCS ALTMX
        LDA TMP0
        STA (TMP2),Y
        INY 
        CPY #8
        BCC ALTM1
ALTMX   LDA #$91
        JSR CHROUT
        JSR DISPMEM
        JMP STRT

        ; [G]
GOTO    LDX SP
        TXS
GOTO2   JSR COPY1P
        SEI
        LDA PCH
        PHA
        LDA PCL
        PHA
        LDA SR
        PHA
        LDA ACC
        LDX XR
        LDY YR
        RTI

        ; [J]
JSUB    LDX SP
        TXS
        JSR GOTO2
        STY YR
        STX XR
        STA ACC
        PHP
        PLA
        STA SR
        JMP DSPLYR

        ; DISPLAY MEMORY
DISPMEM JSR CRLF
        LDA #">"
        JSR CHROUT
        JSR SHOWAD
        LDY #0
        BEQ DMEMGO
DMEMLP  JSR SPACE
DMEMGO  LDA (TMP2),Y
        JSR WRTWO
        INY 
        CPY #8
        BCC DMEMLP
        LDY #MSG5-MSGBAS
        JSR SNDMSG
        LDY #0
DCHAR   LDA (TMP2),Y
        TAX
        AND #$BF
        CMP #$22
        BEQ DDOT
        TXA
        AND #$7F
        CMP #$20
        TXA
        BCS DCHROK
DDOT    LDA #$2E
DCHROK  JSR CHROUT
        INY 
        CPY #8
        BCC DCHAR
        RTS 

        ; [C]
COMPAR  LDA #0
        .BYTE $2C

        ; [T]
TRANS   LDA #$80
        STA SAVY
        LDA #0
        STA UPFLG
        JSR GETDIF
        BCS TERROR
        JSR GETPAR
        BCC TOKAY
TERROR  JMP ERROR
TOKAY   BIT SAVY
        BPL COMPAR1
        ; COMPARE ADDS1,ADDS3
        LDA TMP2
        CMP TMP0
        LDA TMP2+1
        SBC TMP0+1
        BCS COMPAR1
        ; ADD ADDS2 TO ADDS1
        LDA STORE
        ADC TMP0
        STA TMP0
        LDA STORE+1
        ADC TMP0+1
        STA TMP0+1
        LDX #1
TDOWN   LDA STASH,X
        STA TMP2,X
        DEX 
        BPL TDOWN
        LDA #$80
        STA UPFLG
COMPAR1 JSR CRLF
        LDY #0
TCLOOP  JSR STOP
        BEQ TEXIT
        LDA (TMP2),Y
        BIT SAVY
        BPL COMPAR2
        STA (TMP0),Y
COMPAR2 CMP (TMP0),Y
        BEQ TMVAD
        JSR SHOWAD
TMVAD   BIT UPFLG
        BMI TDECAD
        INC TMP0
        BNE TINCOK
        INC TMP0+1
        BNE TINCOK
        JMP ERROR
TDECAD  JSR SUBA1
        JSR SUB21
        JMP TMOR
TINCOK  JSR ADDA2

TMOR    JSR SUB13
        BCS TCLOOP
TEXIT   JMP STRT

        ; [H]
HUNT    JSR GETDIF
        BCS HERROR
        LDY #0
        JSR GETCHR
        CMP #"'"
        BNE NOSTRH
        JSR GETCHR
        CMP #0
        BEQ HERROR
HPAR    STA STAGE,Y
        INY 
        JSR GETCHR
        BEQ HTGO
        CPY #ESTAGE-STAGE
        BNE HPAR
        BEQ HTGO
NOSTRH  JSR RDPAR
HLP     LDA TMP0
        STA STAGE,Y
        INY 
        JSR GETPAR
        BCS HTGO
        CPY #ESTAGE-STAGE
        BNE HLP
HTGO    STY SAVY
        JSR CRLF
HSCAN   LDY #0
HLP3    LDA (TMP2),Y
        CMP STAGE,Y
        BNE HNOFT
        INY 
        CPY SAVY
        BNE HLP3
        ; MATCH FOUND
        JSR SHOWAD
HNOFT   JSR STOP
        BEQ HEXIT
        JSR ADDA2
        JSR SUB13
        BCS HSCAN
HEXIT   JMP STRT
HERROR  JMP ERROR

        ; [LSV]
LD      LDY #1
        STY FA
        STY SADD
        DEY
        STY FNLEN
        STY SATUS
        LDA #>STAGE
        STA FNADR+1
        LDA #<STAGE
        STA FNADR
L1      JSR GETCHR
        BEQ LSHORT
        CMP #$20
        BEQ L1
        CMP #$22
        BNE LERROR
        LDX CHRPNT
L3      LDA INBUFF,X
        BEQ LSHORT
        INX 
        CMP #$22
        BEQ L8
        STA (FNADR),Y
        INC FNLEN
        INY 
        CPY #ESTAGE-STAGE
        BCC L3
LERROR  JMP ERROR
L8      STX CHRPNT
        JSR GETCHR
        BEQ LSHORT
        JSR GETPAR
        BCS LSHORT
        LDA TMP0
        STA FA
        JSR GETPAR
        BCS LSHORT
        JSR COPY12
        JSR GETPAR
        BCS LDADDR
        JSR CRLF
        LDX TMP0
        LDY TMP0+1
        LDA SAVY
        CMP #"S"
        BNE LERROR
        LDA #0
        STA SADD
        LDA #TMP2
        JSR SAVE
LSVXIT  JMP STRT
LSHORT  LDA SAVY
        CMP #"V"
        BEQ LOADIT
        CMP #"L"
        BNE LERROR
        LDA #0
LOADIT  JSR LOAD
        LDA SATUS
        AND #$10
        BEQ LSVXIT
        LDA SAVY
        BEQ LERROR
        LDY #MSG6-MSGBAS
        JSR SNDMSG
        JMP STRT
LDADDR  LDX TMP2
        LDY TMP2+1
        LDA #0
        STA SADD
        BEQ LSHORT

        ; [F]
FILL    JSR GETDIF
        BCS AERROR
        JSR GETPAR
        BCS AERROR
        JSR GETCHR
        BNE AERROR
        LDY #0
FILLP   LDA TMP0
        STA (TMP2),Y
        JSR STOP
        BEQ FSTART
        JSR ADDA2
        JSR SUB13
        BCS FILLP
FSTART  JMP STRT

        ; [A.]
ASSEM   BCS AERROR
        JSR COPY12
AGET1   LDX #0
        STX U0AA0+1
        STX DIGCNT
AGET2   JSR GETCHR
        BNE ALMOR
        CPX #0
        BEQ FSTART
ALMOR   CMP #$20
        BEQ AGET1
        STA MNEMW,X
        INX
        CPX #3
        BNE AGET2
ASQEEZ  DEX 
        BMI AOPRND
        LDA MNEMW,X
        SEC
        SBC #$3F
        LDY #$05
ASHIFT  LSR A
        ROR U0AA0+1
        ROR U0AA0
        DEY
        BNE ASHIFT
        BEQ ASQEEZ
AERROR  JMP ERROR
        ; GET THE OPERAND
AOPRND  LDX #2
ASCAN   LDA DIGCNT
        BNE AFORM1
        ; LOOK FOR MODE CHARS
        JSR RDVAL
        BEQ AFORM0
        BCS AERROR
        LDA #"$"
        STA U0AA0,X
        INX
        LDY #4
        LDA NUMBIT
        CMP #8
        BCC AADDR
        CPY DIGCNT
        BEQ AFILL0
AADDR   LDA TMP0+1
        BNE AFILL0
        LDY #2               ;ZERO PGE MODE
AFILL0  LDA #$30
AFIL0L  STA U0AA0,X
        INX
        DEY
        BNE AFIL0L
        ; GET FORMAT CHAR
AFORM0  DEC CHRPNT
AFORM1  JSR GETCHR
        BEQ AESCAN
        CMP #$20
        BEQ ASCAN
        STA U0AA0,X
        INX
        CPX #U0AAE-U0AA0
        BCC ASCAN
        BCS AERROR

AESCAN  STX STORE
        LDX #0
        STX OPCODE

ATRYOP  LDX #0
        STX U9F
        LDA OPCODE
        JSR INSTXX
        LDX ACMD
        STX STORE+1
        TAX
        LDA MNEMR,X
        JSR CHEKOP
        LDA MNEML,X
        JSR CHEKOP
        LDX #6
TRYIT   CPX #3
        BNE TRYMOD
        LDY LENGTH
        BEQ TRYMOD
TRYAD   LDA ACMD
        CMP #$E8
        LDA #$30
        BCS TRY4B
        JSR CHEK2B
        DEY
        BNE TRYAD
TRYMOD  ASL ACMD
        BCC UB4DF
        LDA CHAR1-1,X
        JSR CHEKOP
        LDA CHAR2-1,X
        BEQ UB4DF
        JSR CHEKOP
UB4DF   DEX
        BNE TRYIT
        BEQ TRYBRAN

TRY4B   JSR CHEK2B
        JSR CHEK2B
TRYBRAN LDA STORE
        CMP U9F
        BEQ ABRAN
        JMP BUMPOP
        ; CHECK BRANCH
ABRAN   LDY LENGTH
        BEQ A1BYTE
        LDA STORE+1
        CMP #$9D
        BNE OBJPUT
        LDA TMP0
        SBC TMP2
        TAX
        LDA TMP0+1
        SBC TMP2+1
        BCC ABBACK
        BNE SERROR
        CPX #$82
        BCS SERROR
        BCC ABRANX
ABBACK  TAY
        INY
        BNE SERROR
        CPX #$82
        BCC SERROR
ABRANX  DEX
        DEX
        TXA
        LDY LENGTH
        BNE OBJP2
OBJPUT  LDA TMP0-1,Y
OBJP2   STA (TMP2),Y
        DEY
        BNE OBJPUT
A1BYTE  LDA OPCODE
        STA (TMP2),Y
        JSR CRLF
        LDA #$91
        JSR CHROUT
        LDY #MSG7-MSGBAS
        JSR SNDCLR
        JSR DISLIN
        INC LENGTH
        LDA LENGTH
        JSR BUMPAD2
        ; STUFF KEYBOARD BUFFER
        LDA #"A"
        STA KEYD
        LDA #" "
        STA KEYD+1
        STA KEYD+6
        LDA TMP2+1
        JSR ASCTWO
        STA KEYD+2
        STX KEYD+3
        LDA TMP2
        JSR ASCTWO
        STA KEYD+4
        STX KEYD+5
        LDA #7
        STA NDX
        JMP STRT
SERROR  JMP ERROR

CHEK2B  JSR CHEKOP

CHEKOP  STX SAVX
        LDX U9F
        CMP U0AA0,X
        BEQ OPOK
        PLA
        PLA

BUMPOP  INC OPCODE
        BEQ SERROR
        JMP ATRYOP
OPOK    INC U9F
        LDX SAVX
        RTS

        ; [D]
DISASS  BCS DIS0AD
        JSR COPY12
        JSR GETPAR
        BCC DIS2AD
DIS0AD  LDA #$14
        STA TMP0
        BNE DISGO
DIS2AD  JSR SUB12
        BCC DERROR
DISGO   JSR CLINE
        JSR STOP
        BEQ DISEXIT
        JSR DSOUT1
        INC LENGTH
        LDA LENGTH
        JSR BUMPAD2
        LDA LENGTH
        JSR SUBA2
        BCS DISGO
DISEXIT JMP STRT
DERROR  JMP ERROR

DSOUT1  LDA #"."
        JSR CHROUT
        JSR SPACE

DISLIN  JSR SHOWAD
        JSR SPACE
        LDY #0
        LDA (TMP2),Y
        JSR INSTXX
        PHA
        LDX LENGTH
        INX
DSBYT   DEX 
        BPL DSHEX
        STY SAVY
        LDY #MSG8-MSGBAS
        JSR SNDMSG
        LDY SAVY
        JMP NXBYT
DSHEX   LDA (TMP2),Y
        JSR WRBYTE

NXBYT   INY 
        CPY #3
        BCC DSBYT
        PLA
        LDX #3
        JSR PROPXX
        LDX #6
PRADR1  CPX #3
        BNE PRADR3
        LDY LENGTH
        BEQ PRADR3
PRADR2  LDA ACMD
        CMP #$E8
        PHP
        LDA (TMP2),Y
        PLP
        BCS RELAD
        JSR WRTWO
        DEY
        BNE PRADR2
PRADR3  ASL ACMD
        BCC PRADR4
        LDA CHAR1-1,X
        JSR CHROUT
        LDA CHAR2-1,X
        BEQ PRADR4
        JSR CHROUT
PRADR4  DEX 
        BNE PRADR1
        RTS
RELAD   JSR UB64D
        CLC
        ADC #1
        BNE RELEND
        INX
RELEND  JMP WRADDR

UB64D   LDX TMP2+1
        TAY
        BPL RELC2
        DEX
RELC2   ADC TMP2
        BCC RELC3
        INX
RELC3   RTS 
        ; GET OPCODE MODE,LEN
INSTXX  TAY 
        LSR A
        BCC IEVEN
        LSR A
        BCS ERR
        CMP #$22
        BEQ ERR  ;KILL $89
        AND #$07
        ORA #$80
IEVEN   LSR A
        TAX
        LDA MODE,X
        BCS RTMODE
        LSR A
        LSR A
        LSR A
        LSR A
RTMODE  AND #$0F
        BNE GETFMT
ERR     LDY #$80
        LDA #0
GETFMT  TAX
        LDA MODE2,X
        STA ACMD
        AND #$03
        STA LENGTH
        TYA
        AND #$8F
        TAX
        TYA
        LDY #3
        CPX #$8A
        BEQ GTFM4
GTFM2   LSR A
        BCC GTFM4
        LSR A
GTFM3   LSR A
        ORA #$20
        DEY
        BNE GTFM3
        INY
GTFM4   DEY
        BNE GTFM2
        RTS

PROPXX  TAY 
        LDA MNEML,Y
        STA STORE
        LDA MNEMR,Y
        STA STORE+1
PRMN1   LDA #0
        LDY #$05
PRMN2   ASL STORE+1
        ROL STORE
        ROL A
        DEY
        BNE PRMN2
        ADC #$3F
        JSR CHROUT
        DEX
        BNE PRMN1
        JMP SPACE

        ; READ PARAMETER
RDPAR   DEC CHRPNT

GETPAR  JSR RDVAL
        BCS GTERR
        JSR GOTCHR
        BNE CKTERM
        DEC CHRPNT
        LDA DIGCNT
        BNE GETGOT
        BEQ GTNIL
CKTERM  CMP #$20
        BEQ GETGOT
        CMP #","
        BEQ GETGOT
GTERR   PLA 
        PLA
        JMP ERROR
GTNIL   SEC 
        .BYTE $24
GETGOT  CLC 
        LDA DIGCNT
        RTS

        ; READ VALUE
RDVAL   LDA #0
        STA TMP0
        STA TMP0+1
        STA DIGCNT
        TXA
        PHA
        TYA
        PHA
RDVMOR  JSR GETCHR
        BEQ RDNILK
        CMP #$20
        BEQ RDVMOR
        ; CHECK NUMERIC MODE
        LDX #3
GNMODE  CMP HIKEY,X
        BEQ GOTMOD
        DEX
        BPL GNMODE
        INX
        DEC CHRPNT
GOTMOD  LDY MODTAB,X
        LDA LENTAB,X
        STA NUMBIT

        ; GET DIGIT
NUDIG   JSR GETCHR
RDNILK  BEQ RDNIL
        SEC
        SBC #$30
        BCC RDNIL
        CMP #$0A
        BCC DIGMOR
        SBC #$07
        CMP #$10
        BCS RDNIL
DIGMOR  STA INDIG
        CPY INDIG
        BCC RDERR
        BEQ RDERR
        INC DIGCNT
        CPY #10
        BNE NODECM
        LDX #1
DECLP1  LDA TMP0,X
        STA STASH,X
        DEX
        BPL DECLP1
NODECM  LDX NUMBIT
TIMES2  ASL TMP0
        ROL TMP0+1
        BCS RDERR
        DEX
        BNE TIMES2
        CPY #10
        BNE NODEC2
        ASL STASH
        ROL STASH+1
        BCS RDERR
        LDA STASH
        ADC TMP0
        STA TMP0
        LDA STASH+1
        ADC TMP0+1
        STA TMP0+1
        BCS RDERR
NODEC2  CLC 
        LDA INDIG
        ADC TMP0
        STA TMP0
        TXA
        ADC TMP0+1
        STA TMP0+1
        BCC NUDIG
RDERR   SEC 
        .BYTE $24
RDNIL   CLC 
        STY NUMBIT
        PLA
        TAY
        PLA
        TAX
        LDA DIGCNT
        RTS

SHOWAD  LDA TMP2
        LDX TMP2+1

        ; PRINT ADDRESS
WRADDR  PHA 
        TXA
        JSR WRTWO
        PLA

WRBYTE  JSR WRTWO

SPACE   LDA #$20
        BNE FLIP

CHOUT   CMP #$0D
        BNE FLIP
CRLF    LDA #$0D
        BIT $13
        BPL FLIP
        JSR CHROUT
        LDA #$0A
FLIP    JMP CHROUT

FRESH   JSR CRLF
        LDA #$20
        JSR CHROUT
        JMP SNCLR

WRTWO   STX SAVX
        JSR ASCTWO
        JSR CHROUT
        TXA
        LDX SAVX
        JMP CHROUT

ASCTWO  PHA 
        JSR ASCII
        TAX
        PLA
        LSR A
        LSR A
        LSR A
        LSR A

ASCII   AND #$0F
        CMP #$0A
        BCC ASC1
        ADC #6
ASC1    ADC #$30
        RTS

        ; GET PREV CHAR
GOTCHR  DEC CHRPNT

        ; GET NEXT CHAR
GETCHR  STX SAVX
        LDX CHRPNT
        LDA INBUFF,X
        BEQ NOCHAR
        CMP #":"
        BEQ NOCHAR
        CMP #"?"
NOCHAR  PHP 
        INC CHRPNT
        LDX SAVX
        PLP
        RTS

        ; TRANSFR ADDR1 TO ADDR2
COPY12  LDA TMP0
        STA TMP2
        LDA TMP0+1
        STA TMP2+1
        RTS
        ; SUBTRACT ADDR2 FROM ADDR1
SUB12   SEC 
        LDA TMP0
        SBC TMP2
        STA TMP0
        LDA TMP0+1
        SBC TMP2+1
        STA TMP0+1
        RTS

SUBA1   LDA #1

        ; SUBTRACT FROM ADDR1
SUBA2   STA SAVX
        SEC
        LDA TMP0
        SBC SAVX
        STA TMP0
        LDA TMP0+1
        SBC #0
        STA TMP0+1
        RTS

        ; SUBTRACT 1 FROM ADDR3
SUB13   SEC 
        LDA STORE
        SBC #1
        STA STORE
        LDA STORE+1
        SBC #0
        STA STORE+1
        RTS

        ; ADD TO ADDR2
ADDA2   LDA #1

BUMPAD2 CLC 
        ADC TMP2
        STA TMP2
        BCC BUMPEX
        INC TMP2+1
BUMPEX  RTS 

        ; SUBTRACT 1 FROM ADDR2
SUB21   SEC 
        LDA TMP2
        SBC #1
        STA TMP2
        LDA TMP2+1
        SBC #0
        STA TMP2+1
        RTS

        ; COPY ADDR1 TO PC
COPY1P  BCS CPY1PX
        LDA TMP0
        LDY TMP0+1
        STA PCL
        STY PCH
CPY1PX  RTS 

GETDIF  BCS GDIFX
        JSR COPY12
        JSR GETPAR
        BCS GDIFX
        LDA TMP0
        STA STASH
        LDA TMP0+1
        STA STASH+1
        JSR SUB12
        LDA TMP0
        STA STORE
        LDA TMP0+1
        STA STORE+1
        BCC GDIFX
        CLC
        .BYTE $24
GDIFX   SEC 
        RTS

        ; [$+&%]
CONVRT  JSR RDPAR
        JSR FRESH
        LDA #"$"
        JSR CHROUT
        LDA TMP0
        LDX TMP0+1
        JSR WRADDR
        JSR FRESH
        LDA #"+"
        JSR CHROUT
        JSR CVTDEC
        LDA #0
        LDX #6
        LDY #3
        JSR NMPRNT
        JSR FRESH
        LDA #"&"
        JSR CHROUT
        LDA #0
        LDX #8
        LDY #2
        JSR PRINUM
        JSR FRESH
        LDA #"%"
        JSR CHROUT
        LDA #0
        LDX #$18
        LDY #0
        JSR PRINUM
        JMP STRT

CVTDEC  JSR COPY12
        LDA #0
        LDX #2
DECML1  STA U0AA0,X
        DEX
        BPL DECML1
        ; CONVERT TO DECIMAL
        LDY #16
        PHP
        SEI
        SED
DECML2  ASL TMP2
        ROL TMP2+1
        LDX #2
DECDBL  LDA U0AA0,X
        ADC U0AA0,X
        STA U0AA0,X
        DEX
        BPL DECDBL
        DEY
        BNE DECML2
        PLP
        RTS

PRINUM  PHA 
        LDA TMP0
        STA U0AA0+2
        LDA TMP0+1
        STA U0AA0+1
        LDA #0
        STA U0AA0
        PLA

        ; PRINT WITH ZERO SUPPR
NMPRNT  STA DIGCNT
        STY NUMBIT
DIGOUT  LDY NUMBIT
        LDA #0
ROLBIT  ASL U0AA0+2
        ROL U0AA0+1
        ROL U0AA0
        ROL A
        DEY
        BPL ROLBIT
        TAY
        BNE NZERO
        CPX #1
        BEQ NZERO
        LDY DIGCNT
        BEQ ZERSUP
NZERO   INC DIGCNT
        ORA #$30
        JSR CHROUT
ZERSUP  DEX 
        BNE DIGOUT
        RTS

        ; [@]
DSTAT   BNE CHGDEV
        LDX #8
        .BYTE $2C
CHGDEV  LDX TMP0
        CPX #4
        BCC IOERR
        CPX #32
        BCS IOERR
        STX TMP0
        LDA #0
        STA SATUS
        STA FNLEN
        JSR GETCHR
        BEQ INSTAT1
        DEC CHRPNT
        CMP #"$"
        BEQ DIRECT
        LDA TMP0
        JSR LISTEN
        LDA #$6F
        JSR SECOND
DCOMD   LDX CHRPNT
        INC CHRPNT
        LDA INBUFF,X
        BEQ INSTAT
        JSR CIOUT
        BCC DCOMD
INSTAT  JSR UNLSN
INSTAT1 JSR CRLF
        LDA TMP0
        JSR TALK
        LDA #$6F
        JSR TKSA
RDSTAT  JSR ACPTR
        JSR CHROUT
        CMP #$0D
        BEQ DEXIT
        LDA SATUS
        AND #$BF
        BEQ RDSTAT
DEXIT   JSR UNTLK
        JMP STRT
IOERR   JMP ERROR
DIRECT  LDA TMP0
        JSR LISTEN
        LDA #$F0
        JSR SECOND
        LDX CHRPNT
DIR2    LDA INBUFF,X
        BEQ DIR3
        JSR CIOUT
        INX
        BNE DIR2
DIR3    JSR UNLSN
        JSR CRLF
        LDA TMP0
        PHA
        JSR TALK
        LDA #$60
        JSR TKSA
        LDY #3
DIRLIN  STY STORE
DLINK   JSR ACPTR
        STA TMP0
        LDA SATUS
        BNE DREXIT
        JSR ACPTR
        STA TMP0+1
        LDA SATUS
        BNE DREXIT
        DEC STORE
        BNE DLINK
        JSR CVTDEC
        LDA #0
        LDX #6
        LDY #3
        JSR NMPRNT
        LDA #" "
        JSR CHROUT
DNAME   JSR ACPTR
        BEQ DMORE
        LDX SATUS
        BNE DREXIT
        JSR CHROUT
        CLC
        BCC DNAME
DMORE   JSR CRLF
        JSR STOP
        BEQ DREXIT
        JSR GETIN
        BEQ NOPAWS
PAWS    JSR GETIN
        BEQ PAWS
NOPAWS  LDY #2
        BNE DIRLIN
DREXIT  JSR UNTLK
        PLA
        JSR LISTEN
        LDA #$E0
        JSR SECOND
        JSR UNLSN
        JMP STRT

        ; PRINT AND CLEAR ROUTINES
CLINE   JSR CRLF
        JMP SNCLR
SNDCLR  JSR SNDMSG
SNCLR   LDY #$28
SNCLP   LDA #$20
        JSR CHROUT
        LDA #$14
        JSR CHROUT
        DEY
        BNE SNCLP
        RTS
SNDMSG  LDA MSGBAS,Y
        PHP
        AND #$7F
        JSR CHOUT
        INY
        PLP
        BPL SNDMSG
        RTS

MSGBAS  =*

MSG2    .BYTE $0D
        .TEXT "   PC  SR AC XR YR SP   V1.2"
        .BYTE $0D+$80
MSG3    .BYTE $1D,$3F+$80
MSG4    .TEXT "..SYS"
        .BYTE $20+$80
MSG5    .BYTE $3A,$12+$80
MSG6    .TEXT " ERRO"
        .BYTE "R"+$80
MSG7    .BYTE $41,$20+$80
MSG8    .TEXT "  "
        .BYTE $20+$80

        ; MODE TABLE... NYBBLE ORGANIZED
        ; 0=ERR  4=IMPLIED  8=ZER,X  C=ZER,Y
        ; 1=IMM  5=ACC      8=ABS,X  D=REL
        ; 2=ZER  6=(IND,X)  A=ABS,Y
        ; 3=ABS  7=(IND),Y  B=(IND)
MODE    .BYTE $40,$02,$45,$03
        .BYTE $D0,$08,$40,$09
        .BYTE $30,$22,$45,$33
        .BYTE $D0,$08,$40,$09
        .BYTE $40,$02,$45,$33
        .BYTE $D0,$08,$40,$09
        .BYTE $40,$02,$45,$B3
        .BYTE $D0,$08,$40,$09
        .BYTE $00,$22,$44,$33
        .BYTE $D0,$8C,$44,$00
        .BYTE $11,$22,$44,$33
        .BYTE $D0,$8C,$44,$9A
        .BYTE $10,$22,$44,$33
        .BYTE $D0,$08,$40,$09
        .BYTE $10,$22,$44,$33
        .BYTE $D0,$08,$40,$09
        .BYTE $62,$13,$78,$A9

MODE2   .BYTE $00,$21,$81,$82
        .BYTE $00,$00,$59,$4D
        .BYTE $91,$92,$86,$4A
        .BYTE $85,$9D

CHAR1   .BYTE $2C,$29,$2C
        .BYTE $23,$28,$24

CHAR2   .BYTE $59,$00,$58
        .BYTE $24,$24,$00

MNEML   .BYTE $1C,$8A,$1C,$23
        .BYTE $5D,$8B,$1B,$A1
        .BYTE $9D,$8A,$1D,$23
        .BYTE $9D,$8B,$1D,$A1
        .BYTE $00,$29,$19,$AE
        .BYTE $69,$A8,$19,$23
        .BYTE $24,$53,$1B,$23
        .BYTE $24,$53,$19,$A1
        .BYTE $00,$1A,$5B,$5B
        .BYTE $A5,$69,$24,$24
        .BYTE $AE,$AE,$A8,$AD
        .BYTE $29,$00,$7C,$00
        .BYTE $15,$9C,$6D,$9C
        .BYTE $A5,$69,$29,$53
        .BYTE $84,$13,$34,$11
        .BYTE $A5,$69,$23,$A0
MNEMR   .BYTE $D8,$62,$5A,$48
        .BYTE $26,$62,$94,$88
        .BYTE $54,$44,$C8,$54
        .BYTE $68,$44,$E8,$94
        .BYTE $00,$B4,$08,$84
        .BYTE $74,$B4,$28,$6E
        .BYTE $74,$F4,$CC,$4A
        .BYTE $72,$F2,$A4,$8A
        .BYTE $00,$AA,$A2,$A2
        .BYTE $74,$74,$74,$72
        .BYTE $44,$68,$B2,$32
        .BYTE $B2,$00,$22,$00
        .BYTE $1A,$1A,$26,$26
        .BYTE $72,$72,$88,$C8
        .BYTE $C4,$CA,$26,$48
        .BYTE $44,$44,$A2,$C8
        .BYTE $0D,$20,$20,$20
KEYW    .TEXT "ACDFGHJMRTX@.>;"
HIKEY   .TEXT "$+&%LSV"
KEYTOP  =*

        ; VECTORS
KADDR   .WORD ASSEM-1,COMPAR-1,DISASS-1,FILL-1
        .WORD GOTO-1,HUNT-1,JSUB-1,DSPLYM-1
        .WORD DSPLYR-1,TRANS-1,EXIT-1,DSTAT-1
        .WORD ASSEM-1,ALTM-1,ALTR-1

        ; MODULO NUMBER SYSTEMS
MODTAB  .BYTE $10,$0A,$08,02

        ; BITS PER NUMBER SYSTEM
LENTAB  .BYTE $04,$03,$03,$01
LINKAD  .WORD BREAK
SUPAD   .WORD SUPER