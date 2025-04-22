# CONMOD

画面の設定変更と設定状態の表示を行うツールです。  
無保証につき各自の責任で使用して下さい。


## Usage

```
conmod [-Q] [-GM<n>] [-TM<n>] [-<n>] [-F<n>] [-B<n>] [-C<n>] [-D<n>] [-GP] [-TP]
```

実行すると画面の設定状態を表示します。  

* \[ DOS  CONCTRL \] …… DOS \_CONCTRL(16,-1)および(14,-1)の返り値
* \[ IOCS  CRTMOD \] …… IOCS \_CRTMOD(-1)の返り値
* \[ IOCS TGUSEMD \] …… IOCS \_TGUSEMD(0,-1)および(1,-1)の返り値
* \[ GRAPHIC IOCS \] …… グラフィックIOCSが使えるか(IOCS \_APAGEにて判定)
* \[ GRAPHIC MASK \] …… GraphicMaskの各種設定

オプションを指定すると設定を変更してから状態を表示します。  


### Options

オプション先頭の`-`は省略できます。

* -Q …… 設定の状態表示をしない
* -GM\<n\> …… n=0-3。IOCS \_TGUSEMD のグラフィック使用状況を変更する
* -TM\<n\> …… n=0-3。IOCS \_TGUSEMD のテキスト使用状況を変更する
* -\<n\> …… n=0-5。DOS \_CONCTRL で画面を切り換える
* -F\<n\> …… n=0-3。DOS \_CONCTRL でファンクションキー行の表示を変更する
* -B\<n\> …… n=0-1。DOS \_CONCTRL カーソルの表示を変更する(0:非表示 1:表示)
* -C\<n\> …… n=0-19。IOCS \_CRTMOD で画面を切り換える(画面の初期化はしない)
* -D\<n\> …… n=0-19。IOCS \_CRTMOD で画面を切り換える(画面を初期化する)
* -GP …… グラフィックパレット初期化(動作内容は色数によって違う)
  * 64K色 …… 標準パレット
  * 256色 …… 何もしない
  * 16色 …… GraphicMaskの常駐パレットの値
* -TP …… テキストパレット初期化

設定の変更は -GM -T -n -F -B \(-C or -D\) -GP -TP の順に行われます。
また、-Cと-Dは後に指定した方が有効になります。

## Known bugs

* -C、-Dでモードを変更するとファンクション表示の行までスクロールしてしまいます。


## Build

PCやネット上での取り扱いを用意にするために、src/内のファイルはUTF-8で記述されています。
X68000上でビルドする際には、UTF-8からShift_JISへの変換が必要です。

### u8tosjを使用する方法

あらかじめ、[u8tosj](https://github.com/kg68k/u8tosj)をインストールしておいてください。

トップディレクトリで`make`を実行してください。以下の処理が行われます。
1. `build/`ディレクトリの作成。
3. `src/`内のファイルをShift_JISに変換して`build/`へ保存。

次に、カレントディレクトリを`build/`に変更し、`make`を実行してください。
実行ファイルが作成されます。

### u8tosjを使用しない方法

`src/`内のファイルを適当なツールで適宜Shift_JISに変換してから`make`を実行してください。
UTF-8のままでは正しくビルドできませんので注意してください。


## License

GNU GENERAL PUBLIC LICENSE Version 3 or later.


## Author

TcbnErik / https://github.com/kg68k/conmod
