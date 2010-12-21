# These exceptions MUST be always caught, displaying a human-readable
# message in html view, and something useful for JSON/YAML clients (custom
# HTTP headers might be a way).
#
# Inheritance is encouraged.

class OnBoard
  class BadRequest  < RuntimeError; end
  class Conflict    < RuntimeError; end
  class Warning     < Exception;    end 
end
