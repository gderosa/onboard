# encoding: UTF-8

class OnBoard
  class Controller < ::Sinatra::Base

    helpers do
    
      def handle_external_errors(e, req)
        result = nil
        @@error_handlers ||= {}

        # So, if @@error_handlers[MyError] exists, it's also valid
        # for MyDerivedError where:
        #
        #   class MyDerivedError < MyError; end         
        #
        select = @@error_handlers.select{|k, v| e.is_a? k } || {}
        arrays = select.values
        arrays.each do |array|
          array.each do |handler|
            result = handler.call(e, req)
            return result if result and result != :pass 
          end
        end
        return result
      end

      def handle_errors(&blk)
        @msg = {}
        begin
          blk.call
        rescue OnBoard::Error
          e = $!.clone
          status e.http_status_code
          @msg[:err] = e # will be converted to message string as needed
        rescue OnBoard::Warning
          @msg[:warn] = $!
        rescue StandardError
          if h = handle_external_errors($!, request) 
            status h[:status]
            @msg = h[:msg]
          else
            raise # unhandled
          end
        end
        @msg[:ok] = true unless @msg[:err]
        return @msg
      end

    end
  end
end
