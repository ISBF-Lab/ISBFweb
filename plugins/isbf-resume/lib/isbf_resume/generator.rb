# frozen_string_literal: true

require "open3"
require "timeout"

module IsbfResume
  class Generator
    class GenerationError < StandardError
    end

    class InvalidResume < StandardError
      attr_reader :field_errors

      def initialize(field_errors)
        @field_errors = field_errors
        super("Invalid resume fields")
      end
    end

    ROOT = File.expand_path("../..", __dir__)
    MAX_OUTPUT_BYTES = 256.kilobytes

    def self.call(export)
      python = ENV.fetch("ISBF_RESUME_PYTHON", "/opt/resume-venv/bin/python")
      command = [
        python,
        File.join(ROOT, "resume_generator.py"),
        export.input_path,
        "--output-dir",
        export.directory,
        "--preview"
      ]
      output = +""
      status = nil
      Open3.popen3(
        { "PYTHONUTF8" => "1" },
        *command,
        pgroup: true,
        umask: 0o077
      ) do |stdin, stdout, stderr, process|
        stdin.close
        readers = [
          Thread.new { stdout.read(MAX_OUTPUT_BYTES) },
          Thread.new { stderr.read(MAX_OUTPUT_BYTES) }
        ]
        begin
          Timeout.timeout(GENERATION_TIMEOUT) do
            output = readers.first.value
            readers.last.value
            status = process.value
          end
        rescue Timeout::Error
          begin
            Process.kill("KILL", -process.pid)
          rescue StandardError
            Errno::ESRCH
          end
          raise GenerationError
        ensure
          readers.each(&:kill)
        end
      end
      manifest = JSON.parse(output)
      raise GenerationError unless manifest.is_a?(Hash)
      if status.exitstatus == 2
        raise InvalidResume.new(manifest.fetch("errors"))
      end
      raise GenerationError unless status.success?
      template =
        JSON.parse(File.read(export.input_path)).fetch("template", "blue-gold")
      export.complete!(manifest.merge("template" => template))
    rescue Errno::ENOENT, JSON::ParserError, KeyError, ArgumentError
      raise GenerationError
    ensure
      File.unlink(export.input_path) if File.file?(export.input_path)
    end
  end
end
