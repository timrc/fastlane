require_relative 'analytics_ingester_client'
require_relative 'action_launch_context'
require_relative 'analytics_event_builder'

module FastlaneCore
  class AnalyticsSession
    GA_TRACKING = "UA-121171860-1"

    private_constant :GA_TRACKING
    attr_accessor :session_id
    attr_accessor :client

    def initialize(analytics_ingester_client: AnalyticsIngesterClient.new(GA_TRACKING))
      require 'securerandom'
      @session_id = SecureRandom.uuid
      @client = analytics_ingester_client
      @threads = []
      @launch_event_sent = false
    end

    def action_launched(launch_context: nil)
      unless did_show_message?
        show_message
      end

      if @launch_event_sent || launch_context.p_hash.nil?
        return
      end

      @launch_event_sent = true
      builder = AnalyticsEventBuilder.new(
        p_hash: launch_context.p_hash,
        session_id: session_id,
        action_name: nil
      )

      launch_event = builder.new_event(:launch)
      post_thread = client.post_event(launch_event)
      unless post_thread.nil?
        @threads << post_thread
      end
    end

    def action_completed(completion_context: nil)
    end

    def show_message
      UI.message("Sending anonymous analytics information")
      UI.message("Learn more at https://docs.fastlane.tools/#metrics")
      UI.message("No personal or sensitive data is sent.")
      UI.message("You can disable this by adding `opt_out_usage` at the top of your Fastfile")
    end

    def did_show_message?
      file_name = ".did_show_opt_info"

      new_path = File.join(FastlaneCore.fastlane_user_dir, file_name)
      did_show = File.exist?(new_path)

      return did_show if did_show

      File.write(new_path, '1')
      false
    end

    def finalize_session
      @threads.map(&:join)
    end
  end
end
