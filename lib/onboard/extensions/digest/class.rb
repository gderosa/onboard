require 'onboard/extensions/digest/instance'

module Digest
  class Class

    # For Ruby < 1.9.2

    unless self.methods.include? :base64digest
      # From Ruby 1.9.2 source
      def self.base64digest(str, *args)
        [self.digest(str, *args)].pack('m0')
      end
    end

    def self.digest_length
      self.new.digest_length
    end

  end
end

