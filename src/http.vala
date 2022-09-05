/*---------------------------------------------------------------------------------------------
 *  Copyright (c) 2022 Emre ÖZÇAKIR  
 *  Licensed under the MIT License. See License file in the project root for more information.
 *-------------------------------------------------------------------------------------------*/

namespace Http {

    using Gee;

    public errordomain HttpError {
        MALFORMED_URL,
        BAD_RESPONSE,
        UNSUPPORTED_PROTOCOL,
        UNKNOWN_TRANSFER_LENGTH,
        BAD_CHUNK_SIZE,
        UNKNOWN_PAYLOAD_LENGTH,
        CONNECTION_ERROR
    }

    // Supported Http verbs
    public enum Method
    {
        HEAD, GET, POST;

        public string to_string(){
            switch (this){
                case HEAD: return "HEAD";
                case GET : return "GET";
                case POST: return "POST";
            }
            assert_not_reached();
        }
    }

    /* Read-only Memory Block */
    public class ByteArray
    {
        private StringBuilder storage;

        public ssize_t length { get { return storage.len;} }
        public uint8[] data  { get { return storage.data;} }
        // Download size in bytes for logging purposes
        public ssize_t download_size;

        public ByteArray( owned uint8[] data, ssize_t length, ssize_t down_size = 0)
        {
            storage = new StringBuilder();
            storage.str = (string) (owned) data;
            storage.len = length;
            if ( down_size > 0 ) this.download_size = down_size;
            else this.download_size = length;
        }
    }


    /* CLASS BUFFER
    ------------------------------------------- */
    private class Buffer
    {
        private StringBuilder storage;

        public ssize_t length {
            get { return storage.len; }
        }

        public uint8[] data {
            get { return storage.data; }
        }

        public Buffer(){
            storage = new StringBuilder();
        }

        public void append(uint8[] data){
            storage.append_len( (string) data, data.length );
        }

        public void append_len(uint8[] data, ssize_t length ){
            storage.append_len( (string) data, length );
        }

        public void prepend(uint8[] data){
            storage.prepend_len( (string) data, data.length );
        }

        public uint8[] steal_data(){
            return (uint8[]) (owned) storage.str;
        }

        public void clear(){
            storage = new StringBuilder();
        }
    }


    /* CLASS URL
    ------------------------------------------- */
    public class URL
    {
        public string scheme { get; private set; }
        public string host { get; private set; }
        public uint16 port { get; private set; }
        public string path { get; private set; }
        public string query { get; private set; }
        public string fragment { get; private set; }
        public string raw { get; private set; }

        public URL.from_string( string url_str ) throws HttpError
        {
            RegexMatchFlags NO_FLAG = 0;
            MatchInfo matched;
            // Default values
            this.scheme   = "http";
            this.port     = 80;
            this.path     = "/";
            this.query    = "";
            this.fragment = "";
            this.raw = url_str;

            // [scheme://]host[:port][/path][?query][#fragment]
            var pattern_str = "(?i)^(?:(?<scheme>https?|ftps?)://)?"
                            + "(?<host>(?:[A-Za-z0-9_~-]+)(?:\\.[A-Za-z0-9_~-]+)*(?:\\.[\\w]+)|localhost)"
                            + "(?::(?<port>\\d{1,5}))?(?<path>/[^\\?#]*)?"
                            + "(?<query>\\?[^#]*)?(?<fragment>#.*)?$";

            var pattern = new Regex( pattern_str );

            if ( pattern.match( url_str, NO_FLAG, out matched ) )
            {
                string scheme   = matched.fetch_named("scheme");
                string host     = matched.fetch_named("host");
                string port     = matched.fetch_named("port");
                string path     = matched.fetch_named("path");
                string query    = matched.fetch_named("query");
                string fragment = matched.fetch_named("fragment");

                if ( scheme != "" ){
                    if ( scheme.down() == "https")
                    {
                        this.scheme = "https";
                        this.port = 443;
                    }
                    else if ( scheme.down() == "http")
                    {
                        this.scheme = "http";
                        this.port = 80;
                    }
                    else if ( scheme.down() == "ftps" || scheme.down() == "ftp")
                    {
                        // FTP support is planned
                        throw new HttpError.UNSUPPORTED_PROTOCOL("File transfer protocol is not supported");
                    } else {
                        throw new HttpError.UNSUPPORTED_PROTOCOL("Unknown protocol");
                    }
                }

                this.host = host.down();

                // Value of unmatched trailing groups is null
                if ( port != null && port != "" ){
                    this.port = (uint16) int.parse( port );
                }
                if ( path != null && path != "" ){
                    this.path = path;
                }
                if ( query != null && query != "" ){
                    this.query = query;
                }
                if ( fragment != null && fragment != "" ){
                    this.fragment = fragment;
                }

            } else {
                throw new HttpError.MALFORMED_URL("Malformed URL");
            }
        }/* END CONSTRUCTOR */

