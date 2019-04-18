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
      'confirm': {  # TODO: make this not required on json?
        'check': {
          'User-Password': "p"
        }
      }
    }
  end

  let(:complex_new_user_data) do
    {
      "user": {
        "name": "__user_test",
        "check": [
          {
            "User-Name": "__user_test",
            "Attribute": "User-Name",
            "Operator": ":=",
            "Value": "__user_test"
          },
          {
            "User-Name": "__user_test",
            "Attribute": "SSHA1-Password",
            "Operator": ":=",
            "Value": "Yg+Zkt25hotWV4vLYXcEjGZv153BmsHJMilz0+XT15W5J4S78ieoZQ=="
          },
          {
            "User-Name": "__user_test",
            "Attribute": "Login-Time",
            "Operator": ":=",
            "Value": "Wk2305-0855,Sa,Su2305-1655"
          }
        ],
        "reply": [
          {
            "User-Name": "__user_test",
            "Attribute": "Reply-Message",
            "Operator": ":=",
            "Value": "my reply msg"
          },
          {
            "User-Name": "__user_test",
            "Attribute": "Session-Timeout",
            "Operator": ":=",
            "Value": "7200"
          },
          {
            "User-Name": "__user_test",
            "Attribute": "Idle-Timeout",
            "Operator": ":=",
            "Value": "1800"
          },
          {
            "User-Name": "__user_test",
            "Attribute": "WISPr-Bandwidth-Max-Down",
            "Operator": ":=",
            "Value": "800000"
          },
          {
            "User-Name": "__user_test",
            "Attribute": "WISPr-Bandwidth-Max-Up",
            "Operator": ":=",
            "Value": "400000"
          }
        ],
        "groups": [

        ],
        "personal": {
          "User-Name": "__user_test",
          "First-Name": "Jonathan",
          "Last-Name": "Swift",
          "Email": "johnny@begood.net",
          "Work-Phone": "+353 1 1234567",
          "Home-Phone": "+353 1 7654321",
          "Mobile-Phone": "+353 85 5555555",
          "Address": "St Patrick's Cathedral",
          "City": "Dublin",
          "State": "",
          "Country": nil,
          "Postal-Code": "D08 H6X3",
          "Notes": "A quick note.",
          "Creation-Date": "2019-04-17 21:20:13 +0000",
          "Update-Date": "2019-04-17 22:04:35 +0000",
          "Birth-Date": "1977-11-30",
          "Birth-City": "Dublin",
          "Birth-State": "",
          "ID-Code": "",
          "Attachments": [

          ]
        },
        "accepted_terms": [

        ]
      }
    }
  end

  it "creates a user" do
    # cleanup, no matter what
    delete_json '/api/v1/services/radius/users/__user_test'
    #
    post_json '/api/v1/services/radius/users', user_creation_data
    expect(last_response.status).to eq(201)
    get_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.body).to be_json_eql(%("__user_test")).at_path("user/check/1/User-Name")
  end

  it "replaces user data" do
    put_json '/api/v1/services/radius/users/__user_test', complex_new_user_data
    expect(last_response).to be_ok
    # puts last_response.body
  end

  it "deletes a user" do
    delete_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.status).to be_between(200, 399)  # OKs or redirs
    get_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.status).to eq(404)
  end
end
