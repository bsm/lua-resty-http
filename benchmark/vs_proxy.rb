=begin
Very naive resty.http vs capture/proxy benchmark:

    $ ruby benchmark/vs_proxy.rb
    == Sinatra/1.3.3 has taken the stage on 1986 for test with backup from Thin
    >> Thin web server (v1.5.0 codename Knife)
    >> Maximum connections set to 1024
    >> Listening on 0.0.0.0:1986, CTRL+C to stop
    Rehearsal --------------------------------------------------------
    S via resty.http       0.110000   0.030000   0.140000 (  0.147134)
    S via capture/proxy    0.080000   0.010000   0.090000 (  0.104620)
    L via resty.http       0.020000   0.020000   0.040000 (  0.056494)
    L via capture/proxy    0.030000   0.010000   0.040000 (  0.166540)
    ----------------------------------------------- total: 0.310000sec

                               user     system      total        real
    S via resty.http       0.040000   0.020000   0.060000 (  0.073327)
    S via capture/proxy    0.040000   0.030000   0.070000 (  0.084767)
    L via resty.http       0.010000   0.020000   0.030000 (  0.048865)
    L via capture/proxy    0.020000   0.020000   0.040000 (  0.172873)

=end
ENV['RACK_ENV'] ||= 'test'

require 'bundler/setup'
require 'resty_test'
require 'benchmark'

RestyTest.configure do |c|
  c.root = File.expand_path("../../spec/resty", __FILE__)
  c.config_file = File.expand_path("../nginx.conf", __FILE__)
end

BACKEND = Thread.new do
  require 'sinatra/base'

  class Server < Sinatra::Base

    get '/*' do
      len = params[:len].to_i if params[:len]
      "A" * (len || 1024)
    end

    run! port: 1986
  end
end

RestyTest.start!
sleep(1)
client = Excon.new("http://127.0.0.1:1984")
lquery = { len: (1024 * 1024 * 2), times: 5 }


Benchmark.bmbm(20) do |x|
  x.report "S via resty.http" do
    raise "Invalid response size" unless client.post(path: "/http").body == "102400"
  end
  x.report "S via capture/proxy" do
    raise "Invalid response size" unless client.post(path: "/capture").body == "102400"
  end

  x.report "L via resty.http" do
    raise "Invalid response size" unless client.post(path: "/http", query: lquery).body == "10485760"
  end
  x.report "L via capture/proxy" do
    raise "Invalid response size" unless client.post(path: "/capture", query: lquery).body == "10485760"
  end
end

BACKEND.exit
sleep(0.1) while BACKEND.alive?
RestyTest.stop!
