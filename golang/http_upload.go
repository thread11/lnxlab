package main

import (
	"flag"
	"fmt"
	"html/template"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"os"
)

const HTML = `
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=Edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title></title>
<link rel="shortcut icon" href="data:;base64,iVBORw0KGgo=">
</head>
<body>
<form enctype="multipart/form-data" method="post" action="/upload">
<input type="file" name="file" />
<button type="submit">upload</button>
</form>
</body>
</html>
`

func index(response http.ResponseWriter, request *http.Request) {
	var err error

	var tpl *template.Template
	tpl, err = template.New("X").Parse(HTML)
	if err != nil {
		log.Println(err)
	}

	tpl.Execute(response, nil)
}

func upload(response http.ResponseWriter, request *http.Request) {
	var err error

	err = request.ParseMultipartForm(32 << 20)
	if err != nil {
		log.Println(err)
		return
	}

	var file multipart.File
	var header *multipart.FileHeader

	file, header, err = request.FormFile("file")
	if file != nil {
		defer file.Close()
	}
	if header != nil {
		log.Println("Uploaded file name:", header.Filename)
		log.Println("Uploaded file size:", header.Size)
		log.Println("Uploaded file header:", header.Header)
	}
	if err != nil {
		log.Println(err)
		return
	}

	var file2 *os.File
	file2, err = os.OpenFile(header.Filename, os.O_WRONLY|os.O_CREATE, 0666)
	if file2 != nil {
		defer file2.Close()
	}
	if err != nil {
		log.Println(err)
		return
	}

	_, err = io.Copy(file2, file)
	if err != nil {
		log.Println(err)
		return
	}

	http.Redirect(response, request, "/", http.StatusSeeOther)
}

func main() {
	var err error

	log.SetFlags(log.LstdFlags | log.Lshortfile)

	var host string
	var port int

	flag.StringVar(&host, "host", "0.0.0.0", "Host")
	flag.IntVar(&port, "port", 1234, "Port")

	flag.Parse()

	var address string
	address = fmt.Sprintf("%s:%d", host, port)

	http.HandleFunc("/", index)
	http.HandleFunc("/upload", upload)

	log.Printf("ListenAndServe: http://%s/\n", address)

	err = http.ListenAndServe(address, nil)
	if err != nil {
		log.Fatal(err)
	}
}
