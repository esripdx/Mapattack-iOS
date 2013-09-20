#!/usr/bin/env ruby

require 'socket'
require 'msgpack'

PORT = 5309

server = UDPSocket.new
server.bind "192.168.56.160", PORT

loop {
  unpacked = nil
  sender_inet_addr = nil

  begin
    data, sender_inet_addr = server.recvfrom_nonblock(576)
    puts "received data from #{sender_inet_addr}:"
    unpacked = MessagePack.unpack data
    p unpacked
  rescue IO::WaitReadable
    IO.select([server]) # blocks until readable
    retry
  end

  send_host = sender_inet_addr[3]
  send_port = sender_inet_addr[1]

  puts "sending data to #{send_host}:#{send_port}"
  5.times do |n|
    server.send MessagePack.pack(unpacked.merge(id: n)), Socket::MSG_DONTWAIT, send_host, send_port
    sleep 1
  end
}
