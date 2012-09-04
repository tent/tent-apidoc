require 'bundler/setup'
require 'tent-client'
require 'tentd'
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

    def clients
      @clients ||= begin
        adapter = [:tent_rack, TentD.new(:database => 'postgres://localhost/tent_doc').tap { DataMapper.auto_migrate! }]
        app = TentD::Model::App.create
        app_auth = app.authorizations.create(
          :scopes => %w{ read_posts write_posts import_posts read_profile write_profile read_followers write_followers read_followings write_followings read_groups write_groups read_permissions write_permissions read_apps write_apps follow_ui read_secrets write_secrets },
          :profile_info_types => ['all'],
          :post_types => ['all']
        )
        follower = TentD::Model::Follower.create(:entity => 'http://example.org')
        {
          :app => TentClient.new('https://example.com', {:faraday_adapter => adapter}.merge(app.auth_details)),
          :app_auth => TentClient.new('https://example.com', {:faraday_adapter => adapter}.merge(app_auth.auth_details)),
          :follower => TentClient.new('https://example.com', {:faraday_adapter => adapter}.merge(follower.auth_details))
        }
      end
    end

    def example(name)
      (@examples ||= {})[name] = response_to_markdown(yield(clients))
    end

    private

    def response_to_markdown(response)
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
      return '' if body.nil? || body.empty?
      fenced_code(body)
    end

    def header_string(headers)
      headers.map { |k,v| "#{k}: #{v}" }.join("\n")
    end

    def fenced_code(code)
      language = if code.kind_of?(Hash)
        code = JSON.pretty_generate(code)
        'json'
      else
        'text'
      end
      "\n```#{language}\n#{code}\n```\n"
    end
  end
end

require 'tent-apidoc/examples'
