.title CONMOD

;Copyright (C) 2025 TcbnErik
;
;This file is part of CONMOD.
;
;This program is free software: you can redistribute it and/or modify
;it under the terms of the GNU General Public License as published by
;the Free Software Foundation, either version 3 of the License, or
;(at your option) any later version.
;
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with this program.  If not, see <https://www.gnu.org/licenses/>.

VERSION_STRING: .reg '1.0.0-beta.1'


.include macro.mac
.include console.mac
.include doscall.mac
.include iocscall.mac
.include graphicmask.mac

CRTMOD_MAX: .equ 47


.offset 0
option_q_flag:  .ds.b 1  ;-1:表示する 0:表示しない
option_gm_flag: .ds.b 1
option_tm_flag: .ds.b 1
option_n_flag:  .ds.b 1
option_f_flag:  .ds.b 1
option_b_flag:  .ds.b 1
.even
option_cd_mode: .ds.b 1  ;-1:無指定 $01=-Cn $00=-Dn
option_crtmod:  .ds.b 1  ;-Cn/-Dnのnの値
option_gp_flag: .ds.b 1
option_tp_flag: .ds.b 1
gm_flag:        .ds.b 1  ;-1:gm未常駐 0:gm常駐
option_flag_size:


; Main -----------------------------------------

.cpu 68000
.text

Start:
		lea	(option_flag,pc),a6

		bsr	print_title
		bsr	check_option
		bsr	check_gm_version

		bsr	change_tg_use_mode
		bsr	change_console
		bsr	change_function
		bsr	change_cursor
		bsr	change_crtmod
		bsr	change_g_palette
		bsr	change_t_palette

		tst.b	(option_q_flag,a6)
		beq	@f			表示しない

		bsr	print_conmod
		bsr	print_crtmod
		bsr	print_usemd
		bsr	print_giocs
		bsr	print_gmask
@@
		DOS	_EXIT

; Option ---------------------------------------

check_option
		tst.b	(a2)+
		bne	commandline_loop
@@
		rts

commandline_loop
		move.b	(a2)+,d0
		beq	@b
		cmpi.b	#SPACE,d0
		beq	commandline_loop
		cmpi.b	#'-',d0			超手抜き
		beq	commandline_loop

		cmpi.b	#'0',d0
		bmi	@f
		cmpi.b	#'9',d0
		bhi	@f

		subq.l	#1,a2			-n
		moveq	#5,d1			MAX
		bsr	get_value
		move.b	d0,(option_n_flag,a6)

		bra	commandline_loop
@@
		cmpi.b	#'?',d0
		beq	print_usage
		andi	#$df,d0
		cmpi.b	#'H',d0
		beq	print_usage

		cmpi.b	#'G',d0
		beq	option_g
		cmpi.b	#'T',d0
		beq	option_t

		cmpi.b	#'F',d0
		beq	option_f
		cmpi.b	#'B',d0
		beq	option_b

		cmpi.b	#'C',d0
		beq	option_c
		cmpi.b	#'D',d0
		beq	option_d

		cmpi.b	#'Q',d0
		bne	option_error
;option_q
		clr.b	(option_q_flag,a6)
		bra	commandline_loop

option_g
		bsr	check_option_xm_xp
		bmi	@f

		move.b	d0,(option_gm_flag,a6)
		bra	commandline_loop
@@
		clr.b	(option_gp_flag,a6)
		bra	commandline_loop

option_t
		bsr	check_option_xm_xp
		bmi	@f

		move.b	d0,(option_tm_flag,a6)
		bra	commandline_loop
@@
		clr.b	(option_tp_flag,a6)
		bra	commandline_loop

option_c:
  moveq #$01,d1
  bra @f
option_d:
  moveq #$00,d1
@@:
  move.b d1,(option_cd_mode,a6)

  st d1  ;d1.w = $00ff, 0～CRTMOD_MAXの範囲外は未対応だが、未知の拡張に備えて受け付ける
  bsr get_value
  move.b d0,(option_crtmod,a6)
  bra commandline_loop

