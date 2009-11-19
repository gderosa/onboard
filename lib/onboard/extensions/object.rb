begin
  require 'json_printer/lib/json_printer'
  $json_printer_available = true
rescue LoadError
  $json_printer_available = false
end

begin
  require 'ya2yaml-0.29/lib/ya2yaml'
  $ya2yaml_1_9compatible_available = true
rescue LoadError
  $ya2yaml_1_9compatible_available = false
end

# NOTE: the above stuff won't be required any more when the following gems
# will be available (on stable, well-known repos):
#
# * json_printer 
# * ya2yaml >= 0.29 (compatible with ruby1.9)
#
# TODO: watch http://rubyforge.org/frs/?group_id=2206 and 
# http://github.com/techcrunch/json_printer to get news on this.

class Object
  def to_(what)
    if $json_printer_available and what.to_s == 'json'
      return JsonPrinter.render self
    elsif $ya2yaml_1_9compatible_available and what.to_s == 'yaml'
      return self.ya2yaml
    else
      method(('to_' + what.to_s).to_sym).call
    end
  end
end


