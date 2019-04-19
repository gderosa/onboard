describe 'RADIUS admin' do

  def app
    OnBoard::Controller
  end

  JsonSpec.configure do
    exclude_keys "Id", "Creation-Date", "Update-Date", "Priority"
  end

  let(:user_modification_data) do
    {
      'groups' => ["__new_group_test1", "__new_group_test2"],
      'update_groups' => "on"
    }
  end

  let(:group_attr_modification_data) do
    {
      'check' => {
        'Auth-Type' => 'Reject',
        'Login-Time' => 'Mo-We1630-1830'
      },
      'reply' => {

      }
    }
  end

  let(:expected_check_attrs_after_modification) do
    <<-END
    [
      {
        "Id": 1,
        "Group-Name": "__new_group_test2",
        "Attribute": "Auth-Type",
        "Operator": "+=",
        "Value": "Reject"
      },
      {
        "Id": 2,
        "Group-Name": "__new_group_test2",
        "Attribute": "Login-Time",
        "Operator": "+=",
        "Value": "Mo-We1630-1830"
      }
    ]
    END
  end

  let(:expected_group_membership_after_modification) do
    <<-END
    [
      {
        "User-Name": "__user_test",
        "Group-Name": "__new_group_test1",
        "Priority": 1
      },
      {
        "User-Name": "__user_test",
        "Group-Name": "__new_group_test2",
        "Priority": 2
      }
    ]
    END
  end

  # Used? Only here for illustrative purposes?
  let(:expected_group_endpoint_body_1) do
  <<-END
  {
    "group": {
      "name": "__new_group_test1",
      "check": [],
      "reply": []
    },
    "members": {
      "total_items": 1,
      "page": 1,
      "per_page": 10,
      "users": [
        {
          "name": "__user_test",
          "check": [
            {
              "Id": 313,
              "User-Name": "__user_test",
              "Attribute": "User-Name",
              "Operator": ":=",
              "Value": "__user_test"
            }
          ],
          "reply": [
            {
              "Id": 133,
              "User-Name": "__user_test",
              "Attribute": "Fall-Through",
              "Operator": "=",
              "Value": "yes"
            }
          ],
          "groups": [],
          "personal": null,
          "accepted_terms": null
        }
      ]
    }
  }
  END
  end

  before :all do
    @user_creation_data = {
      'check' => {
        'User-Name' => "__user_test",
      }
    }

    # cleanup, no matter what
    delete_json '/api/v1/services/radius/users/__user_test'
    delete_json '/api/v1/services/radius/users/__user_test_extra1'
    delete_json '/api/v1/services/radius/users/__user_test_extra2'
    delete_json '/api/v1/services/radius/groups/__new_group_test1'
    delete_json '/api/v1/services/radius/groups/__new_group_test2'

    post_json '/api/v1/services/radius/users', @user_creation_data
  end

  after :all do
    delete_json '/api/v1/services/radius/users/__user_test'

    delete_json '/api/v1/services/radius/users/__user_test_extra1'
    delete_json '/api/v1/services/radius/users/__user_test_extra2'

    delete_json '/api/v1/services/radius/groups/__new_group_test1'
    delete_json '/api/v1/services/radius/groups/__new_group_test2'
  end


  it "adds user to groups" do
    put_json '/api/v1/services/radius/users/__user_test', user_modification_data
    expect(last_response).to be_ok
    expect(last_response.body).to be_json_eql(expected_group_membership_after_modification).at_path('user/groups')
  end

  context "test group #1" do
    it "is present at relevant endpoint" do
      get_json '/api/v1/services/radius/groups/__new_group_test1'
      expect(last_response).to be_ok
    end
    it "has the test user as its member" do
      get_json '/api/v1/services/radius/groups/__new_group_test1'
      expect(last_response.body).to be_json_eql('"__user_test"').at_path('members/users/0/name')
    end
    it "gets new users added" do
      put_json '/api/v1/services/radius/groups/__new_group_test1', {
        'add_members' => ['__user_test_extra1', '__user_test_extra2']
      }
      expect(last_response).to be_ok
      get_json '/api/v1/services/radius/groups/__new_group_test1'
      expect(last_response.body).to have_json_size(3).at_path('members/users/')
      expect(last_response.body).to be_json_eql('"__user_test_extra1"').at_path('members/users/1/name')
      expect(last_response.body).to be_json_eql('"__user_test_extra2"').at_path('members/users/2/name')
    end
    it "has some users removed" do
      put_json '/api/v1/services/radius/groups/__new_group_test1', {
        'remove_members' => ['__user_test_extra1']
      }
      # puts last_response.body
      expect(last_response).to be_ok
      get_json '/api/v1/services/radius/groups/__new_group_test1'
      expect(last_response.body).to have_json_size(2).at_path('members/users/')
      expect(last_response.body).to be_json_eql('"__user_test"'       ).at_path('members/users/0/name')
      expect(last_response.body).to be_json_eql('"__user_test_extra2"').at_path('members/users/1/name')
    end
  end

  context "test group #2" do
    it "modifies check attributes" do
      put_json '/api/v1/services/radius/groups/__new_group_test2', group_attr_modification_data
      get_json '/api/v1/services/radius/groups/__new_group_test2'
      # puts last_response.body
      expect(last_response.body).to be_json_eql(expected_check_attrs_after_modification).at_path('group/check')
    end
  end

  # TODO: edit attributes of a group
end
