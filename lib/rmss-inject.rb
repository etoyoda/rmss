# ソケット監視プログラム。
#

require 'rmss'

class RMSSInject
  include RMSS

  def main sock, fnam
    msg = (fnam ? File.open(fnam) : STDIN).read
    sendsock(sock, msg)
  end

  def initialize
    @args, @opts = nil
  end

  def run argv
    optparse!(argv)
    uriout = @args.shift
    filein = @args.shift
    getconn(uriout, false){|conn| main(conn, filein) }
  end

end

RMSSInject.new.run(ARGV) if $0 == __FILE__
