#!/usr/bin/env ruby

require 'socket'
require 'msgpack'

server = UDPSocket.new
server.bind "127.0.0.1", 5309

begin
  p MessagePack.unpack server.recv_nonblock(576)
rescue IO::WaitReadable
  IO.select([server]) # blocks until readable
  retry
end
