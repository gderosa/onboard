require 'cronedit'

class OnBoard
  module Virtualization
    module QEMU
      class Snapshot
        module Schedule
          class << self

            def manage(h)
              enable      = h[:http_params]['snapshot_schedule']['enable']
              drives      = h[:http_params]['snapshot_schedule']['drives']
              hour        = h[:http_params]['snapshot_schedule']['H']
              minute      = h[:http_params]['snapshot_schedule']['M']
              weekday     = h[:http_params]['snapshot_schedule']['w']
              dayofmonth  = h[:http_params]['snapshot_schedule']['d']

              delete_older_than_days =
h[:http_params]['snapshot_schedule']['delete_older_than_days']

              vmid    = h[:http_params]['vmid']            
              cronid  = "qemu_snapshot_#{vmid}"

              if enable
                CronEdit::Crontab.Add cronid, {
                  :minute   => minute,
                  :hour     => hour,
                  :day      => dayofmonth,
                  :weekday  => weekday,
                  :command  => 
"#{QEMU::BINDIR}/snapshot take #{vmid} `date '+scheduled_\\%y\\%m\\%d_\\%H\\%M'`" 
                      # escape cron comment sign '%' 
                      # TODO: patch CronEdit to do this trasparently?
                } 
              else
                CronEdit::Crontab.Remove cronid
              end
            end

          end
        end
      end
    end
  end
end

