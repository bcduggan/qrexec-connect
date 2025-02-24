default:

.PHONY: install-connect-nfs \
	install-client \
	install-qrexec-connect \
	install-sd-units

install-client: install-qrexec-connect install-sd-units

install-connect-nfs: rpc/qubes.ConnectNFS.rpc rpc/qubes.ConnectNFS.config
	cp --preserve=mode rpc/qubes.ConnectNFS.rpc /etc/qubes-rpc/qubes.ConnectNFS
	cp --preserve=mode rpc/qubes.ConnectNFS.config /etc/qubes/rpc-config/qubes.ConnectNFS

/opt/bin/.:
	mkdir --parents $(@D)
	
install-qrexec-connect: qrexec-connect | /opt/bin/.
	cp --preserve=mode qrexec-connect /opt/bin/

install-sd-units: systemd-user/.
	cp --recursive --preserve=mode systemd-user/* /etc/systemd/user/

install-connectnfs: qubes-rpc/qubes.ConnectNFS rpc-config/qubes.ConnectNFS
	cp --preserve=mode qubes-rpc/qubes.ConnectNFS /etc/qubes-rpc/
	cp --preserve=mode rpc-config/qubes.ConnectNFS /etc/qubes/rpc-config/
