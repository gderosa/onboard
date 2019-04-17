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

end
