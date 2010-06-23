require 'helper'

class MockRackApp
  def call
    [200, {}, "OK"]
  end  
end

def app
  Rack::Builder.new {
    use B::List
    run lambda { |env| [200, {}, ["Success"]] }
  }.to_app
end

class TestBList < Test::Unit::TestCase
  include Rack::Test::Methods
  
  context "Given a rack app that uses B::List" do
    setup do
      get "/b-list/auth"
      assert_equal 200, last_response.status_code
    end
  end
end
