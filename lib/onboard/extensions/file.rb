require 'onboard/extensions/string'

class File
  def self.valid_encodings(path)
=begin
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
=end
    # Experimentally, this is more efficient :-P
    # TODO: manage LARGE files with some heuristic...
    return File.read(path).valid_encodings
  end
end
