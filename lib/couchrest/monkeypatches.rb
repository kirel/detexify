require File.join(File.dirname(__FILE__), 'support', 'class')
require File.join(File.dirname(__FILE__), 'support', 'blank')

# This file must be loaded after the JSON gem and any other library that beats up the Time class.
class Time
  # This date format sorts lexicographically
  # and is compatible with Javascript's <tt>new Date(time_string)</tt> constructor.
  # Note this this format stores all dates in UTC so that collation 
  # order is preserved. (There's no longer a need to set <tt>ENV['TZ'] = 'UTC'</tt>
  # in your application.)

  def to_json(options = nil)
    u = self.getutc
    %("#{u.strftime("%Y/%m/%d %H:%M:%S +0000")}")
  end

  # Decodes the JSON time format to a UTC time.
  # Based on Time.parse from ActiveSupport. ActiveSupport's version
  # is more complete, returning a time in your current timezone, 
  # rather than keeping the time in UTC. YMMV.
  # def self.parse string, fallback=nil
  #   d = DateTime.parse(string).new_offset
  #   self.utc(d.year, d.month, d.day, d.hour, d.min, d.sec)
  # rescue
  #   fallback
  # end
end

# Monkey patch for faster net/http io
if RUBY_VERSION.to_f < 1.9
  class Net::BufferedIO #:nodoc:
    alias :old_rbuf_fill :rbuf_fill
    def rbuf_fill
      if @io.respond_to?(:read_nonblock)
        begin
          @rbuf << @io.read_nonblock(65536)
        rescue Errno::EWOULDBLOCK
          if IO.select([@io], nil, nil, @read_timeout)
            retry
          else
            raise Timeout::TimeoutError
          end
        end
      else
        timeout(@read_timeout) do
          @rbuf << @io.sysread(65536)
        end
      end
    end
  end
end

module RestClient
  def self.copy(url, headers={})
    Request.execute(:method => :copy,
      :url => url,
      :headers => headers)
  end

#   class Request
#     
#     def establish_connection(uri)
#       Thread.current[:connection].finish if (Thread.current[:connection] && Thread.current[:connection].started?)
#       p net_http_class
#       net = net_http_class.new(uri.host, uri.port)
#       net.use_ssl = uri.is_a?(URI::HTTPS)
#       net.verify_mode = OpenSSL::SSL::VERIFY_NONE
#       Thread.current[:connection] = net
#       Thread.current[:connection].start
#       Thread.current[:connection]
#     end
#     
#     def transmit(uri, req, payload)
#       setup_credentials(req)
#       
#       Thread.current[:host] ||= uri.host
#       Thread.current[:port] ||= uri.port
#       
#       if (Thread.current[:connection].nil? || (Thread.current[:host] != uri.host))
#         p "establishing a connection"
#         establish_connection(uri)
#       end
# 
#       display_log request_log
#       http = Thread.current[:connection]
#       http.read_timeout = @timeout if @timeout
#       
#       begin
#         res = http.request(req, payload)
#       rescue
#         p "Net::HTTP connection failed, reconnecting"
#         establish_connection(uri)
#         http = Thread.current[:connection]
#         require 'ruby-debug'
#         debugger
#         req.body_stream = nil
#         
#         res = http.request(req, payload)
#         display_log response_log(res)
#         result res
#       else
#         display_log response_log(res)
#         process_result res
#       end
#       
#     rescue EOFError
#       raise RestClient::ServerBrokeConnection
#     rescue Timeout::Error
#       raise RestClient::RequestTimeout
#     end
#   end
  
end