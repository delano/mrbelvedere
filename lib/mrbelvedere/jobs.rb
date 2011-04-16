Thread.abort_on_exception = true

require 'bluth'

module ScheduledTasks
  include Familia
  
  class << self
    attr_accessor :worker
  end
  
  on_the_minute = MrBelvedere.time_at_the_next(1.minute)
  on_the_5minute = MrBelvedere.time_at_the_next(5.minutes)
  on_the_10minute = MrBelvedere.time_at_the_next(10.minutes)
  on_the_hour = MrBelvedere.time_at_the_next(1.hour)
  on_the_halfhour = on_the_hour + 30.minutes
  on_the_midnight = MrBelvedere.time_at_the_next(24.hours)
  
  # This is executed only by a Bluth::ScheduleWorker#run
  Bluth::ScheduleWorker.onstart do
    ScheduledTasks.worker = self
    Familia.info "Scheduled start times:"
    [on_the_minute, on_the_5minute, on_the_10minute, on_the_hour, on_the_midnight].each do |t|
      from_now = (t.to_i-Familia.now.to_i).in_minutes
      Familia.info "  #{t} (#{from_now}m from now)"
    end
    Familia.info "Startup complete."
  end
  
  Bluth::ScheduleWorker.onexit do
  end
  
  
  Bluth::ScheduleWorker.every 10.seconds, :tags => [:mrbelvedere, :weekly], :first_in => '2s' do |task|
    carefully do
      p MrB::Session.all.size
      p Bluth.uri
    end
  end
  
  def ScheduledTasks.carefully(&logic)
    ret, msg = nil, nil
    begin
      ret = instance_eval &logic
      
    rescue Rufus::Scheduler::TimeOutError => ex
      msg = "Timeout: #{ex.message} (#{ex.class})"
      BS.info msg
      
    rescue Errno::ECONNREFUSED => ex
      unless Bluth::Worker.reconnect! :scheduler
        msg = "Scheduler: #{ex.message} (reconnect failed)"
      end
    rescue => ex
      msg = "Scheduler: #{ex.message} (#{ex.class})"
      Familia.info msg
      Familia.info ex.backtrace
    end
    ret
  end
end