#!/usr/bin/env python3
"""
Simple IRC Server for Hackerbot Development
A minimal IRC server implementation for local development and testing.
"""
import os

# Configuration
IRC_HOST = os.environ.get('IRC_HOST', '127.0.0.1')
IRC_PORT = int(os.environ.get('IRC_PORT', '6667'))

import socket
import threading
import sys
import time
import signal
import os

# Global variables
server_socket = None
clients = {}
channels = {"#hackerbot": set()}
running = True

class IRCClient:
    def __init__(self, conn, addr):
        self.conn = conn
        self.addr = addr
        self.nick = None
        self.user = None
        self.registered = False
        self.channels = set()

    def send(self, msg):
        """Send a message to the client."""
        try:
            self.conn.send(f"{msg}\r\n".encode())
        except:
            pass

    def send_numeric(self, numeric, target, message):
        """Send a numeric response."""
        self.send(f":irc.local {numeric} {target} {message}")

    def welcome(self):
        """Send welcome messages."""
        if self.nick and self.user and not self.registered:
            self.send_numeric("001", self.nick, ":Welcome to the Hackerbot IRC Server")
            self.send_numeric("002", self.nick, ":Your host is irc.local")
            self.send_numeric("003", self.nick, ":This server was created just now")
            self.send_numeric("004", self.nick, "irc.local 1.0")
            self.send_numeric("251", self.nick, ":There are 1 users and 0 services on 1 servers")
            self.send_numeric("255", self.nick, ":I have 1 clients and 0 servers")
            self.send_numeric("372", self.nick, ":- Message of the day - ")
            self.send_numeric("376", self.nick, ":End of MOTD command")
            self.registered = True

    def join_channel(self, channel):
        """Join a channel."""
        if channel in channels:
            self.channels.add(channel)
            channels[channel].add(self)

            # Send join message to user
            self.send(f":{self.nick}!~user@localhost JOIN {channel}")

            # Send channel info
            self.send_numeric("331", self.nick, f"{channel} :No topic is set")
            self.send_numeric("353", self.nick, f"= {channel} :{' '.join([c.nick for c in channels[channel] if c.nick])}")
            self.send_numeric("366", self.nick, f"{channel} :End of NAMES list")

            # Notify other users
            for client in channels[channel]:
                if client != self:
                    client.send(f":{self.nick}!~user@localhost JOIN {channel}")

    def part_channel(self, channel):
        """Leave a channel."""
        if channel in self.channels:
            self.channels.remove(channel)
            if self in channels[channel]:
                channels[channel].remove(self)

            # Send part message
            self.send(f":{self.nick}!~user@localhost PART {channel}")

            # Notify other users
            for client in channels[channel]:
                client.send(f":{self.nick}!~user@localhost PART {channel}")

    def handle_message(self, message):
        """Handle incoming IRC message."""
        if not message:
            return

        parts = message.split()
        if not parts:
            return

        command = parts[0].upper()

        if command == "NICK" and len(parts) > 1:
            self.nick = parts[1]
            self.welcome()

        elif command == "USER" and len(parts) > 4:
            self.user = parts[1]
            self.welcome()

        elif command == "JOIN" and len(parts) > 1:
            channel = parts[1]
            if not channel.startswith("#"):
                channel = "#" + channel
            self.join_channel(channel)

        elif command == "PART" and len(parts) > 1:
            channel = parts[1]
            if not channel.startswith("#"):
                channel = "#" + channel
            self.part_channel(channel)

        elif command == "PRIVMSG" and len(parts) > 2:
            target = parts[1]
            msg = " ".join(parts[2:]).lstrip(":")

            if target.startswith("#") and target in channels:
                # Send to channel
                for client in channels[target]:
                    if client != self:
                        client.send(f":{self.nick}!~user@localhost PRIVMSG {target} :{msg}")
            else:
                # Send to user (not implemented for simplicity)
                self.send_numeric("401", self.nick, f"{target} :No such nick/channel")

        elif command == "PING":
            if len(parts) > 1:
                self.send(f"PONG :{parts[1]}")
            else:
                self.send("PONG")

        elif command == "QUIT":
            self.disconnect()

        elif command == "WHOIS" and len(parts) > 1:
            target = parts[1]
            # Simple WHOIS response
            self.send_numeric("311", self.nick, f"{target} ~user localhost * :Hackerbot User")
            self.send_numeric("312", self.nick, f"{target} irc.local :Hackerbot IRC Server")
            self.send_numeric("318", self.nick, f"{target} :End of WHOIS list")

        elif command == "LIST":
            for channel in channels:
                self.send_numeric("322", self.nick, f"{channel} {len(channels[channel])} :Development Channel")
            self.send_numeric("323", self.nick, ":End of LIST")

        elif command == "NAMES" and len(parts) > 1:
            channel = parts[1]
            if channel in channels:
                nicks = [c.nick for c in channels[channel] if c.nick]
                self.send_numeric("353", self.nick, f"= {channel} :{' '.join(nicks)}")
            self.send_numeric("366", self.nick, f"{channel} :End of NAMES list")

    def disconnect(self):
        """Disconnect the client."""
        if self in clients:
            del clients[self]

        # Leave all channels
        for channel in list(self.channels):
            self.part_channel(channel)

        try:
            self.conn.close()
        except:
            pass

def handle_client(conn, addr):
    """Handle a client connection."""
    client = IRCClient(conn, addr)
    clients[client] = True

    try:
        while running:
            data = conn.recv(1024)
            if not data:
                break

            # Handle each line separately
            messages = data.decode().split('\r\n')
            for message in messages:
                if message.strip():
                    client.handle_message(message.strip())

    except Exception as e:
        print(f"Error handling client {addr}: {e}")
    finally:
        client.disconnect()

def signal_handler(signum, frame):
    """Handle shutdown signals."""
    global running
    print("\nShutting down server...")
    running = False

def main():
    global server_socket, running

    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # Create server socket
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    try:
        server_socket.bind((IRC_HOST, IRC_PORT))
        server_socket.listen(5)

        print(f"IRC server started on {IRC_HOST}:{IRC_PORT}")
        print(f"Connect with: irc://{IRC_HOST}:{IRC_PORT}/#hackerbot")
        print("Press Ctrl+C to stop the server")

        # Write PID file
        with open('/tmp/ircd.pid', 'w') as f:
            f.write(str(os.getpid()))

        # Accept connections
        while running:
            try:
                conn, addr = server_socket.accept()
                client_thread = threading.Thread(target=handle_client, args=(conn, addr))
                client_thread.daemon = True
                client_thread.start()
            except OSError:
                break

    except Exception as e:
        print(f"Server error: {e}")
    finally:
        running = False
        if server_socket:
            server_socket.close()

        # Clean up PID file
        if os.path.exists('/tmp/ircd.pid'):
            os.remove('/tmp/ircd.pid')

        # Close all client connections
        for client in list(clients.keys()):
            client.disconnect()

if __name__ == "__main__":
    main()
