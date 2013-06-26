require 'uuid'

require 'facets/hash'

require 'onboard/extensions/string'

class OnBoard
  module Virtualization
    module QEMU
      class Config

        autoload :Common, 'onboard/virtualization/qemu/config/common'
        autoload :Drive,  'onboard/virtualization/qemu/config/drive'
        autoload :USB,    'onboard/virtualization/qemu/config/usb'

        # paste from man page
        KEYBOARD_LAYOUTS = %w{ 
            ar  de-ch  es  fo     fr-ca  hu  ja  mk     no  pt-br  sv
            da  en-gb  et  fr     fr-ch  is  lt  nl     pl  ru     th
            de  en-us  fi  fr-be  hr     it  lv  nl-be  pt  sl     tr        
        }.sort

        class << self

          def absolute_path(path)
            return path if path =~ /^\// or path.is_uri?
            return File.join FILESDIR, path
          end

          def relative_path(path)
            return nil unless path
            return path.sub /^#{FILESDIR}\//, ''
          end

        end

        attr_reader :uuid, :cmd, :drop_privileges, :force_command_line

        def [](k)
          @cmd['opts'][k] 
        end

        def []=(k, val)
          @cmd['opts'][k] = val
        end 

        alias drop_privileges? drop_privileges

        def name
          self['-name'] 
        end

        def initialize(h)
          @drop_privileges = true
          if h[:http_params]
            @drop_privileges = false if h[:http_params]['run_as_root'] == 'on'
            @uuid = h[:uuid] || h[:http_params][:uuid] || UUID.generate 
            @cmd  = {
              #'exe'   => 'kvm',
              'opts'  => {
                '-enable-kvm' => true,
                '-uuid'       => @uuid,
                '-name'       => h[:http_params]['name'],
                '-m'          => h[:http_params]['m'].to_i,
                '-smp'        => h[:http_params]['smp'], 
                '-vnc'        => h[:http_params]['vnc'],
                '-spice'      => {
                  'port'        => (
h[:http_params]['spice'].respond_to?(:[]) && h[:http_params]['spice']['port'].to_i
                  ),
                },
                '-k'          => h[:http_params]['k'],
                '-vga'        => h[:http_params]['vga'],
                '-soundhw'    => h[:http_params]['soundhw'],
                #'-drive'     => [
                #  {
                #    'file'     => h[:http_params]['disk'], 
                #    'media'    => 'disk',
                #    'index'    => 0
                #  }
                #],
                '-daemonize'  => true,
                '-monitor'    => {
                  'unix'        => "#{VARRUN}/qemu-#{uuid_short}.sock",
                  'server'      => true,
                  'nowait'      => true
                },
                '-pidfile'    => "#{VARRUN}/qemu-#{uuid_short}.pid"
              }
            }

            @cmd['opts']['-device'] ||= []
            # Load default devices
            @cmd['opts']['-device'] += USB::DEFAULT_CONTROLLERS
            @cmd['opts']['-device'] += USB::DEFAULT_DEVICES

            # Host Device Passthrough
            # PCI Passthrough
            if h[:http_params]['pci_passthrough']
              h[:http_params]['pci_passthrough'].each_pair do |id, type|
                next if type == ''
                @cmd['opts']['-device'] << {
                  'driver'  => type,
                  'host'    => id
                }
              end
            end
            # USB Passthrough
            if h[:http_params]['usb_passthrough'].respond_to? :each
              h[:http_params]['usb_passthrough'].each do |device_http_params|
                if device_http_params.respond_to? :[]
                  # device_http_params['mode'] is something like:
                  # ""
                  # "hostbus,hostport"
                  # "hostbus,hostaddr"
                  # "vendorid,productid"
                  if device_http_params['mode'].respond_to? :split
                    usb_param_list = device_http_params['mode'].split(',')
                    if usb_param_list.any?
                      device_conf_entry = {'driver' => 'usb-host'}
                      usb_param_list.each do |p|
                        device_conf_entry[p] = device_http_params[p]
                      end
                      if device_http_params['bus'] =~ /\S/
                        device_conf_entry['bus'] = device_http_params['bus'] + '.0'
                      end
                      @cmd['opts']['-device'] << device_conf_entry
                    end
                  end
                end
              end
            end
            # END Host Device Passthrough

            # TODO: -device instead of -usbdevice ... ?
            if h[:http_params]['usbdisk'] =~ /\S/
              @cmd['opts']['-usbdevice'] ||= []
              @cmd['opts']['-usbdevice'] << {
                'type'  => 'disk',
                'file'  => self.class.absolute_path(h[:http_params]['usbdisk']),
              }
            end

            @cmd['opts']['-drive'] ||= []
            h[:http_params]['disk'].each_with_index do |hd, idx|
              if hd['file']
                default = {
                  'serial'  => generate_drive_serial,
                  'media'   => 'disk',
                }
                
                # NOTE: you can't use this Facets thing if you have already required Sequel.
                # The '|' operation between two Hashes produces a Sequel boolean expression object.
                # So there's a conflict between the two gems, which should be reported/fixed.
                #
                # newhd = hd | default | (Drive.slot2data(hd['slot']) || {}) 
                #
                newhd = default.merge(hd).merge( Drive.slot2data(hd['slot']) || {}  )

                # TODO: do not hardcode '[network]'
                if newhd['use_network_url'] and newhd['path'] =~ %r{\[network\]/([^/]+)/([^/]+)/([^/]+)/(.*)}
                  protocol, host, volume, path_to_image = $1, $2, $3, $4
                  newhd['file_url'] = "#{protocol}://#{host}/#{volume}/#{path_to_image}"
                end
                # pp newhd # DEBUG
                
                @cmd['opts']['-drive'] << newhd
              end
            end
            @cmd['opts']['-drive'] ||= []
            @cmd['opts']['-drive'] << {
              'serial'=> generate_drive_serial, 
              'file'  => (
                self.class.absolute_path(h[:http_params]['cdrom']) if 
                    h[:http_params]['cdrom'] =~ /\S/  
              ),
              'media'     => 'cdrom',
              'if'        => 'ide',     # IDE (default)
              'bus'       => 1,         # Secondary
              'unit'      => 0,         # Master
            }
            @cmd['opts']['-net'] ||= []
            valid_netifs = h[:http_params]['net'].reject do |netif_h|
              netif_h['type'] =~ /^\s*(none)?\s*$/
            end
            if valid_netifs.length == 0
              @cmd['opts']['-net'] << {'type' => 'none'}
            else
              valid_netifs.each do |netif_h|
                netif_h.each_pair do |k, v|
                  netif_h[k] = nil if (v =~ /^\s*(\[auto\])?\s*$/) 
                end
                @cmd['opts']['-net'] << {
                  'type'    => 'nic',
                  'vlan'    => netif_h['vlan'], # Could be a (non-numeric) String??
                  'model'   => netif_h['model'],
                  'macaddr' => netif_h['macaddr'],
                }
                @cmd['opts']['-net'] << {
                  'type'    => netif_h['type'],
                  'vlan'    => netif_h['vlan'], # Could be a (non-numeric) String??
                  'ifname'  => netif_h['ifname'] || generate_tapname(netif_h),
                  'bridge'  => netif_h['bridge'],
                }
              end 
            end
            if h[:http_params]['cmdline_append'] =~ /\S/
              @cmd['opts']['append'] = h[:http_params]['cmdline_append']
            end
            if h[:http_params]['edit_the_command_line'] == 'on'
              @force_command_line = h[:http_params]['command_line']
            else
              @force_command_line = false
            end
          else
            @uuid               = h[:config]['uuid']
            @cmd                = h[:config]['cmd']
            @drop_privileges    = h[:config]['drop_privileges'] if
                h[:config].keys.include? 'drop_privileges' # avoid assigning non true as default
            @force_command_line = h[:config]['force_command_line']
          end
        end

        def generate_drive_serial
          return ('QM' + uuid_short + sprintf('%02x', drive_counter)).upcase
        end

        def generate_tapname(parms)
          return nil unless parms['type'] == 'tap'
          base = "qm#{uuid_short}"
          count = 0
          loop do
            name = "#{base}.#{sprintf('%02x', count)}"
            already_existing_names = @cmd['opts']['-net'].map{|x| x['ifname']}
            if already_existing_names.include? name
              count += 1
            else
              return name
            end
          end
        end

        def drive_counter
          if @cmd['opts'] and @cmd['opts']['-drive'].respond_to? :length
            @cmd['opts']['-drive'].length
          else
            0
          end
        end

        def quick_snapshots?
          @cmd['opts']['-drive'].any? do |drive|
            drive['cache'] == 'unsafe'
          end
        end

        def uuid_short
          @uuid.split('-')[0] 
        end

        def opts
          @cmd['opts']
        end

        def to_h
          {
            'uuid'                => @uuid,
            'cmd'                 => @cmd,
            'drop_privileges'     => @drop_privileges,
            'force_command_line'  => @force_command_line
          }
        end

        def to_json(*a); to_h.to_json(*a); end

        def file
          File.join QEMU::CONFDIR, "#@uuid.yml"
        end

        def save
          yaml_file = file
          File.open yaml_file, 'w' do |f|
            f.write YAML.dump to_h 
          end
        end

      end
    end
  end
end
