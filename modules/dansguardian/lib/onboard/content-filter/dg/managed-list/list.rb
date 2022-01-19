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
            @file_encoding  = case h[:file_encoding]
                              when Encoding
                                h[:file_encoding]
                              when String
                                begin
                                  Encoding.find h[:file_encoding]
                                rescue ArgumentError
                                  Encoding::BINARY
                                end
                              else
                                Encoding::BINARY
                              end
            @relative_path  = h[:relative_path]
            @data           = ::DansGuardian::List.new(
              :file           =>absolute_path,  # included by FilePathMixin
              :file_encoding  => @file_encoding
            )
          end

          # Delegate to ::DansGuardian::List instance methods.

          def items;          @data.items;          end
          def listcategory;   @data.listcategory;   end
          def read!;          @data.read!;          end
          def file_encoding;  @data.file_encoding;  end

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

# Lots of encoding issues :-( , download the raw file!
=begin
          def export
            h = {}
            # h['file_encoding']  = @file_encoding.name # not 'intrinsic'
            h['listcategory']   = listcategory
            h['items']          = items.map do |s|
              s.encode Encoding::default_external
            end
            return h
          end

          def to_json(*args); export.to_json(*args); end
          def to_yaml(*args); export.to_yaml(*args); end
=end

          def <=>(other)
            if other.is_a? ManagedList::Dir
              +1 # list directories before files
            else
              @relative_path <=> other.relative_path
            end
          end

          def update!(params)
            File.open absolute_path, "w:#{@file_encoding}" do |f|
              listcategory =
                  params['listcategory'].from_asciihex(@file_encoding)
              f.puts "#listcategory: \"#{listcategory}\""
              f.puts
              f.puts '# List items:'
              f.puts params['items'].gsub(
		      "\r\n", "\n").from_asciihex(@file_encoding)
              f.puts
              f.puts '# Includes:'
              if params['include'].respond_to? :each
                params['include'].each do |inc|
                  f.print '# ' if inc['include'] != 'on'
                  f.puts(
".Include<#{ManagedList.absolute_path inc['relative_path']}>"
                  )
                end
              end
            end
          end

        end
      end
    end
  end
end
