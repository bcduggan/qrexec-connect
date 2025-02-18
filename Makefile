.PHONY: install-client install-server install

QUBES_RPC_DIR = /etc/qubes-rpc
EXECUTABLE_DIR = /opt/bin
SD_UNIT_DIR = /etc/systemd/user

QUBES_RPCS = $(wildcard qubes-rpc/*)
EXECUTABLES = $(wildcard bin/*)
SD_UNIT_FILES = $(wildcard systemd-user/*)

TARGET_QUBES_RPCS = $(addprefix $(QUBES_RPC_DIR)/,$(notdir $(QUBES_RPCS)))
TARGET_EXECUTABLES = $(addprefix $(EXECUTABLE_DIR)/,$(notdir $(EXECUTABLES)))
TARGET_SD_UNIT_FILES = $(addprefix $(SD_UNIT_DIR)/,$(notdir $(SD_UNIT_FILES)))

default:

.PHONY: install install-rpcs install-executables install-sd-unit-files \
        uninstall uninstall-rpcs uninstall-executables uninstall-sd-unit-files

install: install-qubes-rpcs install-executables install-sd-unit-files

install-qubes-rpcs: $(TARGET_QUBES_RPCS)
install-executables: $(TARGET_EXECUTABLES)
install-sd-unit-files: $(TARGET_SD_UNIT_FILES)

$(QUBES_RPC_DIR)/$(notdir %): $(QUBES_RPCS)
	install --mode=0755 --target-directory=$(@D) qubes-rpc/$(@F)

$(EXECUTABLE_DIR)/$(notdir %): $(EXECUTABLES)
	install -D --mode=0755 --target-directory=$(@D) bin/$(@F)

$(SD_UNIT_DIR)/$(notdir %): $(SD_UNIT_FILES)
	install --mode=0644 --target-directory=$(@D) systemd-user/$(@F)
	systemctl --global enable $@

uninstall: uninstall-rpcs uninstall-executables uninstall-sd-unit-files

uninstall-rpcs:
	rm $(TARGET_QUBES_RPCS)

uninstall-executables:
	rm $(TARGET_EXECUTABLES)

uninstall-sd-unit-files:
	rm $(TARGET_SD_UNIT_FILES)
