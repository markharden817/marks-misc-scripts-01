# Shutting down guest VMs​  
- Log into any CVM via SSH.
- Enter acli shell
`nutanix@CVM$ acli`
- List all VMs
`<acropolis> vm.list`
- Gracfully shutdown all VMs
`<acropolis> vm.shutdown *`
- Confirm that all VMs are powered off:
`<acropolis> vm.list power_state=on`
- Exit acli shell
`<acropolis> exit`

# Stopping the Nutanix Cluster
- Log into any CVM via SSH(if required)
`nutanix@CVM$ cluster stop`
- Confirm with `[y]` when prompted
- Wait to cluster to finish shutting down
	
# Shutting down the Controller VMs
- For each host in cluster
- SSH into Host
- List running vms 
`virsh list`
- Shutdown hosts CVM
`virsh shutdown <Controller VM name>`
		
# Shutting down each node in the cluster
- Log into the IPMI web console on each node.
- Under Remote Control > Power Control, select Power Off Server - Orderly Shutdown to gracefully shut down the node.