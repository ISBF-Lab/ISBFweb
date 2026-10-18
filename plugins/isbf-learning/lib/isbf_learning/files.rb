# frozen_string_literal: true

require "fileutils"
require "securerandom"
require "tempfile"

module IsbfLearning
  module Files
    MAX_STORAGE_BYTES = 2048 * 1024 * 1024
    CHUNK_BYTES = 64 * 1024
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/
    QUOTA_KEY = "storage-bytes"

    class << self
      def valid_id?(id)
        id.is_a?(String) && UUID.match?(id)
      end

      def root
        ENV["ISBF_LEARNING_STORAGE_PATH"].presence ||
          (
            if Rails.env.test?
              Rails.root.join("tmp/isbf-learning-private-test").to_s
            else
              "/shared/isbf-learning-private"
            end
          )
      end

      def path(id)
        raise Discourse::InvalidParameters.new(:id) unless id.is_a?(String) && UUID.match?(id)

        base = File.expand_path(root)
        [Rails.public_path.to_s, "/shared/uploads"].each do |public_root|
          public_root = File.expand_path(public_root)
          if base == public_root || base.start_with?(public_root + File::SEPARATOR)
            raise IsbfLearning::StorageError, "Private storage must be outside public uploads"
          end
        end
        destination = File.join(base, id)
        if File.symlink?(base) || File.symlink?(destination)
          raise IsbfLearning::StorageError, "Invalid private storage path"
        end
        destination
      end

      def metadata(id)
        path(id)
        row = PluginStore.get(IsbfLearning::STORE, "file:#{id}")
        return nil unless row

        {
          id: id,
          name: row["name"],
          size: row["size"],
          owner_id: row["owner_id"],
          bound: row["bound"] == true,
          url: "/isbf/learning/files/#{id}",
        }
      end

      def mark_bound!(id)
        path(id)
        row = PluginStoreRow.lock.find_by!(plugin_name: IsbfLearning::STORE, key: "file:#{id}")
        metadata = PluginStore.cast_value(row.type_name, row.value)
        metadata["bound"] = true
        unless PluginStore.set(IsbfLearning::STORE, "file:#{id}", metadata)
          raise IsbfLearning::StorageError, "Could not bind private file"
        end
      end

      def download(id, user, guardian)
        path(id)
        unless user && IsbfLearning.file_accessible?(id, user, guardian)
          raise Discourse::InvalidAccess
        end

        info = metadata(id)
        destination = path(id)
        raise Discourse::NotFound unless info && File.file?(destination)

        { path: destination, name: info[:name], size: info[:size] }
      end

      def upload(user, guardian, file)
        raise Discourse::InvalidAccess unless user
        IsbfLearning.ensure_can_submit!(user, guardian)
        unless file.is_a?(ActionDispatch::Http::UploadedFile)
          raise Discourse::InvalidParameters.new(:file)
        end
        RateLimiter.new(
          user,
          "uploads-per-minute",
          SiteSetting.max_uploads_per_minute,
          1.minute,
        ).performed!

        name = File.basename(file.original_filename.to_s.tr("\\", "/"))
        validate!(user, name, file.size)
        id = SecureRandom.uuid
        destination = path(id)
        FileUtils.mkdir_p(File.dirname(destination), mode: 0o700)
        temporary = Tempfile.new([".pending-", ""], File.dirname(destination))
        temporary.binmode
        published = false
        size = 0
        begin
          DistributedMutex.synchronize("isbf-learning-file-storage") do
            PluginStoreRow.transaction do
              counter =
                PluginStoreRow.find_or_create_by!(
                  plugin_name: IsbfLearning::STORE,
                  key: QUOTA_KEY,
                ) do |row|
                  row.type_name = "Integer"
                  row.value = "0"
                end
              # The database lock preserves the quota even if the Redis lease expires.
              counter.lock!
              remaining = quota_limit - counter.value.to_i
              if file.size > remaining
                raise IsbfLearning::StorageError, "Private storage quota exceeded"
              end

              file.rewind
              while chunk = file.read(CHUNK_BYTES)
                size += chunk.bytesize
                if size > remaining
                  raise IsbfLearning::StorageError, "Private storage quota exceeded"
                end
                temporary.write(chunk)
              end
              validate!(user, name, size)
              temporary.flush
              temporary.fsync
              temporary.close
              total = counter.value.to_i + size
              File.rename(temporary.path, destination)
              published = true
              unless PluginStore.set(
                       IsbfLearning::STORE,
                       "file:#{id}",
                       { name: name, size: size, owner_id: user.id },
                     )
                raise IsbfLearning::StorageError, "Could not save private file metadata"
              end
              counter.update!(value: total.to_s)
            end
            published = false
          end
          {
            id: id,
            name: name,
            size: size,
            owner_id: user.id,
            url: "/isbf/learning/files/#{id}",
            original_filename: name,
            filesize: size,
            extension: File.extname(name).delete_prefix(".").downcase,
            short_url: "/isbf/learning/files/#{id}",
          }
        ensure
          File.unlink(destination) if published && File.exist?(destination)
          temporary.close!
        end
      rescue SystemCallError, IOError
        raise IsbfLearning::StorageError, "Private file storage is unavailable"
      end

      private

      def quota_limit
        [
          [SiteSetting.isbf_learning_storage_limit_mb.to_i, 0].max * 1024 * 1024,
          MAX_STORAGE_BYTES,
        ].min
      end

      def validate!(user, name, size)
        upload =
          Upload.new(user: user, original_filename: name, filesize: size, validate_file_size: true)
        unless upload.valid? && size.positive?
          message = upload.errors.full_messages.join("; ").presence || "The file is empty"
          raise IsbfLearning::StorageError, message
        end
      end
    end
  end
end
