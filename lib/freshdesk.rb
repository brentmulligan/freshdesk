# Ruby bindings
require 'cgi'
require 'set'
require 'openssl'
require 'rest_client'
require 'json'
require 'yaml'


# Version
require 'freshdesk/version'

# API operations
require 'freshdesk/api_operations/create'
require 'freshdesk/api_operations/update'
require 'freshdesk/api_operations/delete'
require 'freshdesk/api_operations/list'

# Resources
require 'freshdesk/util'
require 'freshdesk/fresh_object'
require 'freshdesk/api_resource'
require 'freshdesk/singleton_api_resource'
require 'freshdesk/list_object'
require 'freshdesk/ticket'

# Errors
require 'freshdesk/errors/fresh_error'
require 'freshdesk/errors/api_connection_error'
require 'freshdesk/errors/authentication_error'

module Freshdesk
  @api_base = 'http://merchbro.freshdesk.com/'

  #@api_key = ''

  class << self
    attr_accessor :api_key, :api_base, :api_version
  end

  def self.api_url(url='')
    url = url.include?('tickets') ? 'helpdesk' + url + '.json' : url
    @api_base + url
  end

  def self.request(method, url, api_key, params={}, headers={})

    unless api_key ||= @api_key
      raise AuthenticationError.new('No API key provided. ' +
                                    'Set your API key using "Freshdesk.api_key = <API-KEY>".')
    end

    if api_key =~ /\s/
      raise AuthenticationError.new('Your API key is invalid, as it contains whitespace.')
    end

    params = Util.objects_to_ids(params)
    url = api_url(url)

    case method.to_s.downcase.to_sym
    when :get, :head, :delete
      # Make params into GET parameters
      url += "#{URI.parse(url).query ? '&' : '?'}#{uri_encode(params)}" if params && params.any?
      payload = nil
    else
      payload = uri_encode(params)
    end

    request_opts = {  :headers => request_headers(api_key).update(headers),
                      :method => method, :open_timeout => 30,
                      :payload => payload, :url => url, :timeout => 80 }

    begin
      puts url
      response = execute_request(request_opts)
    rescue SocketError => e
      handle_restclient_error(e)
    rescue NoMethodError => e
      # Work around RestClient bug
      if e.message =~ /\WRequestFailed\W/
        e = APIConnectionError.new('Unexpected HTTP response code')
        handle_restclient_error(e)
      else
        raise
      end
    rescue RestClient::ExceptionWithResponse => e
      if rcode = e.http_code and rbody = e.http_body
        handle_api_error(rcode, rbody)
      else
        handle_restclient_error(e)
      end
    rescue RestClient::Exception, Errno::ECONNREFUSED => e
      handle_restclient_error(e)
    end

    puts response
    [parse(response), api_key]
  end


  private

  def self.execute_request(opts)
    RestClient::Request.execute(opts)
  end

  def self.parse(response)
    begin
      # Would use :symbolize_names => true, but apparently there is
      # some library out there that makes symbolize_names not work.
      response = JSON.parse(response.body)
    rescue JSON::ParserError
      raise general_api_error(response.code, response.body)
    end

    Util.symbolize_names(response)
  end

  def self.handle_api_error(rcode, rbody)
    begin
      error_obj = JSON.parse(rbody)
      error_obj = Util.symbolize_names(error_obj)
      error = error_obj[:error] or raise FreshError.new # escape from parsing

    rescue JSON::ParserError, FreshError
      raise general_api_error(rcode, rbody)
    end

    case rcode
    when 400, 404
      raise invalid_request_error error, rcode, rbody, error_obj
    when 401
      raise authentication_error error, rcode, rbody, error_obj
    else
      raise api_error error, rcode, rbody, error_obj
    end

  end

  def self.general_api_error(rcode, rbody)
    APIError.new("Invalid response object from API: #{rbody.inspect} " +
                     "(HTTP response code was #{rcode})", rcode, rbody)
  end

  def self.invalid_request_error(error, rcode, rbody, error_obj)
    InvalidRequestError.new(error[:message], error[:param], rcode, rbody, error_obj)
  end

  def self.authentication_error(error, rcode, rbody, error_obj)
    AuthenticationError.new(error[:message], rcode, rbody, error_obj)
  end

  def self.api_error(error, rcode, rbody, error_obj)
    APIError.new(error[:message], rcode, rbody, error_obj)
  end

  def self.handle_restclient_error(e)
    case e
    when RestClient::ServerBrokeConnection, RestClient::RequestTimeout
      message = "Could not connect to Freshdesk (#{@api_base}). " +
          "Please check your internet connection and try again. " +
          "If this problem persists, you should check Freshdesk's service status."

    else
      message = "Unexpected error communicating with Freshdesk. "

    end

    raise APIConnectionError.new(message + "\n\n(Network error: #{e.message})")
  end

  def self.user_agent
    @uname ||= get_uname
    lang_version = "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})"

    {
        :bindings_version => Freshdesk::VERSION,
        :lang => 'ruby',
        :lang_version => lang_version,
        :platform => RUBY_PLATFORM,
        :publisher => 'bme',
        :uname => @uname
    }

  end

  def self.get_uname
    `uname -a 2>/dev/null`.strip if RUBY_PLATFORM =~ /linux|darwin/i
  rescue Errno::ENOMEM => ex # couldn't create subprocess
    "uname lookup failed"
  end


  def self.uri_encode(params)
    Util.flatten_params(params).
        map { |k, v| "#{k}=#{Util.url_encode(v)}" }.join('&')
  end


  def self.request_headers(api_key)
    password = 'X'

    headers = {
        :user_agent => "Freshdesk-Ruby #{Freshdesk::VERSION}",
        :authorization => 'Basic ' + ["#{api_key}:#{password}"].pack('m').delete("\r\n"),
        :content_type => 'application/x-www-form-urlencoded'
    }

    headers[:freshdesk_version] = api_version if api_version

    begin
      headers.update(:x_freshdesk_client_user_agent => JSON.generate(user_agent))
    rescue => e
       headers.update(:x_freshdesk_client_raw_user_agent => user_agent.inspect,
                     :error => "#{e} (#{e.class})")
    end
  end


end
