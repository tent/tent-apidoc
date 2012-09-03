require 'bundler/setup'
require 'tent-client'
require 'tent-server'
require 'rack/utils'

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

    def client
      @client ||= begin
        adapter = [:tent_rack, TentD.new(:database => 'postgres://localhost/tent_doc').tap { DataMapper.auto_migrate! }]
        TentClient.new('https://example.com', :faraday_adapter => adapter)
      end
    end

    def example(name)
      (@examples ||= {})[name] = response_to_markdown(yield(client))
    end

    private

    def response_to_markdown(response)
      markdown = request_markdown(response.env)
      markdown += body_markdown(response.env[:request_body])
      markdown += response_head_markdown(response)
      markdown += body_markdown(response.body)
    end

    def request_markdown(env)
      request = ["#{env[:method].to_s.upcase} #{env[:url].request_uri} HTTP/1.1"]
      request += header_string(env[:request_headers])
      fenced_code(request)
    end

    def response_head_markdown(response)
      head = ["HTTP/1.1 #{response.status} #{Rack::Utils::HTTP_STATUS_CODES[response.status]}"]
      response.headers.delete('X-Cascade')
      head += header_string(response.headers)
      fenced_code(head)
    end

    def body_markdown(body)
      content = body.respond_to?(:read) ? body.read : body
      return '' if body.nil? || body.empty?
      fenced_code(body)
    end

    def header_string(headers)
      headers.map { |k,v| "#{k}: #{v}" }
    end

    def fenced_code(lines)
      lines = Array(lines)
      language = lines.first.match(/\A\s+\{/) ? 'json' : 'text'
      Array(lines).unshift("\n```#{language}").push("```\n").join("\n")
    end
  end
end
