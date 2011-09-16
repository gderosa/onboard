require 'sinatra/base'

require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/pub/services/radius/users/:userid.:format' do
      user = Service::RADIUS::User.new(params[:userid])
      signup_config = Service::RADIUS::Signup.get_config
      msg = {}
      msg = handle_errors do
        user.retrieve_attributes_from_db
        user.retrieve_group_membership_from_db
        user.retrieve_personal_info_from_db
        user.get_personal_attachment_info
        not_found unless user.found?
        user.retrieve_accepted_terms_from_db
      end

      redirect '/pub/services/radius/login.html' unless
          user.check_password session[:radpass] and user.name == session[:raduser]

      format(
        :module   => 'radius-admin',
        :path     => '/pub/services/radius/users/user',
        :title    => "#{i18n.radius.user.user.capitalize}: #{params[:userid]}",
        :format   => params[:format],
        :locals   => {:signup_config => signup_config},
        :objects  => {
          'user'    => user,
        },
        :msg      => msg
      )
    end

    put '/pub/services/radius/users/:userid.:format' do
      config = Service::RADIUS::Signup.get_config
      if config['enable_selfcare']
        params_filtered = params.let_in(
          'personal'  => true,
          'check'     => {
            'User-Password' => true,
          },
          'confirm'   => {
            'check'     => {
              'User-Password' => true,
            },
          },
          'delete'    => {
            'personal' => {
              'Attachments' => true,
            },
          },
        )
      end
      user = Service::RADIUS::User.new(params[:userid])
      msg = handle_errors do

        user.retrieve_attributes_from_db
        user.retrieve_group_membership_from_db

        not_found unless user.found?
        
        redirect '/pub/services/radius/login.html' unless
            user.check_password session[:radpass] and user.name == session[:raduser]

        user.retrieve_personal_info_from_db
        user.get_personal_attachment_info

        Service::RADIUS::User.validate_personal_info(
            :params => params,
            :fields => config['mandatory']['personal'].select{|k, v| v}.keys
        )       
        if config['enable_selfcare']
          user.update(params_filtered)
          user.retrieve_attributes_from_db
          user.retrieve_group_membership_from_db
          user.retrieve_accepted_terms_from_db
          user.retrieve_personal_info_from_db
          user.get_personal_attachment_info

          session[:raduser] = user.name
          session[:radpass] = params['check']['User-Password']
        end
      end

      unless config['enable_selfcare']
        msg[:ok] = false
        msg[:err] = 'Editing not allowed!'
        status 403 # Forbidden
      end

      format(
        :module   => 'radius-admin',
        :path     => '/pub/services/radius/users/user',
        :title    => "RADIUS User: #{params[:userid]}",
        :format   => params[:format],
        :msg      => msg,
        :locals   => {:signup_config => config}, 
        :objects  => {
          'user'    => user
        }
      )
    end

    get '/pub/services/radius/users/:userid/attachments/personal/:basename' do
      user = Service::RADIUS::User.new(params[:userid])
      msg = {}
      msg = handle_errors do
        user.retrieve_attributes_from_db
        not_found unless user.found?
      end

      redirect '/pub/services/radius/login.html' unless
          user.check_password session[:radpass] and user.name == session[:raduser]
     
      attachment(params[:basename]) if params['disposition'] == 'attachment'
      send_file( File.join(
          OnBoard::Service::RADIUS::User::UPLOADS,
          params[:userid],
          'personal',
          params[:basename]
      ) )
    end

  end
end
