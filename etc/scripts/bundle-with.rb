#!/usr/bin/env ruby

# Bundler does not handle when a gem is (or would be) both in
# BUNDLE_WITHOUT and BUNDLE_WITH,
# therefore we better use only one of those options.
#
# When we want to add a group of gems, we actually remove it
# from BUNDLE_WITHOUT. This script implements the necessary "negative" logic.
#
# Example: bundle-with.rb openvpn easy-rsa

require 'yaml'

ROOT = File.join File.dirname(__FILE__), '../..'
BUNDLECONFIG = File.join ROOT, '/.bundle/config'

# TODO: use system('bundle config ...') instead?
if File.exists? BUNDLECONFIG
  config = YAML.load File.read BUNDLECONFIG
  config.delete 'BUNDLE_WITH'
  if config['BUNDLE_WITHOUT'].respond_to? :split
    withouts = config['BUNDLE_WITHOUT'].split(':')
    withouts = withouts - ARGV
    config['BUNDLE_WITHOUT'] = withouts.join(':')
    File.open(BUNDLECONFIG, 'w') do |f|
      f.write YAML.dump config
    end
  end
end
