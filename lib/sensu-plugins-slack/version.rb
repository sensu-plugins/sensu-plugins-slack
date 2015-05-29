require 'json'

# encoding: utf-8
module SensuPluginsSlack
  # This defines the version of the gem
  module Version
    MAJOR = 0
    MINOR = 0
    PATCH = 1

    VER_STRING = [MAJOR, MINOR, PATCH].compact.join('.')
  end
end
