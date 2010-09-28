require 'json' # std library

begin
  require 'ya2yaml'
  $ya2yaml_available = true
rescue LoadError
  $ya2yaml_available = false
end

class Object
  def to_(what)
    if what.to_s == 'json'
      begin
        return JSON.pretty_generate(self)
      rescue NoMethodError
        return self.to_json
      end
    elsif $ya2yaml_available and what.to_s == 'yaml'
      return self.ya2yaml
    else
      method(('to_' + what.to_s).to_sym).call
    end
  end
end


