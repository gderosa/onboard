describe 'RADIUS admin' do

  def app
    OnBoard::Controller
  end

  JsonSpec.configure do
    exclude_keys "Id"  # , "other_key" etc.
  end

  # TODO: consider https://www.rubydoc.info/gems/sinatra/Sinatra/IndifferentHash ?

  let(:user_creation_data) do
    {
      'check' => {
        'User-Name' => "__user_test",
        'Password-Type' => "SSHA1-Password",
        'User-Password'=> "pass"
      },
      'confirm' => {
        'check' => {
          'User-Password' => "pass"
        }
      }
    }
  end

  let(:user_modification_data) do
    {
      'check' => {
        'Password-Type' => "SSHA1-Password",
        'User-Password' => "newpass",
        'Auth-Type' => "Reject",
        'Login-Time' => "Wk2305-0855,Sa,Su2305-1655"
      },
      'reply' => {
        'Reply-Message' => "my reply msg",
        'Session-Timeout' => 7200,
        'Idle-Timeout' => 1800,
        'WISPr-Bandwidth-Max-Down' => 500000,
        'WISPr-Bandwidth-Max-Up' => 250000
      },
      'confirm' => {
        'check' => {
          'User-Password' => "newpass"
        }
      }
    }
  end

  let(:expected_json_after_modification) do
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

  let(:expected_new_userdata) do
    parse_json(expected_json_after_modification)
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

    actual_check_attributes = parse_json last_response.body, 'user/check'
    attributes_to_check = ['Auth-Type', 'Login-Time', 'Password-Type']
    actual_check_attributes.each do |h|
      attributes_to_check.each do |attribute_name|
        if h['Attribute'] == attribute_name
          expect(h['Value']).to eq(user_modification_data['check'][attribute_name])
        end
      end
    end

    actual_reply_attributes = parse_json last_response.body, 'user/reply'
    attributes_to_check = ['Reply-Message', 'Session-Timeout', 'Idle-Timeout', 'WISPr-Bandwidth-Max-Down', 'WISPr-Bandwidth-Max-Up']
    actual_reply_attributes.each do |h|
      attributes_to_check.each do |attribute_name|
        if h['Attribute'] == attribute_name
          expect(h['Value']).to eq(user_modification_data['reply'][attribute_name])
        end
      end
    end
  end

  it "deletes a user" do
    delete_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.status).to be_between(200, 399)  # OKs or redirs
    get_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.status).to eq(404)
  end
end
