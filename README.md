# qrexec-connect
_It's like qrexec-client-vm, but systemd-socket-activated._

qrexec-connect is a systemd-native service for controlling inter-qube network
connections over qrexec with systemd. Enable a new qrexec connection with a
single systemd socket unit file. Manage and monitor connection services on
client qubes with systemctl.

For example, to forward TCP connections to 127.0.0.1:1234 on a client qube
to the same port on the @default service qube, create a new socket unit file
with a `qrexec-connect-` prefix: 

```ini
# /home/user/.config/systemd/user/qrexec-connect-gitweb.socket
[Socket]
# Arbitrary IP address port on the service qube:
ListenStream=127.0.0.1:1234
# Arguments you would use with qrexec-client-vm:
FileDescriptorName=@default qubes.ConnectTCP+1234

# Each user-generated socket unit needs its own Install section.
[Install]
WantedBy=sockets.target
```

To forward connections to 127.0.0.2:2345 on the client qube to gitweb on a
service named `work`:

```ini
# /home/user/.config/systemd/user/qrexec-connect-gitweb-work.socket
[Socket]
ListenStream=127.0.0.1:2345
FileDescriptorName=work qubes.ConnectTCP:1234

[Install]
WantedBy=sockets.target
```
See [Examples](#examples) to complete the setup.

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
a drop-in that applies to all socket units named with a `qrexec-connect-`
prefix to set default directives to all port-binding socket units. Together,
this minimizes the amount of configuration users have to generate for each new
port binding to a new file with three-to-five lines of configuration plus the
usual `systemctl` commands.

## Installation

I don't intend to package this right now.

I will generate a signed checksum file when I feel it's robust enough for daily
use.

**Client qube**

This will install to directories that only persist on template qubes. You don't
need to restart the qube to use qrexec-connect, so you can install it in an App
qube if you just want to test it.

```console
user@client:~$ sudo make install-client
```

To install in an App qube with persistence, copy the systemd unit and drop-in
to `/usr/local/systemd/user` and the qrexec-connect executable to
`/usr/local/bin` assuming no naming conflict. Take a look a the commands in the
`Makefile` to preserve file modes.

**Service qube**

qrexec-connect doesn't require any installation on the service qube to use with
the qubes.ConnectTCP RPC.

Using qrexec-connect to bind Unix sockets or other custom RPCs, like the
included qubes.ConnectNFS, requires user-specific server configuration. See
[Examples](#examples).

## Examples

### TCP ports

Bind TCP ports between qubes just like qvm-connect-tcp or the [Accept=true
usage of qrexec-client-vm with
qubes.ConnectTCP](https://www.qubes-os.org/doc/firewall/#opening-a-single-tcp-port-to-other-network-isolated-qube).

**Client qube**

Create `/home/user/.config/systemd/user/qrexec-connect-ssh.socket` with this content:

```ini
[Socket]
ListenStream=127.0.0.1:2222
FileDescriptorName=ssh-server qubes.ConnectTCP+2222

[Install]
WantedBy=sockets.target
```

Reload systemd user unit files, start the new socket unit, and make it persistent across reboots:

```console
user@ssh-client:~$ systemctl --user daemon-reload
user@ssh-client:~$ systemctl --user enable --now qrexec-connect-ssh.socket
```

Don't start the qrexec-connect service itself.

**Service qube**

qrexec-connect doesn't require service qube configuration for any normal TCP port binding.

**Policy**

Create a Qubes policy to allow connections from a client qube named
`ssh-client` to a service qube named `ssh-server`:

```
qubes.ConnectTCP +2222 ssh-client ssh-server allow
```

**Test**

Now can SSH to localhost on the client qube at 127.0.0.1:2222:

```console
user@ssh-client:~$ ssh -p 2222 user@127.0.0.1
```

### Unix sockets

Bind Unix sockets between qubes. This probably also works with a
qrexec-client-vm template service and an Accept=true socket unit, but is
undocumented.

**Client qube**

Create `/home/user/.config/systemd/user/qrexec-connect-ssh-agent.socket` with this content:

```ini
[Socket]
ListenStream=%t/qrexec-connect/ssh-agent
FileDescriptorName=@default qubes.ConnectSSHAgent

[Install]
WantedBy=sockets.target
```

`%t` is a systemd unit file specifier that expands to `$XDG_RUNTIME_DIR`. For
the Qubes default user, this will almost always be `/run/user/1000`.

It's safer and more organized to use a common parent directory for files a
single application controls in the `$XDG_RUNTIME_DIR` directory. This socket unit
uses the `qrexec-connect` directory, but users can assign any directory and
socket filename that doesn't already exist and the user can read and write.

systemd will create any directories that don't already exist before creating
the socket file itself. The path value for `ListenStream` is only a convention.

The `FileDescriptorName` value uses `@default` as the destination qube, just like
qrexec-connect-vm accepts. See the Policy section to see how to configure the
default service qube.

Reload systemd user unit files, start the new socket unit, and make it
persistent across reboots:

```console
user@ssh-client:~$ systemctl --user daemon-reload
user@sss-client:~$ systemctl --user enable --now qrexec-connect-ssh-agent.socket
```

Don't start the qrexec-connect service itself.

_NB: It's possible to use the same socket path as the service qube on the
client qube. If the client qube creates that socket automatically, the user
will need to disable the functionality that automatically creates that socket.
For example, to use `ListenStream=%t/gnupg/S.gpg-agent.ssh` on Debian, run
`systemctl --user mask gpg-agent-ssh.socket` on the client qube._

**Service qube**

Create a symlink to the socket you want to bind from the service qube to the
client qube:

```console
user@ssh-agent:~$ ln --symbolic /run/user/1000/gnupg/S.gpg-agent.ssh /etc/qubes-rpc/qubes.ConnectSSHAgent
```

Configure the socket RPC so that the qrexec daemon doesn't send any prefix data
before sending data from the client qube. Create
`/etc/rpc-config/qubes.ConnectSSHAgent` with the following content:

```
skip-service-descriptor=true
```

**Policy**

```
qubes.ConnectSSHAgent + ssh-client @default allow target=ssh-agent
```

**Test**

Make sure the SSH agent on the service qube represents an SSH key:

```console
user@ssh-client:~$ SSH_AUTH_SOCK=/run/user/1000/gnupg/S.gpg-agent.ssh ssh-add -l
```

List the same represented SSH keys on the client:

```console
user@ssh-agent:~$ SSH_AUTH_SOCK=/run/user/1000/qrexec-connect/ssh-agent ssh-add -l
```

### NFS

qrexec-connect, qvm-connect-tcp, and qrexec-client-vm can bind the standard
NFS port, 2049, from a service qube to a client qube with qubes.ConnectTCP. But
this method only allows client qubes to connect as a single remote host from
the service qube's perspective. For example, calling `nfs-server
qubes.ConnectTCP+2049` will always connect from the localhost IP on the service
qube, 127.0.0.1. This means the service qube must apply the same access control
rules to all client qube connections.

The qubes.ConnectNFS RPC always connects to port 2049 on the service qube. Its
argument is an IP address to bind to ("bind" is overloaded here), or
connect from, on the service qube, like `nfs-server qubes.ConnectNFS+127.0.1.1`.
This allows the service qube to create exports with host-specific permissions.
For example:

```
# /etc/exports
/home/user/Documents 127.0.1.1(rw,...)
/home/user/Documents 127.0.1.2(ro,...)
/home/user/Pictures  127.0.1.3(rw,...)
```

Use Qubes policy to control the server-local IP address that client qubes can
bind to.

**Client qube**

Create a socket unit file named
`/home/user/.config/systemd/user/qrexec-connect-nfs-documents.socket` with this
content:

```ini
[Socket]
ListenStream=127.0.0.1:2049
FileDescriptorName=nfs-server qubes.ConnectNFS+127.0.1.1
```

Create a mount unit file named
`/home/user/.config/systemd/user/nfs-documents.mount` with this content:

```ini
[Unit]
Description=Documents
After=qrexec-connect-nfs-documents.socket

[Mount]
What=127.0.0.1:/home/user/Documents
Where=/home/user/Documents
Type=nfs4
Options=defaults,user,noauto,relatime,rw

[Install]
WantedBy=multi-user.target
```

Reload systemd units and start the mount unit:

```console
user@nfs-client:~$ systemctl --user daemon-reload
user@nfs-client:~$ systemctl --user start nfs-documents.mount
```

**Service qube**

Install the qubes.ConnectNFS RPC:

```console
user@nfs-server:~$ sudo make install-connectnfs
```

Install NFS and enable NFSv4 on the service qube. On Debian:

```console
user@nfs-server:~$ sudo apt update
user@nfs-server:~$ sudo apt install --assume-yes nfs-kernel-server
```

On Debian, you may also need to unmask `rpcbind.service`:

```console
user@nfs-server:~$ sudo systemctl unmask rpcbind.service
```

Define exports in `/etc/exports`:

```
/home/user/Documents 127.0.1.1(rw,sync,no_subtree_check,root_squash,insecure)
/home/user/Documents 127.0.1.2(ro,sync,no_subtree_check,root_squash,insecure)
```

This example defines a read-only and read-write export for two remote hosts for
demonstration purposes.

The `insecure` option is required because qubes.ConnectNFS should be executed
as the Qubes default, non-root user, `user`, which can only bind to ports
higher than 1000. NFS considers this "insecure".

Restart the NFS server and verify the export is registered:

```console
user@nfs-server:~$ sudo systemctl restart nfs-server.service
user@nfs-server:~$ sudo exportfs -s
/home/user/Documents  127.0.1.1(sync,wdelay,hide,no_subtree_check,sec=sys,rw,insecure,root_squash,no_all_squash)
/home/user/Documents  127.0.1.2(sync,wdelay,hide,no_subtree_check,sec=sys,ro,insecure,root_squash,no_all_squash)
```

The `127.0.1.1.` address doesn't exist by default. IP address definitions are
distribution-specific. On Debian, create a `/etc/network/interfaces.d/nfs` with
the following content:

```
auto lo
iface lo inet loopback

iface lo:0 inet static
    address 127.0.1.1/8

iface lo:1 inet static
    address 127.0.1.1/8
```

This configuration uses interface aliasing to avoid errors when shutting down the interface. See [NetworkConfiguration](https://wiki.debian.org/NetworkConfiguration)

Shutdown and startup the lo interface:

```console
user@nfs-server:~$ sudo ifdown lo
user@nfs-server:~$ sudo ifup lo
```

**Policy**

```
qubes.ConnectNFS +127.0.1.1 nfs-client nfs-server allow
```
