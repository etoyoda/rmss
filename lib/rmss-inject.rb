# ソケット監視プログラム。
#

require 'rmss'

class RMSSInject
  include RMSS

  def main sock, fnam
    sleep((@opts[:cwait] || 1).to_i)
    msg = (fnam ? File.open(fnam) : STDIN).read
    msgtype = @opts[:msgtype] || 'bI'
    sendsock(sock, msg, msgtype)
    # チェックポイント要求をしていたら応答を受ける
    if /^(bI|aN|fX)$/ =~ msgtype then
      mt, mr = recvsock(sock)
      raise "unexpected msgtype #{mt}" unless 'EN' == mt
      raise "wrong checkpoint" unless 'ACK' + msg.byteslice(0,30) == mr
      dprint "checkpoint ok"
    end
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
