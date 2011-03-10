require 'sinatra/base'
require 'onboard/content-filter/dg'

class OnBoard
  class Controller < Sinatra::Base

    get '/content-filter/dansguardian/filtergroups.:format' do
      dg = OnBoard::ContentFilter::DG.new
      format(
        :path     => '/content-filter/dansguardian/filtergroups',
        :module   => 'dansguardian',
        :title    => 'DansGuardian: Filter Groups',
        :format   => params[:format],
        :objects  => {
          :dg       => dg
        }
      )
    end


    put '/content-filter/dansguardian/filtergroups.:format' do
      dg = OnBoard::ContentFilter::DG.new
      params['filtergroups'].each_pair do |key, h|
        fgid    = key.to_i
        fgfile  = dg.fg_file(fgid)
        if h['delete'] == 'on' and fgid > 1
          FileUtils.rm dg.fg_file(fgid)
          # replace with a symlink to default because DansGuardian doesn't
          # tolerate "holes", i.e. dansguardianf1.conf, dansguardianf3.conf
          # but dansguardianf2.conf deleted
          FileUtils.ln_s( 
              File.basename(dg.fg_file(1)),
              dg.fg_file(fgid)
          )
          dg.fix_filtergroups
        else
          ::DansGuardian::Updater.update!(
            fgfile, 
            {
              :groupname => h['groupname'],
              :groupmode => 
                ::DansGuardian::Config::FilterGroup::GROUPMODE.invert[
                  h['groupmode'].to_sym
                ],
            }
          )
        end
      end
      if dg.running?
        dg.reload
      end
      dg.update_info 
      format(
        :path     => '/content-filter/dansguardian/filtergroups',
        :module   => 'dansguardian',
        :title    => 'DansGuardian: Filter Groups',
        :format   => params[:format],
        :objects  => {
          :dg       => dg
        }
      )
    end

    post '/content-filter/dansguardian/filtergroups.:format' do
      dg = OnBoard::ContentFilter::DG.new
      new_fg_file = dg.fg_file(
        (dg.deleted_filtergroups.min) || (dg.config.main[:filtergroups] + 1)
      )
      FileUtils.rm new_fg_file if File.exists? new_fg_file
      FileUtils.cp(
        dg.fg_file(params['template']), new_fg_file 
      )
      ::DansGuardian::Updater.update! new_fg_file, {
        :groupname => params['groupname']
      }
      dg.fix_filtergroups
      dg.reload_groups
      dg.update_info
      format(
        :path     => '/content-filter/dansguardian/filtergroups',
        :module   => 'dansguardian',
        :title    => 'DansGuardian: Filter Groups',
        :format   => params[:format],
        :objects  => {
          :dg       => dg
        }
      )
    end

    get '/content-filter/dansguardian/filtergroups/:id.:format' do
      #dgconf = ::DansGuardian::Config.new(
      #  :mainfile => ::OnBoard::ContentFilter::DG.config_file
      #)
      o = OnBoard::ContentFilter::DG::FilterGroup.get(params[:id].to_i) 
      format(
        :path     => '/content-filter/dansguardian/filtergroups/filtergroup',
        :module   => 'dansguardian',
        :title    => "DansGuardian: Filter Group ##{params[:id]}",
        :format   => params[:format],
        :objects  => o 
      )
    end

    put '/content-filter/dansguardian/filtergroups/:id.:format' do
      # This is a "web application object":
      ::OnBoard::ContentFilter::DG::FilterGroup.get(
        params[:id]
      ).update!(params)  
      
      o = OnBoard::ContentFilter::DG::FilterGroup.get(params[:id].to_i)
      format(
        :path     => '/content-filter/dansguardian/filtergroups/filtergroup',
        :module   => 'dansguardian',
        :title    => "DansGuardian: Filter Group ##{params[:id]}",
        :format   => params[:format],
        :objects  => o 
      )
    end
  
  end
end
