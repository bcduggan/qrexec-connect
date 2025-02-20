default:

.PHONY: install-server \
	install-client \
	install-rpcs \
	install-qrexec-systemd-socket-activate \
	install-sd-units

install-server:	install-qubes-rpcs

install-client: install-qrexec-systemd-socket-activate install-sd-units

install-qubes-rpcs: qubes-rpc/.
	cp --preserve=mode $(QUBES_RPC_DIR)/* /etc/qubes-rpc/

/opt/bin:
	mkdir --parents $(@D)
	
install-qrexec-systemd-socket-activate: qrexec-systemd-socket-activate | /opt/bin/.
	cp --preserve=mode qrexec-systemd-socket-activate /opt/bin/

install-sd-units: systemd-user/.
	cp --preserve=mode systemd-user/* /etc/systemd/user/
