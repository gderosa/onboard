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
          FileUtils.ln_s( 
              File.basename(dg.fg_file(1)),
              dg.fg_file(fgid)
          )
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
   
  end
end
