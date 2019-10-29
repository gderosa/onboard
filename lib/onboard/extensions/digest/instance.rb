require 'digest'

module Digest
  module Instance

    # For Ruby < 1.9.2

    unless self.instance_methods.include? :base64digest
      # From Ruby 1.9.2 source
      def base64digest(str = nil)
        [str ? digest(str) : digest].pack('m0')
      end
    end

    unless self.instance_methods.include? :base64digest!
      # From Ruby 1.9.2 source
      def base64digest!
        [digest!].pack('m0')
      end
    end

  end
end

