
##### MyWay #####
{"virtio0"=>
  {"removable"=>false,
   "io-status"=>"ok",
   "file"=>"gluster://localhost/gv1a/QEMU/MyWay/MyWay.99-delta.qcow2",
   "backing_file"=>"MyWay.02-allvirtio.qcow2",
   "backing_file_depth"=>"3",
   "ro"=>false,
   "drv"=>"qcow2",
   "encrypted"=>false,
   "bps"=>"0",
   "bps_rd"=>"0",
   "bps_wr"=>"0",
   "iops"=>"0",
   "iops_rd"=>"0",
   "iops_wr"=>"0",
   "config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a98753a98
     @config=
      {"serial"=>"QMA23C301000",
       "media"=>"disk",
       "path"=>
        "[network]/gluster/localhost/gv1a/QEMU/MyWay/MyWay.99-delta.qcow2",
       "slot"=>"virtio0",
       "use_network_url"=>"on",
       "cache"=>"unsafe",
       "file"=>
        "/home/onboard/files/[network]/gluster/localhost/gv1a/QEMU/MyWay/MyWay.99-delta.qcow2",
       "if"=>"virtio",
       "index"=>0,
       "file_url"=>
        "gluster://localhost/gv1a/QEMU/MyWay/MyWay.99-delta.qcow2"}>,
   "img"=>
    {"image"=>
      "/home/onboard/files/[network]/gluster/localhost/gv1a/QEMU/MyWay/MyWay.99-delta.qcow2",
     "file_format"=>"qcow2",
     "virtual_size"=>"500G (536870912000 bytes)",
     "disk_size"=>"152G",
     "cluster_size"=>"65536",
     "backing_file"=>"MyWay.02-allvirtio.qcow2 (actual path",
     "snapshots"=>
      [#<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a98574628
        @data=
         {:id=>1,
          :tag=>"after_succesful_glusterization",
          :vmsize=>"1.3G",
          :time=>2013-07-05 00:09:38 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a985746a0
            @str="00:03:57.372">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a98573ca0
        @data=
         {:id=>6,
          :tag=>"disk_2013-08-03",
          :vmsize=>"0",
          :time=>2013-08-03 23:18:16 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a98573d40
            @str="00:00:00.000">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a98573318
        @data=
         {:id=>19,
          :tag=>"scheduled_131027_0420",
          :vmsize=>"11G",
          :time=>2013-10-27 04:23:34 +0100,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a98573390
            @str="2017:13:48.474">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a98572850
        @data=
         {:id=>20,
          :tag=>"scheduled_131103_0420",
          :vmsize=>"8.7G",
          :time=>2013-11-03 04:23:54 +0100,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a985728a0
            @str="2184:48:04.958">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a98571d60
        @data=
         {:id=>21,
          :tag=>"scheduled_131110_0420",
          :vmsize=>"10G",
          :time=>2013-11-10 04:24:00 +0100,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a98571e00
            @str="2352:26:10.843">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a986ce870
        @data=
         {:id=>22,
          :tag=>"scheduled_131117_0420",
          :vmsize=>"10G",
          :time=>2013-11-17 04:24:19 +0100,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a986ce910
            @str="116:29:02.906">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a986cdab0
        @data=
         {:id=>23,
          :tag=>"scheduled_131124_0420",
          :vmsize=>"11G",
          :time=>2013-11-24 04:24:26 +0100,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a986cdb28
            @str="284:05:37.533">}>]}},
 "ide1-cd0"=>
  {"file"=>nil,
   "removable"=>true,
   "locked"=>false,
   "tray-open"=>false,
   "io-status"=>"ok",
   "config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a986cd948
     @config=
      {"serial"=>"QMA23C301001",
       "file"=>nil,
       "media"=>"cdrom",
       "if"=>"ide",
       "bus"=>1,
       "unit"=>0}>,
   "img"=>{"snapshots"=>[]}},
 "floppy0"=>
  {"file"=>nil, "removable"=>true, "locked"=>false, "tray-open"=>false},
 "sd0"=>{"file"=>nil, "removable"=>true, "locked"=>false, "tray-open"=>false}}

##### Elastix #####
{"ide0-hd0"=>
  {"removable"=>false,
   "io-status"=>"ok",
   "file"=>"gluster://localhost/gv1a/QEMU/Elastix/Elastix.99-current.qcow2",
   "backing_file"=>"Elastix.01-201307052217.qcow2",
   "backing_file_depth"=>"2",
   "ro"=>false,
   "drv"=>"qcow2",
   "encrypted"=>false,
   "bps"=>"0",
   "bps_rd"=>"0",
   "bps_wr"=>"0",
   "iops"=>"0",
   "iops_rd"=>"0",
   "iops_wr"=>"0",
   "config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a984aa468
     @config=
      {"serial"=>"QMAF0DBCD000",
       "media"=>"disk",
       "path"=>
        "[network]/gluster/localhost/gv1a/QEMU/Elastix/Elastix.99-current.qcow2",
       "slot"=>"ide0-hd0",
       "use_network_url"=>"on",
       "cache"=>"unsafe",
       "file"=>
        "/home/onboard/files/[network]/gluster/localhost/gv1a/QEMU/Elastix/Elastix.99-current.qcow2",
       "if"=>"ide",
       "bus"=>0,
       "unit"=>0,
       "file_url"=>
        "gluster://localhost/gv1a/QEMU/Elastix/Elastix.99-current.qcow2"}>,
   "img"=>
    {"image"=>
      "/home/onboard/files/[network]/gluster/localhost/gv1a/QEMU/Elastix/Elastix.99-current.qcow2",
     "file_format"=>"qcow2",
     "virtual_size"=>"50G (53687091200 bytes)",
     "disk_size"=>"14G",
     "cluster_size"=>"65536",
     "backing_file"=>"Elastix.01-201307052217.qcow2 (actual path",
     "snapshots"=>
      [#<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a984a8690
        @data=
         {:id=>1,
          :tag=>"2013-07-25_1935",
          :vmsize=>"947M",
          :time=>2013-07-25 19:35:31 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a984a86e0
            @str="346:16:15.491">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a984a7f10
        @data=
         {:id=>2,
          :tag=>"disk_2013-08-03",
          :vmsize=>"0",
          :time=>2013-08-03 23:45:15 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a984a7f60
            @str="00:00:00.000">}>]}},
 "ide1-cd0"=>
  {"file"=>nil,
   "removable"=>true,
   "locked"=>false,
   "tray-open"=>false,
   "io-status"=>"ok",
   "config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a984afdf0
     @config=
      {"serial"=>"QMAF0DBCD001",
       "file"=>nil,
       "media"=>"cdrom",
       "if"=>"ide",
       "bus"=>1,
       "unit"=>0}>,
   "img"=>{"snapshots"=>[]}},
 "floppy0"=>
  {"file"=>nil, "removable"=>true, "locked"=>false, "tray-open"=>false},
 "sd0"=>{"file"=>nil, "removable"=>true, "locked"=>false, "tray-open"=>false}}

##### OpenErp-production #####
{"virtio0"=>
  {"removable"=>false,
   "io-status"=>"ok",
   "file"=>"gluster://localhost/gv1a/QEMU/OpenErp-production/99-curr.qcow2",
   "backing_file"=>"00-base.qcow2",
   "backing_file_depth"=>"1",
   "ro"=>false,
   "drv"=>"qcow2",
   "encrypted"=>false,
   "bps"=>"0",
   "bps_rd"=>"0",
   "bps_wr"=>"0",
   "iops"=>"0",
   "iops_rd"=>"0",
   "iops_wr"=>"0",
   "config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a981b52a8
     @config=
      {"serial"=>"QM8D8CCF7000",
       "media"=>"disk",
       "path"=>
        "[network]/gluster/localhost/gv1a/QEMU/OpenErp-production/99-curr.qcow2",
       "slot"=>"virtio0",
       "use_network_url"=>"on",
       "cache"=>"unsafe",
       "file"=>
        "/home/onboard/files/[network]/gluster/localhost/gv1a/QEMU/OpenErp-production/99-curr.qcow2",
       "if"=>"virtio",
       "index"=>0,
       "file_url"=>
        "gluster://localhost/gv1a/QEMU/OpenErp-production/99-curr.qcow2"}>,
   "img"=>
    {"image"=>
      "/home/onboard/files/[network]/gluster/localhost/gv1a/QEMU/OpenErp-production/99-curr.qcow2",
     "file_format"=>"qcow2",
     "virtual_size"=>"160G (171798691840 bytes)",
     "disk_size"=>"1.1G",
     "cluster_size"=>"65536",
     "backing_file"=>"00-base.qcow2 (actual path",
     "snapshots"=>
      [#<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a981b35e8
        @data=
         {:id=>1,
          :tag=>"disk_2013-08-03",
          :vmsize=>"0",
          :time=>2013-08-03 23:47:59 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a981b3638
            @str="00:00:00.000">}>]}},
 "ide1-cd0"=>
  {"file"=>nil,
   "removable"=>true,
   "locked"=>false,
   "tray-open"=>false,
   "io-status"=>"ok",
   "config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a981b34f8
     @config=
      {"serial"=>"QM8D8CCF7001",
       "file"=>nil,
       "media"=>"cdrom",
       "if"=>"ide",
       "bus"=>1,
       "unit"=>0}>,
   "img"=>{"snapshots"=>[]}},
 "floppy0"=>
  {"file"=>nil, "removable"=>true, "locked"=>false, "tray-open"=>false},
 "sd0"=>{"file"=>nil, "removable"=>true, "locked"=>false, "tray-open"=>false}}

##### Elastix-VIOSTOR #####
{"virtio0"=>
  {"config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a801e18c0
     @config=
      {"serial"=>"QM8404EA2000",
       "media"=>"disk",
       "path"=>
        "[network]/gluster/localhost/gv1a/QEMU/Elastix/Elastix.VirtIO.qcow2",
       "slot"=>"virtio0",
       "use_network_url"=>"on",
       "cache"=>"unsafe",
       "file"=>
        "/home/onboard/files/[network]/gluster/localhost/gv1a/QEMU/Elastix/Elastix.VirtIO.qcow2",
       "if"=>"virtio",
       "index"=>0,
       "file_url"=>
        "gluster://localhost/gv1a/QEMU/Elastix/Elastix.VirtIO.qcow2"}>,
   "img"=>
    {"image"=>
      "/home/onboard/files/[network]/gluster/localhost/gv1a/QEMU/Elastix/Elastix.VirtIO.qcow2",
     "file_format"=>"qcow2",
     "virtual_size"=>"80G (85899345920 bytes)",
     "disk_size"=>"9.6G",
     "cluster_size"=>"65536",
     "snapshots"=>
      [#<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a801dfcf0
        @data=
         {:id=>1,
          :tag=>"chroot",
          :vmsize=>"0",
          :time=>2013-07-17 11:18:13 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a801dfd40
            @str="00:15:05.359">}>]}},
 "ide0-hd0"=>
  {"config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a801dfbd8
     @config=
      {"serial"=>"QM8404EA2001",
       "media"=>"disk",
       "path"=>
        "[network]/gluster/localhost/gv1a/QEMU/Elastix/Elastix.01.VirtIO-201307121138.qcow2",
       "slot"=>"ide0-hd0",
       "cache"=>"writeback",
       "file"=>
        "/home/onboard/files/[network]/gluster/localhost/gv1a/QEMU/Elastix/Elastix.01.VirtIO-201307121138.qcow2",
       "if"=>"ide",
       "bus"=>0,
       "unit"=>0}>,
   "img"=>
    {"image"=>
      "/home/onboard/files/[network]/gluster/localhost/gv1a/QEMU/Elastix/Elastix.01.VirtIO-201307121138.qcow2",
     "file_format"=>"qcow2",
     "virtual_size"=>"50G (53687091200 bytes)",
     "disk_size"=>"5.5G",
     "cluster_size"=>"65536",
     "backing_file"=>"Elastix.01-201307052217.qcow2 (actual path",
     "snapshots"=>
      [#<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a801ec770
        @data=
         {:id=>1,
          :tag=>"chroot",
          :vmsize=>"341M",
          :time=>2013-07-17 11:18:13 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a801ec7c0
            @str="00:15:05.359">}>]}},
 "ide1-cd0"=>
  {"config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a801ec680
     @config=
      {"serial"=>"QM8404EA2002",
       "file"=>nil,
       "media"=>"cdrom",
       "if"=>"ide",
       "bus"=>1,
       "unit"=>0}>,
   "img"=>{"snapshots"=>[]}}}

##### SorrySAP #####
{"virtio0"=>
  {"removable"=>false,
   "io-status"=>"ok",
   "file"=>"/home/onboard/files/QEMU/OpenErp-next/OpenErp.qcow2",
   "ro"=>false,
   "drv"=>"qcow2",
   "encrypted"=>false,
   "bps"=>"0",
   "bps_rd"=>"0",
   "bps_wr"=>"0",
   "iops"=>"0",
   "iops_rd"=>"0",
   "iops_wr"=>"0",
   "config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a8028e4d0
     @config=
      {"serial"=>"QMAC744E5000",
       "media"=>"disk",
       "path"=>"QEMU/OpenErp-next/OpenErp.qcow2",
       "slot"=>"virtio0",
       "cache"=>"unsafe",
       "file"=>"/home/onboard/files/QEMU/OpenErp-next/OpenErp.qcow2",
       "if"=>"virtio",
       "index"=>0}>,
   "img"=>
    {"image"=>"/home/onboard/files/QEMU/OpenErp-next/OpenErp.qcow2",
     "file_format"=>"qcow2",
     "virtual_size"=>"100G (107374182400 bytes)",
     "disk_size"=>"40G",
     "cluster_size"=>"65536",
     "snapshots"=>
      [#<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a8028ca68
        @data=
         {:id=>2,
          :tag=>"test",
          :vmsize=>"1.0G",
          :time=>2013-01-28 18:34:54 +0100,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a8028cab8
            @str="1184:16:16.486">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a8029a8c0
        @data=
         {:id=>18,
          :tag=>"scheduled_130512_2142",
          :vmsize=>"679M",
          :time=>2013-05-12 21:42:34 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a8029a910
            @str="1218:25:15.259">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a8029a168
        @data=
         {:id=>21,
          :tag=>"scheduled_130602_2142",
          :vmsize=>"0",
          :time=>2013-06-02 21:42:02 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a8029a1b8
            @str="00:00:00.000">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a80299a10
        @data=
         {:id=>22,
          :tag=>"scheduled_130609_2142",
          :vmsize=>"0",
          :time=>2013-06-09 21:42:33 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a80299a60
            @str="00:00:00.000">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a802992b8
        @data=
         {:id=>23,
          :tag=>"before_migration",
          :vmsize=>"0",
          :time=>2013-06-24 09:55:33 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a80299308
            @str="00:00:00.000">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a80298b60
        @data=
         {:id=>24,
          :tag=>"Openerp_preinstall",
          :vmsize=>"756M",
          :time=>2013-07-12 20:44:33 +0200,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a80298bb0
            @str="04:11:29.141">}>]}},
 "ide1-cd0"=>
  {"file"=>nil,
   "removable"=>true,
   "locked"=>false,
   "tray-open"=>false,
   "io-status"=>"ok",
   "config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a80298a70
     @config=
      {"serial"=>"QMAC744E5001",
       "file"=>nil,
       "media"=>"cdrom",
       "if"=>"ide",
       "bus"=>1,
       "unit"=>0}>,
   "img"=>{"snapshots"=>[]}},
 "floppy0"=>
  {"file"=>nil, "removable"=>true, "locked"=>false, "tray-open"=>false},
 "sd0"=>{"file"=>nil, "removable"=>true, "locked"=>false, "tray-open"=>false}}

##### DebianFormazione #####
{"virtio0"=>
  {"config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a80330578
     @config=
      {"serial"=>"QM74713C3000",
       "media"=>"disk",
       "path"=>"QEMU/DebianFormazione/disk0.qcow2",
       "slot"=>"virtio0",
       "cache"=>"unsafe",
       "file"=>"/home/onboard/files/QEMU/DebianFormazione/disk0.qcow2",
       "if"=>"virtio",
       "index"=>0}>,
   "img"=>
    {"image"=>"/home/onboard/files/QEMU/DebianFormazione/disk0.qcow2",
     "file_format"=>"qcow2",
     "virtual_size"=>"100G (107374182400 bytes)",
     "disk_size"=>"7.3G",
     "cluster_size"=>"65536",
     "snapshots"=>
      [#<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a80340540
        @data=
         {:id=>1,
          :tag=>"DebClean",
          :vmsize=>"981M",
          :time=>2013-10-28 14:33:33 +0100,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a80340590
            @str="01:40:02.316">}>,
       #<OnBoard::Virtualization::QEMU::Snapshot:0x007f9a8033fd70
        @data=
         {:id=>2,
          :tag=>"MoodleManuale",
          :vmsize=>"975M",
          :time=>2013-10-29 15:01:40 +0100,
          :vmclock=>
           #<OnBoard::Virtualization::QEMU::Snapshot::VMClock:0x007f9a8033fde8
            @str="26:08:04.912">}>]}},
 "ide1-cd0"=>
  {"config"=>
    #<OnBoard::Virtualization::QEMU::Config::Drive:0x007f9a8033fc58
     @config=
      {"serial"=>"QM74713C3001",
       "file"=>nil,
       "media"=>"cdrom",
       "if"=>"ide",
       "bus"=>1,
       "unit"=>0}>,
   "img"=>{"snapshots"=>[]}}}
