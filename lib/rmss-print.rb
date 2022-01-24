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
      puts "\a# message #{msgtype}"
      puts msg
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
    }
  end

end

RMSSPrint.new.run(ARGV) if $0 == __FILE__
