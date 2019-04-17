describe 'RADIUS admin' do

  def app
    OnBoard::Controller
  end

  let(:user_creation_data) do
    {
      'check': {
        'User-Name': "__user_test",
        'Password-Type': "SSHA1-Password",
        'User-Password': "p"
      },
      'confirm': {  # TODO: make this not required on json
        'check': {
          'User-Password': "p"
        }
      }
    }
  end

  it "responds with db table info" do
    get '/services/radius/config.json'
    expect(last_response).to be_ok
    expect(last_response.body).to have_json_path("accounting/table")
  end

  it "responds with db table info (/api/v1)" do
    get '/api/v1/services/radius/config'
    expect(last_response).to be_ok
    expect(last_response.body).to have_json_path("accounting/table")
  end

  it "creates a user" do
    # cleanup, no matter what
    delete_json '/services/radius/users/__user_test.json'
    #
    post_json '/services/radius/users.json', user_creation_data
    expect(last_response.status).to eq(201)
 end

  it "deletes a user" do
    delete_json '/services/radius/users/__user_test.json'
    expect(last_response.status).to be_between(200, 399)  # OKs or redirs
    get_json '/services/radius/users/__user_test.json'
    expect(last_response.status).to eq(404)
  end

  it "creates a user (/api/v1)" do
    # cleanup, no matter what
    delete_json '/api/v1/services/radius/users/__user_test'
    #
    post_json '/services/radius/users.json', user_creation_data
    expect(last_response.status).to eq(201)
    get_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.body).to be_json_eql(%("__user_test")).at_path("user/check/1/User-Name")
 end

  it "deletes a user (/api/v1)" do
    delete_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.status).to be_between(200, 399)  # OKs or redirs
    get_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.status).to eq(404)
  end
end
