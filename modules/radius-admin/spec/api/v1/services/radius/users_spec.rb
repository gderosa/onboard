describe 'RADIUS admin' do

  def app
    OnBoard::Controller
  end

  let(:user_creation_data) do
    {
      'check': {
        'User-Name': "__user_test",
        'Password-Type': "SSHA1-Password",
        'User-Password': "pass"
      },
      'confirm': {
        'check': {
          'User-Password': "pass"
        }
      }
    }
  end

  let(:user_modification_data) do
    {
      'check': {
        'Password-Type': "SSHA1-Password",
        'User-Password': "newpass",
        'Auth-Type': "Reject",
        'check[Login-Time]': "Wk2305-0855,Sa,Su2305-1655"
      },
      'confirm': {
        'check': {
          'User-Password': "newpass"
        }
      }
    }
  end

  let(:expected_json_ater_modification) do
    # Some details may differ e.g. password may be encrypted with a different "salt" etc.
    <<-END
    {
      "user": {
        "name": "__user_test",
        "check": [
          {
            "Id": 57,
            "User-Name": "__user_test",
            "Attribute": "User-Name",
            "Operator": ":=",
            "Value": "__user_test"
          },
          {
            "Id": 59,
            "User-Name": "__user_test",
            "Attribute": "SSHA1-Password",
            "Operator": ":=",
            "Value": "5E0+LXhlpobHHhmYadzzif1j3CvzrHkNEkb9HSbVB96RIsZl8oUb4w=="
          },
          {
            "Id": 60,
            "User-Name": "__user_test",
            "Attribute": "Auth-Type",
            "Operator": ":=",
            "Value": "Reject"
          },
          {
            "Id": 61,
            "User-Name": "__user_test",
            "Attribute": "check[Login-Time]",
            "Operator": ":=",
            "Value": "Wk2305-0855,Sa,Su2305-1655"
          }
        ],
        "reply": [

        ],
        "groups": [

        ],
        "personal": {
          "Attachments": [

          ]
        },
        "accepted_terms": null
      }
    }
    END
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
    put_json '/api/v1/services/radius/users/__user_test', user_modification_data
    expect(last_response).to be_ok
    puts last_response.body
  end

  it "deletes a user" do
    delete_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.status).to be_between(200, 399)  # OKs or redirs
    get_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.status).to eq(404)
  end
end
