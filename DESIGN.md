#　rmss 設計思考メモ
## これは何
WMO/JMA ソケット手順などの電文交換プログラムを ruby で実装するもの。

WMO 国際通信関係者間ではこの種のプログラムを message switching system という
（日本気象庁では「アデスのようなもの」と言わないと通じない）のが名前の由来。
さしあたり ruby で実装するが、いずれ C で書くこともあるかもしれないので、
区別できるように rmss と命名しておく。

## コマンド構成
MSSの前後に多様な処理を接続できるよう、マルチプロセス構造にしておく

* rmss-inject: キューに電文を投入するコマンド
* rmss-qstat: キュー状態を表示・チェックするコマンド
* rmss-send: ソケットから入力、キューを保持して電文が現れたらソケットに送るデーモン
* rmss-duplex: ひとつのソケット（通常TCP）で全二重通信をして、ひとつのソケット（通常UNIX）から読みつつ別のソケット（通常UNIX）に書く
* rmss-switch: ソケットから入力、電文を受けたら設定により他の多数ソケットに配信するデーモン
* rmss-store: ソケットを待ち受けて電文を保存するデーモン

## 電文とは
WMO/JMA ソケット手順が伝送するペイロードは、任意のオクテット列である。長さは720Kbytesが上限とされている。
純粋なソケット手順にはファイル名や通過番号など、ペイロードを特定する情報はない。

通過番号はペイロードの先頭に置かれるBCHに記載される。まあ、そこまでを電文のプロパティと考えるべきかもしれない。
運用監視にあたり通過番号とヘッダをログに打ち出すことは実用上不可欠と思われるから。

## キューとは
rmss-inject はすぐに終了したい。rmss-switch は多数の送信先で突っかかって ACK を返すのが遅れると困る。
UNIX ソケットで rmss-send に送り込んで ACK を取ったらすぐに終了する。
rmss-send の送信先ソケットは UNIX でも TCP でもよいことにする。TCP の場合は純粋クラサバになる。
rmss-send では送信遅延、エラー再送、自局突然のシャットダウンなどの問題に備え、受け取ったものはすぐ保存したい。

保存形式としては、シーケンシャル（tarなど）とKVS的DB（GDBMなど）がありうるが、まずはKVSで実装するのだろう。
さしあたりは送信成功したら消す。
たとえば通番でKVSのキーを与えるのだろう。
ヘッダなど意味のある文字列にすれば運用監視はやりやすそうに見えるが、利用者供給データでファイル名を作るようなことにつながりかねず、セキュリティ的には懸念が増える。

## 接続とデータの向き
データの流れる向きと接続の向きは両方ありうるようである。
つまり、rmss-send は入力が次の2種類、

* UNIXServer で接続待ち受け
* TCPServer で接続待ち受け

出力は次の4種類となる:

* UNIXServer で接続待ち受け
* TCPServer で接続待ち受け
* UNIXServer で接続を張りに行く
* TCPServer で接続を張りに行く

サーバもクライアントも sendmsg(2)/recvmsg(2) は共通に使えるのでメインループは共通に使える。

## メインループ

rmss-send/switch の動作は基本的に「１電文受けたら、保存・送信・保存破棄」のループ。
ただし、
* 受けた電文がチェックポイント要求つきであれば、保存後ただちにチェックポイント応答を返す
* 受けた電文がヘルスチェック要求であれば、送信に入らずヘルスチェック応答を返す

ブロックする処理の間にヘルスチェック要求が来る場合がしばしば問題になるらしい。
何がブロックしうるかというと、送信と応答送信である。
応答送信がブロックするときはヘルスチェックどころではないので考えなくてよい。
送信がブロックするときは、ソケットの向こう側の都合なので何があるかわからない。
すべてタイムアウトするようにすべきである。

ここまで考えたところでアデスはひとつのTCPソケットを両方向の電文送受に使うことを知る。そりゃあ大変だ。 rmss-duplex という別プロセスにしよう。
素朴には、送信と受信でスレッドを分けることが考えられるが、両スレッドが両方向で読み書きをするので、排他制御が必要。
むしろ状態遷移をガッチリコントロールしてシングルスレッドにしたほうがいいかもしれない。
状態遷移か、ジョブをキューに詰むイメージかもしれない。
なにしろ難しいのでこれは例外にして、極力単方向プロセスのチェーンにする。

## UNIX ソケットの削除について
UNIX ソケットはファイルシステム上に特殊なファイルとして位置を占める。
クローズしてもファイルシステムに残ってしまうから、削除しなければならない。
普通に考えれば、作成したプロセス＝サーバが削除するのであろうし、
rmssライブラリはそれを責任をもって行わしめるAPIでなければならない。
つまり RMSS::getconn はソケットを返すのではなく yield すべきである。

