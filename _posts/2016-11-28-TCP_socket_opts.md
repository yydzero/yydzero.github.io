## SO\_REUSEADDR and SO\_REUSEPORT
* SO\_REUSEPORT allows multiple sockets on the same host to bind to the same port;
* SO\_REUSEPORT can be used with both TCP and UDP sockets. With TCP sockets, it allows multiple listening sockets — normally each in a different thread — to be bound to the same port. Each thread can then accept incoming connections on the port by calling accept(). This presents an alternative to the traditional approaches used by multithreaded servers that accept incoming connections on a single socket.
* The first of the traditional approaches is to have a single listener thread that accepts all incoming connections and then passes these off to other threads for processing. The problem with this approach is that the listening thread can become a bottleneck in extreme cases.
* The second of the traditional approaches used by multithreaded servers operating on a single port is to have all of the threads (or processes) perform an accept() call on a single listening socket in a simple event loop of the form:

```
    while (1) {
        new_fd = accept(...);
        process_connection(new_fd);
    }
```
The problem with this technique is that when multiple threads are waiting in the accept() call, wake-ups are not fair, so that, under high load, incoming connections may be distributed across threads in a very unbalanced fashion.

* By contrast, the SO\_REUSEPORT implementation distributes connections evenly across all of the threads (or processes) that are blocked in accept() on the same port.
* The traditional SO\_REUSEADDR socket option already allows multiple UDP sockets to be bound to, and accept datagrams on, the same UDP port. However, by contrast with SO_REUSEPORT, SO_REUSEADDR does not prevent port hijacking and does not distribute datagrams evenly across the receiving threads.
* Generally speaking, a port can be reused two minutes after calling `close()`, while SO_REUSEADDR option can make it reusable immediately.
* example code to bind to one specific port:

```
int socket_desc;
socket_desc=socket(AF_INET,SOCK_STREAM,0);
struct sockaddr_in address;
address.sin_family = AF_INET;
address.sin_addr.s_addr = INADDR_ANY;
//Port defined Here:
address.sin_port=htons(81);

bind(socket_desc,(struct sockaddr *)&address,sizeof(address));
```
* two possible reasons if bind fails:
	* If you ask for port below 1024;
	* If you forgot to use htons() function. In this case bytes of port number are used in wrong order and that leads to #1.

