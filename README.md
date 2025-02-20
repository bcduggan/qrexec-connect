# qrexec-systemd-socket-activate

_It's like qrexec-client-vm, but systemd-socket-activated._

Enable systemd-managed qrexec network connections as systemd service instances.
For example, to forward TCP connections to localhost port 1234 on a client qube
to the same port on a service qube named "gitweb", create a drop-in file for an
instance of the `qrexec-connect-tcp@.socket` unit on the client:

```ini
# /home/user/.config/systemd/user/qrexec-connect-tcp@1234.socket.d/gitweb.conf
[Socket]
ListenStream=127.0.0.1:1234
FileDescriptorName=gitweb
```

To forward connections to 127.0.0.2:1234 on the same client qube to a service
qube named `work`:

```ini
# /home/user/.config/systemd/user/qrexec-connect-tcp@1234.socket.d/work.conf
[Socket]
ListenStream=127.0.0.2:1234
FileDescriptorName=work
```

Implement the classic Split-SSH by symlinking the SSH socket to a filename that
doesn't use forbidden qrexec RPC argument characters on the service qube:

```ini
# service qube
# /home/user/.config/systemd/user/gpg-agent-ssh.socket.d/qubes.ConnectUnix.conf
[Socket]
Symlinks=%t/qubes.ConnectUnix/gpg-agent-ssh
```

And a corresponding instance drop-in on the client qube:

```ini
# /home/user/.config/systemd/user/qrexec-connect-unix@gpg-agent-ssh.socket.d/@default.conf
[Socket]
ListenStream=%t/qrexec-connect-unix/S.gpg-agent.ssh
FileDescriptorName=@default
```

With `qrexec-systemd-socket-activate`, each systemd service prefix (the part
before the `@`) maps to a single Qubes RPC on a service qube:

- qrexec-connect-tcp: qubes.ConnectTCP
- qrexec-connect-unix: qubes.ConnectUnix (provided in this repository)
- qrexec-connect-tcp-bind: qubes.ConnectTCPBind (provided in this repository)

The RPC argument is the service instance name, the part between the `@` and the
suffix, `.socket`. For example, the RPC argument in the gitweb example is
`1234`.

And the target qube is the value of `FileDescriptorName` in the instance drop-in.

## Motivation

Users have to create a new pair of .socket and .service unit files for each
service they want to expose through `qvm-connect-tcp`. This works, but requires
the user to duplicate lot of content for each service. It doesn't allow
forwarding to multiple target qubes with the same service because
`qvm-connect-tcp` isn't systemd-socket-activated. And `qvm-connect-tcp` doesn't
support forwarding Unix sockets or setting a source IP address for TCP
connections.

I wanted a more ergonomic way to enable forwarding network connections between
client and service qubes. `qrexec-systemd-socket-activate` runs as a single
systemd service for each of the above services, avoiding the systemd service
proliferation that `qvm-connect-tcp` necessitates with `Accept=yes`. It allows
(requires, actually) the user to explicitly declare the RPC argument as a
systemd instance and the target qube for each local client address with
`FileDescriptorName`. Since each of the parts that define a qrexec connection
are encoded in systemd units, the user can easily discover and monitor them
with `systemctl`.

Unlike `qvm-connect-tcp`, `qrexec-systemd-socket-activate` supports arbitrary
Qubes RPCs. The provided systemd service units start `qubes.ConnectTCP` and the
RPCs provided in this repository. But the user can define new systemd
socket-activated services to support any Qubes RPC they can imagine, like
`qubes.ConnectAbstractUnix` or even `qubes.ConnectUnixBind`, if the user cared
to write them.
