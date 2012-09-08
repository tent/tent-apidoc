require 'bundler/setup'
require 'tent-client'
require 'tentd'
require 'rack/utils'

ENV['TENT_ENTITY'] = 'https://example.org'

class TentApiDoc
  class FaradayAdapter < Faraday::Adapter::Rack
    def call(env)
      env[:request_body] = env[:body].dup if env[:body]
      super
    end
  end

  Faraday.register_middleware :adapter, :tent_rack => FaradayAdapter

  class << self
    attr_accessor :examples

    def clients
      @clients ||= begin
        adapter = [:tent_rack, TentD.new(:database => 'postgres://localhost/tent_doc').tap { DataMapper.auto_migrate! }]
        TentD.faraday_adapter = adapter # tentception
        {
          :base => TentClient.new('https://example.com', :faraday_adapter => adapter)
        }
      end
    end

    def example(name)
      (@examples ||= {})[name] = response_to_markdown(yield)
    end

    def variables
      @variables ||= {}
    end

    private

    def response_to_markdown(response)
      return unless response
      markdown = request_markdown(response.env)
      markdown += body_markdown(response.env[:request_body])
      markdown += response_head_markdown(response)
      markdown += body_markdown(response.body)
    end

    def request_markdown(env)
      request = "#{env[:method].to_s.upcase} #{env[:url].request_uri} HTTP/1.1\n"
      request += header_string(env[:request_headers])
      fenced_code(request)
    end

    def response_head_markdown(response)
      head = "HTTP/1.1 #{response.status} #{Rack::Utils::HTTP_STATUS_CODES[response.status]}\n"
      response.headers.delete('X-Cascade')
      head += header_string(response.headers)
      fenced_code(head)
    end

    def body_markdown(body)
      return '' if body.nil? || body.respond_to?(:empty?) && body.empty?
      body = (body.rewind && body.read) if body.respond_to?(:read)
      fenced_code(body)
    end

    def header_string(headers)
      headers.map { |k,v| "#{k}: #{v}" }.join("\n")
    end

    def fenced_code(code)
      language = if code.kind_of?(Hash) || code.kind_of?(Array)
        code = JSON.pretty_generate(code)
        'json'
      elsif code.match(/\A\s*\{/)
        code = JSON.pretty_generate(JSON.parse(code))
        'json'
      else
        'text'
      end
      "\n```#{language}\n#{code}\n```\n"
    end

    def client_options(authable)
      authable.auth_details.merge(:faraday_adapter => TentD.faraday_adapter)
    end
  end
end

TentApiDoc.clients

require 'tent-apidoc/examples'
