class LookupHttp

  def initialize(opts={})
    require 'net/http'
    require 'net/https'
    @config = opts

    @debug_log = @config[:debug_log]
    @http = Net::HTTP.new(@config[:host], @config[:port])
    @http.read_timeout = @config[:http_read_timeout] || 10
    @http.open_timeout = @config[:http_connect_timeout] || 10

    if @config[:use_ssl]
      @http.use_ssl = true

      if @config[:ssl_verify] == false
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      else
        @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      if @config[:ssl_cert]
        store = OpenSSL::X509::Store.new
        store.add_cert(OpenSSL::X509::Certificate.new(File.read(@config[:ssl_ca_cert])))
        @http.cert_store = store

        @http.key = OpenSSL::PKey::RSA.new(File.read(@config[:ssl_cert]))
        @http.cert = OpenSSL::X509::Certificate.new(File.read(@config[:ssl_key]))
      end
    else
      @http.use_ssl = false
    end
  end

  def parse_response(answer)
    return unless answer

    format = @config[:output] || 'plain'
    log_debug("[lookup_http]: Query returned data, parsing response as #{format}")

    case format
    when 'json'
      parse_json answer
    when 'yaml'
      parse_yaml answer
    else
      answer
    end
  end

  # Handlers
  # Here we define specific handlers to parse the output of the http request
  # and return its structured representation.  Currently we support YAML and JSON
  #
  def parse_json(answer)
    require 'rubygems'
    require 'json'
    JSON.parse(answer)
  end

  def parse_yaml(answer)
    require 'yaml'
    YAML.load(answer)
  end


  def get_parsed(path)
    httpreq = Net::HTTP::Get.new(path)

    if @config[:use_auth]
      httpreq.basic_auth @config[:auth_user], @config[:auth_pass]
    end

    if @config[:headers]
      @config[:headers].each do |name,content|
        httpreq.add_field name.to_s, content
      end
    end

    begin
      httpres = @http.request(httpreq)
    rescue Exception => e
      Hiera.warn("[lookup_http]: Net::HTTP threw exception #{e.message}")
      raise Exception, e.message unless @config[:failure] == 'graceful'
      return
    end

    unless httpres.kind_of?(Net::HTTPSuccess)
      log_debug("[lookup_http]: bad http response from #{@config[:host]}:#{@config[:port]}#{path}")
      log_debug("HTTP response code was #{httpres.code}")
      unless httpres.code == '404' && @config[:ignore_404]
        raise Exception, 'Bad HTTP response' unless @config[:failure] == 'graceful'
      end
      return
    end

    parse_response httpres.body
  end

  ## This allows us to pass Hiera.debug or Jerakia.log.debug to the lookup_http class
  ## we should find a better way to handle logging withing LookupHttp
  def log_debug(msg)
    if @debug_log
      eval "#{@debug_log} '#{msg}'"
    end
  end


end

