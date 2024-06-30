#!/bin/sh
set -e # 失敗したら終了する

# 起動時にすでにデータベースファイルが存在する場合は、一旦バックアップする
if [ -f /var/lib/grafana/grafana.db ]; then
  mv /var/lib/grafana/grafana.db /var/lib/grafana/grafana.db.bk
fi

# replicaが存在したらリストアする
litestream restore -if-replica-exists -config /etc/litestream.yml /var/lib/grafana/grafana.db

# replicaのレストアができた && バックアップしたデータベースファイルが存在する場合は削除する
if [ -f /var/lib/grafana/grafana.db ]; then
  if [ -f /var/lib/grafana/grafana.db.bk ]; then
    rm /var/lib/grafana/grafana.db.bk
  fi
else
  # replicaのレストアができなかった場合 && バックアップしたデータベースファイルがあれば元に戻す
  if [ -f /var/lib/grafana/grafana.db.bk ]; then
    mv /var/lib/grafana/grafana.db.bk /var/lib/grafana/grafana.db
  fi
fi

# litestreamを起動しつつGrafanaを起動する
exec litestream replicate -exec "/run.sh"
