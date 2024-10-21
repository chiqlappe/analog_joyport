
;-------------------------------
; PC-8001�p ADC (MCP3004) ����v���O����
; 2024/10/21
; x.com/chiqlappe
;-------------------------------

ANALOG_PORT	equ	$8C		;$8D~$8F��$8C�̃C���[�W
ADC_SCK		equ	0		;"SCK"�̃r�b�g�ԍ�
ADC_DI		equ	1		;"DI"�̃r�b�g�ԍ�
ADC_CS		equ	2		;"CS"�̃r�b�g�ԍ�
;
ADC_DO		equ	4		;"DO"�̃r�b�g�ԍ�
PB0		equ	5		;"PB0"�̃r�b�g�ԍ� (�f�W�^������0)
PB1		equ	6		;"PB1"�̃r�b�g�ԍ� (�f�W�^������1)
;
ADC_START	equ	%00000001	;��M�J�n�M���̃X�^�[�g�r�b�g
ADC_MODE	equ	%00000010	;"single-ended mode"���g�p
ADC_CH0		equ	%00000000 | ADC_START | ADC_MODE	;�`�����l��0�̎�M�J�n�M�� LSB����5�r�b�g���M�����
ADC_CH1		equ	%00010000 | ADC_START | ADC_MODE	;�`�����l��1�̎�M�J�n�M��
ADC_CH2		equ	%00001000 | ADC_START | ADC_MODE	;�`�����l��2�̎�M�J�n�M��
ADC_CH3		equ	%00011000 | ADC_START | ADC_MODE	;�`�����l��3�̎�M�J�n�M��



	org	$C000

	JP	ADC.INI			;ADC�̏�����
	JP	USR_RECV		;�T���v�����O���ʂ̓ǂݏo��


;USR���ߗp
;ADC����T���v�����O���ʂ�ǂݏo��
;�����̃G���[�`�F�b�N�͍s��Ȃ����Ƃɒ���
;USR���߂̈���=�`�����l���ԍ�+��M�r�b�g��*256
;USR���߂̖߂�l=��M�f�[�^
;�`�����l���ԍ� 0~3
;��M�r�b�g�� 1~8
;-------------------------------
USR_RECV:
	CP	2
	RET	NZ			;�����������łȂ���ΏI��

	PUSH	HL			;FAC-3

	LD	A,(HL)			;A=�`�����l���ԍ�{0~3}
	INC	HL
	LD	D,(HL)			;D=��M�r�b�g��{1~8}

	LD	HL,.TBL
	ADD	A,L
	LD	L,A
	JR	NC,.L1
	INC	H
.L1:	LD	E,(HL)			;E=��M�J�n�M��
	CALL	ADC.RECV		;in D,E out A=��M�f�[�^

	POP	HL			;FAC-3
	LD	(HL),A
	INC	HL
	LD	(HL),0
	RET

	;��M�J�n�M���e�[�u��
.TBL:	db	ADC_CH0, ADC_CH1, ADC_CH2, ADC_CH3



;A/D�R���o�[�^�h���C�o (MCP3004)
;-------------------------------
ADC:

	;ADC�̏�����
.INI:	LD	A,(1<<ADC_SCK)+(1<<ADC_CS) ;CS��"HI"->"LOW"�ɂ���(�d�v)
	OUT	(ANALOG_PORT),A
	LD	A,1<<ADC_SCK
	OUT	(ANALOG_PORT),A
	;JR	.CLOCK			;SCK���m����"HI"�ɂ���

	;ADC���P�N���b�N�i�߂�
	;in	A=���O��OUT�����l
.CLOCK:	AND	~(1<<ADC_SCK)		;SCK="LOW"
	OUT	(ANALOG_PORT),A
	OR	1<<ADC_SCK		;SCK="HI"
	OUT	(ANALOG_PORT),A
	RET

	;ADC����f�[�^����M����
	;in	E=��M�J�n�M��(bit0=start,bit1=SGL,bit2=D2,bit3=D1,bit4=D0)
	;	D=��M����r�b�g��{1~8}
	;out	A=��M�f�[�^
.RECV:	LD	A,1<<ADC_SCK		;SCK="HI",CS="LOW"
	OUT	(ANALOG_PORT),A		;�`�b�v�Z���N�g��L���ɂ���

	LD	B,5			;��M�J�n�M���̃r�b�g��
.L1:	RR	E			;CY<-bit0
	LD	A,1<<ADC_SCK		;SCK="HI",CS="LOW",DI="LOW"
	JR	NC,.L4
	OR	1<<ADC_DI		;DI="HI"
.L4:	OUT	(ANALOG_PORT),A		;��M�J�n�M���𑗐M����
	CALL	.CLOCK
	DJNZ	.L1

	CALL	.CLOCK			;�T���v�����O�̂��߂�1�N���b�N�҂�
	CALL	.CLOCK			;�����Ă���Null Bit���̂Ă�

	LD	B,D			;��M����r�b�g��
	LD	C,0			;��M�f�[�^�i�[�p
	LD	E,1<<ADC_DO		;�ǂݏo���p�r�b�g�}�X�N
.L2:	CALL	.CLOCK			;1�N���b�N�҂�
	IN	A,(ANALOG_PORT)		;�T���v�����O���ʂ���ʃr�b�g����1�r�b�g��������
	AND	E			;�K�v�ȃr�b�g�ȊO���}�X�N����
	JR	Z,.L3			;�l��0�Ȃ�CY=0
	SCF				;�l��1�Ȃ�CY=1
.L3:	RL	C			;C���W�X�^������]����bit0��CY���Z�b�g����
	DJNZ	.L2			;�������M����r�b�g���������肩����

	LD	A,(1<<ADC_SCK)+(1<<ADC_CS) ;SCK="HI",CS="HI"
	OUT	(ANALOG_PORT),A		;�`�b�v�Z���N�g�𖳌��ɂ���

	LD	A,C			;A���W�X�^�Ɏ�M�f�[�^���Z�b�g����
	RET

