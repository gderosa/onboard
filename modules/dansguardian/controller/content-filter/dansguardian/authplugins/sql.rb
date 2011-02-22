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

    get '/content-filter/dansguardian/authplugins/sql/groups.:format' do
      
      dg = OnBoard::ContentFilter::DG.new
      dgconf = dg.config
      fgnames = {}
      1.upto dgconf.main[:filtergroups] do |fgid|
        next if dg.deleted_filtergroups.include? fgid
        fgnames[fgid] = dgconf.filtergroup(fgid)[:groupname] 
      end

      sqlauth_data      = ::DansGuardian::Parser.read_file (
        ::OnBoard::ContentFilter::DG::AuthPlugin.config_file(:sql) 
      )
      sqlauth_groupfile = sqlauth_data[:sqlauthgroups] 
      sqlgroups_data    = ::DansGuardian::Parser.read_file sqlauth_groupfile

      format(
        :path     => '/content-filter/dansguardian/authplugins/sql/groups',
        :module   => 'dansguardian',
        :title    => "DansGuardian: SQL/RADIUS Groups mapping",
        :format   => params[:format],
        :objects  => {
          :fgnames    => fgnames,
          :groups     => sqlgroups_data
        }  
      )
    end
   
  end
end
