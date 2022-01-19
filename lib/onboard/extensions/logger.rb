class Logger
  # Log information about an Exception which is believed to be
  # safely handled
  def handled_error(e)
    info %Q{(handled): #{caller.first}: #{e.class}: #{e.message}}
  end
end

