#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## Unreleased
### Changed
- Slack handler posts JSON content type and format to slack.
- Slack config supports icon_url and icon_emoji
### Added
- New handler-slack-multichannel.rb handler for more complex multi-channel alerting to Slack

## [0.0.3] - 2015-07-14
### Changed
- updated sensu-plugin gem to 1.2.0

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
-additional functionality to slack hander to improve generated output

## [0.0.2] - 2015-06-03
### Fixed
- added binstubs

### Changed
- removed cruft from /lib

## 0.0.1 - 2015-05-29
### Added
- initial release
