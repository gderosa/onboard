require 'cronedit'

class OnBoard
  module Virtualization
    module QEMU
      class Snapshot
        module Schedule
          class << self

            def cronid(vmid)
              "qemu_snapshot_#{vmid}"
            end

            def manage(h)
              enable      = h[:http_params]['snapshot_schedule']['enable']
              begin
                drive_names = (
                  h[:http_params]['snapshot_schedule']['drives'].select do |k, v|
                    v and v != 0 and v != ''
                  end
                ).keys
              rescue NoMethodError
                drive_names = []
              end
              comma_separated_drive_names = drive_names.join(',')
              hour        = h[:http_params]['snapshot_schedule']['H']
              minute      = h[:http_params]['snapshot_schedule']['M']
              weekday     = h[:http_params]['snapshot_schedule']['w']
              dayofmonth  = h[:http_params]['snapshot_schedule']['d']

              delete_older_than_days =
h[:http_params]['snapshot_schedule']['delete_older_than_days']

              vmid      = h[:http_params]['vmid']            
              snapname  = "`date '+scheduled_\\%y\\%m\\%d_\\%H\\%M'`"
                  # Will be replaced by the shell at time of snapshotting.
                  # Cron comment sign '%' are escaped. 
                  # TODO: patch CronEdit to do such cron-escaping trasparently? 
              envstr    = "DELETE_SCHEDULED_OLDER_THAN=#{delete_older_than_days}d"
              exe       = "#{QEMU::BINDIR}/snapshot"

              cmd       = ''
              cmd       << envstr                             << ' '
              cmd       << "#{exe} take #{vmid} #{snapname}"  << ' '
              cmd       << comma_separated_drive_names                       

              if enable 
                CronEdit::Crontab.Add cronid(vmid), {
                  :minute   => minute,
                  :hour     => hour,
                  :day      => dayofmonth,
                  :weekday  => weekday,
                  :command  => cmd 
                } 
              else
                CronEdit::Crontab.Remove cronid(vmid)
              end
            end

            def get_entry(vmid)
              crontab_line = CronEdit::Crontab.List[cronid(vmid)]
              if crontab_line
                CronEdit::CronEntry.new CronEdit::Crontab.List[cronid(vmid)]
              end
            end

          end
        end
      end
    end
  end
end

