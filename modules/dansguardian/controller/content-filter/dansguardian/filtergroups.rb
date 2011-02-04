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
      params['filtergroups'].each_pair do |key, edit_h|
        fgid  = key.to_i
        fg    = dg.config.filtergroup(fgid)
        
        fg[:groupname] = edit_h['groupname']
        fg[:groupmode] = edit_h['groupmode'].to_sym
      end
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
