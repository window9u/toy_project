package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	listenAddr := os.Getenv("LISTEN_ADDR")
	logPath := os.Getenv("LOG_PATH")
	if len(listenAddr) == 0 {
		listenAddr = ":8080"
	}
	if len(logPath) == 0 {
		logPath = "/data/log.txt"
	}
	logFile, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer logFile.Close()
	logger := log.New(logFile, "", log.Ldate|log.Ltime|log.Lmicroseconds)

	mux := http.NewServeMux()
	mux.HandleFunc("/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello %s!!", r.Host)
		logger.Printf("host: %s, method: %s, url: %s", r.Host, r.Method, r.URL)
	}))
	fmt.Println("server starts to run")
	logger.Printf("server run on %s", listenAddr)
	log.Fatal(http.ListenAndServe(listenAddr, mux))
	logger.Printf("server stop")
}
