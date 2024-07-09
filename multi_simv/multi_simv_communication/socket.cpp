#include <svdpi.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <fcntl.h>
#include <cerrno>
#include <sys/select.h>
#include <ctime>
#include <string>
#include <vector>
#include <stdexcept>

#define MAX_NODES 10
#define MAX_CLIENTS 10
#define MAX_PACKET_SIZE 4096
#define END_FLAG "<END>"
#define TIMEOUT_SECONDS 50
#define MAX_RETRIES 30
#define RETRY_DELAY 2

class SocketInfo {
public:
    int fd;
    bool is_ip;
    bool is_server;
    int client_count;
    std::vector<int> client_fds;
    union {
        sockaddr_un un;
        sockaddr_in in;
    } addr;

    SocketInfo() : fd(-1), is_ip(false), is_server(false), client_count(0), client_fds(MAX_CLIENTS, -1) {}
};

std::vector<SocketInfo> sockets(MAX_NODES);

extern "C" {

DPI_DLLESPEC int socket_init(int is_server, const char* address, int port, const char* base_path, int socket_index, int max_clients=1) {
    if (socket_index < 0 || socket_index >= MAX_NODES) {
        printf("Error: Invalid socket index\n");
        return -1;
    }

    SocketInfo& sock = sockets[socket_index];
    sock.is_server = is_server != 0;
    sock.client_count = 0;

    sock.is_ip = (address != nullptr && port != 0);

    if (sock.is_ip) {
        sock.fd = socket(AF_INET, SOCK_STREAM, 0);
        sock.addr.in.sin_family = AF_INET;
        sock.addr.in.sin_port = htons(port);
        inet_pton(AF_INET, address, &(sock.addr.in.sin_addr));
    } else {
        sock.fd = socket(AF_UNIX, SOCK_STREAM, 0);
        sock.addr.un.sun_family = AF_UNIX;
        snprintf(sock.addr.un.sun_path, sizeof(sock.addr.un.sun_path), 
                 "%s%d", base_path, socket_index);
    }

    if (sock.fd == -1) {
        perror("socket");
        return -1;
    }

    if (is_server) {
        if (!sock.is_ip) {
            unlink(sock.addr.un.sun_path);
        }
        if (bind(sock.fd, (struct sockaddr*)&sock.addr, 
                 sock.is_ip ? sizeof(sock.addr.in) : sizeof(sock.addr.un)) == -1) {
            perror("bind");
            return -1;
        }
        if (listen(sock.fd, max_clients) == -1) {
            perror("listen");
            return -1;
        }
        printf("Server is waiting for connections on socket %d...\n", socket_index);
        
        int flags = fcntl(sock.fd, F_GETFL, 0);
        fcntl(sock.fd, F_SETFL, flags | O_NONBLOCK);

        fd_set readfds;
        timeval tv;
        int max_fd = sock.fd;
        
        while (sock.client_count < max_clients) {
            FD_ZERO(&readfds);
            FD_SET(sock.fd, &readfds);
            tv.tv_sec = TIMEOUT_SECONDS;
            tv.tv_usec = 0;

            int activity = select(max_fd + 1, &readfds, NULL, NULL, &tv);
            if (activity < 0) {
                perror("select");
                return -1;
            }

            if (FD_ISSET(sock.fd, &readfds)) {
                int client_socket = accept(sock.fd, NULL, NULL);
                if (client_socket == -1) {
                    if (errno != EAGAIN && errno != EWOULDBLOCK) {
                        perror("accept");
                        return -1;
                    }
                } else {
                    sock.client_fds[sock.client_count++] = client_socket;
                    printf("Client %d connected on socket %d.\n", sock.client_count, socket_index);
                    if (client_socket > max_fd) {
                        max_fd = client_socket;
                    }
                }
            }
        }
    } else {
        int retries = 0;
        while (retries < MAX_RETRIES) {
            if (connect(sock.fd, (struct sockaddr*)&sock.addr, 
                        sock.is_ip ? sizeof(sock.addr.in) : sizeof(sock.addr.un)) == 0) {
                printf("Connected to server on socket %d.\n", socket_index);
                break;
            }
            if (errno != ECONNREFUSED && errno != ENOENT) {
                perror("connect");
                return -1;
            }
            printf("Connection failed. Retrying in %d seconds...\n", RETRY_DELAY);
            sleep(RETRY_DELAY);
            retries++;
        }
        if (retries == MAX_RETRIES) {
            printf("Failed to connect after %d attempts.\n", MAX_RETRIES);
            return -1;
        }
    }

    return sock.fd;
}

DPI_DLLESPEC const char* socket_send(int socket_index, const char* data) {
    static std::string result;

    if (socket_index < 0 || socket_index >= MAX_NODES) {
        result = "ERROR: Invalid socket index";
        return result.c_str();
    }

    SocketInfo& sock = sockets[socket_index];
    if (sock.fd == -1) {
        result = "ERROR: Socket not initialized";
        return result.c_str();
    }

    std::string buffer = std::string(data) + END_FLAG;

    if (sock.is_server) {
        for (int i = 0; i < sock.client_count; i++) {
            int bytes_sent = send(sock.client_fds[i], buffer.c_str(), buffer.length(), 0);
            if (bytes_sent == -1) {
                perror("send failed");
                result = "ERROR: Send failed to at least one client";
                return result.c_str();
            }
            if (static_cast<size_t>(bytes_sent) < buffer.length()) {
                result = "WARNING: Not all data sent to at least one client";
                return result.c_str();
            }
        }
        result = "OK: Data broadcast successfully";
    } else {
        int bytes_sent = send(sock.fd, buffer.c_str(), buffer.length(), 0);
        if (bytes_sent == -1) {
            perror("send failed");
            result = "ERROR: Send failed";
            return result.c_str();
        }
        if (static_cast<size_t>(bytes_sent) < buffer.length()) {
            result = "WARNING: Not all data sent";
            return result.c_str();
        }
        result = "OK: Data sent successfully";
    }
    return result.c_str();
}

DPI_DLLESPEC const char* socket_recv(int socket_index, int non_blocking=0) {
    static std::string result;
    static std::string buffer_storage[MAX_NODES];  // 为每个socket保存一个缓冲区

    if (socket_index < 0 || socket_index >= MAX_NODES) {
        result = "ERROR: Invalid socket index";
        return result.c_str();
    }

    SocketInfo& sock = sockets[socket_index];
    if (sock.fd == -1) {
        result = "ERROR: Socket not initialized";
        return result.c_str();
    }

    std::string& accumulated = buffer_storage[socket_index];
    char buffer[MAX_PACKET_SIZE];
    
    int flags = fcntl(sock.fd, F_GETFL, 0);
    if (non_blocking) {
        fcntl(sock.fd, F_SETFL, flags | O_NONBLOCK);
    } else {
        fcntl(sock.fd, F_SETFL, flags & ~O_NONBLOCK);
    }
    
    // 首先检查缓冲区中是否已有完整消息
    size_t end_pos = accumulated.find(END_FLAG);
    if (end_pos != std::string::npos) {
        result = accumulated.substr(0, end_pos);
        accumulated = accumulated.substr(end_pos + strlen(END_FLAG));
        return result.c_str();
    }

    while (true) {
        int bytes_received;
        if (sock.is_server) {
            fd_set readfds;
            FD_ZERO(&readfds);
            int max_fd = -1;
            for (int i = 0; i < sock.client_count; i++) {
                FD_SET(sock.client_fds[i], &readfds);
                if (sock.client_fds[i] > max_fd) {
                    max_fd = sock.client_fds[i];
                }
            }
            timeval tv = {TIMEOUT_SECONDS, 0};
            int activity = select(max_fd + 1, &readfds, NULL, NULL, &tv);
            if (activity < 0) {
                perror("select");
                result = "ERROR: Select failed";
                return result.c_str();
            }
            if (activity == 0) {
                result = "ERROR: Receive timeout";
                return result.c_str();
            }
            for (int i = 0; i < sock.client_count; i++) {
                if (FD_ISSET(sock.client_fds[i], &readfds)) {
                    bytes_received = recv(sock.client_fds[i], buffer, MAX_PACKET_SIZE - 1, 0);
                    break;
                }
            }
        } else {
            bytes_received = recv(sock.fd, buffer, MAX_PACKET_SIZE - 1, 0);
        }
        
        if (bytes_received == -1) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                // 非阻塞模式下没有数据可读
                if (non_blocking) {
                    result = "NO_DATA";
                    return result.c_str();
                }
                continue;  // 阻塞模式下继续等待
            }
            perror("recv failed");
            result = "ERROR: Receive failed";
            return result.c_str();
        }
        else if (bytes_received == 0) {
            result = "ERROR: Connection closed";
            return result.c_str();
        }
        
        buffer[bytes_received] = '\0';
        accumulated += buffer;
        
        end_pos = accumulated.find(END_FLAG);
        if (end_pos != std::string::npos) {
            result = accumulated.substr(0, end_pos);
            accumulated = accumulated.substr(end_pos + strlen(END_FLAG));
            break;
        }
    }
    
    fcntl(sock.fd, F_SETFL, flags);  // 恢复原来的 flags
    
    return result.c_str();
}

}  // extern "C"