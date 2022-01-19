
require 'socket'

module RMSS

  def sendsock(sock, msg, msgtype = 'BI')
    shdr = sprintf('%08u%2s', msg.size, msgtype)
    r = sock.sendmsg(shdr)
    raise Errno::EMSGSIZE unless r == shdr.size
    sock.sendmsg(msg)
    raise Errno::EMSGSIZE unless r == shdr.size
    nil
  end

  def recvsock(sock)
    shdr = sock.recvmsg(10)
    raise Errno::EMSGSIZE unless shdr[0].size == 10
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

  def getconn argv, opts = nil
    args, opts = optparse(argv)
    require 'uri'
    uri = URI.parse(args.first)
    case uri.scheme
    when 'file' then
      serv = UNIXServer.new(uri.path)
      return serv.accept
    when 'tcp' then
      serv = TCPServer.new(uri.host, uri.port)
      return serv.accept
    end
    raise "unknown scheme #{scheme}"
  end

end # module RMSS
