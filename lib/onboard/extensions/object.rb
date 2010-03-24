begin
  require 'json_printer/lib/json_printer'
  $json_printer_available = true
rescue LoadError
  $json_printer_available = false
end

begin
  require 'ya2yaml'
  $ya2yaml_available = true
rescue LoadError
  $ya2yaml_available = false
end

# NOTE: the above stuff won't be required any more when the following gems
# will be available (on stable, well-known repos):
#
# * json_printer 
#
# TODO: watch http://github.com/techcrunch/json_printer to get news on this.

class Object
  def to_(what)
    if $json_printer_available and what.to_s == 'json'
      return JsonPrinter.render self
    elsif $ya2yaml_available and what.to_s == 'yaml'
      return self.ya2yaml
    else
      method(('to_' + what.to_s).to_sym).call
    end
  end
end


