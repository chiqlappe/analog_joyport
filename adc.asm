
;-------------------------------
; PC-8001用 ADC (MCP3004) 制御プログラム
; 2024/10/21
; x.com/chiqlappe
;-------------------------------

ANALOG_PORT	equ	$8C		;$8D~$8Fは$8Cのイメージ
ADC_SCK		equ	0		;"SCK"のビット番号
ADC_DI		equ	1		;"DI"のビット番号
ADC_CS		equ	2		;"CS"のビット番号
;
ADC_DO		equ	4		;"DO"のビット番号
PB0		equ	5		;"PB0"のビット番号 (デジタル入力0)
PB1		equ	6		;"PB1"のビット番号 (デジタル入力1)
;
ADC_START	equ	%00000001	;受信開始信号のスタートビット
ADC_MODE	equ	%00000010	;"single-ended mode"を使用
ADC_CH0		equ	%00000000 | ADC_START | ADC_MODE	;チャンネル0の受信開始信号 LSBから5ビット送信される
ADC_CH1		equ	%00010000 | ADC_START | ADC_MODE	;チャンネル1の受信開始信号
ADC_CH2		equ	%00001000 | ADC_START | ADC_MODE	;チャンネル2の受信開始信号
ADC_CH3		equ	%00011000 | ADC_START | ADC_MODE	;チャンネル3の受信開始信号



	org	$C000

	JP	ADC.INI			;ADCの初期化
	JP	USR_RECV		;サンプリング結果の読み出し


;USR命令用
;ADCからサンプリング結果を読み出す
;引数のエラーチェックは行わないことに注意
;USR命令の引数=チャンネル番号+受信ビット数*256
;USR命令の戻り値=受信データ
;チャンネル番号 0~3
;受信ビット数 1~8
;-------------------------------
USR_RECV:
	CP	2
	RET	NZ			;引数が整数でなければ終了

	PUSH	HL			;FAC-3

	LD	A,(HL)			;A=チャンネル番号{0~3}
	INC	HL
	LD	D,(HL)			;D=受信ビット数{1~8}

	LD	HL,.TBL
	ADD	A,L
	LD	L,A
	JR	NC,.L1
	INC	H
.L1:	LD	E,(HL)			;E=受信開始信号
	CALL	ADC.RECV		;in D,E out A=受信データ

	POP	HL			;FAC-3
	LD	(HL),A
	INC	HL
	LD	(HL),0
	RET

	;受信開始信号テーブル
.TBL:	db	ADC_CH0, ADC_CH1, ADC_CH2, ADC_CH3



;A/Dコンバータドライバ (MCP3004)
;-------------------------------
ADC:

	;ADCの初期化
.INI:	LD	A,(1<<ADC_SCK)+(1<<ADC_CS) ;CSを"HI"->"LOW"にする(重要)
	OUT	(ANALOG_PORT),A
	LD	A,1<<ADC_SCK
	OUT	(ANALOG_PORT),A
	;JR	.CLOCK			;SCKを確実に"HI"にする

	;ADCを１クロック進める
	;in	A=直前にOUTした値
.CLOCK:	AND	~(1<<ADC_SCK)		;SCK="LOW"
	OUT	(ANALOG_PORT),A
	OR	1<<ADC_SCK		;SCK="HI"
	OUT	(ANALOG_PORT),A
	RET

	;ADCからデータを受信する
	;in	E=受信開始信号(bit0=start,bit1=SGL,bit2=D2,bit3=D1,bit4=D0)
	;	D=受信するビット数{1~8}
	;out	A=受信データ
.RECV:	LD	A,1<<ADC_SCK		;SCK="HI",CS="LOW"
	OUT	(ANALOG_PORT),A		;チップセレクトを有効にする

	LD	B,5			;受信開始信号のビット数
.L1:	RR	E			;CY<-bit0
	LD	A,1<<ADC_SCK		;SCK="HI",CS="LOW",DI="LOW"
	JR	NC,.L4
	OR	1<<ADC_DI		;DI="HI"
.L4:	OUT	(ANALOG_PORT),A		;受信開始信号を送信する
	CALL	.CLOCK
	DJNZ	.L1

	CALL	.CLOCK			;サンプリングのために1クロック待つ
	CALL	.CLOCK			;送られてきたNull Bitを捨てる

	LD	B,D			;受信するビット数
	LD	C,0			;受信データ格納用
	LD	E,1<<ADC_DO		;読み出し用ビットマスク
.L2:	CALL	.CLOCK			;1クロック待つ
	IN	A,(ANALOG_PORT)		;サンプリング結果が上位ビットから1ビットずつ送られる
	AND	E			;必要なビット以外をマスクする
	JR	Z,.L3			;値が0ならCY=0
	SCF				;値が1ならCY=1
.L3:	RL	C			;Cレジスタを左回転してbit0にCYをセットする
	DJNZ	.L2			;これを受信するビット数だけくりかえす

	LD	A,(1<<ADC_SCK)+(1<<ADC_CS) ;SCK="HI",CS="HI"
	OUT	(ANALOG_PORT),A		;チップセレクトを無効にする

	LD	A,C			;Aレジスタに受信データをセットする
	RET