option_f
		moveq	#3,d1
		bsr	get_value
		move.b	d0,(option_f_flag,a6)
		bra	commandline_loop

option_b
		moveq	#1,d1
		bsr	get_value
		move.b	d0,(option_b_flag,a6)
		bra	commandline_loop

get_value
		moveq	#0,d0
		moveq	#0,d2

		move.b	(a2)+,d0
		subi.b	#'0',d0
		cmpi.b	#9,d0
		bhi	value_error
@@
		move.b	(a2)+,d2
		subi.b	#'0',d2
		cmpi.b	#9,d2
		bhi	value_end

		mulu	#10,d0
		swap	d0
		tst	d0
		bne	value_over		16bitの範囲を越えた
		swap	d0
		add	d2,d0
		bcc	@b
		bra	value_over
value_end
		subq.l	#1,a2

		cmp	d0,d1			value>MAXか？
		bcs	value_over
		rts

check_option_xm_xp
		move.b	(a2)+,d0
		beq	option_error
		ori.b	#$20,d0
		cmpi.b	#'p',d0
		beq	@f
		cmpi.b	#'m',d0
		bne	option_error

		moveq	#3,d1			-Gn/-Tn用
		bra	get_value
@@
		moveq	#-1,d0
		rts

print_usage
		pea	(usage_mes,pc)
		bra	@f
option_error
		pea	(option_err_mes,pc)
		bra	@f
value_over
		pea	(value_over_mes,pc)
		bra	@f
value_error
		pea	(value_error_mes,pc)
		bra	@f
@@
		DOS	_PRINT
		DOS	_EXIT

; Set ------------------------------------------

change_tg_use_mode
		move.b	(option_gm_flag,a6),d2	-GMn
		bmi	@f

		moveq	#0,d1
		bsr	gm_tgusemd
@@
		move.b	(option_tm_flag,a6),d2	-TMn
		bmi	@f

		moveq	#1,d1
		bsr	gm_tgusemd
@@
		rts

change_console
		moveq	#16,d6			-n
		swap	d6
		move.b	(option_n_flag,a6),d6
		bmi	@f

		beq	g_use_mode_ok		グラフィックを使わない画面モード
		cmpi.b	#2,d6
		beq	g_use_mode_ok

		bsr	check_g_use_mode
		bmi	@f
g_use_mode_ok
		bsr	dos_conctrl
@@
		rts

change_function
		bsr	get_cursor_position	-Fn

		moveq	#14,d6
		swap	d6
		move.b	(option_f_flag,a6),d6
		bmi	change_function_end

		bsr	dos_conctrl

		subq.b	#3,d0
		seq	d0
		subq.b	#3,d6
		seq	d6
		cmp.b	d0,d6
		beq	change_function_end	スクロール範囲は同じ
@@
		cmpi	#31,d5
		bcs	@f			そのままでＯＫ

		IOCS	_B_DOWN_S
		subq	#1,d5
		bra	@b
@@
		bsr	restore_cursor_position
change_function_end
		rts

;-Bn ... カーソル表示、非表示
change_cursor:
  move.b (option_b_flag,a6),d1
  bmi @f
    moveq #18,d0
    sub.b d1,d0   ;-B0 -> 18=非表示  -B1 -> 17=表示
    move d0,-(sp)
    DOS _CONCTRL
    addq.l #2,sp
  @@:
  rts

;-Cn / -Dn ... CRTモード変更
change_crtmod:
  move (option_cd_mode,a6),d6  ;-Cn/-Dn
  bmi 9f
    bsr check_g_use_mode
    bmi 9f
      moveq #-1,d1
      IOCS _CRTMOD
      move d0,d7  ;変更前のモード
      bsr get_cursor_position
      move d6,d1
      IOCS _CRTMOD

      cmp.b d6,d7
      bne @f  ;違うモードに変更した場合はテキストはクリアされる
        bsr restore_cursor_position
      @@:
  9:
  rts

