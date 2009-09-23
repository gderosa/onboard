# Copyright 2009, Guido De Rosa <job at guidoderosa . net>
# Distributed under the same terms of 'rubytree' -- 
# http://rubytre.rubyforge.org/

require 'tree'

module Tree
  class TreeNode
    def add_recursive(path, content)
      #
      # A leading slash in the path means that it is absolute (i.e. refers 
      # to the tree root) 
      #
      # path may be an Array (instead of String), but this is intended for
      # "private" use only (i.e. recursive calls)  
      #
      if path.respond_to? :split
        path = path.split('/') 
      end
      if path[0] == "" # as a result of a leading slash in path string
        path.shift
        return self.root.add_recursive(path, content)        
      end
      if path.length == 1
        begin
          node = self.class.new(path[0], content) # it may be a derived class
          add node
          return node
        rescue RuntimeError # node already exists
          self[path[0]].content = content
        end
      else
        begin 
          add self.class.new(path[0], nil) # it may be a derived class
        rescue RuntimeError # node already exists
          # do nothing
        end
        first = path.shift
        self[first].add_recursive(path, content) 
      end
    end
    alias add_path add_recursive
  end
end

# example/test :

# You should get:
#                                                 -> like ("awesome content")
#                                               /
#         ROOT -> path -> to -> anything -> I -<                
#             \                                 \ 
#              \                                  -> like2 ("awesome content2")
#               \                                         \
#                -> absolute -> path ("abs_path_content")  \
#                                                           \
#                                                            sub
#                                                             |
#                                                            path 
#                                                           ("sub_path_content")
if $0 == __FILE__
  # TODO: use Ruby test frameworks
  require 'pp'
  root = Tree::TreeNode.new("ROOT", "my content")
  node1 = root.add_recursive("path/to/anything/I/like", "awesome content")
  node2 = root.add_recursive("/path/to/anything/I/like2", "awesome content2")
  pp root
  puts 
  pp root['path']['to']['anything']['I']['like'].content
  pp root['path']['to']['anything']['I']['like2'].content
  
  node2.add_recursive("sub/path", "sub_path_content")
  node2.add_recursive("/absolute/path", "abs_path_content")
  pp root['path']['to']['anything']['I']['like2']['sub']['path'].content
  pp root['absolute']['path'].content
end
