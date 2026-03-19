# frozen_string_literal: true

DiscourseUpdateStatusCard::Engine.routes.draw do
  scope "/", defaults: { format: :json } do
    get "status" => "admin/status#show"
  end
end

Discourse::Application.routes.draw do
  mount DiscourseUpdateStatusCard::Engine, at: "/admin/plugins/discourse-update-status-card"
end
