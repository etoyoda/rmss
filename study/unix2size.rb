# UNIX ドメインソケットの読み書きをする練習
# 一度の sendmsg/recvmsg で送受信できる限界を越えた大きさのメッセージを送受
# する試験
# 1 MB までのメッセージについて試験した。210 kB を越えると recvmsg は
# 複数回に分けて受信する必要がある。

require 'socket'
require 'digest/md5'

def sendbull(sock, bull)
  shdr = sprintf('%08u%2s', bull.size, 'BI')
  r = sock.sendmsg(shdr)
  raise Errno::EMSGSIZE unless r == shdr.size
  sock.sendmsg(bull)
  raise Errno::EMSGSIZE unless r == shdr.size
  nil
end

def recvbull(sock)
  shdr = sock.recvmsg(10)
  raise Errno::EMSGSIZE unless shdr[0].size == 10
  bullsize = shdr.first[0,10].to_i
  recvsize = bullsize
  buf = []
  loop {
    resp = sock.recvmsg(recvsize)
    msg = resp.first
    buf.push msg
    recvsize -= msg.size
    break if recvsize.zero?
    STDERR.puts "retrying remaining #{recvsize}"
  }
  buf.join
end

def parent(sockname, cpid)
  UNIXServer.open(sockname) {|server|
    sock = server.accept
    msg = "x" * 1024
    11.times {
      sendbull(sock, msg)
      STDERR.puts "#{Digest::MD5.hexdigest(msg)} #{msg.size} bytes sent"
      msg = msg * 2
    }
  }
ensure
  File.unlink(sockname)
end

def child sockname
  UNIXSocket.open(sockname) {|sock|
    11.times {
      bull = recvbull(sock)
      STDERR.printf("%s %u bytes recved\n", Digest::MD5.hexdigest(bull), bull.size)
    }
  }
end

sockname = "/tmp/rmss.check.#{Process.pid}"

if cpid = fork
  parent(sockname, cpid)
else
  child(sockname)
end
