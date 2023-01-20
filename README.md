# MuseScore MEI Export Plugin

The MuseScore MEI Export plugin will export MuseScore documents to
MEI. This requires an internet connection, since it uses a remote server
to do the conversion. 

The source code for the remote server is available in this repository.

The plugin functions by converting the MuseScore document, transparently
converts it to MusicXML, and then sends the resulting document to the remote
server running Verovio. The conversion is done through Verovio, and then
the resulting MEI file is sent back to MuseScore and then saved in an output
directory that the user chooses.

You can use the default conversion server, or, if you want to run your own, you
can install it and set it up, and change it in the plugin.

## Installing the Plugin

**Note:** The plugin currently only works with MuseScore 3. The plugin system
in MuseScore 4 is broken right now. 

The plugin code can be found in the `plugin/export_mei` folder. Follow the
[instructions on the MuseScore website](https://musescore.org/en/handbook/3/plugins#installation) 
for installing plugins.

## Installing the Export Server

The export server is written in Python. The easiest way to get started is
by using Poetry for dependency management and virtual environments. 

After downloading the source code for this project, run:

    $ poetry install

This should install the dependencies. From there you can run a development version
of the server with:

    $ sanic export_server.server:app --port 8009 --fast --dev

The server itself is very simple, so you can also use the code
in the export server to write your own version using tools you know.

To support the plugin's request format, your own server should use the
`multipart/form-data` upload format in a `POST` request. 

