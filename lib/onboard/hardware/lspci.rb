class OnBoard
  module Hardware
    class LSPCI
      @@out = ""
      @@by_id = {}

      def initialize
        @@out = `lspci -m` if @@out == "" # execute only once
        parse if @@by_id == {}            # parse only once
      end

      def self.flush
        @@out = ""
        @@by_id = {}
      end

      def parse
        @@out.each_line do |line|
          line =~ /^(..:..\..) "([^"]+)" "([^"]+)" "([^"]+)"/
            @@by_id[$1] = {
              :desc   => $2,
              :vendor => $3,
              :model  => $4
            }
        end
      end

      def by_id
        @@by_id
      end

      def self.by_id
        self.new.by_id
      end
    end
  end
end
