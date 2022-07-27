package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
)

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

	var fileServerHandler http.Handler
	fileServerHandler = http.FileServer(http.Dir("."))
	http.Handle("/", fileServerHandler)

	log.Printf("ListenAndServe: http://%s/\n", address)

	err = http.ListenAndServe(address, nil)
	if err != nil {
		log.Fatal(err)
	}
}
