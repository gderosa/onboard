class OnBoard
  module System
    class Log
      Tail_n = 120 # show the last Tail_n number of lines in HTML, JSON, YAML
      DATAFILE = File.join VARLIB, 'system/logs/registered.yaml'

      # badly designed class, too much hashes...
      # 'id' is not really an id, just a shortcut. We're moving to
      # a path-based identification, and now h['id'] may also be nil

      class << self

        def set_defaults!

          # TODO: do not hardcode
          @logs ||= [
            {
              'path'    => OnBoard::LOGFILE_PATH,
              'id'      => OnBoard::LOGFILE_BASENAME,
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

          @categories ||= {
            'main'      => "Main logs",
            'os'        => "OS logs"
          }

        end

        def sanitize!
          file_needs_update = false
          new = []
          @logs.each do |h|
            if File.exists? h['path']
              new << h
            else
              file_needs_update = true
            end
          end
          @logs = new
          save if file_needs_update
        end

        def all
          sanitize!
          @logs
        end

        def getAll
          all
        end

        def delete_if(&blk)
          @logs.delete_if &blk
          save
        end

        def categories
          @categories
        end

        def data
          {'logs' => @logs, 'categories' => @categories}
        end

        def register(new_h)
          # "create or replace"
          @logs.each_with_index do |old_h, i|
            if old_h['path'] == new_h['path']
              @logs[i] = new_h
              return
            end
          end
          @logs << new_h
          save
        end

        def register_category(name, description)
          @categories[name] = description
          save
        end

        def to_json(*a); data.to_json(*a); end

        def to_yaml(*a); data.to_yaml(*a); end

        def save
          FileUtils.mkdir_p File.dirname DATAFILE
          File.open DATAFILE, 'w' do |f|
            f.write YAML.dump data
          end
        end

        def load
          if File.exists? DATAFILE
            h = YAML.load File.read DATAFILE
            @categories         ||= {}
            @categories.update      h['categories']
            @logs               ||= []
            @logs               |=  h['logs']
          end
        end

      end

      attr_reader :meta

      def initialize(h) # keeps one of the elements of @logs
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

      alias to_h data

      def to_json(*a); to_h.to_json(*a); end

      def to_yaml(*a); to_h.to_yaml(*a); end

      # Native Unix tools are faster, so use them!
      def tail(n=Tail_n)
        return nil unless @meta['path']
        if File.readable? @meta['path']
          return `tail -n #{n} #{@meta['path']}`
        else
          return `sudo tail -n #{n} #{@meta['path']}`
        end
      end

      # It doesn't make much sense to embed the content of a whole log file
      # into JSON, YAML or HTML; a human or a machine may go to
      # data['content_uri'] and simply download it

    end
  end
end

OnBoard::System::Log.set_defaults! # horrible

