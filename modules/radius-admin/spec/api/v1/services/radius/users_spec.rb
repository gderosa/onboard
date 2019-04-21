describe 'RADIUS admin' do

  def app
    OnBoard::Controller
  end

  JsonSpec.configure do
    exclude_keys "Id", "Creation-Date", "Update-Date"
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
        # Even RADIUS attributes of numeric type must be strings
        # (in the database, a single column `Value` hosts all data types...)
        # We don't want to implement extra per-attr-type conversion logic,
        # which is left to RADIUS servers and clients.
        'Session-Timeout' => "7200",
        'Idle-Timeout' => "1800",
        'WISPr-Bandwidth-Max-Down' => "500000",
        'WISPr-Bandwidth-Max-Up' => "250000"
      },
      'personal' => {
        'First-Name' => 'George',
        'Last-Name' => 'Boole',
        'Email': "george.boole@ucc.ie",
        'Birth-Date': "1815-11-02"
      },
      'confirm' => {
        'check' => {
          'User-Password' => "newpass"
        }
      }
    }
  end


  # Only "personal" data are used of this, RADIUS attrs are amtched against user_modification_data,
  # after a data rearrangement/reshape to make RADIUS idiosyncrasies and our (sensible?) key/values
  # meet.
  let(:expected_json_after_modification) do
    <<-END
    {
      "user": {
        "name": "__user_test",
        "check": [
          {
            "Id": 197,
            "User-Name": "__user_test",
            "Attribute": "User-Name",
            "Operator": ":=",
            "Value": "__user_test"
          },
          {
            "Id": 199,
            "User-Name": "__user_test",
            "Attribute": "SSHA1-Password",
            "Operator": ":=",
            "Value": "SQaMuG003/CnO1uVEUafF87kr0PBW04gV+1Em+G/+bJ3Sj472o58uw=="
          },
          {
            "Id": 200,
            "User-Name": "__user_test",
            "Attribute": "Auth-Type",
            "Operator": ":=",
            "Value": "Reject"
          },
          {
            "Id": 201,
            "User-Name": "__user_test",
            "Attribute": "Login-Time",
            "Operator": ":=",
            "Value": "Wk2305-0855,Sa,Su2305-1655"
          }
        ],
        "reply": [
          {
            "Id": 30,
            "User-Name": "__user_test",
            "Attribute": "Reply-Message",
            "Operator": ":=",
            "Value": "my reply msg"
          },
          {
            "Id": 31,
            "User-Name": "__user_test",
            "Attribute": "Session-Timeout",
            "Operator": ":=",
            "Value": "7200"
          },
          {
            "Id": 32,
            "User-Name": "__user_test",
            "Attribute": "Idle-Timeout",
            "Operator": ":=",
            "Value": "1800"
          },
          {
            "Id": 33,
            "User-Name": "__user_test",
            "Attribute": "WISPr-Bandwidth-Max-Down",
            "Operator": ":=",
            "Value": "500000"
          },
          {
            "Id": 34,
            "User-Name": "__user_test",
            "Attribute": "WISPr-Bandwidth-Max-Up",
            "Operator": ":=",
            "Value": "250000"
          }
        ],
        "groups": [

        ],
        "personal": {
          "Id": 2,
          "User-Name": "__user_test",
          "First-Name": "George",
          "Last-Name": "Boole",
          "Email": "george.boole@ucc.ie",
          "Work-Phone": null,
          "Home-Phone": null,
          "Mobile-Phone": null,
          "Address": null,
          "City": null,
          "State": null,
          "Country": null,
          "Postal-Code": null,
          "Notes": null,
          "Creation-Date": "2019-04-18 18:10:02 +0000",
          "Update-Date": null,
          "Birth-Date": "1815-11-02",
          "Birth-City": null,
          "Birth-State": null,
          "ID-Code": null,
          "Attachments": []
        },
        "accepted_terms": null
      }
    }
    END
  end
  # We should fill more personal detail fields, however, they are quite obvious,
  # optional strings.

  it "creates a user" do
    # cleanup, no matter what
    delete_json '/api/v1/services/radius/users/__user_test'
    #
    post_json '/api/v1/services/radius/users', user_creation_data
    pp last_response.headers
    expect(last_response.status).to eq(201)
    expect(last_response.headers['Location']).to eq('/api/v1/services/radius/users/__user_test')
    # puts last_response.body
    get_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.body).to be_json_eql(%("__user_test")).at_path("user/check/0/User-Name")
  end

  it "replaces user data" do
    put_json '/api/v1/services/radius/users/__user_test', user_modification_data
    expect(last_response).to be_ok

    # puts last_response.body

    actual_check_attributes = parse_json last_response.body, 'user/check'
    attributes_to_check = ['Auth-Type', 'Login-Time']
    attributes_to_check.each do |attribute_name|
      selected_attributes = actual_check_attributes.select{|h| h['Attribute'] == attribute_name}
      expect(selected_attributes.size).to eql(1)
      expect(selected_attributes[0]['Value']).to eql(user_modification_data['check'][attribute_name])
    end

    # e.g. "SSHA1-Password"
    password_attributes = actual_check_attributes.select{|h| h['Attribute'] == user_modification_data['check']['Password-Type']}
    # must exist and be one, we don't check value as it's SHA-1 encrypted + salt
    expect(password_attributes.size).to eql(1)

    actual_reply_attributes = parse_json last_response.body, 'user/reply'
    attributes_to_check = ['Reply-Message', 'Session-Timeout', 'Idle-Timeout', 'WISPr-Bandwidth-Max-Down', 'WISPr-Bandwidth-Max-Up']
    attributes_to_check.each do |attribute_name|
      selected_attributes = actual_reply_attributes.select{|h| h['Attribute'] == attribute_name}
      expect(selected_attributes.size).to eql(1)
      expect(selected_attributes[0]['Value']).to eql(user_modification_data['reply'][attribute_name])
    end

    # Personal data are less idiosyncratic: no RADIUS attrs but our own db table, key/values as you'd expect
    expected_personal = parse_json expected_json_after_modification, 'user/personal'
    expect(last_response.body).to be_json_eql(expected_personal.to_json).at_path('user/personal')
  end

  it "deletes a user" do
    delete_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.status).to be_between(200, 399)  # OKs or redirs
    get_json '/api/v1/services/radius/users/__user_test'
    expect(last_response.status).to eq(404)
  end
end
