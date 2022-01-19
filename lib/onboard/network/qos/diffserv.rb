# encoding: utf-8

class OnBoard
  module Network
    module QoS

      module DiffServ

        BE = BestEffort = 0b000000  # Default

        Reliability     = 0b000001  # Old RFC791
        Throughput      = 0b000010  # Old RFC791
        LowDelay        = 0b000100  # Old RFC791

        CS1             = 0b001000  # Low precedence in RFC791 / "Scavenger"
        AF11            = 0b001010  # Assured Forwarding class 1, low drop
        AF12            = 0b001100  # Assured Forwarding class 1, medium drop
        AF13            = 0b001110  # Assured Forwarding class 1, high drop

        CS2             = 0b010000  # Medium-low precedence in RFC791
        AF21            = 0b010010  # Assured Forwarding class 2, low drop
        AF22            = 0b010100  # Assured Forwarding class 2, medium drop
        AF23            = 0b010110  # Assured Forwarding class 2, high drop

        CS3             = 0b011000  # Medium-high precedence in RFC791
        AF31            = 0b011010  # Assured Forwarding class 3, low drop    # VoIP:SIP
        AF32            = 0b011100  # Assured Forwarding class 3, medium drop
        AF33            = 0b011110  # Assured Forwarding class 3, high drop

        CS4             = 0b100000  # High precedence in RFC791
        AF41            = 0b100010  # Assured Forwarding class 4, low drop
        AF42            = 0b100100  # Assured Forwarding class 4, medium drop
        AF43            = 0b100110  # Assured Forwarding class 4, high drop

        CS5             = 0b101000  # Cisco "Critical"
        CS6             = 0b110000  # Cisco routing/internetworking
        CS7             = 0b111000  # Cisco "Network Control"

        VOICE_ADMIT     = 0b101100  # RFC5865

        EF = ExpeditedForwarding \
                        = 0b101110  # Expedited Forwarding!                   # VoIP:voice



        # An Array because there's a preferred/logical order

        CodePoints = [
          {
            :value        => BE,
            :short_name   => 'BE',
            :long_name    => 'Best Effort',
            :symbol       => :BE,
            :comment      => 'Default'
          },

          {
            :value        => Reliability,
            :short_name   => 'Reliability',
            :long_name    => 'Maximize reliability',
            :symbol       => :reliability,
            :comment      => 'Old RFC791'
          },
          {
            :value        => Throughput,
            :short_name   => 'Throughput',
            :long_name    => 'Maximize throughput',
            :symbol       => :throughput,
            :comment      => 'Old RFC791'
          },
          {
            :value        => LowDelay,
            :short_name   => 'Low delay',
            :long_name    => 'Low delay',
            :symbol       => :lowdelay,
            :comment      => 'Old RFC791'
          },

          {
            :value        => CS1,
            :short_name   => 'CS1',
            :long_name    => 'Class Selector 1',
            :symbol       => :CS1,
            :comment      => 'Low precedence in RFC791 / “Scavenger”'
          },
          {
            :value        => AF11,
            :short_name   => 'AF11',
            :long_name    => 'Assured Forwarding class 1, low drop',
            :symbol       => :AF11,
          },
          {
            :value        => AF12,
            :short_name   => 'AF12',
            :long_name    => 'Assured Forwarding class 1, medium drop',
            :symbol       => :AF12,
          },
          {
            :value        => AF13,
            :short_name   => 'AF13',
            :long_name    => 'Assured Forwarding class 1, high drop',
            :symbol       => :AF13,
          },

          {
            :value        => CS2,
            :short_name   => 'CS2',
            :long_name    => 'Class Selector 2',
            :symbol       => :CS2,
            :comment      => 'Medium-low precedence in RFC791'
          },
          {
            :value        => AF21,
            :short_name   => 'AF21',
            :long_name    => 'Assured Forwarding class 2, low drop',
            :symbol       => :AF21,
          },
          {
            :value        => AF22,
            :short_name   => 'AF22',
            :long_name    => 'Assured Forwarding class 2, medium drop',
            :symbol       => :AF22,
          },
          {
            :value        => AF23,
            :short_name   => 'AF23',
            :long_name    => 'Assured Forwarding class 2, high drop',
            :symbol       => :AF23,
          },

          {
            :value        => CS3,
            :short_name   => 'CS3',
            :long_name    => 'Class Selector 3',
            :symbol       => :CS3,
            :comment      => 'Medium-high precedence in RFC791'
          },
          {
            :value        => AF31,
            :short_name   => 'AF31',
            :long_name    => 'Assured Forwarding class 3, low drop',
            :symbol       => :AF31,
            :comment      => 'Recommended for VoIP: signaling'
          },
          {
            :value        => AF32,
            :short_name   => 'AF32',
            :long_name    => 'Assured Forwarding class 3, medium drop',
            :symbol       => :AF32,
          },
          {
            :value        => AF33,
            :short_name   => 'AF33',
            :long_name    => 'Assured Forwarding class 3, high drop',
            :symbol       => :AF33,
          },

          {
            :value        => CS4,
            :short_name   => 'CS4',
            :long_name    => 'Class Selector 4',
            :symbol       => :CS4,
            :comment      => 'High precedence in RFC791'
          },
          {
            :value        => AF41,
            :short_name   => 'AF41',
            :long_name    => 'Assured Forwarding class 4, low drop',
            :symbol       => :AF41,
            :comment      => 'Recommended for video conferencing, etc.'
          },
          {
            :value        => AF42,
            :short_name   => 'AF42',
            :long_name    => 'Assured Forwarding class 4, medium drop',
            :symbol       => :AF42,
          },
          {
            :value        => AF43,
            :short_name   => 'AF43',
            :long_name    => 'Assured Forwarding class 4, high drop',
            :symbol       => :AF43,
          },

          {
            :value        => CS5,
            :short_name   => 'CS5',
            :long_name    => 'Class Selector 5',
            :symbol       => :CS5,
            :comment      => 'Cisco “critical”'
          },
          {
            :value        => CS6,
            :short_name   => 'CS6',
            :long_name    => 'Class Selector 6',
            :symbol       => :CS6,
            :comment      => 'Cisco internetworking/routing'
          },
          {
            :value        => CS7,
            :short_name   => 'CS7',
            :long_name    => 'Class Selector 7',
            :symbol       => :CS7,
            :comment      => 'Cisco “network control”'
          },

          {
            :value        => VOICE_ADMIT,
            :short_name   => 'VOICE-ADMIT',
            :long_name    => 'Capacity-Admitted Traffic',
            :symbol       => :"VOICE-ADMIT",
            :comment      => 'Capacity-Admitted Traffic, RFC5865'
          },
          {
            :value        => EF,
            :short_name   => 'EF',
            :long_name    => 'Expedited Forwarding',
            :symbol       => :EF,
            :comment      => 'Highest priority, recommended for VoIP: voice'
          }
        ]
      end # module DiffServ

      DSCP = DiffServ::CodePoints

    end # module QoS

  end
end
