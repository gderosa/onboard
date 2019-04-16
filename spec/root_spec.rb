ENV['APP_ENV'] = 'test'

require './onboard'  # <-- your sinatra app

require 'rspec'
require 'rack/test'

describe 'The App Root' do
  include Rack::Test::Methods

  def app
    OnBoard::Controller
  end

  it "responds with a 200" do
    get '/'
    expect(last_response).to be_ok
    #expect(last_response.body).to eq('Hello World')
  end
end
