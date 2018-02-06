# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed [here](https://github.com/sensu-plugins/community/blob/master/HOW_WE_CHANGELOG.md)

## [Unreleased]
### Fixed
- Fixed unknown sensu check return value 127

### Changed
- Added default color for unknown sensu check return values

## [3.1.0] - 2018-01-31
### Changed
- `handler-slack.rb`: emit an `unknown` with helpful debug messages when passing in bad config (@majormoses)

### Added
- added sample event payload and config (@majormoses)

## [3.0.0] - 2018-01-11
### Breaking Changes
- bumped `sensu-plugin` dependency to 2.x which removes in handler filtering for `occurrences`. If you want to keep using the same filtering features you must specify it and ensure that you have applied the filter by setting `"filters": ["occurrences"]`. For more information see [here](https://blog.sensuapp.org/deprecating-event-filtering-in-sensu-plugin-b60c7c500be3) (@majormoses)

### Changed
- update changelog guidelines location, fix spelling in PR template (@majormoses)

## [2.0.0] - 2017-10-21
### Breaking Changes
- `handler-slack-multichannel.rb`: Fixed title unknown issue when using proxy clients, change from client address to client name (@autumnw)

## [1.5.1] - 2017-08-18
### Fixed
- `handler-slack-multichannel.rb`: Add param webhook_urls to support one webhook_url per channel (@autumnw)

### Added
- slack badge to README. (@majormoses)

## [1.5.0] - 2017-08-07
### Added
- `handler-slack.rb`: Add param dashboard to show http link on client notification

## [1.4.0] - 2017-07-24
### Added
- `slack-handler-multichannel.rb`: Added support for client-defined channel overrides (@fildred13)

## [1.3.0] - 2017-07-19
### Added
- `slack-handler-multichannel.rb`: Added support for `icon_emoji` option, which documentation already suggested was supported (@fildred13)

## [1.2.0] - 2017-07-13
### Added
- ruby 2.4 testing in travis (@majormoses)
- `slack-handler-multichannel.rb`: Add custom_field options to supply additional fields (@justbkuz)

## [1.1.1] - 2017-06-24
### Fixed
- Ran rubocop against `bin/slack-handler.rb` and `bin/slack-handler-multichannel.rb` (@pgporada)
- Fixed occurrences of http:// needing to be https:// by default (@pgporada)
- Fixed the location of the Sensu image that gets pulled in (@pgporada)

## [1.1.0] - 2017-06-22
### Added
- `slack-handler-multichannel.rb`: Add title line to mirror functionality of slack-handler.rb (@zer0nimbus)
- `handler-slack.rb`: Add a `link_names` parameter to allow for mentions (@unionsep)

### Fixed
- Allow custom channels with custom payload (@bashtoni)
- `handler-slack.rb`: Access the event notification from the correct location (@dunpealer)

## [1.0.0] - 2016-06-14
### Added
- Added a payload_template to allow for a customized JSON payload
- Ruby 2.3.0 support

### Fixed
- Extended the payload_template to work with multi-channel handlers

### Changed
- Update to Rubocop 0.40 and cleanup

### Removed
- Ruby 1.9.3 support

## [0.1.2] - 2016-02-05
### Added
- new certs

## [0.1.1] - 2015-12-09
### Changed
- Slack handler posts JSON content type and format to slack.
- Slack config supports icon_url and icon_emoji
### Added
- add arguments to specify proxy settings

## [0.1.0] - 2015-11-12
### Added
- New handler-slack-multichannel.rb handler for more complex multi-channel alerting to Slack
- Allow the client to set the channel

### Changed
- updated sensu-plugin gem to 1.2.0

### Fixed
- Fixed exception caused by missing field

## [0.0.4] - 2015-07-13
### Changed
- put gemspec deps in alpha order
- remove cruft from sensu-plugins-slack.rb
- Remove JSON gem dep that is not longer needed with Ruby 1.9+
- Put Rakfile deps in alpha order
- update documentation links in the README and CONTRIBUTING
- remove the Vagrantfile

## [0.0.3] - 2015-06-03
### Added
- additional functionality to slack hander to improve generated output

## [0.0.2] - 2015-06-03
### Fixed
- added binstubs

### Changed
- removed cruft from /lib

## 0.0.1 - 2015-05-29
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/3.1.0...HEAD
[3.1.0]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/3.0.0...3.1.0
[3.0.0]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/2.0.0...3.0.0
[2.0.0]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/1.5.0...2.0.0
[1.5.1]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/1.5.0...1.5.1
[1.5.0]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/1.4.0...1.5.0
[1.4.0]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/1.3.0...1.4.0
[1.3.0]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/1.2.0...1.3.0
[1.2.0]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/1.1.1...1.2.0
[1.1.1]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/1.1.0...1.1.1.
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/v0.1.2...1.0.0
[0.1.2]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/0.1.1...v0.1.2
[0.1.1]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/0.0.4...0.1.0
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-slack/compare/0.0.1...0.0.2
