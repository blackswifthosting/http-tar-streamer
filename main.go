package main

import (
	"archive/tar"
	"compress/gzip"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
)

var dir string

func main() {
	var err error
	app := fiber.New()
	port := 8080

	envPort := os.Getenv("LISTEN_PORT")
	if envPort != "" {
		port, err = strconv.Atoi(envPort)
		if err != nil {
			fmt.Println(err)
			return
		}
	}

	// Get the current directory
	dir, err = os.Getwd()
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Printf("Serving current directory: %s\n", dir)

	// Activate logging for GoFiber
	// https://docs.gofiber.io/api/middleware/logger/
	app.Use(logger.New())

	// Display the list of files
	app.Get("/", appIndex)
	app.Get("/:archivename", appDownloadFolder)

	// Start the server
	app.Listen(fmt.Sprintf(":%d", port))
}

func appIndex(c *fiber.Ctx) error {

	// List all files in the current directory
	files, err := os.ReadDir(dir)
	if err != nil {
		return c.Status(http.StatusInternalServerError).SendString(err.Error())
	}

	// Create a list of files
	var list string
	for _, file := range files {
		// Only list directories
		if file.IsDir() {
			fileName := file.Name()
			list += fmt.Sprintf(`%s <a href="/%s.tar">tar</a> <a href="/%s.tar.gz">tar.gz</a><br>`, fileName, fileName, fileName)
		}
	}

	// Serve the list of files as the HTTP response
	c.Response().Header.Set("Content-Type", "text/html")
	return c.SendString(list)
}

func appDownloadFolder(c *fiber.Ctx) error {
	archivename := c.Params("archivename")
	filename := archivename
	compression := false

	// Cowardly refuse to serve files if the filename contains any separator like "/"
	if filepath.Base(archivename) != archivename {
		return c.Status(http.StatusBadRequest).SendString("Invalid file name")
	}

	// If ext is .gz remove it from the foldername
	if filepath.Ext(archivename) == ".gz" {
		compression = true
		filename = archivename[:len(archivename)-len(filepath.Ext(archivename))]
	}

	// Check that extension is .tar and remove it from the foldername
	if filepath.Ext(filename) != ".tar" {
		return c.Status(http.StatusBadRequest).SendString("Invalid file extension")
	}

	// Remove the .tar extension from the foldername
	foldername := filename[:len(filename)-len(filepath.Ext(filename))]
	folderpath := filepath.Join(dir, foldername)

	// Check that the folder exists
	if _, err := os.Stat(folderpath); os.IsNotExist(err) {
		return c.Status(http.StatusNotFound).SendString("Folder not found")
	}

	// Create a new data stream for the tar file
	pr, pw := io.Pipe()

	// Create a new goroutine to write the tar file into the data stream
	go func() {
		defer pw.Close()

		var tw *tar.Writer
		if compression {
			// Create a new gzip.Writer to compress the tar file
			gw := gzip.NewWriter(pw)
			defer gw.Close()

			// Create a new tar.Writer to write the tar file
			tw = tar.NewWriter(gw)
		} else {
			// Create a new tar.Writer to write the tar file
			tw = tar.NewWriter(pw)
		}

		// Add files to the tar file
		err := tarFolder(foldername, tw)
		if err != nil {
			fmt.Println(err)
		}

		// Close the tar.Writer to write the tar footer
		tw.Close()
	}()

	// Set the Content-Type header for the tar file
	c.Response().Header.Set("Content-Type", "application/x-tar")

	// Set the Content-Encoding header for the compressed tar file
	if compression {
		c.Response().Header.Set("Content-Encoding", "gzip")
	}

	// Set the HTTP response body as the data stream of the tar file
	c.Response().SetBodyStream(pr, -1) // -1 means the content length is unknown (streaming data)

	// Return nil to indicate that the response has been successfully sent
	return nil
}

func tarFolder(directory string, tw *tar.Writer) error {

	// Walk through the directory and add all files to the tar file
	err := filepath.Walk(directory, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		header, err := tar.FileInfoHeader(info, path)
		if err != nil {
			return err
		}

		header.Name = path
		if info.IsDir() {
			header.Name += "/"
		}

		err = tw.WriteHeader(header)
		if err != nil {
			return err
		}

		if !info.IsDir() {
			f, err := os.Open(path)
			if err != nil {
				return err
			}
			defer f.Close()

			_, err = io.Copy(tw, f)
			if err != nil {
				return err
			}
		}

		return nil
	})

	return err
}
