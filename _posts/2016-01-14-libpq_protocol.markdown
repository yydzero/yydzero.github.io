==> A single server can support multiple protocol versions. The initial
	startup-request message tells the server which protocol version the client is
	attempting to use, and then the server follows that protocol if it is able.

==> The protocol has separate phases for startup and normal operation. In the startup
	phase, the frontend opens a connection to the server and authenticates itself
	to the satisfaction of the server. (This might involve a single message, or
	multiple messages depending on the authentication method being used.) If all
	goes well, the server then sends status information to the frontend, and finally
	enters normal operation.

	During normal operation, the frontend sends queries and other commands to the
	backend, and the backend sends back query results and other responses. There are a
	few cases (such as NOTIFY) wherein the backend will send unsolicited messages.

	Within normal operation, SQL commands can be executed through either of two
	sub-protocols. In the "simple query" protocol, the frontend just sends a textual
	query string, which is parsed and immediately executed by the backend. In the
	"extended query" protocol, processing of queries is separated into multiple steps:
	parsing, binding of parameter values, and execution. This offers flexibility and
	performance benefits, at the cost of extra complexity.

	Normal operation has additional sub-protocols for special operations such as COPY.

==> All communication is through a stream of messages. The first byte of a message identifies
	the message type, and the next four bytes specify the length of the rest of the message.

	To avoid losing synchronization with the message stream, both servers and clients
	typically read an entire message into a buffer (using the byte count) before attempting
	to process its contents. This allows easy recovery if an error is detected while processing
	the contents. In extreme situations (such as not having enough memory to buffer the message),
	the receiver can use the byte count to determine how much input to skip before it resumes
	reading messages.

	NOTE: that is to say, once you call pq_endmessage to send the message, you can not call
	appendBinaryStringInfo or pq_sendint/pq_putmessage again, otherwise, client would mess the data
	received;

	Conversely, both servers and clients must take care never to send an incomplete message.
	This is commonly done by marshaling the entire message in a buffer before beginning to send it(
	pq_beginmessage and pq_sendint/appendBinaryStringInfo). If a communications failure occurs partway
	through sending or receiving a message, the only sensible response is to abandon the connection,
	since there is little hope of recovering message-boundary synchronization.

==> In the extended-query protocol, execution of SQL commands is divided into multiple steps. The
	state retained between steps is represented by two types of objects: prepared statements and portals.
	A prepared statement represents the result of parsing and semantic analysis of a textual query string.
	A prepared statement is not in itself ready to execute, because it might lack specific values for
	parameters. A portal represents a ready-to-execute or already-partially-executed statement, with any
	missing parameter values filled in.

	The overall execution cycle consists of a parse step, which creates a prepared statement from a textual
	query string; a bind step, which creates a portal given a prepared statement and values for any needed
	parameters; and an execute step that runs a portal's query. In the case of a query that returns rows
	(SELECT, SHOW, etc), the execute step can be told to fetch only a limited number of rows, so that
	multiple execute steps might be needed to complete the operation.

	The backend can keep track of multiple prepared statements and portals (but note that these exist only
	within a session, and are never shared across sessions). Existing prepared statements and portals are
	referenced by names assigned when they were created. In addition, an "unnamed" prepared statement and
	portal exist. Although these behave largely the same as named objects, operations on them are optimized
	for the case of executing a query only once and then discarding it, whereas operations on named objects
	are optimized on the expectation of multiple uses.

==> Data of a particular data type might be transmitted in any of several different formats. The only supported
	formats now are "text" and "binary", but the protocol makes provision for future extensions. The desired
	format for any value is specified by a format code. Text has format code zero, binary has format code one,
	and all other format codes are reserved for future definition.

	The text representation of values is first transform the value into text format binary, then send this binary;

	Binary representations for integers is its directy binary, which use network byte order (most significant
	byte first). Keep in mind that binary representations for complex data types might change across
	server versions; the text format is usually the more portable choice.

==> Message flow:
	--> startup phase:
		To begin a session, a frontend opens a connection to the server and sends a startup message.
		This message includes the names of the user and of the database the user wants to connect to;
		it also identifies the particular protocol version to be used. The server then uses this
		information and the contents of its configuration files (such as pg_hba.conf) to determine
		whether the connection is provisionally acceptable, and what additional authentication
		is required (if any).

		The server then sends an appropriate authentication request message, to which the frontend
		must reply with an appropriate authentication response message (such as a password). For
		all authentication methods except GSSAPI and SSPI, there is at most one request and one
		response. In some methods, no response at all is needed from the frontend, and so no
		authentication request occurs. For GSSAPI and SSPI, multiple exchanges of packets may
		be needed to complete the authentication.

		The authentication cycle ends with the server either rejecting the connection attempt
		(ErrorResponse), or sending AuthenticationOk.

		If the frontend does not support the authentication method requested by the server,
		then it should immediately close the connection.

		After having received AuthenticationOk, the frontend must wait for further messages
		from the server. In this phase a backend process is being started, and the frontend is
		just an interested bystander. It is still possible for the startup attempt to fail (ErrorResponse),
		but in the normal case the backend will send some ParameterStatus messages,
		BackendKeyData, and finally ReadyForQuery.

		During this phase the backend will attempt to apply any additional run-time parameter
		settings that were given in the startup message. If successful, these values become session
		defaults. An error causes ErrorResponse and exit.

		The possible messages from the backend in this phase are:
		--> BackendKeyData
			This message provides secret-key data that the frontend must save if it wants to be
			able to issue cancel requests later. The frontend should not respond to this message,
			but should continue listening for a ReadyForQuery message.

		--> ParameterStatus
			This message informs the frontend about the current (initial) setting of backend parameters.
			The frontend can ignore this message, or record the settings for its future use; The frontend
			should not respond to this message, but should continue listening for a ReadyForQuery message.

		--> ReadyForQuery
			Start-up is completed. The frontend can now issue commands.

		--> ErrorResponse
			Start-up failed. The connection is closed after sending this message.

		--> NoticeResponse
			A warning message has been issued. The frontend should display the message but continue
			listening for ReadyForQuery or ErrorResponse.

