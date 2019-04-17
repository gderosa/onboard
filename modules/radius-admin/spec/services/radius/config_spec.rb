describe 'RADIUS admin' do

  def app
    OnBoard::Controller
  end

  it "responds with db table info" do
    get_json '/services/radius/config.json'
    expect(last_response).to be_ok
    expect(last_response.body).to have_json_path("accounting/table")
  end

end
