package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	listenAddr := os.Getenv("LISTEN_ADDR")
	if len(listenAddr) == 0 {
		listenAddr = ":80"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello World!!")
		fmt.Fprintln(os.Stdout, r)
	}))
	fmt.Println("server starts to run")
	log.Fatal(http.ListenAndServe(listenAddr, mux))
}
