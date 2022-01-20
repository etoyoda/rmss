# ソケット監視プログラム。
#
# rmss-print.rb unix /path
# rmss-print.rb tcp host port

require 'rmss'

class RMSSInject
  include RMSS

  def main sock, fnam
    msg = (fnam ? File.open(fnam) : STDIN).read
    recvsock(sock, msg)
  end

  def initialize
    @args, @opts = nil
  end

  def run argv
    optparse!(argv)
    uriout = @args.shift
    filein = @args.shift
    main(getconn(uriout, false), filein)
  end

end

RMSSInject.new.run(ARGV) if $0 == __FILE__