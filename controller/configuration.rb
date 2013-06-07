require 'sinatra/base'

class OnBoard::Controller

  get "/configuration/save.html" do
    format(
      :path     => '/configuration/save',
      :format   => 'html',
      :title    => 'Save configuration'
    )
  end

  post "/configuration/save.html" do
    OnBoard.save! if params['save'] =~ /yes/i
    format(
      :path     => '/configuration/save',
      :format   => 'html',
      :title    => 'Save configuration'
    )
  end

  get "/configuration/export.html" do
    format(
      :path     => '/configuration/export',
      :format   => 'html',
      :title    => 'Export Configuration'
    )
  end

  get "/configuration.tgz" do
    base = OnBoard::DATADIR
    subdirs = %w{etc/config var/lib var/www}.select do |subdir|
      File.exists? File.join base, subdir
    end
    cmd = "tar --directory #{base} --create #{subdirs.join ' '} | gzip -cf"
    content_type 'application/x-gzip'
    `#{cmd}`
  end

end
