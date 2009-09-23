class OnBoard
  module System
    class Log
      Tail_n = 25 # show the last Tail_n number of lines in HTML, JSON, YAML

      # TODO: do not hardcode
      @@logs = [
        {
          'path'    => OnBoard::ROOTDIR + "/onboard.log", 
          'id'      => "onboard.log",
          'desc'    => "Main log",
          'category'=> 'main'
        },
        {
          'path'    => "/var/log/messages",
          'id'      => "messages",
          'desc'    => "OS \"messages\"",
          'htmldesc'=> "OS &ldquo;messages&rdquo;",
          'category'=> 'os'
        },
        {
          'path'    => "/var/log/syslog",
          'id'      => "syslog",
          'desc'    => "Main system log",
          'category'=> 'os'
        },
        {
          'path'    => "/var/log/daemon.log",
          'id'      => "daemon.log",
          'desc'    => "\"daemon\" log",
          'htmldesc'=> "&ldquo;daemon&rdquo; log",
          'category'=> 'os'
        }
      ]
      @@categories = {
        'main'      => "Main logs",
        'os'        => "OS logs"
      }

      def self.getAll
        @@logs
      end

      def self.all
        @@logs
      end

      def self.categories
        @@categories
      end
      
      def self.data
        {'logs' => @@logs, 'categories' => @@categories} 
      end

      attr_reader :meta

      def initialize(h) # keeps one of the elements of @@logs
        @meta = h
      end

      def data
        # DONE: Do not show the whole file to not bloat the web browser
        # TODO: Open the "File" class and add a "tail" method ?
        # NOTE: File::Tail gem is not what we want, since it displays the
        #   file as it grows (and presumably never returns...) 
        return {
          'meta'        => @meta, 
          'content_uri' => "/system/logs/#{@meta['id']}.raw",
          'tail'        => tail() 
        }  
      end


=begin
      # NOTE: Thanks to Brian Campbell for this:
      #   http://stackoverflow.com/questions/754494/reading-the-last-n-lines-of-a-file-in-ruby/754511#754511
      def tail(n=Tail_n)
        (lines.length > n) ? lines[-n..-1] : lines 
      end

      def lines
        filename = @meta['path']
        IO.readlines(filename)
      end
=end

      # An alternative solution that aims at not wasting system RAM anymore.
      def tail(n=Tail_n)
        `tail -n #{n} #{@meta['path']}` 
      end

      # It doesn't make much sense to embed the content of a whole log file
      # into a JSON or YAML or a web page; an human or a machine may go to 
      # data['content_uri'] and simply download it

    end
  end
end
