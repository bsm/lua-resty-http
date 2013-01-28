ENV['RACK_ENV'] ||= 'test'

require 'bundler/setup'
require 'rspec'
require 'resty_test'
require 'multi_json'

BACKEND = Thread.new do
  require 'sinatra/base'

  class Server < Sinatra::Base
    set :port, 1986

    get '/' do
      "Hello World!"
    end

    post '/echo' do
      "ECHO #{request.body.string}"
    end

    get '/back/end' do
      case params[:size]
      when "xl" then "A" * (4.6 * 1024 * 1024)
      else           "A" * 1024
      end
    end

    run!
  end
end

sleep(1)

RSpec.configure do |c|
  c.before :suite do
    RestyTest.start!
  end
  c.after :suite do
    BACKEND.exit
    RestyTest.stop!
  end
end