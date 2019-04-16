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

  it "creates a user" do
    # cleanup, no matter what
    delete '/services/radius/users/__user_test.json', { "ACCEPT" => "application/json" }
    post '/services/radius/users.json',
      '{"check":{"User-Name":"__user_test","Password-Type":"SSHA1-Password","User-Password":"p"},"confirm":{"check":{"User-Password":"p"}}}',
      { "CONTENT_TYPE" => "application/json" }
    expect(last_response.status).to eq(201)
 end

  it "deletes a user" do
    delete '/services/radius/users/__user_test.json', { "ACCEPT" => "application/json" }
    expect(last_response.status).to be_between(200, 399)  # OKs or redirs
    delete '/services/radius/users/__user_test.json', { "ACCEPT" => "application/json" }
    get '/services/radius/users/__user_test.json', { "ACCEPT" => "application/json" }
    expect(last_response.status).to eq(404)
  end
end
