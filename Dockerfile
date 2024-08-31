FROM alpine:edge as builder

ARG BUILD_VERSION=0.0.0

RUN apk add --no-cache "zig=~0.13"

WORKDIR /work

COPY . .

RUN zig build -Doptimize=ReleaseSafe -Dversion=${BUILD_VERSION} --summary all

FROM scratch
LABEL maintainer="emneo <emneo@kreog.com>"

WORKDIR /

COPY --from=builder /work/zig-out/bin/liskvork .

ENTRYPOINT ["/liskvork"]
