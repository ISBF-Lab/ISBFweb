# frozen_string_literal: true

# name: isbf-account-switch
# about: Allows administrator-approved account links and device-authorized account switching.
# version: 0.1.0
# authors: ISBF Lab
# url: https://github.com/ISBF-Lab/ISBF-Account-Switch
# required_version: 3.2.0

enabled_site_setting :isbf_account_switch_enabled
add_admin_route "isbf_account_switch.admin.title", "isbf-account-switch", use_new_show_route: true

module ::IsbfAccountSwitch
  PLUGIN_NAME = "isbf-account-switch"
  DEVICE_COOKIE = "isbf_account_switch_device"
end

after_initialize do
  module ::IsbfAccountSwitch
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace IsbfAccountSwitch
    end
  end

  require_relative "app/models/isbf_account_switch/account_link"
  require_relative "app/models/isbf_account_switch/audit_event"
  require_relative "app/models/isbf_account_switch/device_grant"
  require_relative "app/services/isbf_account_switch/device_authorizer"
  require_relative "app/controllers/isbf_account_switch/accounts_controller"
  require_relative "app/controllers/isbf_account_switch/admin/links_controller"

  IsbfAccountSwitch::Engine.routes.draw do
    get "/accounts" => "accounts#index"
    post "/links" => "accounts#create"
    delete "/links/:id" => "accounts#revoke"
    post "/links/:id/verify" => "accounts#verify"
    post "/links/:id/switch" => "accounts#switch"
    delete "/device" => "accounts#revoke_device"

    namespace :admin do
      get "/links" => "links#index"
      put "/links/:id/approve" => "links#approve"
      put "/links/:id/reject" => "links#reject"
      put "/links/:id/revoke" => "links#revoke"
    end
  end

  Discourse::Application.routes.append do
    get "/admin/plugins/isbf-account-switch/links" => "admin/plugins#index",
        :constraints => AdminConstraint.new
    mount ::IsbfAccountSwitch::Engine, at: "/isbf/account-switch"
  end

  module ::IsbfAccountSwitch::SessionControllerExtension
    def destroy(...)
      if SiteSetting.isbf_account_switch_enabled
        IsbfAccountSwitch::DeviceAuthorizer.revoke_from_cookie!(
          cookies: cookies,
          actor: current_user,
          request: request,
        )
      end
      super
    end
  end

  SessionController.prepend(IsbfAccountSwitch::SessionControllerExtension)
end
