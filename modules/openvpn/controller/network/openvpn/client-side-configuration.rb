require 'rubygems'
require 'stringio'
require 'facets/hash'
require 'archive/tar/minitar'
require 'zlib'
gem 'rubyzip', '>= 1.0.0'
require 'zip'
require 'sinatra/base'

class OnBoard

  class Controller < Sinatra::Base

    get '/network/openvpn/client-side-configuration.:format' do
      all_vpns                = Network::OpenVPN::VPN.getAll
      #all_interfaces          = nil
      ## use cached data if possible
      #if Network::OpenVPN::VPN.class_variables.include? :@@all_interfaces
      #  all_interfaces =
      #      Network::OpenVPN::VPN.class_variable_get :@@all_interfaces
      #  if !(all_interfaces.respond_to? :length and all_interfaces.length > 0)
      #    all_interfaces = Network::Interface.getAll
      #  end
      #end
      objects = {
        :vpns               => all_vpns.select{|v| v.data['server']},
        :network_interfaces => :unused # was: all_interfaces
      }
      format(
        :module   => 'openvpn',
        :path     => '/network/openvpn/client-side-configuration',
        :format   => params[:format],
        :objects  => objects,
        :title    => 'Cient-side configuration Wizard'
      )
    end

    get '/network/openvpn/client-side-configuration/howto.:format' do
      vpn = Network::OpenVPN::VPN.getAll.detect do |vpn_|
        vpn_.data['uuid'] == params['vpn_uuid']
      end
      not_found unless vpn
      certs = vpn.find_client_certificates_from_pki(params['pki'] || vpn.data['pkiname'] || 'default')
      objects = {
        :vpn   => vpn,
        :certs => certs
      }
      format(
        :module   => 'openvpn',
        :path     => '/network/openvpn/client-side-configuration/howto',
        :format   => params[:format],
        :formats  => %w{html rb} & @@formats, # exclude 'rb' in production
        :objects  => objects,
        :title    => 'Cient-side configuration: short guide'
      )
    end

    # no web page here, just config files
    get %r{/network/openvpn/client-side-configuration/files/(.*)\.(zip|tgz|tar\.gz)} do
      name, requested_file_extension = params[:captures]
      client_cn = name
      vpn = Network::OpenVPN::VPN.getAll.detect do |vpn_|
        vpn_.data['uuid'] == params['vpn_uuid']
      end
      ssl_pki = Crypto::SSL::PKI.new(params['pki'] || vpn.data['pkiname'])

      not_found unless vpn

      ca_cn = vpn.data['ca']['subject']['CN']
      ca_filename = ca_cn.gsub(' ', '_')
      # NOTE: no certificate check here!!! (TODO:
      # do in howto.html? instert a msg in the archive? use HTTP status?)
      # Actually a check is done in howto.html but just on X509::Name part,
      # not cryptographically...
      ca_filepath_orig =
          File.exists?("#{ssl_pki.certdir}/#{ca_cn}.crt") ?
          "#{ssl_pki.certdir}/#{ca_cn}.crt" :
          ssl_pki.cacertpath
      subject_filename = name.gsub(' ', '_')
          # params['name'] is the client CN
      clientside_configuration = vpn.clientside_configuration(
        :ca     => "#{ca_filename }.crt",
        :cert   => "#{subject_filename}.crt",
        :key    => "#{subject_filename}.key",
        :remote => params['address'],
        :port   => params['port']
      )
      ovpn_conf_ext = 'conf'
      ovpn_conf_ext = 'ovpn' if params['os'] == 'windows'

      files = [
        {
          :name     => "#{subject_filename}.#{ovpn_conf_ext}",
          :content  => clientside_configuration
        },
        {
          :name     => "#{subject_filename}.crt",
          :content  => File.read("#{ssl_pki.certdir}/#{client_cn}.crt")
        },
        {
          :name     => "#{subject_filename}.key",
          :content  => File.read("#{ssl_pki.keydir}/#{client_cn}.key"),
          :mode     => 0400 # private key security
        },
        {
          :name     => "#{ca_filename}.crt",
          :content  => File.read(ca_filepath_orig)
        }
      ]

      case requested_file_extension
      when 'zip'
        zout = StringIO.new
        Zip::OutputStream.write_buffer(zout) do |zin|
          files.each do |file_h|
            zin.put_next_entry file_h[:name]
            zin.write file_h[:content]
          end
        end
        content_type 'application/zip'
        zout.string
      when 'tgz', 'tar.gz' # sadly, there's nothing like Zippy for tar.gz
        content_type 'application/x-gzip'
        StringIO.open do |sio|
          gz = Zlib::GzipWriter.new(sio)
          Archive::Tar::Minitar::Writer.open(gz) do |tar|
            files.each do |h|
              tar.add_file_simple(
                h[:name],
                :size   => h[:content].length,
                :mode   => (h[:mode] || 0644),
                :mtime  => Time.now
              ){|f| f.write h[:content]}
            end
          end
          gz.close
          sio.string
        end
      else
        not_found
      end
    end

  end

end
