require 'fileutils'
require 'erb'


class ERB

  #   ERB::recurse('/src/dir', binding, '.erb') do |subpath|
  #     "/dest/dir/#{subpath}.html" # or nil/false to discard
  #   end
  #
  def self.recurse(srcdir, binding_, ext, &block)
    Dir.glob "#{srcdir}/**/*#{ext}" do |file|
      # turn
      #   "/src/path/sub/path.html.erb"
      # into
      #   "sub/path.html"
      # (assuming ext == ".erb")
      srcdir_re = Regexp.escape srcdir
      ext_re    = Regexp.escape ext
      subpath = file.sub %r{#{srcdir_re}/*([^/].*)#{ext_re}}, '\1'
      if dest = block.call(subpath)
        FileUtils.mkdir_p File.dirname(dest)
        File.open dest, 'w' do |f|
          f.write ERB.new(File.read file).result(binding_)
        end
      end
    end
  end
end


