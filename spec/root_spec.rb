require 'rspec'
require 'rack/test'

describe 'The App Root' do
  include Rack::Test::Methods

  def app
    OnBoard::Controller
  end

  it "responds with landing page" do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to include('Linux-based Networking')
  end
end
