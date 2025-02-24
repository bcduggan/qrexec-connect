qrexec-connect
==============

*It's like qrexec-client-vm, but systemd-socket-activated.*

qrexec-connect is a systemd-native service for controlling inter-qube network
connections over qrexec with systemd. Enable a new qrexec connection with a
single systemd socket unit file. Manage and monitor connection services on
client qubes with systemctl.

For example, to forward TCP connections to 127.0.0.1:1234 on a client qube
to the same port on the @default service qube, create a new socket unit file
with a ``qrexec-connect-`` prefix: 

.. code:: ini

   # /home/user/.config/systemd/user/qrexec-connect-gitweb.socket
   [Socket]
   # Arbitrary IP address port on the service qube:
   ListenStream=127.0.0.1:1234
   # Arguments you would use with qrexec-client-vm:
   FileDescriptorName=@default qubes.ConnectTCP+1234

   # Each user-generated socket unit needs its own Install section.
   [Install]
   WantedBy=sockets.target

To forward connections to 127.0.0.2:2345 on the client qube to gitweb on a
service named ``work``:

.. code:: ini

   # /home/user/.config/systemd/user/qrexec-connect-gitweb-work.socket
   [Socket]
   ListenStream=127.0.0.1:2345
   FileDescriptorName=work qubes.ConnectTCP:1234

   [Install]
   WantedBy=sockets.target

See _`Examples` to complete the setup.

Motivation
----------

To `permanently bind a port between two qubes with qrexec-client-vm
<https://www.qubes-os.org/doc/firewall/#opening-a-single-tcp-port-to-other-network-isolated-qube>`_,
users have to create a new pair of .socket and .service unit files for each
port. This requires the user to duplicate a lot of content for each port. Since
qrexec-client-vm only communicates through stdio, the corresponding socket
unit must set the `Accept` directive to `true`. Systemd starts a new instance
of the qrexec-client-vm service for each new connection, which generates a
some noise in the service status.

I wanted a more ergonomic, systemd-native way to permanently bind ports between
qubes client and service qubes. qrexec-connect runs as a single,
socket-activated systemd service for all port bindings, avoiding service
instance proliferation. It accepts new connections by itself so users can apply
multiple socket unit files to the single qrexec-connect service. It includes
a drop-in that applies to all socket units named with a `qrexec-connect-`
prefix to set default directives to all port-binding socket units. Together,
this minimizes the amount of configuration users have to generate for each new
port binding to a new file with three-to-five lines of configuration plus the
usual systemctl commands.

Installation
------------

I don't intend to package this right now.

I will generate a signed checksum file when I feel it's robust enough for daily
use.

**Client qube**

Client qubes need the qrexec-connect executable, the systemd service unit, and
the systemd socket drop-in:

.. code:: console

   sudo make install-client

**Service qube**

qrexec-connect doesn't require any installation on the service qube to use with
the qubes.ConnectTCP RPC.

Using qrexec-connect to bind Unix sockets or other custom RPCs, like the
included qubes.ConnectNFS, requires user-specific server configuration. See
_`Examples`.

Examples
--------

**TCP**

See _`qrexec-connect` for short examples.

*Client qube*

Create a systemd socket file for each pair of ports you want to bind. Copy
examples/tcp/client/sshfs.socket to ~/.config/systemd/user/sshfs.socket or
create that file with this content:

.. literalinclude:: examples/tcp/client/ssh.socket
   :language: ini

Reload systemd user unit files and start the new socket unit, only:

.. code:: console

   user@client:~$ systemctl --user daemon-reload
   user@client:~$ systemctl --user start qrexec-connect-ssh.socket

Don't start the qrexec-connect service itself.

Now can SSH to localhost on the client qube at 127.0.0.1:2222.

This will start the socket for this session, but it won't cause the socket to
start after you restart the client qube. To make this socket persistent, run:

.. code:: console

   user@client:~$ systemctl --user enable qrexec-connect-ssh.socket

*Service qube*

qrexec-connect doesn't require service qube configuration for any normal TCP port binding.

