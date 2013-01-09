# These exceptions MUST always be caught, displaying a human-readable
# message in html view, and something useful for JSON/YAML clients (custom
# HTTP headers might be a way).
#
# Inheritance is encouraged.

class OnBoard
  class Exception     < ::Exception;    end

  class Error         < ::Exception;    end  
  class Warning       < ::Exception;    end  # TODO: use catch and throw
  
  # an useful alias
  RuntimeError        = Error

  class ServerError   < Error;          end
  class BadRequest    < Error;          end
  class Conflict      < Error;          end 
  class Unauthorized  < Error;          end

  InternalServerError = ServerError

  class Error
    def http_status_code
      case self # plays well with inheritance
      when BadRequest
        return 400
      when Unauthorized
        return 401
      when Conflict
        return 409
      when ServerError
        return 500
      else
        raise ::RuntimeError, "unhandled exception: #{self}"
      end        
    end
  end

end
