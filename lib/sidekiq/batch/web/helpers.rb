# frozen_string_literal: true

module Sidekiq
  class Batch
    module Web
      module Helpers
        module_function

        VIEW_PATH = File.expand_path("../web/views", __dir__).freeze

        def unique_template(name)
          File.read(unique_filename(name))
        end

        def unique_filename(name)
          File.join(VIEW_PATH, "#{name}.erb")
        end
      end
    end
  end
end
