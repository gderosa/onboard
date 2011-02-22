require 'sinatra/base'
require 'onboard/content-filter/dg'

class OnBoard
  class Controller < Sinatra::Base

    get '/content-filter/dansguardian/authplugins/sql/db.:format' do
      sqlauth = ::DansGuardian::Config::Auth::SQL.new
      data    = ::DansGuardian::Parser.read_file (
        ::OnBoard::ContentFilter::DG::AuthPlugin.config_file(:sql) 
      )
      sqlauth.load data
      format(
        :path     => '/content-filter/dansguardian/authplugins/sql/db',
        :module   => 'dansguardian',
        :title    => "DansGuardian: SQL/RADIUS Authentication",
        :format   => params[:format],
        :objects  => sqlauth  
      )
    end
=begin
    put '/content-filter/dansguardian/filtergroups/:id.:format' do
      # This is a "web application object":
      ::OnBoard::ContentFilter::DG::FilterGroup.get(
        params[:id]
      ).update!(params)  
      # This is unrelated to the web app:
      dgconf = ::DansGuardian::Config.new(
        :mainfile => ::OnBoard::ContentFilter::DG.config_file
      )
      format(
        :path     => '/content-filter/dansguardian/filtergroups/filtergroup',
        :module   => 'dansguardian',
        :title    => "DansGuardian: Filter Group ##{params[:id]}",
        :format   => params[:format],
        :objects  => dgconf.filtergroup(params[:id].to_i) 
      )
    end
=end
  end
end
