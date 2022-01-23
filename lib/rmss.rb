
require 'socket'

module RMSS

  # ソケット sock に電文 msg を送る。種別は msgtype で指定する。
  def sendsock(sock, msg, msgtype = 'BI')
    shdr = sprintf('%08u%2s', msg.size, msgtype)
    r = sock.sendmsg(shdr)
    raise Errno::EMSGSIZE unless r == shdr.size
    sock.sendmsg(msg)
    raise Errno::EMSGSIZE unless r == shdr.size
    nil
  end

  # ソケット sock から電文を取得する。種別と電文本体が返る。
  def recvsock(sock)
    shdr = sock.recvmsg(10)
    unless shdr[0].size == 10
      raise Errno::EPIPE if shdr[0] == ''
      STDERR.puts shdr.inspect
      raise Errno::EMSGSIZE
    end
    msgsize = shdr.first[0,8].to_i
    msgtype = shdr.first[8,2]
    recvsize = msgsize
    buf = []
    loop {
      resp = sock.recvmsg(recvsize)
      fragment = resp.first
      buf.push fragment
      recvsize -= fragment.size
      break if recvsize.zero?
      STDERR.puts "retrying remaining #{recvsize}"
    }
    [msgtype, buf.join]
  end

  # 汎用的なコマンドライン解析。opts はオプションのデフォルト値となる
  def optparse argv, opts = nil
    opts = (opts ? opts.dup : Hash.new)
    ary = []
    argv.each {|arg|
      case arg
      when /^-(\w+)[:=](.*)$/ then
        opts[$1.to_sym] = $2
      when /^-(\w+)$/ then
        opts[$1.to_sym] = true
      else
        ary.push arg
      end
    }
    [ary, opts]
  end

  def optparse!(argv, opts = nil)
    @args, @opts = optparse(argv, opts)
  end

  def getconn suri, serverp = true
    require 'uri'
    uri = URI.parse(suri)
    case uri.scheme
    when 'file', 'unix' then
      if serverp then
        serv = UNIXServer.new(uri.path)
        return serv.accept
      else
        return UNIXSocket.new(uri.path)
      end
    when 'jmasock' then
      if serverp then
        serv = TCPServer.new(uri.host, uri.port)
        return serv.accept
      else
        return TCPSocket.new(uri.host, uri.port)
      end
    end
    raise "unknown scheme #{scheme}"
  end

end # module RMSS
