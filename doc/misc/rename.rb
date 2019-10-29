# put in the paren dir of the project's top level directory

require 'find'


_old="oldname"
_new="newname"
_OLD="OldName"
_NEW="NewName"


Find.find _old do |path|
  newpath = path.gsub /#{_old}/, _new
  puts path + ' -> ' + newpath
  if File.directory? path
    system "mkdir -p #{newpath}"
  else
    system "mkdir -p #{File.dirname newpath}"
    if path =~ /^#{_old}\/\.git/ or path =~ /\.(png|dat)$/
      system "cp -f #{path} #{newpath}"
    else
      oldfile = File.open path, 'r'
      newfile = File.open newpath, 'w'
      oldfile.each_line do |line|
        line.gsub! /#{_old}/, _new
        line.gsub! /#{_OLD}/, _NEW
        newfile.write line
      end
      oldfile.close
      newfile.close
    end
  end
end
