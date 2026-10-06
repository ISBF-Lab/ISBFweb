# frozen_string_literal: true

Fabricator(
  :isbf_calendar_official_item,
  class_name: "IsbfCalendar::OfficialItem"
) do
  topic { Fabricate(:topic_with_op) }
  title "Campus briefing"
  starts_at { Time.iso8601("2026-10-20T09:00:00+08:00") }
  ends_at { Time.iso8601("2026-10-20T10:00:00+08:00") }
  schedule_kind "event"
end

Fabricator(
  :isbf_calendar_official_deadline,
  from: :isbf_calendar_official_item
) do
  title "Registration deadline"
  starts_at { Time.iso8601("2026-10-19T18:00:00+08:00") }
  ends_at { |attributes| attributes[:starts_at] }
  schedule_kind "deadline"
end

Fabricator(:isbf_calendar_entry, class_name: "IsbfCalendar::Entry") do
  user
  title "Study session"
  starts_at { Time.iso8601("2026-10-20T09:00:00+08:00") }
  ends_at { Time.iso8601("2026-10-20T10:00:00+08:00") }
end

Fabricator(:isbf_calendar_official_entry, from: :isbf_calendar_entry) do
  source_item { Fabricate(:isbf_calendar_official_item) }
  title { |attributes| attributes[:source_item].title }
  starts_at { |attributes| attributes[:source_item].starts_at }
  ends_at { |attributes| attributes[:source_item].ends_at }
  all_day { |attributes| attributes[:source_item].all_day }
  schedule_kind { |attributes| attributes[:source_item].schedule_kind }
  accepted_revision { |attributes| attributes[:source_item].revision }
  notified_revision { |attributes| attributes[:source_item].revision }
end