change_g_palette
		clr.l	-(sp)
		DOS	_SUPER			スーパーバイザへ
		move.l	d0,(sp)

		tst.b	(option_gp_flag,a6)
		bmi	set_g_palette_end

		lea	($e82000),a0		グラフィックパレット

		moveq	#-1,d1
		IOCS	0x91			色数収得

		tst.b	d0
		beq	set_g_palette_16
		subq.b	#3,d0
		beq	set_g_palette_64k
		subq.b	#1,d0
		bne	set_g_palette_end	他の値なら無視
set_g_palette_16
		tst.b	(gm_flag,a6)
		beq	@f

		pea	(gm_not_keeped_mes,pc)
		DOS	_PRINT
		addq.l	#4,sp
		bra	set_g_palette_end
@@
		move.l	#_GM_INTERNAL_MODE.shl.16+_GM_KEEP_PALETTE_GET,d1
		IOCS	_TGUSEMD
		subi	#_GM_INTERNAL_MODE,d0
		bne	set_g_palette_end	意味ないけど一応チェック
		tst.l	d0
		beq	set_g_palette_end	まだ常駐パレットは使われていない(無視)

		moveq	#16/2-1,d0
@@
		move.l	(a1)+,(a0)+
		dbra	d0,@b
		bra	set_g_palette_end

set_g_palette_64k
		move.l	#$0001_0001,d0
		move.l	#$0202_0202,d1
		moveq.l	#256/2-1,d2
@@
		move.l	d0,(a0)+
		add.l	d1,d0
		dbra	d2,@b
set_g_palette_end
set_t_palette_end
		DOS	_SUPER			ユーザーモードへ
		addq.l	#4,sp
@@
		rts

change_t_palette
		tst.b	(option_tp_flag,a6)
		bmi	@b

		clr.l	-(sp)
		DOS	_SUPER			スーパーバイザへ
		move.l	d0,(sp)

		lea	($e82200),a0
		lea	($ed002e),a1

		move.l	(a1)+,(a0)+		0,1
		move.l	(a1)+,(a0)+		2,3
		move	(a1),(a0)+		4
		move	(a1),(a0)+		5
		move	(a1),(a0)+		6
		move	(a1)+,(a0)+		7
		moveq	#8-1,d0
@@
		move	(a1),(a0)+		8～15
		dbra	d0,@b
		bra	set_t_palette_end

check_g_use_mode
		moveq	#0,d1
		moveq	#-1,d2
		bsr	gm_tgusemd

		tst.b	d0
		beq	@f			未使用

		subq.b	#3,d0
		beq	@f			破壊

		pea	(g_used_mes,pc)
		DOS	_PRINT
		addq.l	#4,sp
		moveq	#-1,d0			エラー
@@
		rts

dos_conctrl
		move.l	d6,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		rts

get_cursor_position
		moveq	#-1,d1
		IOCS	_B_LOCATE
		move.l	d0,d5			変更前のカーソル位置
		rts

restore_cursor_position
		move	d5,d2			行
		swap	d5
		move	d5,d1			桁
		IOCS	_B_LOCATE		元の位置に戻す
		rts

; [ DOS  CONCTRL ] -----------------------------

print_conmod
		link	a6,#0

		pea	(conctrl_mode,pc)
		DOS	_PRINT

		moveq	#16,d0
		bsr	dos_conctrl_

		moveq	#5,d0
		bsr	print_value
		bne	unknown_value		未定義の値

		pea	(_768,pc)
		cmpi	#2,d1
		bmi	@f			0,1 は 768x512

		addq.l	#_512-_768,(sp)
@@
		DOS	_PRINT			画面サイズ

		pea	(conctrl_size,pc)
		DOS	_PRINT			'x512 グラフィック'

		lea	(_16,pc),a0
		move.b	(conmod_to_color,pc,d1.w),d0
		lsl	#3,d0			１つ８バイト
		pea	(a0,d0.w)
		DOS	_PRINT

		pea	(function_mode,pc)
		DOS	_PRINT

		moveq	#14,d0
		bsr	dos_conctrl_

		moveq	#3,d0
		bsr	print_value
		bne	unknown_value

		lea	(func_table,pc),a0
		move.b	(a0,d1.w),d1
		pea	(a0,d1.w)
		DOS	_PRINT