==> ParameterStatus messages will be generated whenever the active value changes for any of
	the GUCs the backend believes the frontend should know about. Most commonly this occurs
	in response to a SET SQL command executed by the frontend, and this case is effectively
	synchronous — but it is also possible for parameter status changes to occur because the
	administrator changed a configuration file and then sent the SIGHUP signal to the server.
	Also, if a SET command is rolled back, an appropriate ParameterStatus message will be
	generated to report the current effective value.

	At present there is a hard-wired set of parameters for which ParameterStatus will be
	generated: they are server_version, server_encoding, client_encoding, application_name,
	is_superuser, session_authorization, DateStyle, IntervalStyle, TimeZone, integer_datetimes,
	and standard_conforming_strings.

	If a frontend issues a LISTEN command, then the backend will send a NotificationResponse
	message (not to be confused with NoticeResponse!) whenever a NOTIFY command is executed
	for the same channel name.

==> During the processing of a query, the frontend might request cancellation of the query.
	The cancel request is not sent directly on the open connection to the backend for reasons
	of implementation efficiency: we don't want to have the backend constantly checking for
	new input from the frontend during query processing. Cancel requests should be relatively
	infrequent, so we make them slightly cumbersome in order to avoid a penalty in the normal case.

	To issue a cancel request, the frontend opens a new connection to the server and sends a
	CancelRequest message, rather than the StartupMessage message that would ordinarily be
	sent across a new connection. The server will process this request and then close the
	connection. For security reasons, no direct reply is made to the cancel request message.

	A CancelRequest message will be ignored unless it contains the same key data (PID and
	secret key) passed to the frontend during connection start-up. If the request matches the
	PID and secret key for a currently executing backend, the processing of the current query
	is aborted. (In the existing implementation, this is done by sending a special signal to the
	backend process that is processing the query.)

	The cancellation signal might or might not have any effect — for example, if it arrives
	after the backend has finished processing the query, then it will have no effect. If the
	cancellation is effective, it results in the current command being terminated early with an
	error message.

	The upshot of all this is that for reasons of both security and efficiency, the frontend has
	no direct way to tell whether a cancel request has succeeded. It must continue to wait for
	the backend to respond to the query. Issuing a cancel simply improves the odds that the current
	query will finish soon, and improves the odds that it will fail with an error message instead
	of succeeding.

	Since the cancel request is sent across a new connection to the server and not across the regular
	frontend/backend communication link, it is possible for the cancel request to be issued by any
	process, not just the frontend whose query is to be canceled. This might provide additional
	flexibility when building multiple-process applications. It also introduces a security risk,
	in that unauthorized persons might try to cancel queries. The security risk is addressed by
	requiring a dynamically generated secret key to be supplied in cancel requests.

==> To initiate an SSL-encrypted connection, the frontend initially sends an SSLRequest message
	rather than a StartupMessage. The server then responds with a single byte containing S or N,
	indicating that it is willing or unwilling to perform SSL, respectively. The frontend might
	close the connection at this point if it is dissatisfied with the response. To continue after
	S, perform an SSL startup handshake (not described here, part of the SSL specification) with
	the server. If this is successful, continue with sending the usual StartupMessage. In this
	case the StartupMessage and all subsequent data will be SSL-encrypted. To continue after N,
	send the usual StartupMessage and proceed without encryption.

==> References: http://www.postgresql.org/docs/9.4/static/protocol.html

==> Normally, data should be transfered through libpq in message format, except old COPY
	OUT; COPY OUT was designed to commandeer the communication channel (it just transfers
	data without wrapping it into messages). No other messages can be sent while COPY
	OUT is in progress;

==> PostgreSQL puts all socket into nonblocking mode, and uses Latch to implement blocking
	semantics; this is designed to provide safely interruptible reads and writes;

	StreamServerPort is a wrapper of socket/bind/listen, StreamConnection is a wrapper of accept,
	and StreamClose is a wrapper of close;

	GPDB does have nonblocking socket in use, but they are in fts/walsender/interconnect, the core
	does not enable nonblocking socket indeed(confirmed from code);

	In both PG and GP, there is a internal_flush, this is a wrapper of send, insead of flush; there
	is no socket flush call;

	There is an interesting function in pqcomm.c called pq_putmessage_noblock, which is using blocking
	socket; it is fulfilled by enlarge the PostgreSQL local send buffer;
