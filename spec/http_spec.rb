require 'spec_helper'

describe "resty.http" do

  let :client do
    Excon.new("http://127.0.0.1:1984")
  end

  def request(opts = {})
    opts = {method: :get}.merge(opts)
    hash = MultiJson.load(client.request(opts).body)
    hash.keys.each do |key|
      hash[key.to_sym] = hash.delete(key)
    end
    hash
  end

  it 'should GET small pages' do
    res = request(path: "/")
    res[:headers].should include("content-length")
    res[:headers].should include("content-type")
    res[:headers]["content-length"].to_i.should == 12
    res[:body].should == "Hello World!"
  end

  it 'should normalize paths' do
    res = request()
    res[:body].size.should == 12

    res = request(path: "back/end")
    res[:body].size.should == 1024

    res = request(path: "/back/end")
    res[:body].size.should == 1024
  end

  it 'should retrieve large responses in chunks' do
    res = request(path: "/back/end", query: { size: "xl" })
    res[:headers]["content-length"].to_i.should == 4823449
    res[:body].size.should == 4823449
  end

  it 'should handle non-GETs' do
    res = request(method: :post, path: "/echo", body: "Resty!")
    res[:body].should == "ECHO Resty!"
  end

end