# frozen_string_literal: true

# name: isbf-calendar
# about: Private personal schedules and routes for the ISBF calendar UI
# version: 0.1.0
# authors: ISBF Lab
# url: https://github.com/ISBF-Lab/ISBF-Calendar
# required_version: 3.4.0

module ::IsbfCalendar
  PLUGIN_NAME = "isbf-calendar"
end

require_relative "lib/isbf_calendar/engine"

after_initialize { require_relative "app/models/isbf_calendar/entry" }
