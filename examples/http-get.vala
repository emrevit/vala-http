/*---------------------------------------------------------------------------------------------
 *  Copyright (c) 2022 Emre ÖZÇAKIR  
 *  Licensed under the MIT License. See License file in the project root for more information.
 *-------------------------------------------------------------------------------------------*/

using Gee;
using Http;

// Client version
const string version = "0.1";

class Options
{
    [CCode (array_length = false, array_null_terminated = true)]
    public string[] urls;
    public string output;
    public int  timeout = 8;
    public bool display_version = false;
    public bool is_verbose = false;
    public bool quiet = false;

    public static Options? Parse( string[] args, bool exit_on_error )
    {
        var options = new Options();

        OptionEntry[] option_defs = {
            {
                "version", '\0', OptionFlags.NONE, OptionArg.NONE, &options.display_version,
                "Display version number and exit", null
            },
            {
                "timeout", 't', OptionFlags.NONE, OptionArg.INT, &options.timeout,
                "Set the connection timeout", "SECONDS"
            },
            {
                "verbose", 'v', OptionFlags.NONE, OptionArg.NONE, &options.is_verbose,
                "Be verbose", null
            },
            {
                "quiet", 'q', OptionFlags.NONE, OptionArg.NONE, &options.quiet,
                "Suppress all output", null
            },
            {
                OPTION_REMAINING, '\0', OptionFlags.NONE, OptionArg.STRING_ARRAY, &options.urls,
                "URLs to be downloaded", "URLS..."
            },
            { null }
        };

        try {
            var context = new OptionContext ();
            context.set_help_enabled (true);
            context.add_main_entries ( option_defs, null );
            context.parse (ref args);
        }
        catch (OptionError e)
        {
            stderr.printf ("error: %s\n", e.message);
            stderr.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);

            if ( exit_on_error ) Process.exit (0);
            else return null;
        }

        return options;
    }
}/* END CLASS */


class Utilities
{
    private static HashMap<string, string> mime_types;

    static construct {
        mime_types = new HashMap<string, string>();
        mime_types["text/css"] = "css";
        mime_types["text/csv"] = "csv";
        mime_types["text/html"] = "html";
        mime_types["text/javascript"] = "js";
        mime_types["text/plain"] = "txt";
        mime_types["text/xml"] = "xml";
        mime_types["image/gif"] = "gif";
        mime_types["image/jpeg"] = "jpg";
        mime_types["image/png"] = "png";
        mime_types["image/svg+xml"] = "svg";
        mime_types["audio/wav"] = "wav";
        mime_types["video/mp4"] = "mp4";
        mime_types["application/javascript"] = "js";
        mime_types["application/json"] = "json";
        mime_types["application/pdf"] = "pdf";
        mime_types["application/zip"] = "zip";
        mime_types["application/ogg"] = "ogg";
        mime_types["application/font-woff"] = "woff";
        mime_types["application/font-ttf"] = "ttf";
        mime_types["application/vnd.ms-fontobject"] = "eot";
        mime_types["application/font-otf"] = "otf";
        mime_types["application/wasm"] = "wasm";
    }

    /* UTILITY */
    public static string gen_filename( Http.URL url, string content_type )
    {
        // initialize static members of the class
        // Bug #543189 (https://gitlab.gnome.org/GNOME/vala/-/issues/11)
        typeof( Utilities ).class_ref();

        string ext = null;
        string type = content_type.split(";", 2)[0].down();

        if ( mime_types.has_key(type) ) ext = mime_types.get( type );

        Regex pattern = /^(\/?.*\/)([^\/]*)$/;
        MatchInfo matched;
        string basename = "";
        string dirpath  = "";

        if ( pattern.match( url.path, 0, out matched ) )
        {
            dirpath = matched.fetch(1);
            dirpath = Uri.unescape_string( dirpath );
            basename = matched.fetch(2);
            basename = Uri.unescape_string( basename );
            // Characters not allowed in filenames on Windows
            var filename_filter = /<|>|:|"|\\|\||\?|\*/;

            if ( basename == "" )
            {
                var tmp = dirpath.substring(1); // remove leading '/' char
                tmp = tmp.replace("/", "_");
                tmp = filename_filter.replace( tmp, tmp.length, 0, "" );

                if (dirpath == "/" || tmp.length < 2 ){
                    if ( ext != null ) return @"index.$ext";
                    else return "index";
                } else {
                    if ( ext != null ) return @"$(tmp)index.$ext";
                    else return @"$(tmp)index";
                }
            } else {
                pattern = /([^.]*)$/;
                var parsed_ext = "";

                if ( pattern.match( url.path, 0, out matched ) ){
                    parsed_ext = matched.fetch(1);
                }
                var tmp = filename_filter.replace( basename, basename.length, 0, "" );
                if ( ext != parsed_ext ) return @"$tmp.$ext";
                else return tmp;
            }
        }
        // Not likely to reach here
        return "index.html";
    }

    /* UTILITY */
    public static string print_download_size( ssize_t length )
    {
        if ( length < 1024 ){
            return length.to_string() + " Bytes";
        } else if ( length < 1048576 ) {
            return "%.1f KB".printf( length/ 1024.0 );
        } else {
            return "%.2f MB".printf( length/ 1048576.0 );
        }
    }

}/* END CLASS */


int main( string[] args )
{
    var options = Options.Parse( args, true /*Exit on parsing errors*/ );

    // Display version info and exit
    if ( options.display_version ){
        stdout.printf (@"http-client $(version)\nCopyright (C) 2022 Emre ÖZÇAKIR\n");
        Process.exit (0);
    }

    var url_list = new ArrayList<URL>();

    // Rule out the faulty URLs in the list
    foreach (string url in options.urls){
        try {
            var parsed_url = new URL.from_string( url );
            url_list.add( parsed_url );
        } catch ( HttpError err ) {
            if ( !options.quiet ){
                stderr.printf ( @"[!] $(url): $(err.message)\n" );
            }
        }
    }

    var http = new Http.Client(){
        timeout = options.timeout,
        use_compression = true
    };

    http.headers["User-Agent"] = "HttpClient/0.1.0";

    foreach (URL url in url_list)
    {
        if ( !options.quiet ){
            stdout.printf ( @"[+] $(url.host) GET $(url.path)$(url.query)$(url.fragment)\n" );
        }

        try { // Make the request
            var response = http.get( @"$url" );

            if ( !options.quiet ) stdout.printf ( @"    $(response.status)\n" );

            if ( response.status.code == 200 && response.payload != null ){

                if ( response.headers.has_key("content-type") )
                {
                    string filename  = Utilities.gen_filename( url, response.headers["content-type"] );
                    string down_size = Utilities.print_download_size(response.payload.download_size);
                    bool is_compressed = response.payload.length != response.payload.download_size;

                    if ( !options.quiet ) stdout.printf ( @"    $(down_size) $(is_compressed?"(compressed) ":"")downloaded; saving to: $(filename)\n\n" );
                    FileUtils.set_data( @"$filename", response.payload.data );
                }
            }

            // Print response heders
            if ( !options.quiet && options.is_verbose){
                stdout.printf ( @"   ┌───────────────────────┐\n" );
                stdout.printf ( @"   │ Response Headers      │\n" );
                stdout.printf ( @"   └───────────────────────┘\n" );
                response.headers.foreach( entry =>{
                    stdout.printf( @"    $(entry.key): $(entry.value)\n" );
                    return true;
                });
            }

        } catch ( Error err ){
            if ( !options.quiet ) stderr.printf ( @"[!] $(url): $(err.message)\n" );
        }
    }// END FOREACH

    return 0;
}
