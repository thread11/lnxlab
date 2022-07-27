package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"strconv"
	"strings"
	"sync"
)

func ParseHost(host string) ([]string, error) {
	var hosts []string
	hosts = make([]string, 0)

	if strings.Contains(host, ",") {
		var fields []string
		fields = strings.Split(host, ",")

		var value string
		for _, value = range fields {
			hosts = append(hosts, value)
		}
	} else {
		hosts = append(hosts, host)
	}

	return hosts, nil
}

func ParsePort(port string) ([]string, error) {
	var err error

	var ports []string
	ports = make([]string, 0)

	{
		if strings.Contains(port, ",") {
			var fields []string
			fields = strings.Split(port, ",")

			var value string
			for _, value = range fields {
				ports = append(ports, value)
			}
		} else {
			ports = append(ports, port)
		}
	}

	var ports2 []string
	ports2 = make([]string, 0)

	{
		var value string
		for _, value = range ports {
			if strings.Contains(value, "-") {
				var fields []string
				fields = strings.Split(value, "-")

				var min_port int64
				var max_port int64

				min_port, err = strconv.ParseInt(fields[0], 10, 64)
				if err != nil {
					return nil, err
				}
				max_port, err = strconv.ParseInt(fields[1], 10, 64)
				if err != nil {
					return nil, err
				}

				var i int64
				for i = min_port; i <= max_port; i++ {
					ports2 = append(ports2, strconv.FormatInt(i, 10))
				}
			} else {
				ports2 = append(ports2, value)
			}
		}
	}

	return ports2, nil
}

func Listen(host string, ports []string) {
	var wg sync.WaitGroup

	var value string
	for _, value = range ports {
		wg.Add(1)

		go func(port string) {
			defer wg.Done()

			var err error

			var address string
			address = fmt.Sprintf("%s:%s", host, port)

			log.Printf("ListenAndServe: http://%s/\n", address)

			var mux *http.ServeMux
			mux = http.NewServeMux()

			mux.HandleFunc("/", func(response http.ResponseWriter, request *http.Request) {
				var msg string
				msg = fmt.Sprintf("%s -> :%s\n", request.RemoteAddr, port)
				log.Printf(msg)
				response.Write([]byte(msg))
			})

			err = http.ListenAndServe(address, mux)
			if err != nil {
				log.Printf("%s -> error!!! -> %v\n", address, err)
			}
		}(value)
	}

	wg.Wait()
}

func Connect(hosts []string, ports []string) {
	var wg sync.WaitGroup

	var value string
	var value2 string

	for _, value = range hosts {
		for _, value2 = range ports {
			wg.Add(1)

			go func(host string, port string) {
				defer wg.Done()

				var err error

				var address string
				address = fmt.Sprintf("%s:%s", host, port)

				var conn net.Conn
				conn, err = net.Dial("tcp", address)
				if conn != nil {
					defer conn.Close()
				}
				if err == nil {
					log.Printf("%s -> connected\n", address)
				} else {
					log.Printf("%s -> error!!! -> %v\n", address, err)
				}
			}(value, value2)
		}
	}

	wg.Wait()
}

func main() {
	var err error

	log.SetFlags(log.LstdFlags | log.Lshortfile)

	var listen bool
	var connect bool
	var host string
	var port string

	flag.BoolVar(&listen, "listen", false, "Listen")
	flag.BoolVar(&connect, "connect", false, "Connect")
	flag.StringVar(&host, "host", "0.0.0.0", "Host")
	flag.StringVar(&port, "port", "0", "Port")

	flag.Parse()

	host = strings.Replace(host, " ", "", -1)
	host = strings.Replace(host, "|", ",", -1)
	host = strings.Replace(host, "，", ",", -1)
	host = strings.Replace(host, "、", ",", -1)

	port = strings.Replace(port, " ", "", -1)
	port = strings.Replace(port, "/", ",", -1)
	port = strings.Replace(port, "|", ",", -1)
	port = strings.Replace(port, "，", ",", -1)
	port = strings.Replace(port, "、", ",", -1)
	port = strings.Replace(port, "~", "-", -1)

	log.Println("host:", host)
	log.Println("port:", port)

	var hosts []string
	hosts, err = ParseHost(host)
	if err != nil {
		panic(err)
	}

	var ports []string
	ports, err = ParsePort(port)
	if err != nil {
		panic(err)
	}

	log.Println("hosts:", hosts)
	log.Println("ports:", ports)

	if listen {
		Listen(host, ports)
	}

	if connect {
		Connect(hosts, ports)
	}

	if !listen && !connect {
		Listen(host, ports)
	}
}
