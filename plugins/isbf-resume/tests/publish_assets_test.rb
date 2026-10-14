# frozen_string_literal: true

require "fileutils"
require "json"
require "ostruct"
require "pathname"
require "tmpdir"
require "active_support/all"
require "propshaft"
require "minitest/autorun"
require_relative "../deploy/publish-assets"

class PublishAssetsTest < Minitest::Test
  MAIN = "isbf-resume_main.NEW-fingerprint.digested.js"
  IMPORT = "isbf-resume_shared.NEW-fingerprint.digested.js"
  ROUTE = "isbf-resume_route.NEW-fingerprint.digested.js"

  def setup
    @temporary = Dir.mktmpdir("isbf-resume-publication-")
    @generated = Pathname.new(@temporary).join("generated")
    @output = Pathname.new(@temporary).join("public/assets")
    @output.mkpath
    @manifest = @output.join(".manifest.json")
    @original_entries = {
      "application.js" => { "digested_path" => "application-old.js", "integrity" => nil },
      "js/plugins/isbf-resume_main.OLD-fingerprint.digested.js" => {
        "digested_path" => "js/plugins/isbf-resume_main.OLD-fingerprint.digested.js",
        "integrity" => "sha384-previous",
      },
      "manifest.json" => { "digested_path" => "manifest-existing.json", "integrity" => nil },
    }
    @manifest.write(JSON.generate(@original_entries))
    @original_entries.each_value do |entry|
      write_file(@output.join(entry.fetch("digested_path")), "previous public asset")
    end
    [MAIN, IMPORT, ROUTE].each do |filename|
      write_file(@generated.join("js/plugins", filename), "console.log(#{filename.to_json});\n")
    end
    write_file(@generated.join("map/plugins", "#{MAIN}.map"), '{"version":3,"sources":[]}')
    write_file(@generated.join("js/plugins/another-plugin_main.digested.js"), "unrelated plugin")
    write_file(@generated.join("private.txt"), "not a public asset")
    write_file(
      @generated.join("manifest.json"),
      JSON.generate(
        "main" => {
          "fileName" => MAIN,
          "imports" => [IMPORT],
          "externalPluginImports" => [],
          "routeBundles" => [{ "fileName" => ROUTE }],
        },
      ),
    )
    @assembly = Propshaft::Assembly.new(
      OpenStruct.new(
        paths: [@generated],
        output_path: @output,
        manifest_path: @manifest,
        prefix: "/assets",
        version: "resume-regression-v1",
        integrity_hash_algorithm: "sha384",
        file_watcher: nil,
        compilers: [],
      ),
    )
    @publication = IsbfResume::AssetPublication.new(assembly: @assembly, generated_path: @generated)
  end

  def teardown
    FileUtils.remove_entry(@temporary) if @temporary
  end

  def test_verify_rejects_generated_main_missing_from_production_manifest
    assert @generated.join("js/plugins", MAIN).file?
    assert_nil resolver.resolve("js/plugins/#{MAIN}")
    assert_raises(IsbfResume::AssetPublication::Error) { @publication.verify! }
  end

  def test_publish_makes_main_import_route_and_map_available_through_static_resolver
    result = @publication.publish!

    assert_kind_of Hash, result
    assert_kind_of Hash, @publication.verify!
    expected_assets.each do |asset|
      logical_path = asset.logical_path.to_s
      assert_equal "/assets/#{asset.digested_path}", resolver.resolve(logical_path)
      assert_equal asset.compiled_content.b, resolver.read(logical_path).b
      assert_equal asset.integrity(hash_algorithm: "sha384"), resolver.integrity(logical_path)
    end
  end

  def test_verify_rejects_missing_published_main_import_or_route_file
    @publication.publish!
    [MAIN, IMPORT, ROUTE].each do |filename|
      path = @output.join("js/plugins", filename)
      content = path.binread
      path.delete
      assert_raises(IsbfResume::AssetPublication::Error) { @publication.verify! }
      path.binwrite(content)
    end
  end

  def test_verify_rejects_missing_import_or_route_manifest_entry
    @publication.publish!
    published = @manifest.binread
    [IMPORT, ROUTE].each do |filename|
      entries = JSON.parse(published)
      entries.delete("js/plugins/#{filename}")
      @manifest.write(JSON.generate(entries))
      assert_raises(IsbfResume::AssetPublication::Error) { @publication.verify! }
    end
    @manifest.binwrite(published)
  end

  def test_publish_preserves_all_existing_entries_and_excludes_generated_metadata
    generated_metadata = @generated.join("manifest.json").binread
    @publication.publish!
    entries = JSON.parse(@manifest.read)

    @original_entries.each { |path, entry| assert_equal entry, entries.fetch(path) }
    assert_equal(
      (@original_entries.keys + expected_assets.map { |asset| asset.logical_path.to_s }).sort,
      entries.keys.sort,
    )
    assert_equal "previous public asset", resolver.read("manifest.json")
    assert_equal generated_metadata, @generated.join("manifest.json").binread
  end

  def test_conflicting_manifest_entry_is_rejected_without_advancing_manifest
    entries = JSON.parse(@manifest.read)
    entries["js/plugins/#{MAIN}"] = { "digested_path" => "conflicting.js", "integrity" => nil }
    @manifest.write(JSON.generate(entries))
    before = @manifest.binread

    assert_raises(IsbfResume::AssetPublication::Error) { @publication.publish! }
    assert_equal before, @manifest.binread
  end

  def test_conflicting_public_content_is_rejected_without_overwriting_it
    path = @output.join("js/plugins", MAIN)
    write_file(path, "conflicting public content")
    before = @manifest.binread

    assert_raises(IsbfResume::AssetPublication::Error) { @publication.publish! }
    assert_equal "conflicting public content", path.read
    assert_equal before, @manifest.binread
  end

  def test_publication_can_be_retried_without_changing_manifest_or_files
    @publication.publish!
    before = public_snapshot

    @publication.publish!

    assert_equal before, public_snapshot
    assert_kind_of Hash, @publication.verify!
  end

  def test_missing_generated_import_does_not_advance_production_manifest
    @generated.join("js/plugins", IMPORT).delete
    before = @manifest.binread

    assert_raises(IsbfResume::AssetPublication::Error) { @publication.publish! }
    assert_equal before, @manifest.binread
    assert_nil resolver.resolve("js/plugins/#{MAIN}")
  end

  def test_failed_public_file_write_does_not_advance_production_manifest
    # A file in place of the output directory reliably fails even when CI runs as root.
    @output.join("map").write("blocked directory")
    before = @manifest.binread

    assert_raises(IsbfResume::AssetPublication::Error) { @publication.publish! }
    assert_equal before, @manifest.binread
    assert_nil resolver.resolve("js/plugins/#{MAIN}")
  end

  private

  def write_file(path, content)
    path.dirname.mkpath
    path.binwrite(content)
  end

  def resolver
    Propshaft::Resolver::Static.new(manifest_path: @manifest, prefix: "/assets")
  end

  def expected_assets
    @assembly.load_path.assets.select do |asset|
      ["js/plugins/#{MAIN}", "js/plugins/#{IMPORT}", "js/plugins/#{ROUTE}", "map/plugins/#{MAIN}.map"].include?(
        asset.logical_path.to_s,
      )
    end
  end

  def public_snapshot
    @output.glob("**/*", File::FNM_DOTMATCH).select(&:file?).to_h do |path|
      [path.relative_path_from(@output).to_s, path.binread]
    end
  end
end
