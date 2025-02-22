# qrexec-connect

_It's like qrexec-client-vm, but systemd-socket-activated._

qrexec-connect is a systemd-native service for qrexec network connections.
Enable a new qrexec connection with a single systemd socket unit file. Manage
and monitor connection services on client qubes with `systemctl`.

For example, to forward TCP connections to 127.0.0.1:1234 on a client qube
to the same port on the @default service qube (as defined in Qubes policy),
create a new socket unit file with a `qrexec-connect-` prefix: 

```ini
# /home/user/.config/systemd/user/qrexec-connect-gitweb.socket
[Socket]
# Arbitrary IP address port on the service qube:
ListenStream=127.0.0.1:1234
# Arguments you would use with qrexec-client-vm:
FileDescriptorName=@default qubes.ConnectTCP+1234
```

To forward connections to 127.0.0.2:2345 on the client qube to gitweb on a
service named `work`:

```ini
# /home/user/.config/systemd/user/qrexec-connect-gitweb-work.socket
[Socket]
ListenStream=127.0.0.1:2345
FileDescriptorName=work qubes.ConnectTCP:1234
```

## Motivation

To [permanently bind a port between two qubes with
`qrexec-client-vm`](https://www.qubes-os.org/doc/firewall/#opening-a-single-tcp-port-to-other-network-isolated-qube),
users have to create a new pair of .socket and .service unit files for each
port. This requires the user to duplicate a lot of content for each port. Since
`qrexec-client-vm` only communicates through stdio, the corresponding socket
unit must set the `Accept` directive to `true`. Systemd starts a new instance
of the `qrexec-client-vm` service for each new connection, which generates a
some noise in the service status.

I wanted a more ergonomic, systemd-native way to permanently bind ports between
qubes client and service qubes. `qrexec-connect` runs as a single,
socket-activated systemd service for all port bindings, avoiding service
instance proliferation. It accepts new connections by itself so users can apply
multiple socket unit files to the single `qrexec-connect` service. It includes
drop-ins that apply to all socket units named with a `qrexec-connect-` prefix
to set default directives to all port-binding socket units. Together, this
minimizes the amount of configuration users have to generate for each new port
binding to a new file with three lines.
