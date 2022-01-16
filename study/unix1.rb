# UNIX ドメインソケットの読み書きをする練習
# - "hello" メッセージを送信
# - "ack" メッセージを逆向きに送って全二重であることを確認
# - なお、各メッセージは WMO ソケット手順でメッセージ長を伝達している

require 'socket'

def sendbull(sock, bull)
  shdr = sprintf('%08u%2s', bull.size, 'BI')
  sock.sendmsg(shdr)
  sock.sendmsg(bull)
end

def recvbull(sock)
  shdr = sock.recvmsg(10)
  bullsize = shdr[0][0,10].to_i
  bull = sock.recvmsg(bullsize)[0]
end

def parent(sockname, cpid)
  UNIXServer.open(sockname) {|server|
    sock = server.accept
    sendbull(sock, "hello")
    bull = recvbull(sock)
    STDERR.puts bull.inspect
  }
ensure
  File.unlink(sockname)
end

def child sockname
  UNIXSocket.open(sockname) {|sock|
    bull = recvbull(sock)
    STDERR.puts bull.inspect
    sendbull(sock, "ack")
  }
end

sockname = "/tmp/rmss.check.#{Process.pid}"

if cpid = fork
  parent(sockname, cpid)
else
  child(sockname)
end
