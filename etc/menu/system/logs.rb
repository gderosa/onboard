class OnBoard
  MENU_ROOT.add_path('/system/logs', {
    :href     => '/system/logs',
    :children => %r{^/system/logs/.+},
    :name     => 'Logs',
    :desc     => 'log files register what happened to the system',
    :n        => 0
  })
end