print_crlf_and_return
		unlk	a6
		bra	print_crlf

print_crlf
		pea	(crlf,pc)
		DOS	_PRINT
		addq.l	#4,sp
		rts

dos_conctrl_
		swap	d0
		subq	#1,d0
		move.l	d0,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		move	d0,d1
		rts

unknown_value
		pea	(unknown_value_mes,pc)
		DOS	_PRINT
		bra	print_crlf_and_return

conmod_to_color
		.dc.b	3,0,3,0,1,2
		.even

; [ IOCS TGUSEMD ] -----------------------------

print_usemd
		link	a6,#0

		pea	(usemode,pc)
		DOS	_PRINT			グラフィック画面

		moveq	#0,d1
		bsr	get_usemode

		pea	(usemode_t,pc)
		DOS	_PRINT			テキスト画面

		moveq	#1,d1
		bsr	get_usemode

		bra	print_crlf_and_return

get_usemode
		moveq	#-1,d2
		bsr	gm_tgusemd

		move	d0,d1
		moveq	#3,d0
		bsr	print_value
		beq	@f

		moveq	#4,d1			未定義
@@
		add	d1,d1
		move	(usemode_table,pc,d1.w),d1
		pea	(usemode_table,pc,d1.w)
		DOS	_PRINT

		addq.l	#4,sp
		rts

usemode_table:
  .dc mode_0-usemode_table
  .dc mode_1-usemode_table
  .dc mode_2-usemode_table
  .dc mode_3-usemode_table
  .dc unknown_value_mes-usemode_table

; [ IOCS  CRTMOD ] -----------------------------

_15kHz: .equ 0
_24kHz: .equ 1
_31kHz: .equ 2
_31VGA: .equ 3

_256x256:   .equ 0
_512x512:   .equ 1
_768x512:   .equ 2
_1024x424:  .equ 3
_1024x848:  .equ 4
_640x480:   .equ 5
_384x256:   .equ 6
_1024x1024: .equ 7  ;実画面サイズ専用
_256x256sq: .equ 8
_512x512sq: .equ 9
_512x256:   .equ 10

c16:  .equ 0
c256: .equ 1
c64k: .equ 2

CRTSPEC: .macro hz,disp,size,color
  .dc color<<12+size<<8+disp<<4+hz
.endm

GET_CRTSPEC: .macro src_dreg,temp_areg,dst_dreg
  add src_dreg,src_dreg
  lea (CrtSpecTable,pc),temp_areg
  move (temp_areg,src_dreg.w),dst_dreg
.endm

print_crtmod:
  link a6,#0
  bsr printCrtModHeaderAndValue
  bne unknown_value
  unlk a6

  bra printCrtModDetail

printCrtModHeaderAndValue:
  pea (crtmod,pc)
  DOS _PRINT
  addq.l #4,sp

  moveq #-1,d1
  IOCS _CRTMOD
  move d0,d1

  move #CRTMOD_MAX,d0
  bra print_value

printCrtModDetail:
  link a6,#-64
  GET_CRTSPEC d1,a0,d2
  lea (sp),a1

  moveq #$f,d0  ;周波数
  and.b d2,d0
  lsl #3,d0
  lea (CrtHzTable,pc),a0
  adda.l d0,a0
  STRCPY a0,a1,-1
  bsr copySlash

  lsr #4,d2  ;表示画面サイズ
  bsr copyScreenSize

  move.b #'(',(a1)+
  lsr #4,d2  ;実画面サイズ
  bsr copyScreenSize
  move.b #')',(a1)+
  bsr copySlash

  lsr #4,d2  ;色数
  lsl #3,d2
  lea (ColorTable,pc),a0
  adda.l d2,a0
  STRCPY a0,a1,-1

  lea (crlf,pc),a0
  STRCPY a0,a1

  pea (sp)
  DOS _PRINT
  addq.l #4,sp

  unlk a6
  rts

