require 'uri'
require 'socket'

class AdHocHTTP
  attr_reader :uri, :socket, :read_buffer

  DEFAULT_HEADERS = {
    'User-Agent' => 'AdHocHTTP',
    'Accept' => '*/*',
    'Connection' => 'close'
  }

  def initialize(uri)
    @uri = URI.parse(uri)
    @socket = nil
    @read_buffer = ''
  end

  def blocking_get
    host = uri.host
    port = uri.port

    address = Socket.getaddrinfo(host, nil, Socket::AF_INET).first[3]
    socket_address = Socket.pack_sockaddr_in(port, address)
    socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
    socket.connect(socket_address)

    http_msg = "GET #{uri.request_uri} HTTP/1.1\r\n"
    DEFAULT_HEADERS.each do |header, value|
      http_msg += "#{header}: #{value}\r\n"
    end
    http_msg += "\r\n"
    socket.write(http_msg)
    parse_response(socket.read)
  ensure
    socket&.close
  end

  def init_non_blocking_get
    @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

    socket
  end

  def connect_non_blocking_get
    host = uri.host
    port = uri.port
    address = Socket.getaddrinfo(host, nil, Socket::AF_INET).first[3]
    socket_address = Socket.pack_sockaddr_in(port, address)

    socket.connect_nonblock(socket_address, exception: false)
  end

  def write_non_blocking_get
    http_msg = "GET #{uri.request_uri} HTTP/1.1\r\n"
    DEFAULT_HEADERS.each do |header, value|
      http_msg += "#{header}: #{value}\r\n"
    end
    http_msg += "\r\n"
    socket.write_nonblock(http_msg, exception: false)
  end

  def read_non_blocking_get
    parse_partial_response(socket.read_nonblock(65536, exception: false))
  end

  def close_non_blocking_get
    socket&.close
  end

  def parse_partial_response(response)
    return :wait_readable if response == :wait_readable

    if response != nil
      read_buffer << response
      return :wait_readable
    end

    parse_response(read_buffer)
  end

  def parse_response(response)
    status = response.match(/HTTP\/1\.1 (\d{3})/i)[1]
    body = response.match(/(?:\r\n){2}(.*)\z/im)[1]

    [status, body]
  end
end
