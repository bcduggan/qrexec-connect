default:

.PHONY: install-server \
	install-client \
	install-rpcs \
	install-qrexec-connect \
	install-sd-units

install-server:	install-qubes-rpcs

install-client: install-qrexec-connect install-sd-units

install-qubes-rpcs: qubes-rpc/.
	cp --preserve=mode qubes-rpc/* /etc/qubes-rpc/
	cp --preserve=mode rpc-config/* /etc/qubes/rpc-config/

/opt/bin/.:
	mkdir --parents $(@D)
	
install-qrexec-connect: qrexec-connect | /opt/bin/.
	cp --preserve=mode qrexec-connect /opt/bin/

install-sd-units: systemd-user/.
	cp --recursive --preserve=mode systemd-user/* /etc/systemd/user/