copyScreenSize:
  moveq #$f,d0
  and.b d2,d0
  lea (DispSizeTable,pc),a0
  move.b (a0,d0.w),d0
  adda d0,a0
  STRCPY a0,a1,-1
  rts

copySlash:
  lea (Slash,pc),a0
  STRCPY a0,a1,-1
  rts


; [ GRAPHIC IOCS ] -----------------------------

print_giocs
		link	a6,#0

		pea	(giocs,pc)
		DOS	_PRINT

		pea	(can_not_use_mes,pc)
		moveq	#-1,d1
		IOCS	_APAGE
		tst.l	d0
		bmi	@f

		addq.l	#2,(sp)			'不'の字を飛ばす
@@
		DOS	_PRINT

		unlk	a6
		rts

; [ GRAPHIC MASK ] -----------------------------

print_gmask
		bsr	check_gm_version
		beq	@f			常駐している

		rts				未常駐時は表示しない
@@
		link	a6,#0
		lea	(gm_version,pc),a0
		lea	(hex_table,pc),a1

		clr	d0
		rol.l	#4,d0
		tst.b	d0			整数第２位
		beq	@f			十の位が 0 なら 空白にしておく

		move.b	(a1,d0.w),(-3,a0)
@@
		clr	d0
		rol.l	#4,d0
		move.b	(a1,d0.w),(-2,a0)	整数第１位

		.rept	2
		clr	d0
		rol.l	#4,d0
		move.b	(a1,d0.w),(a0)+		小数第１・２位
		.endm

		pea	(gmask,pc)
		DOS	_PRINT

		moveq	#.low._GM_ACTIVE_STATE,d1
		bsr	gm_ex_call

		pea	(gm_active,pc)
		tst	d0
		bne	@f			有効

		addq.l	#gm_inactive-gm_active,(sp)
@@
		DOS	_PRINT			Active State

		pea	(gm_gnc,pc)
		DOS	_PRINT

		moveq	#.low._GM_GNC_STATE,d1
		bsr	gm_ex_call

		pea	(gm_enable,pc)
		tst	d0
		bne	@f			有効

		addq.l	#gm_disable-gm_enable,(sp)
@@
		DOS	_PRINT			GNC State

		moveq	#.low._GM_AUTO_STATE,d1
		bsr	gm_ex_call

		move	d0,d1
		lea	(gm_automask_mode,pc),a0

		lsr	#1,d0
		bcc	@f
		addq.b	#1,(1,a0)
@@
		lsr	#1,d0
		bcc	@f
		addq.b	#1,(a0)
@@
		pea	(gm_automask,pc)
		DOS	_PRINT

		pea	(gm_automask_disable,pc)
		subq	#1,d1
		beq	@f			01:禁止

		addq.l	#gm_automask_enable-gm_automask_disable,(sp)
		subq	#1,d1
		beq	@f			10:許可

		addq.l	#gm_automask_unkworn-gm_automask_enable,(sp)
@@
		DOS	_PRINT			AutoMask State

		pea	(gm_pallete,pc)
		DOS	_PRINT

		moveq	#.low._GM_KEEP_PALETTE_GET,d1
		bsr	gm_ex_call

		pea	(gm_disable,pc)

		tst	d0
		beq	@f

		bsr	toascii_address
		pea	(value_buf,pc)
@@
		DOS	_PRINT			常駐パレット

		bra	print_crlf_and_return

; Sub ------------------------------------------

check_gm_version
		move.l	#_GM_INTERNAL_MODE.shl.16+_GM_VERSION_NUMBER,d1
		IOCS	_TGUSEMD
		cmpi	#_GM_INTERNAL_MODE,d0
		sne	(gm_flag,a6)
		rts

gm_tgusemd
		tst.b	(gm_flag,a6)
		bne	@f			常駐してないのでそのまま
		addi.l	#_GM_INTERNAL_MODE.shl.16,d1
