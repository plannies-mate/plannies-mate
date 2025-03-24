# frozen_string_literal: true

require_relative 'application_controller'

require 'sinatra/json'

# Development / debug endpoints not visible from outside
class DevelopController < ApplicationController
  NOT_FOUND_PATH = '/errors/404.html'

  # We're already using Sinatra::JSON from contrib
  # register Sinatra::Contrib

  get '/' do
    locals = { title: 'APP Endpoints',
               get_paths: get_paths,
               post_paths: method_paths('POST'), }
    app_helpers.render 'root', locals
  end

  get '/debug' do
    content_type :json
    json(
      env: ENV.fetch('RACK_ENV', nil),
      roundup_request_file: app_helpers.roundup_request_file,
      roundup_request_file_exists: File.exist?(app_helpers.roundup_request_file)
    )
  end

  # Serve static files
  # Used for development paths not automatically mapped to static files
  get '/*' do
    path = params[:splat].first
    serve_path(path)
  end

  private

  def serve_path(path)
    file_path = File.join(app_helpers.site_dir, path)

    try_paths = %W[#{file_path}
                   #{file_path}.html
                   #{file_path}/index.html
                   #{file_path}.default.html
                   #{file_path}/default.html]
    try_path = try_paths.find { |p| File.exist?(p) && !File.directory?(p) } unless app_helpers.production?
    if try_path
      set_content_type(try_path)
      if path =~ %r{\A/errors/(\d+)}
        # TODO: set response code to $1
      end
      send_file try_path
    elsif path == NOT_FOUND_PATH
      set_content_type('.txt')
      halt 404, 'File not found!'
    else
      serve_path(NOT_FOUND_PATH)
    end
  end

  def get_paths
    paths = method_paths('GET')
    paths << '/index.html'
    paths << '/authorities'
    paths << '/crikey-whats-that'
    paths << '/scrapers'
    paths << '/repos'
    paths << '/robots.txt'
    paths
  end

  def method_paths(http_method)
    paths = []
    Constants::ROUTES.each do |route|
      paths << route[:controller].routes[http_method]&.map do |r|
        "#{route[:path]}#{r[0]}".sub(%r{\A/+}, '/').sub(%r{(?!^)/\z}, '')
      end
    end
    paths.flatten.compact.sort
  end

  def set_content_type(filename)
    value = case File.extname(filename).downcase
            when '.html' then 'text/html'
            when '.js' then 'application/javascript'
            when '.css' then 'text/css'
            when '.ico' then 'image/x-icon'
            when '.json' then 'application/json'
            when '.png' then 'image/png'
            when '.txt' then 'text/plain'
            else filename
            end
    content_type(value)
    value
  end

  # def get_list_entry(get_paths)
  #   get_li = '<li><span class="endpoint get-endpoint">'
  #   end_li = '</span></li>'
  #   get_list = get_paths.map { |path| "#{get_li}<a href=\"#{path}\">#{path}</a>#{end_li}" }
  #
  #   <<~HTML
  #     <h2>GET Endpoints</h2>
  #     <ul>
  #       #{get_list.join("\n")}
  #     </ul>
  #   HTML
  # end

  # def post_list_entry(post_paths)
  #   post_li = '<li><span class="endpoint post-endpoint">'
  #   end_li = '</span></li>'
  #   post_list = post_paths.map do |path|
  #     # "#{post_li}#{path} <form action=\"#{path}\" method=\"post\"><input type=\"submit\"></input></form>#{end_li}"
  #     "#{post_li}<form action=\"#{path}\" method=\"post\"><button>#{path}</button></form>#{end_li}"
  #   end
  #
  #   <<~HTML
  #     <h2>POST Endpoints</h2>
  #     <ul>
  #       #{post_list.join("\n")}
  #     </ul>
  #   HTML
  # end
end
