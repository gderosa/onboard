require 'rspec'
require 'rack/test'

describe 'RADIUS admin' do
  include Rack::Test::Methods

  def app
    OnBoard::Controller
  end

  it "responds with db table info" do
    get '/services/radius/config.json'
    expect(last_response).to be_ok
    expect(last_response.body).to include('radacct')
  end
end
