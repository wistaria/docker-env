# docker-env

[English](README.md) | [日本語](README-jp.md)

![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-POSIX-4EAA25?logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-test%20environments-FCC624?logo=linux&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-XQuartz%20optional-000000?logo=apple&logoColor=white)
[![Author](https://img.shields.io/badge/author-Synge%20Todo-blue)](https://github.com/wistaria)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

テスト用の Linux ディストリビューション環境を Docker コンテナとして素早く起動し、コマンドラインからログインするためのスクリプト集です。

ホストユーザーと同じ UID/GID のユーザーをコンテナ内に作成するため、マウントした共有ディレクトリでもファイル所有者を扱いやすい構成になっています。

## Features

- Debian、Ubuntu、Fedora、Arch Linux の Docker 環境を起動
- 初回実行時に専用 Docker イメージを自動ビルド
- 2 回目以降は既存コンテナを再起動して接続
- ホストと同じユーザー名、UID、GID のユーザーを作成
- `~/.ssh-docker`、`~/share`、Git 設定を必要に応じて自動マウント
- SSH、HTTP、HTTPS 用ポートをホスト側の非特権ポートへ公開
- XQuartz が利用できる macOS では X11 アプリケーション向けに `DISPLAY` を設定

## Supported Images

| Script | Base image | Docker image | Container |
| --- | --- | --- | --- |
| `debian.sh` | `debian:latest` | `docker-env-debian` | `docker-env-debian_1` |
| `ubuntu.sh` | `ubuntu:latest` | `docker-env-ubuntu` | `docker-env-ubuntu_1` |
| `fedora.sh` | `fedora:latest` | `docker-env-fedora` | `docker-env-fedora_1` |
| `archlinux.sh` | `archlinux:latest` | `docker-env-archlinux` | `docker-env-archlinux_1` |

## Requirements

- Docker
- 起動済みの Docker デーモン
- macOS で GUI アプリケーションを使う場合は XQuartz

XQuartz がインストールされている場合、スクリプトは `DISPLAY=host.docker.internal:0` を設定します。未インストールでも CUI 用途ではそのまま利用できます。

## Quick Start

使いたいディストリビューションのスクリプトを `sh` で実行します。

```sh
sh ubuntu.sh
```

ほかのディストリビューションも同じです。

```sh
sh debian.sh
sh fedora.sh
sh archlinux.sh
```

初回実行時は Docker イメージをビルドし、コンテナを作成して `/bin/bash` を起動します。2 回目以降は既存のコンテナを再起動して `docker attach` します。

コンテナから抜けるには、通常の `exit` でシェルを終了します。コンテナを停止せずにデタッチする場合は、次のキーを押します。

```text
Ctrl-e e
```

## Container User

コンテナ内には、ホストと同じユーザー名、UID、GID のユーザーが作成されます。

| Item | Value |
| --- | --- |
| User | ホストと同じユーザー名 |
| UID/GID | ホストと同じ UID/GID |
| Home | `/home/<ユーザー名>` |
| Password | `docker` |
| Hostname | ディストリビューション名 |

Debian と Ubuntu では `sudo` がインストールされます。Fedora では `gcc`、`make`、`vim`、`wget` が追加でインストールされます。

## Mounted Paths

ホスト側に次のディレクトリや設定ファイルが存在する場合、コンテナへ自動的にマウントされます。

| Host | Container | Mode |
| --- | --- | --- |
| `~/.ssh-docker` | `~/.ssh` | read-only |
| `~/share` | `~/share` | read-write |
| `~/.config/git` | `~/.config/git` | read-only |
| `~/.gitconfig` | `~/.gitconfig` | read-only |

`~/.config/git` が存在する場合は、`~/.gitconfig` よりも優先されます。SSH 鍵は安全のため `~/.ssh` を直接マウントせず、Docker 用に分けた `~/.ssh-docker` のみをマウントします。

ホームディレクトリは Docker ボリューム `docker-env_1` に保存されます。このボリュームは各スクリプトで共通です。

## Ports

各コンテナでは、次のポートがホストへ公開されます。

| Host | Container | Purpose |
| --- | --- | --- |
| `8022` | `22` | SSH |
| `8080` | `80` | HTTP |
| `8443` | `443` | HTTPS |

## Project Layout

```text
.
├── LICENSE
├── README.md
├── README-jp.md
├── archlinux.sh
├── debian.sh
├── fedora.sh
└── ubuntu.sh
```

## Cleanup

コンテナとイメージを削除するには、対象ディストリビューションに合わせて実行します。

```sh
docker rm docker-env-ubuntu_1
docker rmi docker-env-ubuntu
```

ホームディレクトリ用のボリュームも削除する場合は、次を実行します。

```sh
docker volume rm docker-env_1
```

ボリュームを削除すると、コンテナ内のホームディレクトリに保存したファイルも削除されます。

## Notes

- 各スクリプトは Docker デーモンが起動していない場合に終了します。
- 既に同じコンテナ名が存在する場合は、新規作成せず既存コンテナへ接続します。
- 各コンテナはホストの `8022`、`8080`、`8443` 番ポートを使用するため、既に利用中の場合は起動に失敗することがあります。
- 複数ディストリビューションのコンテナを同時に起動すると、公開ポートが競合します。

## Contributing

Issue や Pull Request は歓迎です。新しいディストリビューションを追加する場合は、既存スクリプトと同じ命名規則、ユーザー作成、マウント、ポート設定に揃えてください。

## License

このプロジェクトは [MIT License](LICENSE) のもとで公開されています。
