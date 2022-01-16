# UNIX ドメインソケットの読み書きをする練習
# 一度の sendmsg/recvmsg で送受信できる限界を越えた大きさのメッセージを送受
# する試験

require 'socket'

def sendbull(sock, bull)
  shdr = sprintf('%08u%2s', bull.size, 'BI')
  r = sock.sendmsg(shdr)
  raise Errno::EMSGSIZE unless r == shdr.size
  sock.sendmsg(bull)
  raise Errno::EMSGSIZE unless r == shdr.size
  STDERR.puts "#{bull.size} bytes sent"
  nil
end

def recvbull(sock)
  shdr = sock.recvmsg(10)
  raise Errno::EMSGSIZE unless shdr[0].size == 10
  bullsize = shdr[0][0,10].to_i
  bull = sock.recvmsg(bullsize)
  raise Errno::EMSGSIZE unless bull[0].size == bullsize
  bull[0]
end

def parent(sockname, cpid)
  UNIXServer.open(sockname) {|server|
    sock = server.accept
    msg = "x" * 1024
    10.times {
      sendbull(sock, msg)
      msg = msg * 2
    }
  }
ensure
  File.unlink(sockname)
end

def child sockname
  UNIXSocket.open(sockname) {|sock|
    10.times {
      bull = recvbull(sock)
      STDERR.printf("%u bytes received\n", bull.size)
    }
  }
end

sockname = "/tmp/rmss.check.#{Process.pid}"

if cpid = fork
  parent(sockname, cpid)
else
  child(sockname)
end
