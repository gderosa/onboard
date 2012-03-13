require 'cronedit'

class OnBoard
  module Virtualization
    module QEMU
      class Snapshot
        module Schedule
          class << self

            def manage(h)
              enable      = h[:http_params]['snapshot_schedule']['enable']
              drive_names = (
                  h[:http_params]['snapshot_schedule']['drives'].select do |k, v|
                    v and v != 0 and v != ''
                  end
              ).keys
              comma_separated_drive_names = drive_names.join(',')
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
"#{QEMU::BINDIR}/snapshot take #{vmid} `date '+scheduled_\\%y\\%m\\%d_\\%H\\%M'` #{comma_separated_drive_names}" 
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

