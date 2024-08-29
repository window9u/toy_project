# start from the official Go image
FROM golang:1.22-alpine AS builder

# set the working directory inside the container
WORKDIR /app

# copy go mod and sum files
COPY go.mod ./

# download all dependencies
RUN go mod download

# copy the source code into the container
COPY . .

# build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# start a new stage from scratch
FROM alpine:latest

# set the working directory
WORKDIR /app

# make directory for log file
RUN mkdir -p /data && chmod 755 /data

# copy the binary from builder
COPY --from=builder /app/main .

# expose port 80
EXPOSE 80

# set env
ENV LISTEN_ADDR=:80
ENV LOG_FILE = log.txt

# command to run the executable
CMD ["./main"]