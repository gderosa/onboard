require 'onboard/extensions/array'
require 'onboard/extensions/nilclass'

class OnBoard
  module Virtualization
    module QEMU
      module Sound
        class Hardware

          class << self

            def models(*opts)
              @models = get_models if @models.none? or opts.include_any_of? [:reset, :reset_list, :rescan]
              return @models
            end

            def get_models
              # TODO: get long description too (in a Sound::Hardware::Model object?)
              # think about @shortname, @description or something

              exe = QEMU::Config::Common.get['exe']

              # Assuming an output like:
              # ============================================
              # Valid sound card names (comma separated):
              # pcspk       PC speaker
              # sb16        Creative Sound Blaster 16
              # ac97        Intel 82801AA AC97 Audio
              # es1370      ENSONIQ AudioPCI ES1370
              # hda         Intel HD Audio
              #
              # -soundhw all will enable all of the above
              # ============================================

              models_ = []
              `#{exe} -soundhw ? 2>&1`.each_line do |l|
                if l =~ /(\S+)\s{2,}/
                  models_ << $1
                end
              end
              return models_
            end

          end

        end
      end
    end
  end
end
