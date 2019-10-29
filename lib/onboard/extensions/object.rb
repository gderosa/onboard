require 'json'
require 'yaml'

class Object

  def to_(what)
    if what.to_s == 'json'
      begin
        json = JSON.pretty_generate(self)
        return json
      rescue NoMethodError
        return JSON.generate(self)
      end
    elsif what.to_s == 'yaml'
      return YAML.dump(self)
    else
      method(('to_' + what.to_s).to_sym).call
    end
  end

end


