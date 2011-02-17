require 'onboard/extensions/string'

class File
  def self.valid_encodings(path)
    valid_encs = Encoding.list
    File.foreach path do |line|
      line.strip!
      # restrict the subset 
      valid_encs = line.valid_encodings(valid_encs) 
    end
    valid_encs
  end
end
