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
      msgtype, msg = getsock(sock)
      puts "\a# message #{msgtype}"
      puts msg
    }
    puts "# disconnected"
  end

  def initialize
    @args, @opts = nil
  end

  def run argv
    optparse!(argv, :mode=>'passive')
    passivep = @opts[:mode] == 'passive'
    loop {
      mainloop(getconn(@args.first, passivep))
    }
  end

end

RMSSPrint.new.run(ARGV) if $0 == __FILE__
