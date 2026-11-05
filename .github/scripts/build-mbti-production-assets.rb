# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"

workspace = Pathname.new(ENV.fetch("GITHUB_WORKSPACE")).realpath
unless ENV["GITHUB_ACTIONS"] == "true" && Rails.root.realpath == workspace.join("discourse")
  raise "Production asset evidence must run in the isolated CI checkout"
end
modes = [Rails.env.to_s, ENV["EMBER_ENV"], ENV["SKIP_DB_AND_REDIS"]]
unless modes == %w[production production 1]
  raise "Production assets require explicit production modes and no database or Redis"
end

source_sha = Rails.root.join("tmp/mbti-source-sha.txt").read.strip
raise "Missing exact candidate source SHA" unless source_sha.match?(/\A[0-9a-f]{40}\z/)
candidate_root = workspace.join("candidate")
candidate_sha, _, status = Open3.capture3("git", "-C", candidate_root.to_s, "rev-parse", "HEAD")
raise "Candidate checkout changed" unless status.success? && candidate_sha.strip == source_sha

plugin = Discourse.plugins.find { |candidate| candidate.name == "isbf-mbti" }
raise "Candidate MBTI plugin is not loaded" unless plugin

plugin_root = Rails.root.join("plugins/isbf-mbti")
raise "Unexpected plugin directory" unless Pathname.new(plugin.directory).realpath == plugin_root

output = Rails.root.join("tmp/mbti-production-assets")
raise "Asset evidence directory already exists" if output.exist?

other_manifests =
  Dir
    .glob(Rails.root.join("app/assets/generated/*/manifest.json"))
    .reject { |path| path.include?("/isbf-mbti/") }
    .to_h { |path| [path, Digest::SHA256.file(path).hexdigest] }
locks =
  %w[Gemfile.lock pnpm-lock.yaml].to_h do |path|
    [path, Digest::SHA256.file(Rails.root.join(path)).hexdigest]
  end

Plugin::JsManager.new.compile_js_bundle(plugin)

other_manifests.each do |path, expected|
  actual = Digest::SHA256.file(path).hexdigest
  raise "Unrelated plugin manifest changed: #{path}" if actual != expected
end
locks.each do |path, expected|
  actual = Digest::SHA256.file(Rails.root.join(path)).hexdigest
  raise "Frozen lock changed: #{path}" if actual != expected
end

generated = Rails.root.join("app/assets/generated/isbf-mbti")
manifest = JSON.parse(generated.join("manifest.json").read)
raise "Unexpected production entrypoints" unless manifest.keys == ["main"]
external_imports = manifest.fetch("main").fetch("externalPluginImports")
raise "Unexpected external plugin imports" unless external_imports.empty?

referenced = [manifest.fetch("main").fetch("fileName"), *manifest.fetch("main").fetch("imports")]
referenced.each do |name|
  raise "Invalid generated asset name" unless name == File.basename(name) && name.end_with?(".js")
  raise "Missing generated asset" unless generated.join("js/plugins", name).file?
end

FileUtils.mkdir_p(output)
FileUtils.cp_r(generated, output.join("isbf-mbti"))
asset_hashes =
  Dir.glob(output.join("isbf-mbti/**/*"), File::FNM_DOTMATCH).filter_map do |path|
    raise "Unexpected asset symlink" if File.symlink?(path)
    next unless File.file?(path)
    [Pathname.new(path).relative_path_from(output).to_s, Digest::SHA256.file(path).hexdigest]
  end.to_h
tracked, _, status =
  Open3.capture3(
    "git",
    "-C",
    candidate_root.to_s,
    "ls-tree",
    "-r",
    "-z",
    "--name-only",
    source_sha,
    "--",
    "plugins/isbf-mbti",
  )
raise "Could not read candidate plugin paths" unless status.success?
plugin_hashes = {}
tracked.split("\0").each do |path|
  relative = path.delete_prefix("plugins/isbf-mbti/")
  runtime_path = plugin_root.join(relative)
  raise "Unexpected plugin symlink" if runtime_path.symlink?
  expected = Digest::SHA256.file(candidate_root.join(path)).hexdigest
  raise "Plugin source drift: #{path}" if Digest::SHA256.file(runtime_path).hexdigest != expected
  plugin_hashes[relative] = expected
end
compiler_hashes =
  %w[
    lib/plugin/js_manager.rb
    lib/plugin/js_compiler.rb
    lib/asset_processor.rb
    config/initializers/assets.rb
  ].to_h { |path| [path, Digest::SHA256.file(Rails.root.join(path)).hexdigest] }
receipt = {
  source_sha: source_sha,
  runtime_sha: Rails.root.join("tmp/mbti-runtime-sha.txt").read.strip,
  rails_env: Rails.env.to_s,
  ember_env: ENV.fetch("EMBER_ENV"),
  database_and_redis_skipped: true,
  minified: true,
  manifest: manifest,
  asset_sha256: asset_hashes,
  plugin_source_sha256: plugin_hashes,
  compiler_source_sha256: compiler_hashes,
  frozen_locks_sha256: locks,
  unrelated_manifest_count: other_manifests.length,
}
output.join("receipt.json").write(JSON.pretty_generate(receipt) + "\n")
puts "Produced #{asset_hashes.length} MBTI production asset files for #{source_sha}"
