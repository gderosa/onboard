require 'onboard/extensions/string'

class File
  def self.valid_encodings(path)
    ascii_only_found = false
    valid_encs = Encoding.list
    File.foreach path do |line|
      line.strip!
      # Optimize large ASCII files: other ASCII-only lines don't add
      # any useful information.
      if line.ascii_only?
        if ascii_only_found
          next
        else
          ascii_only_found = true
        end
      end
      # Restrict the subset
      valid_encs = line.valid_encodings(valid_encs) 
    end
    valid_encs
  end
end
