QUBES_RPC_DIR = qubes-rpc
EXECUTABLE_DIR = bin
SD_UNIT_DIR = systemd-user
EXAMPLE_DIR = sysemd-user-drop-in-examples

TARGET_QUBES_RPC_DIR = /etc/qubes-rpc
TARGET_EXECUTABLE_DIR = /opt/bin
TARGET_SD_UNIT_DIR = /etc/systemd/user

default:

.PHONY: install \
	install-rpcs \
	install-executables \
	install-sd-units \

install: install-qubes-rpcs install-executables install-sd-units

install-qubes-rpcs: $(addprefix $(TARGET_QUBES_RPC_DIR)/,$(notdir $(wildcard $(QUBES_RPC_DIR)/*)))
install-executables: $(addprefix $(TARGET_EXECUTABLE_DIR)/,$(notdir $(wildcard $(EXECUTABLE_DIR)/*)))
install-sd-units: $(addprefix $(TARGET_SD_UNIT_DIR)/,$(notdir $(wildcard $(SD_UNIT_DIR)/*)))

$(TARGET_QUBES_RPC_DIR)/%: $(QUBES_RPC_DIR)/*
	install --compare --mode=0755 $(QUBES_RPC_DIR)/$(@F) $(@D)

$(TARGET_EXECUTABLE_DIR)/.:
	mkdir --parents $(@D)
	
$(TARGET_EXECUTABLE_DIR)/%: $(EXECUTABLE_DIR)/* | $(TARGET_EXECUTABLE_DIR)/.
	install --compare --mode=0755 $(EXECUTABLE_DIR)/$(@F) $(@D)

$(TARGET_SD_UNIT_DIR)/%: $(SD_UNIT_DIR)/*
	install --compare --mode=0644 $(SD_UNIT_DIR)/$(@F) $(@D)
