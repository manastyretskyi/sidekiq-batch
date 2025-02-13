# frozen_string_literal: true

require "tilt/erb"

require "sidekiq/batch"
require_relative "web/helpers"

module Sidekiq
  class Batch
    module Web
      def self.registered(app) # rubocop:disable Metrics/AbcSize
        app.helpers do
          include Web::Helpers
        end

        app.get "/batches" do
          @batches = Set.new.all
          @total_size = @batches.size
          @count = (params["count"] || 25).to_i
          @current_page = params["page"].to_i == 0 ? 1 : params["page"].to_i
          range = ((@current_page - 1) * @count)..((@current_page -1) * @count) + @count
          @batches = @batches[range].to_a.map(&Batch.method(:new))

          erb Helpers.unique_template(:batches)
        end

        app.post "/batches" do
          case
          when !!params['delete']
            @batches = Set.new.all
            @batches = @batches.map(&Batch.method(:new))
            @batches.map(&:cleanup!)
          else
          end

          redirect "#{root_path}batches"
        end

        app.get "/batches/:id" do
          @batch = Batch.new(route_params[:id])
          @status = Batch::Status.new(@batch.bid)

          erb Helpers.unique_template(:batch)
        end

        app.post "/batches/:id" do
          @batch = Batch.new(route_params[:id])
          case
          when !!params['delete']
            @batch.cleanup!
          else
          end

          redirect "#{root_path}batches"
        end
      end
    end
  end
end

require_relative "extension/web"
