FROM golang:1.16 as builder

# builderを使うほどではない気がするが
ADD https://github.com/benbjohnson/litestream/releases/download/v0.3.13/litestream-v0.3.13-linux-amd64.tar.gz /tmp/litestream.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz

FROM grafana/grafana-enterprise

COPY --from=builder /usr/local/bin/litestream /usr/local/bin/litestream

COPY litestream.yml /etc/litestream.yml

# 一時的にrootユーザーに切り替え
USER root

# CloudRunは8000ポートを使用するため、Grafanaのポートを変更
RUN sed -i -e 's/\;http_port = 3000/http_port = 8080/' /etc/grafana/grafana.ini 
RUN sed -i -e 's/\;protocol = http/protocol = http/' /etc/grafana/grafana.ini 

# スタートアップスクリプトを追加
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 元のユーザーに戻す
USER grafana

# スタートアップスクリプトをエントリーポイントとして設定
ENTRYPOINT ["/start.sh"]
