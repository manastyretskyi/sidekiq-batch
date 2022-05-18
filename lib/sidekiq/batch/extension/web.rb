# frozen_string_literal: true

require "sidekiq/web" unless defined?(Sidekiq::Web)

Sidekiq::Web.tabs["batches"] = "batches"

Sidekiq::Web.locales << File.expand_path("#{File.dirname(__FILE__)}/../web/locales")

Sidekiq::Web.register(Sidekiq::Batch::Web)