@@
		IOCS	_TGUSEMD
		rts

gm_ex_call
		swap	d1
		move	#_GM_INTERNAL_MODE,d1
		swap	d1
		IOCS	_TGUSEMD
		cmpi	#_GM_INTERNAL_MODE,d0
		bne	@f			一応チェックしておく

		swap	d0
		rts
@@
		pea	(gm_call_err_mes,pc)
		DOS	_PRINT
		bra	print_crlf_and_return

print_title
		pea	(title_mes,pc)
		DOS	_PRINT
		addq.l	#4,sp
		rts

print_value
		moveq	#4-1,d2
		lea	(value_buf,pc),a0

		cmp	d0,d1			d0:MAX
		shi	d7
		bhi	print_value_hex		16 進数表示

		move.l	#'    ',(a0)+
		move	d1,d0
@@
		divu	#10,d0
		swap	d0			余り
		move.b	(hex_table,pc,d0.w),-(a0)

		clr	d0
		swap	d0			まだ上位桁が 0 でないか？

		dbeq	d2,@b
		bra	print_value_2

print_value_hex
		rol	#4,d1
		moveq	#0b1111,d0
		and	d1,d0
		move.b	(hex_table,pc,d0.w),(a0)+

		dbra	d2,print_value_hex

print_value_2
		pea	(value_buf,pc)
		DOS	_PRINT
		addq.l	#4,sp

		tst.b	d7
		rts

toascii_address
		move	#'0',-(sp)
		DOS	_PUTCHAR
		move	#'x',(sp)
		DOS	_PUTCHAR
		addq.l	#2,sp

		moveq	#6-1,d2
		lea	(value_buf,pc),a0
		move.l	a1,d1
		lsl.l	#8,d1
@@
		rol.l	#4,d1
		moveq	#0b1111,d0
		and	d1,d0
		move.b	(hex_table,pc,d0.w),(a0)+

		dbra	d2,@b
		clr.b	(a0)
		rts

hex_table
		.dc.b	'0123456789abcdef'
		.even


.data

