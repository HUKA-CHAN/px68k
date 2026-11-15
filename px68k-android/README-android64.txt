PX68K for Android  -  64bit / 新しい Android (15, 16, 17 ...) 対応版
====================================================================

hissorii さんの PX68K 0.15 (https://github.com/hissorii/px68k) の Android 版を、
現在の Android で動くように手直ししたものです。エミュレーション内容は変えていません。

■ 変更点
  ・MC68000 コア (C68K) を 64bit 対応 (PC / フェッチテーブルをポインタ幅に、MOVEM の修正)
  ・D88 ヘッダ構造体を 32bit 固定幅に (64bit では long が 8 バイトになり読めなかった)
  ・表示ラインが範囲外 (VLINE = -1) のときの配列アクセスを修正
    (32bit では偶然動いていたが、64bit では IPL 起動直後にクラッシュする)
  ・SDL2 を 2.32 系に更新 (Java 側の SDLActivity も同じ版に差し替え)
  ・arm64-v8a / x86_64 を追加 (armeabi-v7a も同梱)、16KB ページサイズ対応
  ・targetSdkVersion 35、minSdkVersion 23 (Android 6.0 以上)
  ・ストレージ: 起動時に「すべてのファイルへのアクセス」を確認 (下記)
  ・ROM が無いときは黙って終了せず、置き場所をダイアログで表示
  ・戻る操作は 1 秒以内に 2 回で終了 (従来どおり)
  ・フレーム待ち / メニュー表示中の空回りをやめて省電力化

■ ファイルの置き場所
  1. 許可した場合 (従来と同じ)
        (内部ストレージ)/px68k/
  2. 許可しない場合
        (内部ストレージ)/Android/data/com.fc2.blog45.hissorii/files/
     ※ このフォルダは PC と USB 接続して書き込むのが確実です。
  どちらの場合も iplrom.dat (または iplrom30.dat / iplromco.dat / iplromxv.dat) と
  cgrom.dat (または cgrom.tmp)、ディスクイメージを置きます。使い方は readme.txt 参照。
  従来の dir.txt による場所指定も使えます。
  あとから許可を変えるときは、Android の設定 → アプリ → PX68K for Android →
  「すべてのファイルへのアクセス」で切り替えてください。

■ 操作のヒント
  ・画面右上の白いボタンを長押し (約 0.3 秒) でメニュー、黄色いボタンでソフトウェアキーボード
  ・メニューは十字キーで選び、右側 2 つのうち左のボタン (TRG1) で決定
  ・マウスで遊ぶソフトは、メニューの Joy/Mouse を Mouse にする
    (画面をなぞるとマウス移動、右側のボタンがマウスボタン)

■ ビルド方法 (Gradle / Android Studio 不要)
  必要なもの: JDK 17 以上、Android NDK r28 以上、SDK build-tools 35 以上、
              API 35 以上の android.jar、SDL2 2.30 以上のソース、zip
    export NDK=/path/to/android-ndk-r28c
    export BUILD_TOOLS=$ANDROID_HOME/build-tools/36.0.0
    export ANDROID_JAR=$ANDROID_HOME/platforms/android-36/android.jar
    export SDL2_DIR=/path/to/SDL2-2.32.10
    ./build-apk.sh        →  px68k.apk
  署名鍵を指定しない場合はデバッグ鍵 (debug.keystore) をその場で作ります。
  上書きインストールするには同じ鍵で署名してください (KEYSTORE / KS_PASS / KS_ALIAS)。
