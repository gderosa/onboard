require 'find'
require 'dansguardian/list'
require 'onboard/content-filter/dg/managed-list/filepath-mixin'

class OnBoard
  module ContentFilter
    class DG
      module ManagedList
        class List

          include ManagedList::FilePathMixin

          def initialize(h)
            @relative_path  = h[:relative_path]
            @data           = ::DansGuardian::List.new(absolute_path)
          end

          # Delegate to ::DansGuardian::List instance methods.

          def items;        @data.items;        end
          def listcategory; @data.listcategory; end
          def read!;        @data.read!;        end

          #def includes
          #  @data.includes.map do |abspath| 
          #    relpath = ManagedList.relative_path abspath
          #    ManagedList::List.new :relative_path => relpath
          #  end
          #end 

          def includables
            includes    = @data.includes
            dir_name    = File.dirname absolute_path
            includables = []
            ::Dir.glob "#{dir_name}/*/**" do |f|
              unless File.directory? File.realpath f
                relpath   = ManagedList.relative_path f
                list      = ManagedList::List.new :relative_path => relpath
                if @data.includes.include? f
                  def list.included?; true;   end
                else
                  def list.included?; false;  end
                end
                includables << list
              end
            end
            return includables
          end

          def <=>(other)
            if other.is_a? ManagedList::Dir
              +1 # list directories before files
            else
              @relative_path <=> other.relative_path
            end
          end

          def update!(params)
            File.open absolute_path, 'w' do |f|
              f.puts "#listcategory: \"#{params['listcategory']}\""
              f.puts
              f.puts '# List items:'
              f.puts params['items']
              f.puts
              f.puts '# Includes:'
              params['include'].each do |inc|
                f.print '# ' if inc['include'] != 'on'
                f.puts ".Include<#{ManagedList.absolute_path inc['relative_path']}>"
              end
            end
          end

        end
      end
    end
  end
end
