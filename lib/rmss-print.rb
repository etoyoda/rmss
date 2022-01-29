# ソケット監視プログラム。
#
# rmss-print.rb [-mode=active] [file:///socket|jmasock://host:port]
#

require 'rmss'

class RMSSPrint
  include RMSS

  def mainloop sock
    puts "# accepts"
    loop {
      msgtype, msg = recvsock(sock)
      # メッセージの表示
      puts "\a# message #{msgtype}"
      puts msg
      # ヘルスチェック応答
      if msgtype == 'EN' and msg == 'chk' then
        sendsock(sock, 'CHK', 'EN')
      # チェックポイント応答
      elsif /^(aN|bI|fX)$/ =~ msgtype then
        sendsock(sock, 'ACK' + msg.byteslice(0,30), 'EN')
      end
    }
  rescue Errno::EPIPE
    puts "# epipe"
  ensure
    puts "# disconnected"
  end

  def initialize
    @args, @opts = nil
  end

  def run argv
    optparse!(argv, :mode=>'passive')
    passivep = @opts[:mode] == 'passive'
    loop {
      getconn(@args.first, passivep){|conn| mainloop(conn)}
      break if @opts[:once]
    }
  end

end

RMSSPrint.new.run(ARGV) if $0 == __FILE__
