FROM golang:1.15-alpine as builder

# 使用清华大学镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

RUN apk update \
    && apk add --no-cache git ca-certificates make bash yarn nodejs

RUN go env -w GO111MODULE=on && \
    go env -w GOPROXY=https://goproxy.cn,direct

WORKDIR /app

RUN git clone https://github.com/YuY-developer/gocron.git \
    && cd gocron \
    && git checkout commadn-long \
    && yarn config set ignore-engines true \
    && make install-vue \
    && make build-vue \
    && make statik \
    && CGO_ENABLED=0 make gocron

FROM alpine:3.12
# 使用清华大学镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
RUN apk update \
    apk add --no-cache ca-certificates tzdata \
    && addgroup -S app \
    && adduser -S -g app app

RUN cp /etc/localtime /etc/localtime

WORKDIR /app

COPY --from=builder /app/gocron/bin/gocron .

RUN chown -R app:app ./

EXPOSE 5920

USER app

ENTRYPOINT ["/app/gocron", "web"]
