# These exceptions MUST always be caught, displaying a human-readable
# message in html view, and something useful for JSON/YAML clients (custom
# HTTP headers might be a way).

class OnBoard

  # This is the case where multiple inheritance
  # would've been proven useful...
  module Exception
  end

  class Error         < ::StandardError;
    include Exception
  end

  # TODO: use catch and throw
  class Warning       < ::Exception;
    include Exception
  end

  # an useful alias
  RuntimeError        = Error

  class ServerError   < Error;            end
  class BadRequest    < Error;            end
  class Conflict      < Error;            end
  class Unauthorized  < Error;            end

  InternalServerError = ServerError

  class RestoreFailure < ServerError;     end

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
