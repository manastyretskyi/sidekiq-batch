require "redis/prescription"

module Sidekiq
  class Batch
    module Set
      module_function

      SCRIPT = Redis::Prescription.read "#{__dir__}/scripts/set.lua"
      private_constant :SCRIPT

      def all
        Sidekiq.redis do |redis|
          SCRIPT.eval(redis)
        end
      end
    end
  end
end
