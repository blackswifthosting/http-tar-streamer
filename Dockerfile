FROM golang:1.21 AS builder
WORKDIR /app
COPY . /app/
RUN make linux_amd64 && ls -lR /app/bin

FROM ubuntu:22.04
RUN mkdir -p /var/www/html
WORKDIR /var/www/html
COPY --from=builder /app/bin/http-tar-streamer-linux-amd64 /usr/local/bin/http-tar-streamer
EXPOSE 8080
CMD ["http-tar-streamer"]

