# frozen_string_literal: true

require "json"
require "pathname"
require "time"

module ::DiscourseUpdateStatusCard
  class PayloadReader
    BASE_DIR = "/shared/discourse-update-status"
    DEFAULT_FILE = "status.json"
    MAX_BYTES = 262_144

    def self.read
      new.read
    end

    def read
      path = resolved_path

      return error_result("not_found", "Status payload file does not exist.", path) unless File.file?(path)
      return error_result("too_large", "Status payload file is too large.", path) if File.size(path) > MAX_BYTES

      raw = File.read(path)
      json = JSON.parse(raw)

      return error_result("invalid_payload", "Top-level JSON payload must be an object.", path) unless json.is_a?(Hash)

      { ok: true, payload: normalized_payload(json, path) }
    rescue JSON::ParserError => e
      error_result("parse_error", e.message, path)
    rescue SecurityError => e
      error_result("invalid_path", e.message, path)
    rescue StandardError => e
      error_result("read_error", e.message, path)
    end

    private

    def resolved_path
      raw_path = SiteSetting.discourse_update_status_card_json_path.presence || DEFAULT_FILE
      candidate = Pathname.new(raw_path)
      candidate = Pathname.new(BASE_DIR).join(candidate) if candidate.relative?

      normalized = candidate.cleanpath
      base = Pathname.new(BASE_DIR).cleanpath

      unless normalized.to_s == base.to_s || normalized.to_s.start_with?("#{base}/")
        raise SecurityError, "Status payload path must stay under #{BASE_DIR}."
      end

      normalized
    end

    def normalized_payload(json, path)
      payload = json.deep_dup

      payload["summary"] ||= {}
      payload["live"] ||= {}
      payload["official"] ||= {}
      payload["checks"] ||= {}
      payload["reports"] ||= {}
      payload["notes"] = Array(payload["notes"])
      payload["meta"] = (payload["meta"] || {}).merge(
        "source_path" => path.to_s,
        "source_mtime" => File.mtime(path).utc.iso8601,
      )

      payload
    end

    def error_result(code, message, path)
      {
        ok: false,
        error_code: code,
        error: message,
        payload: {
          "meta" => {
            "source_path" => path.to_s,
          },
        },
      }
    end
  end
end
