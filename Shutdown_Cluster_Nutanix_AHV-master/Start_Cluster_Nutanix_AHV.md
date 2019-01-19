# Powering on the nodes and cluster after a shutdown
- Log into the IPMI web console on each node.
- Under Remote Control > Power Control, select Power On Server

# Start the cluster
- All Controller VMs start automatically after the node powers on.  Wait approximately 5 minutes after the last node is powered on to allow services to begin.
- Log on to any one Controller VM in the cluster with SSH using Nutanix credentials.  
- Start the Nutanix cluster by issuing the following command: 
`nutanix@cvm$ cluster start`
- Confirm that the cluster services are running:
`nutanix@cvm$ cluster status`


# Power on Guest VMs
### via shell
- Log into any CVM via SSH.
- Enter acli shell
`<acropolis> acli`
- List all VMs
`<acropolis> vm.list`
- Power on VMs
`<acropolis> vm.on <VM Name>` or `<acropolis> vm.on *`
- Confirm that all VMs are powered on.
`<acropolis> vm.list power_state=on`

### via Prism
- Power on the guest VMs.  
From the Prism web console, navigate to Home > VM and select the Table view.  
- Confirm that all VMs are powered on.