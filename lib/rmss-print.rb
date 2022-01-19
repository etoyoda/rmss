# ソケット監視プログラム。
#
# rmss-print.rb unix /path
# rmss-print.rb tcp host port

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

  def run argv
    loop {
      mainloop(getconn(argv))
    }
  end

end

RMSSPrint.new.run(ARGV) if $0 == __FILE__
