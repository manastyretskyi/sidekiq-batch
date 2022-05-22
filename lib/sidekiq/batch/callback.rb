module Sidekiq
  class Batch
    module Callback
      class Worker
        include Sidekiq::Worker

        def perform(clazz, event, opts, bid, parent_bid)
          return unless %w(success complete).include?(event)
          clazz, method = clazz.split("#") if (clazz && clazz.class == String && clazz.include?("#"))
          method = "on_#{event}" if method.nil?
          status = Sidekiq::Batch::Status.new(bid)

          if clazz && object = Object.const_get(clazz)
            instance = object.new
            instance.send(method, status, opts) if instance.respond_to?(method)
          end
        end
      end

      class Finalize
        def dispatch status, opts
          bid = opts["bid"]
          callback_bid = status.bid
          event = opts["event"].to_sym
          callback_batch = bid != callback_bid

          Sidekiq.logger.debug {"Finalize #{event} batch id: #{opts["bid"]}, callback batch id: #{callback_bid} callback_batch #{callback_batch}"}

          batch_status = Status.new bid
          send(event, bid, batch_status, batch_status.parent_bid)

          # Different events are run in different callback batches
          Batch.new(callback_bid).cleanup! if callback_batch
          Batch.new(bid).cleanup! if event == :success
        end

        def success(bid, status, parent_bid)
          return unless parent_bid
          batch = Batch.new parent_bid

          # if job finished successfully and parent batch completed call parent complete callback
          # Success callback is called after complete callback
          if batch.successfull?
            Sidekiq.logger.debug {"Finalize parent complete bid: #{parent_bid}"}
            Batch.enqueue_callbacks(:complete, parent_bid)
          end

        end

        def complete(bid, status, parent_bid)
          children, success = Sidekiq.redis do |r|
            r.multi do |pipeline|
              pipeline.hincrby("BID-#{bid}", "children", 0)
              pipeline.scard("BID-#{bid}-success")
            end
          end

          batch = Batch.new bid
          pending = batch.jobs.count

          # if we batch was successful run success callback
          if batch.successfull?
            Batch.enqueue_callbacks(:success, bid)

          elsif parent_bid
            # if batch was not successfull check and see if its parent is complete
            # if the parent is complete we trigger the complete callback
            # We don't want to run this if the batch was successfull because the success
            # callback may add more jobs to the parent batch

            Sidekiq.logger.debug {"Finalize parent complete bid: #{parent_bid}"}
            batch = Batch.new parent_bid
  
            if batch.completed?
              Batch.enqueue_callbacks(:complete, parent_bid)
            end
          end
        end

        def cleanup_redis bid, callback_bid=nil
          Sidekiq::Batch.cleanup_redis bid
          Sidekiq::Batch.cleanup_redis callback_bid if callback_bid
        end
      end
    end
  end
end
