FROM alpine:3.18

RUN apk add --no-cache bash curl

WORKDIR /app

COPY upload.sh /app/upload.sh
COPY video.mp4 /app/video.mp4

RUN chmod +x /app/upload.sh

ENTRYPOINT ["/app/upload.sh"]
