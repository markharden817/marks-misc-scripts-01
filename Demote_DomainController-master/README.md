
Tech Support will be demoting and retiring the old <$Site> Domain Controllers. These are redundant and this can be done during the day without impact to end users.

# Preperation
1. Configure <$Site>PNDMCTL01 as site bridgehead
1. Remove WINS servers from all DHCP scope options.
1. Set <$Site>PNMSADC02 & <$Site>NMSADC02 to unmanaged in Solarwinds.

# Demote DC02
1. Run dcpromo to demote <$Site>PNMSADC02
1. Wait 10 minutes
1. Remove Static IP address
1. Shut down <$Site>PNMSADC02 - mark for retirement
1. Configure VIP (<$DC2_IP>) on <$Site>PNNGXLB01/02 to proxy remaining DNS/NTP/LDAP/LDAPS traffic to <$Site>PNDMCTL01/02
1. Validate

# Demote DC01
1. Run dcpromo to demote <$Site>PNMSADC01
1. Wait 10 minutes
1. Remove Static IP address
1. Shut down <$Site>PNMSADC01 - mark for retirement
1. Configure VIP (<$DC1_IP>) on <$Site>PNNGXLB01/02 to proxy remaining DNS/NTP/LDAP/LDAPS traffic to <$Site>PNDMCTL01/02
1. Validate

# Cleanup
1. Remove Servers from Sites and Services
1. Remove Servers from DNS forwarders list. 
  * Run Cleanup-OldDC_NS_Records.ps1
1. Instruct office staff to unplug server and label as retired.