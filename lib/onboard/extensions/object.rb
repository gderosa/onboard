begin
  require 'json_printer/lib/json_printer'
  $json_printer_available = true
rescue LoadError
  $json_printer_available = false
end

class Object
  def to_(what)
    if $json_printer_available and what.to_s == 'json'
      return JsonPrinter.render self
    else
      method(('to_' + what.to_s).to_sym).call
    end
  end
end