        public string to_string(){
            return raw;
        }
    }/* END CLASS */


    /* CLASS STATUS
    ------------------------------------------- */
    public class Status
    {
        public string protocol_version { get; private set; }
        public uint   code { get; private set; }
        public string text { get; private set; }

        internal Status( string version, uint code, string text ){
            this.protocol_version = version;
            this.code = code;
            this.text = text;
        }

        public string to_string(){
            return protocol_version + " " + code.to_string() + " " + text;
        }
    }


    /* CLASS RESPONSE
    ------------------------------------------- */
    public class Response
    {
        public HashMap<string,string> headers { get; private set; }
        public Status status   { get; private set; }
        public ByteArray? payload  { get; private set; default = null; }

        internal Response( Status status, HashMap<string,string> headers, ByteArray? payload ){
            this.status  = status;
            this.headers = headers;
            this.payload = payload;
        }

        public string to_string(){
            if ( payload == null ) return "";
            return (string) payload.data;
        }

    }


    /* CLASS MESSAGE
    ------------------------------------------- */
    private class Message
    {
        public Method method;
        public string str;

        public uint8[] data {
            get { return str.data; }
        }

        public Message( Method method = Method.GET, string str = "" )
        {
            this.method = method;
            this.str = str;
        }
    }

    /* INTERNAL CLASS
    ------------------------------------------- */
    private class Connection
    {
        private SocketConnection socket_conn;
        public string id {get; private set; }

        public Socket socket {
            get { return socket_conn.socket; }
        }

        public InputStream input_stream {
            get { return socket_conn.input_stream; }
        }

        public OutputStream output_stream {
            get { return socket_conn.output_stream; }
        }

        public Connection ( SocketConnection conn, string id ){
            this.socket_conn = conn;
            this.id = id;
        }

        public Response send( Message message ) throws IOError, HttpError
        {
            // Send request
            socket_conn.output_stream.write( message.data );

            // Read response
            return read_response_stream( message.method, socket_conn.input_stream );
        }

    }/* END CLASS */

    /* UTILITY
    ------------------------------------------- */
    private Status parse_status_line (string status_line)
    {
        // Allocated in the stack
        uint8 protocol_version[64];
        uint8 status_text[128];
        uint  status_code = 0;

        status_line.scanf("%63s %d %127[^\n]", protocol_version, &status_code, status_text);

        // Strings get cloned
        return new Status( (string) protocol_version, status_code, (string) status_text );
    }

