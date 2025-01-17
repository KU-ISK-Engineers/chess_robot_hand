import socket
import argparse


def connect_tcp(ip, port):
    try:
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client_socket.connect((ip, port))
        print(f"Connected to {ip}:{port}")
        return client_socket
    except socket.error as e:
        print(f"Error connecting to {ip}:{port} - {e}")
        return None


def send_tcp_command(client_socket, command):
    try:
        # Send the command
        client_socket.sendall(command.encode('utf-8'))
        print(f"Command sent: {command}")

        # Receive the response
        response = client_socket.recv(1024).decode('utf-8')
        print(f"Response received: {response}")
    except socket.error as e:
        print(f"Error sending/receiving data: {e}")


if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Send a TCP command to a specified IP and port.")
    parser.add_argument("ip", help="The IP address of the server.")
    parser.add_argument("port", type=int, help="The port number of the server.")
    parser.add_argument("command", help="The command to send to the server.")

    args = parser.parse_args()

    client_socket = connect_tcp(args.ip, args.port)
    if client_socket:
        send_tcp_command(client_socket, args.command)