.even
CrtSpecTable:
  CRTSPEC _31kHz,_512x512,  _1024x1024,c16   ; 0
  CRTSPEC _15kHz,_512x512,  _1024x1024,c16   ; 1
  CRTSPEC _31kHz,_256x256,  _1024x1024,c16   ; 2
  CRTSPEC _15kHz,_256x256,  _1024x1024,c16   ; 3
  CRTSPEC _31kHz,_512x512,  _512x512,  c16   ; 4
  CRTSPEC _15kHz,_512x512,  _512x512,  c16   ; 5
  CRTSPEC _31kHz,_256x256,  _512x512,  c16   ; 6
  CRTSPEC _15kHz,_256x256,  _512x512,  c16   ; 7
  CRTSPEC _31kHz,_512x512,  _512x512,  c256  ; 8
  CRTSPEC _15kHz,_512x512,  _512x512,  c256  ; 9
  CRTSPEC _31kHz,_256x256,  _512x512,  c256  ;10
  CRTSPEC _15kHz,_256x256,  _512x512,  c256  ;11
  CRTSPEC _31kHz,_512x512,  _512x512,  c64k  ;12
  CRTSPEC _15kHz,_512x512,  _512x512,  c64k  ;13
  CRTSPEC _31kHz,_256x256,  _512x512,  c64k  ;14
  CRTSPEC _15kHz,_256x256,  _512x512,  c64k  ;15
  CRTSPEC _31kHz,_768x512,  _1024x1024,c16   ;16
  CRTSPEC _24kHz,_1024x424, _1024x1024,c16   ;17
  CRTSPEC _24kHz,_1024x848, _1024x1024,c16   ;18
  CRTSPEC _31VGA,_640x480,  _1024x1024,c16   ;19  Compact(ROM 1.2)以降で有効
  CRTSPEC _31kHz,_768x512,  _512x512,  c256  ;20  以下、X68030(ROM 1.3)で有効
  CRTSPEC _24kHz,_1024x424, _512x512,  c256  ;21
  CRTSPEC _24kHz,_1024x848, _512x512,  c256  ;22
  CRTSPEC _31VGA,_640x480,  _512x512,  c256  ;23
  CRTSPEC _31kHz,_768x512,  _512x512,  c64k  ;24
  CRTSPEC _24kHz,_1024x424, _512x512,  c64k  ;25
  CRTSPEC _24kHz,_1024x848, _512x512,  c64k  ;26
  CRTSPEC _31VGA,_640x480,  _512x512,  c64k  ;27
  CRTSPEC _31kHz,_384x256,  _1024x1024,c16   ;28  以下、XEiJ(ROM 1.6),crtmod16.xによる拡張
  CRTSPEC _31kHz,_384x256,  _512x512,  c16   ;29
  CRTSPEC _31kHz,_384x256,  _512x512,  c256  ;30
  CRTSPEC _31kHz,_384x256,  _512x512,  c64k  ;31
  CRTSPEC _31kHz,_512x512sq,_1024x1024,c16   ;32
  CRTSPEC _31kHz,_512x512sq,_512x512,  c16   ;33
  CRTSPEC _31kHz,_512x512sq,_512x512,  c256  ;34
  CRTSPEC _31kHz,_512x512sq,_512x512,  c64k  ;35
  CRTSPEC _31kHz,_256x256sq,_1024x1024,c16   ;36
  CRTSPEC _31kHz,_256x256sq,_512x512,  c16   ;37
  CRTSPEC _31kHz,_256x256sq,_512x512,  c256  ;38
  CRTSPEC _31kHz,_256x256sq,_512x512,  c64k  ;39
  CRTSPEC _31kHz,_512x256,  _1024x1024,c16   ;40
  CRTSPEC _31kHz,_512x256,  _512x512,  c16   ;41
  CRTSPEC _31kHz,_512x256,  _512x512,  c256  ;42
  CRTSPEC _31kHz,_512x256,  _512x512,  c64k  ;43
  CRTSPEC _31kHz,_512x256,  _1024x1024,c16   ;44
  CRTSPEC _31kHz,_512x256,  _512x512,  c16   ;45
  CRTSPEC _31kHz,_512x256,  _512x512,  c256  ;46
  CRTSPEC _31kHz,_512x256,  _512x512,  c64k  ;47

.even
value_buf:
  .dc.b 0,0,0,0,' : ',0

.even
option_flag:
  .dcb.b option_flag_size,-1

title_mes:
  .dc.b 'CONMOD version ',VERSION_STRING
  .dc.b '  Copyright (C) 2025 TcbnErik.',CR,LF,0

usage_mes:
  .dc.b 'usage: conmod [-Q] [-GMn] [-TMn] [-n] [-Fn] [-Cn] [-Dn] [-GP] [-TP]',CR,LF
  .dc.b 'options:',CR,LF
  .dc.b '  -Q          設定状態を表示しない',CR,LF
  .dc.b '  -GMn(0-3)   グラフィック使用状況を変更する',CR,LF
  .dc.b '  -TMn(0-3)   テキスト使用状況を変更する',CR,LF
  .dc.b '  -n(0-5)     画面モードを変更する',CR,LF
  .dc.b '  -Fn(0-3)    ファンクションキー行モードを変更する',CR,LF
  .dc.b '  -Bn(0-1)    カーソルの表示を変更する',CR,LF
  .dc.b '  -Cn(0-255)  CRT モードを変更する',CR,LF
  .dc.b '  -Dn(0-255)  CRT モードを変更する(画面の初期化もする)',CR,LF
  .dc.b '  -GP         グラフィックパレットを初期化する',CR,LF
  .dc.b '  -TP         テキストパレットを初期化する',CR,LF
  .dc.b 0

option_err_mes:
  .dc.b 'オプションの指定が正しくありません。',CR,LF,0
value_over_mes:
  .dc.b '数値が大きすぎます。',CR,LF,0
