# frozen_string_literal: true

module ::DiscourseUpdateStatusCard
  module Admin
    class StatusController < ::Admin::AdminController
      requires_plugin DiscourseUpdateStatusCard::PLUGIN_NAME

      def show
        response.headers["Cache-Control"] = "no-store"
        render json: DiscourseUpdateStatusCard::PayloadReader.read
      end
    end
  end
end
