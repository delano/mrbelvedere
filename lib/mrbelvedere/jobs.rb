# Thread.abort_on_exception = true
# 
# require 'bluth'
# 
# module ScheduledTasks
#   include Familia
#   
#   # This is executed only by a Bluth::ScheduleWorker#run
#   Bluth::ScheduleWorker.onstart do
#   end
#   
#   Bluth::ScheduleWorker.onexit do
#   end
#   
#   
#   Bluth::ScheduleWorker.every 1.hour, :tags => [:mrbelvedere, :weekly], :first_in => '2s' do |task|
#     carefully do
#       MrB.instances.each do |mrb|
#         Familia.info "Mr B processing: #{mrb.index}"
#       end
#     end
#   end
#   
#   def ScheduledTasks.carefully(&logic)
#     ret, msg = nil, nil
#     begin
#       ret = instance_eval &logic
#       
#     rescue Rufus::Scheduler::TimeOutError => ex
#       msg = "Timeout: #{ex.message} (#{ex.class})"
#       BS.info msg
#       
#     rescue Errno::ECONNREFUSED => ex
#       unless Bluth::Worker.reconnect! :scheduler
#         msg = "Scheduler: #{ex.message} (reconnect failed)"
#       end
#     rescue => ex
#       msg = "Scheduler: #{ex.message} (#{ex.class})"
#       Familia.info msg
#       Familia.info ex.backtrace
#     end
#     ret
#   end
# end