value_error_mes:
  .dc.b '数値が指定されていません。',CR,LF,0
g_used_mes:
  .dc.b 'GVRAM は使用中です。',CR,LF,0
gm_not_keeped_mes:
  .dc.b 'GraphicMaskが組み込まれていないため、16色常駐パレットは使えません。',CR,LF,0
unknown_value_mes:
  .dc.b '未定義',0

_16
		.dc.b	'   16色',0
_256
		.dc.b	'  256色',0
_65536
		.dc.b	'65536色',0
_0
		.dc.b	'Graphic Off',0
crlf
		.dc.b	CR,LF,0

conctrl_mode
		.dc.b	CR,LF
		.dc.b	'[ DOS  CONCTRL ] ',0
_768
		.dc.b	'768',0
_512
		.dc.b	'512',0
conctrl_size
		.dc.b	'x512 / ',0
function_mode
		.dc.b	CR,LF
		.dc.b	TAB,TAB,' Function ',0
func_table
		.dc.b	func_normal-func_table
		.dc.b	func_shift_-func_table
		.dc.b	func_hide__-func_table
		.dc.b	func_hide32-func_table
func_normal
		.dc.b	'Normal',0
func_shift_
		.dc.b	'Shift',0
func_hide__
		.dc.b	'Hide',0
func_hide32
		.dc.b	'Hide(32line)',0

giocs
		.dc.b	'[ GRAPHIC IOCS ] 使用',0
can_not_use_mes
		.dc.b	'不'
		.dc.b	'可能',CR,LF,0

usemode
		.dc.b	'[ IOCS TGUSEMD ] Graphic  ',0
usemode_t
		.dc.b	CR,LF
		.dc.b	TAB,TAB,'    Text  ',0
mode_0		.dc.b	'未使用',0
mode_1		.dc.b	'システムが使用中',0
mode_2		.dc.b	'アプリケーションが使用中',0
mode_3		.dc.b	'破壊',0

crtmod:
  .dc.b '[ IOCS  CRTMOD ] ',0

CrtHzTable:
  .dc.b '15kHz',0,0,0
  .dc.b '24kHz',0,0,0
  .dc.b '31kHz',0,0,0
  .dc.b '31kHz(VGA)',0

DispSizeTable:
  .irp label,100f,101f,102f,103f,104f,105f,106f,107f,108f,109f,110f
    .dc.b label-DispSizeTable
  .endm
100: .dc.b '256x256',0
101: .dc.b '512x512',0
102: .dc.b '768x512',0
103: .dc.b '1024x424',0
104: .dc.b '1024x848',0
105: .dc.b '640x480',0
106: .dc.b '384x256',0
107: .dc.b '1024x1024',0
108: .dc.b '256x256(正方形)',0
109: .dc.b '512x512(正方形)',0
110: .dc.b '512x256',0

Square: .dc.b '(正方形)',0

ColorTable:
  .dc.b '16色',0,0,0,0
  .dc.b '256色',0,0,0
  .dc.b '65536色',0

Slash: .dc.b ' / ',0

gmask
		.dc.b	'[ GRAPHIC MASK ] Version '
		.dc.b	'  .'
gm_version
		.dc.b	'   / 主要機能 ',0
gm_active
		.dc.b	'動作',0
gm_inactive
		.dc.b	'停止',0
gm_gnc
		.dc.b	'中 / GNC ',0
gm_enable
		.dc.b	'有効',0
gm_disable
		.dc.b	'無効',0
gm_automask
		.dc.b	CR,LF,TAB,TAB,' Auto-Mask %'
gm_automask_mode
		.dc.b	'00 : ',0
gm_automask_disable
		.dc.b	'禁止',0
gm_automask_enable
		.dc.b	'許可',0
gm_automask_unkworn
		.dc.b	'不明',0
gm_pallete
		.dc.b	' / 常駐パレット ',0
gm_call_err_mes
		.dc.b	'GraphicMask拡張コールがサポートされていません',0


.end Start
