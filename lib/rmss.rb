
require 'socket'
require 'timeout'

module RMSS

  def dprint *args
    return unless @opts[:debug]
    STDERR.puts(args.inspect)
  end

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
      dprint(shdr)
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
        begin
          yield serv.accept
        ensure
          File.unlink(uri.path) rescue Errno::ENOENT
        end
      else
        yield UNIXSocket.new(uri.path)
      end
    when 'jmasock' then
      host = uri.host
      host = $1 if /^\[(.+)\]$/ =~ host
      if serverp then
        serv = TCPServer.new(host, uri.port)
        yield serv.accept
      else
        cntmo = (@opts[:cntmo] || 60).to_i
        cnnrt = (@opts[:cnnrt] || 10).to_i
        cnirt = (@opts[:cnirt] || 5).to_i
        # Ruby 2 には TCPSocket.new の :connection_timeout 引数がないので
        # 面倒な書き方になる
        cnnrt.times {
          begin
            conn = nil
            Timeout.timeout(cntmo) {
              conn = TCPSocket.new(host, uri.port)
            }
            yield conn
            break
          rescue Timeout::Error
          end
          sleep(cnirt)
        }
      end
    else
      raise "unknown scheme #{scheme}"
    end
    return serverp
  end

end # module RMSS
