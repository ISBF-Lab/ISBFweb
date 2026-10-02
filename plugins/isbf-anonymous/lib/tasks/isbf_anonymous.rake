# frozen_string_literal: true

namespace :isbf_anonymous do
  desc "Preview or migrate legacy anonymous posts into the shared account pool"
  task migrate_legacy: :environment do
    require_relative "../isbf_anonymous/legacy_migrator"

    dry_run = ENV["DRY_RUN"] != "0"
    cleanup = ENV["CLEANUP"] == "1"
    puts JSON.pretty_generate(
           IsbfAnonymous::LegacyMigrator.new(dry_run: dry_run, cleanup: cleanup).run,
         )
  end
end
