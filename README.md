An HTTP/1.1 Client Library written in Vala
==========================================

A lightweight HTTP/1.1 client library built on top of GIO sockets—*not a wrapper around `libsoup`*. It automatically resolves redirections, supports chunked encoding, and can handle compressed *(gzipped)* streams. Additionally, it tries to keep connections alive and reuses the same TCP connection for successive requests to a server.

### Status
This library is written as a personal project in a short amount of time. Though it just works most of the time, it hasn't been tested thoroughly, so expect it to be buggy.

Building from the Source
--------------------------------------------

Before proceeding, make sure you have the essential build tools, `meson`, `ninja`, Glib development package(s) and the Vala compiler installed on your system. Firstly run the `meson setup build` in the project folder:

```shell
$ meson setup build
```

Then, to build the library:
```shell
$ meson compile -C build
```

After a successful compilation, you can find a sample client application located under the `./build/examples` directory. The client application functions like `wget` and downloads any number of given URLs into the working directory:

```shell
$ ./build/http-get \
     https://upload.wikimedia.org/wikipedia/commons/d/dd/Carina_Nebula_Detail.jpg \
     https://developer.gnome.org/documentation/
```

Usage
--------------------------------------------

The following snippet shows the basic usage of the library:

```vala
var http = new Http.Client();

try {
    var response = http.get( "https://api.ipify.org" );
    if ( response.status.code == 200 ){
        stdout.printf(@"My public IP address is: $(response)\n");
    }
} catch (Error err){
    stderr.printf(@"$(err.message)\n");
}
```

>If you haven't compiled and used libraries in Vala before, you can check out [this article](https://wiki.gnome.org/Projects/Vala/SharedLibSample) *(checking the Makefile in the project root might help as well)*.

The library itself consists of a single source file, which means you can easily add it to a project and compile it with the rest of the source files. For instance, you can save the snippet above into a file and compile it directly using the command below:

```vala
$ valac snippet.vala src/http.vala --pkg gio-2.0 --pkg gee-0.8
```

Currently, the library only supports `HEAD`, `GET`, and `POST` methods:

```vala
Response get  (string url);
Response head (string url);  /* For a successful head request,
                              * response body (payload) will be null
                              */
Response post_form (string url, Gee.HashMap<string,string> data);
Response post (string url, string data, Gee.HashMap<string,string>? headers = null);
```

A response object has the following structure:

```js
{
    status : {
        protocol_version: string,
        code: uint,
        text: string
    },
    // Response headers
    headers: Gee.HashMap<string,string>,
    // Response body
    payload : {
        data : uint8[],
        length : ssize_t,
        // When data is compressed, the actual size and the download size will differ.
        download_size: ssize_t
    }
}
```

To post a form, you can use the `post_form` method:

```vala
var http = new Http.Client();

var data = new Gee.HashMap<string,string>();
data["name"]  = "John Doe";
data["email"] = "john@example.com";

try {
    var response = http.post_form( "example.com", data );
    if ( response.status.code == 200 ){
        stdout.printf(@"$(response)\n");
    }
} catch (Error err){
    stderr.printf(@"$(err.message)\n");
}
```

If you want finer control, you can use the `post` method:

```vala
var http = new Http.Client();

var data = new Gee.HashMap<string,string>();
data["name"]  ="John Doe";
data["email"] ="john@example.com";

string encoded_data = Http.encode(data);

// You can provide additional headers to be sent with the request
var post_headers = new Gee.HashMap<string,string>();
post_headers["Content-Type"]   = "application/x-www-form-urlencoded";
post_headers["Content-Length"] = encoded_data.length.to_string();

try {
    var response = http.post( "example.com", encoded_data, post_headers );
    if ( response.status.code == 200 ){
        stdout.printf(@"$(response)\n");
    }
} catch (Error err){
    stderr.printf(@"$(err.message)\n");
}
```

To save bandwidth, you can enable compression by setting the `use_compression` property:

```vala
var http = new Http.Client(){
               use_compression = true // default is false
           };
```

When a compressed response body is receiced, it will be decompressed automatically. The `response.payload.data` array will always contain the decompressed data.

And lastly, you can change the connection timeout by setting the `timeout` property:

```vala
var http = new Http.Client(){
               timeout = 4  // in seconds, default is 8
           };
```