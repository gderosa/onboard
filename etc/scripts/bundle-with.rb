#!/usr/bin/env ruby

# Since `bundle config set with` doesn't exist, and `without` is "remembered",
# let's remove a group from the "without"-list, by just running
#
#     ruby bundle-with.rb group1 [group2] [...]

# I can't find a better programmatic way to change Bundler config than
# hacking into the YAML config file...

require 'yaml'

ROOT = File.join File.dirname(__FILE__), '../..'
BUNDLECONFIG = File.join ROOT, '/.bundle/config'

if File.exists? BUNDLECONFIG
  config = YAML.load File.read BUNDLECONFIG
  if config['BUNDLE_WITHOUT'].respond_to? :split
    withouts = config['BUNDLE_WITHOUT'].split(':')
    withouts = withouts - ARGV
    config['BUNDLE_WITHOUT'] = withouts.join(':')
    File.open(BUNDLECONFIG, 'w') do |f|
      f.write YAML.dump config
    end
  end
end
