# frozen_string_literal: true

module DiscourseAvatarFrames
  class ImageAnalysis
    SAMPLE_SIZE = 288
    ANGLES = 360

    def self.call(png)
      Tempfile.create(%w[avatar-frame-analysis .png]) do |file|
        file.binmode
        file.write(png.static_data)
        file.flush
        input = "#{file.path}[0]"
        opaque =
          ImageMagick.magick(
            input,
            "-format",
            "%[opaque]",
            "info:",
            operation: "avatar_frame_transparency",
            read: [file.path],
          )
        if opaque.strip.casecmp?("true")
          raise Png::Invalid, I18n.t("avatar_frames.errors.transparency_required")
        end
        Tempfile.create(%w[avatar-frame-mask .png]) do |mask|
          ImageMagick.magick(
            input,
            "-alpha",
            "extract",
            "-resize",
            "#{SAMPLE_SIZE}x#{SAMPLE_SIZE}!",
            "-depth",
            "8",
            "-interlace",
            "none",
            "-define",
            "png:color-type=0",
            "-define",
            "png:bit-depth=8",
            "png:#{mask.path}",
            operation: "avatar_frame_calibration",
            read: [file.path],
            write: [mask.path],
          )
          new(decode_mask(File.binread(mask.path))).suggestion
        end
      end
    rescue Discourse::Utils::CommandError
      raise Png::Invalid, I18n.t("avatar_frames.errors.invalid_image")
    end

    def self.decode_mask(data)
      offset = Png::SIGNATURE.bytesize
      compressed = +"".b
      while offset < data.bytesize
        length = data.byteslice(offset, 4).unpack1("N")
        kind = data.byteslice(offset + 4, 4)
        payload = data.byteslice(offset + 8, length)
        if kind == "IHDR" && payload.unpack("NNC5") != [SAMPLE_SIZE, SAMPLE_SIZE, 8, 0, 0, 0, 0]
          raise Png::Invalid, I18n.t("avatar_frames.errors.invalid_image")
        end
        compressed << payload if kind == "IDAT"
        offset += length + 12
      end
      rows = Zlib::Inflate.inflate(compressed).bytes
      unless rows.size == SAMPLE_SIZE * (SAMPLE_SIZE + 1)
        raise Png::Invalid, I18n.t("avatar_frames.errors.invalid_image")
      end

      pixels = []
      SAMPLE_SIZE.times do |y|
        filter = rows[y * (SAMPLE_SIZE + 1)]
        SAMPLE_SIZE.times do |x|
          left = x.positive? ? pixels.last : 0
          up = y.positive? ? pixels[(y - 1) * SAMPLE_SIZE + x] : 0
          corner =
            (
              if x.positive? && y.positive?
                pixels[(y - 1) * SAMPLE_SIZE + x - 1]
              else
                0
              end
            )
          predictor =
            case filter
            when 0
              0
            when 1
              left
            when 2
              up
            when 3
              (left + up) / 2
            when 4
              estimate = left + up - corner
              [left, up, corner].min_by { |value| (estimate - value).abs }
            else
              raise Png::Invalid, I18n.t("avatar_frames.errors.invalid_image")
            end
          pixels << (rows[y * (SAMPLE_SIZE + 1) + x + 1] + predictor) % 256
        end
      end
      pixels
    end
    private_class_method :decode_mask

    def initialize(alpha)
      @alpha = alpha
    end

    def suggestion
      points = boundary_points
      return if points.size < ANGLES * 0.85

      radii = points.map { |x, y,| Math.hypot(x - SAMPLE_SIZE / 2.0, y - SAMPLE_SIZE / 2.0) }.sort
      median = radii[radii.size / 2]
      points =
        points.select do |x, y,|
          (Math.hypot(x - SAMPLE_SIZE / 2.0, y - SAMPLE_SIZE / 2.0) - median).abs <= 12
        end
      circle = nil
      3.times do
        return if points.size < ANGLES * 0.85
        circle = fit_circle(points)
        return unless circle
        cx, cy, radius = circle
        points = points.select { |x, y,| (Math.hypot(x - cx, y - cy) - radius).abs <= 2 }
      end
      return if points.size < ANGLES * 0.85
      angles = points.map(&:last).sort
      gaps = angles.each_cons(2).map { |a, b| b - a }
      gaps << angles.first + ANGLES - angles.last
      return if gaps.max > 35

      cx, cy, radius = circle
      unless radius.between?(SAMPLE_SIZE * 0.3, SAMPLE_SIZE * 0.475) &&
               (cx - SAMPLE_SIZE / 2.0).abs <= SAMPLE_SIZE * 0.15 &&
               (cy - SAMPLE_SIZE / 2.0).abs <= SAMPLE_SIZE * 0.15
        return
      end

      scale = SAMPLE_SIZE / (radius * 2)
      {
        scale: (scale * 100).round(3),
        offset_x: (scale * (0.5 - cx / SAMPLE_SIZE) * 100).round(3),
        offset_y: (scale * (0.5 - cy / SAMPLE_SIZE) * 100).round(3),
      }
    end

    private

    def boundary_points
      center = SAMPLE_SIZE / 2.0
      (0...ANGLES).filter_map do |angle|
        radians = angle * Math::PI / 180
        dx = Math.cos(radians)
        dy = Math.sin(radians)
        (40...SAMPLE_SIZE / 2 + 24)
          .each do |radius|
            x = (center + dx * radius).floor
            y = (center + dy * radius).floor
            break unless x.between?(0, SAMPLE_SIZE - 1) && y.between?(0, SAMPLE_SIZE - 1)
            next if @alpha[y * SAMPLE_SIZE + x] < 128
            break x + 0.5, y + 0.5, angle
          end
          .then { |point| point if point.is_a?(Array) }
      end
    end

    def fit_circle(points)
      equations = Array.new(3) { Array.new(4, 0.0) }
      points.each do |x, y,|
        row = [x, y, 1]
        target = -(x * x + y * y)
        3.times do |i|
          3.times { |j| equations[i][j] += row[i] * row[j] }
          equations[i][3] += row[i] * target
        end
      end
      3.times do |i|
        pivot = (i...3).max_by { |j| equations[j][i].abs }
        return nil if equations[pivot][i].abs < 1e-8
        equations[i], equations[pivot] = equations[pivot], equations[i]
        divisor = equations[i][i]
        equations[i].map! { |value| value / divisor }
        3.times do |j|
          next if j == i
          multiplier = equations[j][i]
          4.times { |column| equations[j][column] -= multiplier * equations[i][column] }
        end
      end
      a, b, c = equations.map(&:last)
      radius_squared = (a * a + b * b) / 4 - c
      return unless radius_squared.positive?
      [-a / 2, -b / 2, Math.sqrt(radius_squared)]
    end
  end
end
