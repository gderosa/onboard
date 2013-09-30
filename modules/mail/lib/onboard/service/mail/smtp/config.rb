require 'onboard/service/mail/constants'
require 'onboard/service/mail/smtp/constants'

class OnBoard
  module Service
    module Mail
      module SMTP
        class Config
          
          class << self
            def get
              begin
                self.new YAML.load File.read SMTP::CONFFILE
              rescue Errno::ENOENT
                self.new({})
              end
            end
          end

          def initialize(h)
            @data = h 
          end

          def save
            File.open SMTP::CONFFILE, 'w' do |f|
              f.write YAML.dump @data
            end
          end

          def to_json(*a)
            export = @data.dup
            export['password'] = '<removed>'
            export.to_json(*a)
          end

          def method_missing(metid, *args, &blk)
            @data[:metid] # TODO setters...
          end

        end
      end
    end
  end
end
