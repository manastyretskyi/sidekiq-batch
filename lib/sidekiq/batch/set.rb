require "redis/prescription"

module Sidekiq
  class Batch
    class Set
      def initialize
        @script = File.read("#{__dir__}/scripts/set.lua")
        @lua_script_sha = nil
      end

      def all
        Sidekiq.redis do |conn|
          set_script_sha(conn)
          conn.call("EVALSHA", @lua_script_sha, 0)
        end
      end

      private

      def set_script_sha(conn)
        @lua_script_sha ||= conn.script(:load, @script)
      end
    end
  end
end
