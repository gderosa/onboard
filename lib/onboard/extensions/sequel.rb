require 'sequel'

require 'onboard/extensions/sequel/dataset'

module Sequel

  class << self

    # Turn a column-aliases Hash (deprecated syntax) into an argument
    # list (Array) of Sequel.as(:column, :alias) objects.
    #
    #     DB[:mytable].select(
    #       Sequel.aliases {:id => :my_aliased_id, :name => :my_aliased_name}
    #     )
    #
    # On the deprecation/removal of such syntax you can read:
    # https://github.com/jeremyevans/sequel/pull/373#issuecomment-1792266
    #
    def aliases(h)
      list = []
      h.each_pair do |k, v|
        list << Sequel.as(k.to_sym, v.to_sym)
      end
      list
    end

  end

end