    /* UTILITY
    ------------------------------------------- */
    private Response read_response_stream ( Method method, InputStream @is ) throws HttpError, IOError
    {
        var headers = new HashMap<string,string> ();
        var buffer = new Buffer();

        var @data_stream = new DataInputStream( @is );
        // default value for close_base_stream is true which will close the underlying
        // inputStream when the wrapper stream goes out of the scope
        @data_stream.set_close_base_stream( false );

        var status = parse_status_line( @data_stream.read_line() );

        string[] transfer_encodings;
        string line;

        // Parse Headers
        while ( true ) {
            line = @data_stream.read_line( null );  /* throws IOError */
            if ( line == "\r" || line == "" ) break;
            var headerComponents = line.split( ":", 2 );
            if ( headerComponents.length == 2 ){
                var header = headerComponents[0].strip().down();
                var value  = headerComponents[1].strip();
                headers[ header ] = value;
            }
        }

        // if a redirection has a body, consume the data before proceeding
        if ( status.code == 301 || /* Moved Permanently */
             status.code == 302 || /* Found */
             status.code == 307 || /* Temporary Redirect */
             status.code == 308    /* Permanent Redirect */
        ){
            if ( headers.has_key("content-length") ){
                var content_length = int.parse( headers["content-length"] );
                // consume the response body
                if ( content_length > 0){
                    var data = new uint8[ content_length ];
                    size_t bytes_read = 0;
                    @data_stream.read_all( data, out bytes_read ); /* throws IOError */
                }
            }
            return new Response( status, headers, null );
        }

        if ( method == Method.HEAD ){
            return new Response( status, headers, null );
        }

        // Retrieve payload
        if ( headers.has_key("transfer-encoding") )
        {
            transfer_encodings = headers["transfer-encoding"].split( "," );
            if ( transfer_encodings.length > 0 ) {
                var last_encoding = transfer_encodings[ transfer_encodings.length -1 ].strip().down();
                if ( last_encoding != "chunked" )
                    throw new HttpError.UNKNOWN_TRANSFER_LENGTH("Transfer size cannot be determined reliably");
            }
            // Chunked transfer encoding
            while (true){
                line = @data_stream.read_line().strip(); /* throws IOError */
                int chunk_size;
                int.try_parse( line, out chunk_size, null, 16 /* Hexadecimal */);

                // End of transmission
                if ( chunk_size == 0 ) break;

                var data = new uint8[ chunk_size ];
                size_t bytes_read = 0;
                @data_stream.read_all( data, out bytes_read ); /* throws IOError */
                buffer.append_len( data, (ssize_t) bytes_read );

                var chunk_end = @data_stream.read_line(); /* throws IOError */
                if ( chunk_end != "\r"){
                    throw new HttpError.BAD_CHUNK_SIZE("Inconsistent chunk size");
                }
            }
        }
        else if ( headers.has_key("content-length") )
        {
            var content_length = int.parse( headers["content-length"] );

            if ( content_length > 0){
                var data = new uint8[ content_length ];
                size_t bytes_read = 0;
                @data_stream.read_all( data, out bytes_read ); /* throws IOError */
                buffer.append_len( data, (ssize_t) bytes_read ); /* throws IOError */
            }
        }
        else
        {
            throw new HttpError.UNKNOWN_PAYLOAD_LENGTH("Payload size cannot be determined reliably");
        }
        // Pack buffer into a reference-counted data structure
        var payload = new ByteArray( buffer.steal_data(), buffer.length );

        if ( headers.has_key("content-encoding") && headers["content-encoding"] == "gzip" )
        {
            var download_size = payload.download_size;
            // Create a GZIP converter stream
            MemoryOutputStream mostream = new MemoryOutputStream ( null );
            ZlibDecompressor decompressor = new  ZlibDecompressor ( ZlibCompressorFormat.GZIP );
            ConverterOutputStream costream = new ConverterOutputStream (mostream, decompressor);
            DataOutputStream dostream = new DataOutputStream (costream);
            dostream.write ( payload.data );
            // Stream needs to be closed before transferring the data ownership
            mostream.close ();
            payload = new ByteArray( mostream.steal_data(), (ssize_t) mostream.get_data_size(), download_size );
        }

        return new Response( status, headers, payload );
    }


    /* UTILITY
    ------------------------------------------- */
    public string encode( HashMap<string,string> data )
    {
        var encoded = new StringBuilder();

        // Add request headers
        if ( data != null )
            foreach( var entry in data ){
                encoded.append( @"$(Uri.escape_string (entry.key))=$(Uri.escape_string (entry.value))&" );
            }
        // Remove trailing ampersand (&)
        unowned uint8[] byte_array = encoded.data;
        byte_array[encoded.len-1] = 0;

        return (owned) encoded.str;
    }


    /* CLASS CLIENT
    ------------------------------------------- */
    public class Client : Object
    {
        public bool allow_cookies { get; set; default = false; } // Not implemented yet
        public bool use_compression {
            get {
                return headers.has_key("Accept-Encoding");
            }
            set {
                if ( value ) headers["Accept-Encoding"] = "gzip";
                else headers.unset("Accept-Encoding");
            }
        }
        public uint timeout         { get; set; default = 8;  }
        public HashMap<string,string> headers;

        // Cache connections to reuse them
        private HashMap<string, Connection> connection_pool;

        public Client()
        {
            connection_pool = new HashMap<string, Connection> ();

            headers = new HashMap<string,string>();
            // To keep connection alive
            headers["Connection"] = "keep-alive";
        }

        /* METHOD
        ------------------------------------------- */
        // hides inherited method GLib.Object.get
        public new Response @get (string raw_url ) throws HttpError, IOError, Error
        {
            return deliver_message( Method.GET, raw_url );
        }

