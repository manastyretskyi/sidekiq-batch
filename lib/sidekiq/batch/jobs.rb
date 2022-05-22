module Sidekiq
  class Batch
    class Jobs
      include Enumerable
  
      attr_reader :bid

      def initialize(bid)
        @bid = bid
        @bidkey = "BID:JOBS-" + @bid.to_s
      end

      def <<(jid)
        Sidekiq.redis do |r|
          r.sadd(@bidkey, jid)
        end
      end

      def each(&block)
        Sidekiq.redis do |r|
          r.smembers(@bidkey)
        end.each(&block)

        Sidekiq.redis do |r|
          r.smembers(@bidkey + "-failed")
        end.each(&block)
      end

      def pending
        Sidekiq.redis do |r|
          r.smembers(@bidkey )
        end
      end

      def failed
        Sidekiq.redis do |r|
          r.smembers(@bidkey + "-failed")
        end
      end

      def completed
        Sidekiq.redis do |r|
          r.smembers(@bidkey + "-completed")
        end
      end

      def fail!(jid)
        Sidekiq.redis do |r|
          r.multi do |pipeline|
            r.srem(@bidkey, jid)
            r.sadd(@bidkey + "-failed", jid)
          end
        end
      end

      def complete!(jid)
        Sidekiq.redis do |r|
          r.srem(@bidkey, jid) || r.srem(@bidkey + "-failed", jid).tap do |removed|
            r.sadd(@bidkey + "-compled", jid) if removed
          end
        end
      end

      def cleanup!
        Sidekiq.redis do |r|
          r.del(
            @bidkey,
            "#{@bidkey}-completed",
            "#{@bidkey}-failed",
          )
        end
      end
    end
  end
end
