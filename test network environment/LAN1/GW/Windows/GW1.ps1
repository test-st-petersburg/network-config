# добавляем компоненты

Install-WindowsFeature DSC-Service
Install-WindowsFeature NPAS –IncludeManagementTools
Install-WindowsFeature Routing -IncludeManagementTools
Install-WindowsFeature RemoteAccess -IncludeAllSubFeature –IncludeManagementTools
Install-WindowsFeature SNMP-Service –IncludeManagementTools
Install-WindowsFeature DHCP –IncludeManagementTools

# устанавливаем имена для интерфейсов

Rename-NetAdapter -Name '' -NewName 'WAN'
Rename-NetAdapter -Name '' -NewName 'LAN1'

# удаляем ip адреса для возможности переконфигурирования роутера выполнением скрипта

Remove-NetIpAddress -InterfaceAlias WAN
Remove-NetIpAddress -InterfaceAlias LAN1

# присваиваем адреса

New-NetIpAddress -InterfaceAlias WAN -IpAddress '10.0.1.1' -PrefixLength 24 -DefaultGateway '10.0.1.100'
New-NetIpAddress -InterfaceAlias LAN1 -IpAddress '192.168.1.1' -PrefixLength 24

# отключаем файрволл

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# добавляем статические маршруты

# включаем маршрутизацию (пока без RRAS)

Set-NetIPInterface -InterfaceAlias WAN -Forwarding Enabled
Set-NetIPInterface -InterfaceAlias LAN1 -Forwarding Enabled

# настраиваем DHCP сервер

Set-DhcpServerv4Binding -InterfaceAlias WAN -BindingState $false
Set-DhcpServerv4Binding -InterfaceAlias LAN1 -BindingState $true

Add-DhcpServerv4Scope -Name LAN1 -StartRange 192.168.1.2 -EndRange 192.168.1.254 -SubnetMask 255.255.255.0 -LeaseDuration 1.0:0:0 -State Active
Set-DhcpServerv4OptionValue -ScopeId 192.168.1.0 -Router 192.168.1.1

# поднимаем NAT

netsh routing ip nat install
netsh routing ip nat add interface WAN mode=full
netsh routing ip nat add interface LAN1 mode=private

# настраиваем RAS

Install-RemoteAccess -VpnType VpnS2S

# поднимаем и настраиваем VPN сервер



