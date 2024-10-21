# analog_joyport
PC-8001mk2、PC-8012/8013用アナログジョイポート

## 概要

- この基板はPC-8001mk2、またはPC-8012/8013を接続したPC-8001で、４つのアナログ入力と２つのデジタル入力を使用可能にします
- 使用には対応する入力装置が必要です
- “SLIPSTREAM”専用コントローラーの製作方法はこちら https://github.com/chiqlappe/analog_joypad

## 基板の製作

[製作マニュアル](https://github.com/chiqlappe/analog_joyport/blob/main/manual.pdf)

## プログラム

- [adc.asm](https://github.com/chiqlappe/analog_joyport/blob/main/adc.asm) ADC制御プログラム

- [port_check.wav](https://github.com/chiqlappe/analog_joyport/blob/main/port_check.wav) ADC動作確認プログラム(マシン語+BASIC ファイル名"bas")
