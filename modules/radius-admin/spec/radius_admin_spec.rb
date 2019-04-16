require 'rspec'
require 'rack/test'
require 'json_spec'

describe 'RADIUS admin' do
  include Rack::Test::Methods
  include JsonSpec::Helpers

  def app
    OnBoard::Controller
  end

  it "responds with db table info" do
    get '/services/radius/config.json'
    expect(last_response).to be_ok
    expect(last_response.body).to have_json_path("accounting/table")
  end
end
