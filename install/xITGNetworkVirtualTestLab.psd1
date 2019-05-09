#Requires -Version 5.0
#Requires -Modules Lability

@{

    AllNodes = @(
        @{
            NodeName = '*'
            StartupMemory = 256MB
            MinimumMemory = 256MB
            MaximumMemory = 256MB
			ProcessorCount = 1
			Media = 'RouterOS'
			Generation = 1
			SecureBoot = $false

			# Lab Password - assigned to Administrator and Users
            # LabPassword = 'P@ssw0rd'
        }

        @{
            NodeName = 'WAN'
            SwitchName = 'WAN1', 'WAN2'
            BootOrder = 1
        }

        @{
            NodeName = 'GW1'
            SwitchName = 'LAN1', 'WAN1'
            BootOrder = 2
			BootDelay = 60
		}
        @{
            NodeName = 'WS1'
            SwitchName = 'LAN1'
            BootOrder = 3
        }

        @{
            NodeName = 'GW2'
            SwitchName = 'LAN2', 'WAN2'
            BootOrder = 2
			BootDelay = 60
        }
        @{
            NodeName = 'WS2'
            SwitchName = 'LAN2'
            BootOrder = 3
        }
    )

    NonNodeData = @{
        Lability = @{
			EnvironmentPrefix = 'test-net-config-' # this will prefix the VM names

            Media = (
                @{
					Id = 'RouterOS'
                    ImageName = 'RouterOS cloud hosted router'
                    Description = 'RouterOS cloud hosted router'
					MediaType = 'VHD'
					Architecture = 'x64'
                    OperatingSystem = 'Linux'
					Filename = 'RouterOS.vhdx'
					Uri = 'http://download2.mikrotik.com/routeros/6.44.3/chr-6.44.3.vhdx'
					# 'https://download.mikrotik.com/' требует дополнительных заголовков
                }
            )

            Network = @(
                @{
                    Name = 'WAN1'
                    Type = 'Private'
                },
                @{
                    Name = 'LAN1'
                    Type = 'Private'
                },
                @{
                    Name = 'WAN2'
                    Type = 'Private'
                },
                @{
                    Name = 'LAN2'
                    Type = 'Private'
                }
            )

            DSCResource = @(
                @{ Name = 'xPSDesiredStateConfiguration'; RequiredVersion = '5.0.0.0'; },
                @{ Name = 'xComputerManagement'; RequiredVersion = '1.8.0.0'; Provider = 'PSGallery'; },
                @{ Name = 'xNetworking'; RequiredVersion = '3.0.0.0'; Provider = 'PSGallery'; }
                #@{ Name = 'xDhcpServer'; RequiredVersion = '1.5.0.0'; Provider = 'PSGallery';  }
                #@{ Name = 'xPendingReboot'; RequiredVersion = '0.3.0.0'; }
            )

			Resource = @(
            )
        }
    }

}