        /* METHOD
        ------------------------------------------- */
        public Response post (string raw_url, string data, HashMap<string,string>? post_headers = null) throws HttpError, IOError, Error
        {
            return deliver_message( Method.POST, raw_url, post_headers, data );
        }

        /* METHOD
        ------------------------------------------- */
        public Response post_form (string raw_url, HashMap<string,string> data) throws HttpError, IOError, Error
        {
            string encoded_data = Http.encode(data);

            var post_headers = new Gee.HashMap<string,string>();
            post_headers["Content-Type"]   = "application/x-www-form-urlencoded";

            return post( raw_url, encoded_data, post_headers );
        }

        /* METHOD
        ------------------------------------------- */
        public Response head ( string raw_url ) throws HttpError, IOError, Error
        {
            return deliver_message( Method.HEAD, raw_url );
        }

        /* INTERNAL METHOD
        ------------------------------------------- */
        private Response deliver_message( Method method, string raw_url, HashMap<string,string>? headers = null, string? body = null ) throws HttpError, IOError, Error
        {
            Response response;

            URL url = new URL.from_string( raw_url );
            // get_connection: returns a previously used connection if available; if not, creates a new one
            Connection connection = get_connection( url );

            // build http message
            var message_str = "";
            message_str += @"$(method) $(url.path)$(url.query)$(url.fragment) HTTP/1.1\r\n";
            message_str += @"Host: $(url.host)\r\n";
            // Add client headers
            foreach (var entry in this.headers) message_str += @"$(entry.key): $(entry.value)\r\n";
            // Add additional headers if present
            if ( headers != null ){
                foreach (var entry in headers) message_str += @"$(entry.key): $(entry.value)\r\n";
            }
            // Add content length if there is a body
            if ( body != null ){
                message_str += @"Content-Length: $(body.length)\r\n";
            }
            message_str += "\r\n"; // Mark end of the header section
            // Add body
            if ( body != null ) message_str += body;

            var message = new Message( method, message_str );
            try {
                response = connection.send( message );
                // Handle redirections
                if ( response.status.code == 301 || /* Moved Permanently */
                     response.status.code == 302 || /* Found */
                     response.status.code == 307 || /* Temporary Redirect */
                     response.status.code == 308    /* Permanent Redirect */
                ){
                    if ( !response.headers.has_key( "location" ) )
                        throw new HttpError.BAD_RESPONSE("A redirection without a location field");

                    response = deliver_message( method, response.headers["location"], headers, body );
                }
            } catch (Error err )
            {
                if (err is IOError.CLOSED ){
                    connection_pool.unset( connection.id );
                    response = deliver_message( method, raw_url, headers, body );
                } else throw new HttpError.CONNECTION_ERROR(@"$(err.domain):$(err.code) $(err.message)\n");
            }

            return response;
        }

        /* UTILITY
        ------------------------------------------- */
        private Connection get_connection( URL url ) throws IOError, Error
        {
            Connection connection;

            var id = url.scheme + "://" + url.host;
            // check if a connection is already present
            if ( connection_pool.has_key( id ) ) return connection_pool[ id ];

            var client = new SocketClient ();
            client.set_timeout( timeout );
            client.event.connect( on_socket_client_event );

            // establish a secure connection
            if ( url.scheme == "https" ) client.set_tls(true);

            var connectable = NetworkAddress.parse( url.host, url.port );
            // passes a newly created SocketConnection to the constructor
            connection = new Connection( client.connect ( connectable ), id );

            // add connection to the pool
            connection_pool[ id ] = connection;

            return connection;
        }

        /* CALLBACK
        ------------------------------------------- */
        private static void on_socket_client_event( GLib.SocketClientEvent event,
                                                    GLib.SocketConnectable? connectable,
                                                    GLib.IOStream? ios)
        {
            // get TlsClientConnection to bind signals and set flags prior to handshake
            if (event == SocketClientEvent.TLS_HANDSHAKING) {
                ((TlsClientConnection) ios).accept_certificate.connect( on_accept_certificate) ;
            }
        }

        /* CALLBACK
        ------------------------------------------- */
        private static bool on_accept_certificate( GLib.TlsConnection cx,
                                            GLib.TlsCertificate cert,
                                            GLib.TlsCertificateFlags flags)
        {
            // skip certificate validation
            return true;
        }

    }/* END CLASS */

}/* END NAMESPACE */
