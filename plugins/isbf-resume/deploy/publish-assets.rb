# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "pathname"
require "tempfile"
require "propshaft"

module IsbfResume
  class AssetPublication
    class Error < StandardError
    end

    ASSET_PATH = %r{\A(?:js/plugins/isbf-resume_[^/]+\.js|map/plugins/isbf-resume_[^/]+\.js\.map)\z}

    def initialize(assembly:, generated_path:)
      @assembly = assembly
      @generated_path = Pathname.new(generated_path)
      @output_path = Pathname.new(assembly.config.output_path).realpath
      @manifest_path = Pathname.new(assembly.config.manifest_path)
      raise Error, "Unexpected production manifest location" if @manifest_path.dirname.realpath != @output_path
    end

    def publish!
      original = @manifest_path.binread
      existing = JSON.parse(original)
      selected_assets = assets
      require_current_assets!(selected_assets)
      additions = Propshaft::Manifest.new(integrity_hash_algorithm: @assembly.config.integrity_hash_algorithm)
      selected_assets.each { |asset| additions.push_asset(asset) }
      entries = JSON.parse(additions.to_json)
      entries.each do |path, entry|
        previous = existing[path]
        previous = { "digested_path" => previous, "integrity" => nil } if previous.is_a?(String)
        if existing.key?(path) && previous != entry
          raise Error, "Conflicting production asset entry: #{path}"
        end
      end

      outputs = selected_assets.map { |asset| [output_file(asset.digested_path.to_s), asset.compiled_content.b] }
      outputs.each do |path, content|
        if path.exist? && (!path.file? || path.binread != content)
          raise Error, "Conflicting production asset content: #{path.basename}"
        end
      end
      outputs.each { |path, content| atomic_write(path, content) unless path.exist? }

      # HTML must never see a manifest entry before its public file exists.
      raise Error, "Production manifest changed during publication" if @manifest_path.binread != original
      atomic_write(@manifest_path, JSON.generate(entries.merge(existing)))
      verify!
    rescue JSON::ParserError, SystemCallError => error
      raise Error, error.message
    end

    def verify!
      selected_assets = assets
      require_current_assets!(selected_assets)
      manifest = JSON.parse(@manifest_path.binread)
      resolver = Propshaft::Resolver::Static.new(manifest_path: @manifest_path, prefix: @assembly.config.prefix)
      required_paths.each do |logical_path|
        entry = manifest[logical_path]
        raise Error, "Unpublished resume asset: #{logical_path}" unless entry && resolver.resolve(logical_path)
        digested_path = entry.is_a?(String) ? entry : entry.fetch("digested_path")
        file = output_file(digested_path)
        expected = selected_assets.find { |asset| asset.logical_path.to_s == logical_path }.compiled_content.b
        raise Error, "Missing or inconsistent public resume asset: #{logical_path}" unless file.file? && file.binread == expected
      end
      { "assets" => required_paths, "manifest_sha256" => Digest::SHA256.hexdigest(@manifest_path.binread) }
    rescue JSON::ParserError, SystemCallError => error
      raise Error, error.message
    end

    private

    def assets
      Propshaft::LoadPath.new(
        [@generated_path],
        compilers: @assembly.compilers,
        version: @assembly.config.version,
        integrity_hash_algorithm: @assembly.config.integrity_hash_algorithm,
      ).assets.select { |asset| asset.logical_path.to_s.match?(ASSET_PATH) }
    end

    def required_paths
      generated = JSON.parse(@generated_path.join("manifest.json").read)
      raise Error, "Missing generated resume main entry" unless generated["main"].is_a?(Hash)
      filenames = generated.values.flat_map do |entry|
        [entry.fetch("fileName"), *entry.fetch("imports", []), *entry.fetch("routeBundles", []).map { |bundle| bundle.fetch("fileName") }]
      end
      filenames.map do |filename|
        path = "js/plugins/#{filename}"
        raise Error, "Unexpected generated resume asset path" unless path.match?(ASSET_PATH)
        path
      end.uniq.sort
    end

    def require_current_assets!(selected_assets)
      available = selected_assets.map { |asset| asset.logical_path.to_s }
      missing = required_paths - available
      raise Error, "Missing generated resume assets: #{missing.join(', ')}" if missing.any?
    end

    def output_file(relative_path)
      raise Error, "Unexpected public resume asset path" unless relative_path.match?(ASSET_PATH)
      path = @output_path.join(relative_path)
      cursor = path
      until cursor == @output_path
        raise Error, "Public asset symlink rejected" if cursor.symlink?
        cursor = cursor.parent
      end
      path
    end

    def atomic_write(path, content)
      FileUtils.mkdir_p(path.dirname)
      Tempfile.create([".isbf-resume-assets-", ".tmp"], path.dirname.to_s) do |temporary|
        temporary.binmode
        temporary.write(content)
        temporary.flush
        temporary.fsync
        temporary.chmod(0o644)
        File.rename(temporary.path, path)
      end
    end
  end
end
