describe 'RADIUS admin' do

  def app
    OnBoard::Controller
  end

  JsonSpec.configure do
    exclude_keys "Id", "Creation-Date", "Update-Date", "Priority"
  end

  let(:user_modification_data) do
    {
      'groups' => "__new_group_test1, __new_group_test2",
      'update_groups' => "on"
    }
  end

  let(:expected_group_json_after_modification) do
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

  before :all do
    @user_creation_data = {
      'check' => {
        'User-Name' => "__user_test",
      }
    }

    # cleanup, no matter what
    delete_json '/api/v1/services/radius/users/__user_test'

    post_json '/api/v1/services/radius/users', @user_creation_data
    # puts last_response.body
  end

  after :all do
    delete_json '/api/v1/services/radius/users/__user_test'
    # Apparently "stale" groups are also removed under the hood
  end


  it "adds user to groups" do
    put_json '/api/v1/services/radius/users/__user_test', user_modification_data
    expect(last_response).to be_ok
    expect(last_response.body).to be_json_eql(expected_group_json_after_modification).at_path('user/groups')
  end
end
