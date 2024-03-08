# http-tar-streamer

`http-tar-streamer` is a simple HTTP server that allows you to stream tar archives of directories over HTTP. It supports both uncompressed and gzip-compressed tar archives.

## Features

- Streams tar archives of directories over HTTP, without requiring any extra space on server
- Uses minimal resources, with memory consumption under 10MB
- Supports both uncompressed and gzip-compressed tar archives
- Provides a simple web interface that displays a list of directories in the current working directory when you navigate to the root URL "/"
- Allows you to download a tar archive of any directory by navigating to its URL with a .tar or .tar.gz extension
- Cowardly refuses to serve files if the filename contains any separator like "/" to prevent directory traversal attacks

## Usage

To use http-tar-streamer, you can either run it directly from the command line or build it as a standalone binary.

### Running from the command line

To run http-tar-streamer from the command line, use the following command:

```sh
go run main.go
```

This will start the server on port 8080 and serve the current working directory.

## Building as a standalone binary

To build http-tar-streamer as a standalone binary, use the following command:

```sh
go build -ldflags "-s -w" -o bin/http-tar-streamer main.go
```

This will create a standalone binary named http-tar-streamer in the current working directory. You can then run the binary using the following command:

```sh
./bin/http-tar-streamer
```

This will start the server on port 8080 and serve the current working directory.

## Downloading tar archives

To download a tar archive of a directory, navigate to the URL for that directory with a .tar or .tar.gz extension. For example, if you have a directory named mydir in the current working directory, you can download a tar archive of that directory using the following URLs:

- http://localhost:8080/mydir.tar *(uncompressed tar archive)*
- http://localhost:8080/mydir.tar.gz *(gzip-compressed tar archive)*

You can also use curl to download the tar archive and get the download speed. For example:

```sh 
curl -o /dev/null -s -w %{speed_download} http://localhost:8080/mydir.tar
```

This will download the tar archive to /dev/null and print the download speed in bytes per second.

## Limitations

http-tar-streamer does not support streaming tar archives of individual files, only directories.
