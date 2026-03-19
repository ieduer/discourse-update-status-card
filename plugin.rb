# frozen_string_literal: true

# name: discourse-update-status-card
# about: Read-only admin dashboard card for forum update readiness and maintenance status.
# version: 0.1.0
# authors: ylsuen

enabled_site_setting :discourse_update_status_card_enabled

register_asset "stylesheets/admin/discourse-update-status-card.scss"

module ::DiscourseUpdateStatusCard
  PLUGIN_NAME = "discourse-update-status-card"
end

require_relative "lib/discourse_update_status_card/engine"
require_relative "lib/discourse_update_status_card/payload_reader"

after_initialize do
  require_relative "app/controllers/discourse_update_status_card/admin/status_controller"
end
