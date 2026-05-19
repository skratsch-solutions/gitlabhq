---
stage: Sec
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: LinuxパッケージインスタンスのホストにOpenBaoをインストール
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9669) (GitLab 19.0で実験として)。

{{< /history >}}

> [!warning]
> この機能は[実験的機能](../../policy/development_stages_support.md#experiment)であり、予告なく変更される可能性があります。この機能は、公開テストや本番環境での使用にはまだ対応していません。

ローカルのKubernetesディストリビューションを使用して、OpenBaoをGitLabのLinuxパッケージインストールと同じホストにインストールします。この設定では、次のようになります:

- OpenBaoは、ローカルのKubernetesディストリビューション上で同じホストで動作します。
- GitLabに組み込まれているNGINXは、OpenBao外部URLのTLS終端リバースプロキシとして機能します。
- GitLabアプリケーションは、Kubernetesが公開するエンドポイントを使用して、OpenBao内部URLに接続します。

## 前提条件 {#prerequisites}

前提条件: 

- GitLab 19.0以降がLinuxパッケージでインストールされており、管理者アクセス権があること。
- 同じホストにローカルKubernetesディストリビューションがインストールされていること。[要件](#requirements)を参照してください。
- ホスト上で`helm`および`kubectl`が利用可能であること。
- OpenBaoドメインをホストのパブリックIPアドレスにポイントするDNSレコード。

## 要件 {#requirements}

OpenBaoをインストールする前に、お使いのKubernetesディストリビューションが以下の要件を満たしていることを確認してください:

- [OpenBaoのサイジング推奨事項](_index.md#sizing-recommendations)は、Linuxパッケージインスタンスの要件およびKubernetesクラスターの要件に加えて満たす必要があります。
- 配置されたKubernetesは、GitLabがすでに使用しているポートに接続しようとしないようにしてください。多くの小規模Kubernetesディストリビューションは、デフォルトでポート80および443にバインドするロードバランサーをインストールします。Linuxパッケージで管理されているNGINXがすでにそれらのポートをリスナーしているため、そのようなコンポーネントは無効にしてください。
- 配置されたKubernetesは、Linuxパッケージインスタンスとネットワークを共有している必要があります。これにより、Linuxパッケージで管理されているNGINXが外部OpenBaoトラフィックをOpenBaoサービスにルーティングし、そこからのリクエストをリスナーできます。Linuxパッケージインスタンスは、サービスがKubernetesの`LoadBalancer`または`NodePort`を通じて公開されているかどうかは気にしません。両方が共有ネットワーク内で到達可能である限りです。

## はじめる前 {#before-you-begin}

はじめる前:

1. Kubernetes CNI (ポッドネットワーク) のCIDRを収集します。後でPostgreSQLの認証を設定するために必要です。
1. LinuxパッケージインスタンスとKubernetes間で共有されているネットワークインターフェースのIPアドレス（`<SHARED_NETWORK_IP>`）を収集します。後でいくつかの設定値に必要です。
1. OpenBaoのインストールを試みる前に、Kubernetesディストリビューションが完全に動作していることを確認してください。
1. お使いの`kubectl`コンテキストがこのクラスターに設定されていること（`KUBECONFIG`が正しく設定されていること）を確認してください。

## OpenBaoのPostgreSQLデータベースをプロビジョニングする {#provision-the-openbao-postgresql-database}

`gitlab-psql`はUnixソケット経由で接続し、TCPリスナーを必要としないため、`gitlab-ctl reconfigure`の前にこれらのコマンドを実行できます。

OpenBaoのPostgreSQLデータベースをプロビジョニングするには:

1. OpenBaoデータベースユーザーの強力なパスワードを選択してください。このパスワードは、このセクションの最後のステップでKubernetesシークレットに使用します。

1. OpenBaoデータベースユーザーを作成します:

   ```shell
   sudo gitlab-psql \
     -c "CREATE USER openbao WITH PASSWORD '<strong-password>';"
   ```

1. OpenBaoデータベースを作成します:

   ```shell
   sudo gitlab-psql \
     -c "CREATE DATABASE openbao OWNER openbao;"
   ```

1. Kubernetesネームスペースと、データベースパスワードをHelmチャートに渡すシークレットを作成します:

   ```shell
   kubectl create namespace openbao

   kubectl create secret generic openbao-db-secret \
     --namespace openbao \
     --from-literal=password='<strong-password>'
   ```

## Helmを使用してOpenBaoをインストールする {#install-openbao-by-using-helm}

Helmを使用してOpenBaoをインストールするには:

1. GitLab Helmリポジトリを追加します。

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   ```

1. プレースホルダーの値を実際のドメインとIPアドレスに置き換えて、次の内容で`openbao-values.yaml`ファイルを作成します:

   ```yaml
   config:
     ui: false
     storage:
       postgresql:
         haEnabled: true
         connection:
           host: "<SHARED_NETWORK_IP>"
           port: 5432
           database: openbao
           username: openbao
           sslMode: "disable"
           password:
             secret: openbao-db-secret
             key: password
     initialize:
       enabled: true
       oidcDiscoveryUrl: "https://<GITLAB_DOMAIN>"
       boundIssuer: "https://<GITLAB_DOMAIN>"
       boundAudiences: '"https://<OPENBAO_DOMAIN>"'

   gatewayRoute:
     enabled: false
   ```

1. OpenBaoをインストールします:

   ```shell
   helm upgrade --install openbao gitlab/openbao \
     --namespace openbao \
     --values openbao-values.yaml
   ```

   `--wait`を使用しないでください。ポッドはPostgreSQLに接続できません。`gitlab-ctl reconfigure`の後にPostgreSQLがポッドネットワークからのTCP接続のみを受け入れるためです。現在、ポッドは`CrashLoopBackOff`状態になります。

利用可能なすべてのチャートオプションについては、[OpenBao Helmチャートのドキュメント](https://docs.gitlab.com/charts/charts/openbao/)を参照してください。

## OpenBao内部URLを定義する {#define-the-openbao-internal-url}

OpenBao内部URLを定義するには複数のオプションがあります:

- ロードバランサー。配置されたKubernetesクラスターで内部ロードバランサーを使用している場合は、`gitlab.rb`ファイルの`oak['components']['openbao']['internal_url']`設定をロードバランサーの内部URLに設定して、OpenBao Kubernetesサービスへのリクエストをルーティングできます。この場合、内部URLが内部ロードバランサーのIPに解決するようにDNSを設定する必要があります。
- クラスター`nodePort`。OpenBaoチャートサービスをKubernetesサービスタイプ`nodePort`で実行するようにカスタマイズした場合、内部URLもそれに設定できます。
- サービス`clusterIP`: このオプションが最もシンプルである可能性があります。配置されたクラスターのロードバランサーを完全にスキップすることもできます。その場合は、OpenBao内部URLがOpenBaoサービス`clusterIP`に直接通信するように設定します。Linuxパッケージで管理されているNGINXがすでに存在するため、このオプションにより、マシンに追加のロードバランサーをインストールする手間を省くことができます。

以下のコマンドを実行することで、OpenBaoサービスの`clusterIp`を見つけることができます: 

```shell
kubectl -n openbao get svc openbao-active \
  -o jsonpath='{.spec.clusterIP}'
```

どのケースでも、内部URLのIPは、Kubernetesクラスターの外部にあるホストマシンからアクセスできる必要があることを忘れないでください。

したがって、選択した`<SHARED_NETWORK_IP>`からIPを割り当てるようにクラスターを設定してください。

## GitLabを設定する {#configure-gitlab}

`/etc/gitlab/gitlab.rb`に次の内容を追加し、プレースホルダーの値を実際のIPアドレスとドメインに置き換えます:

```ruby
# PostgreSQL: accept TCP connections from Kubernetes pods.
# Use the shared network IP to restrict exposure to the shared network.
# Using '0.0.0.0' makes PostgreSQL listen on all interfaces, including public ones.
postgresql['listen_address'] = '<SHARED_NETWORK_IP>'

# Local connections (GitLab Rails and other services) continue without a password.
postgresql['trust_auth_cidr_addresses'] = %w[127.0.0.1/32 ::1/128]

# Kubernetes pods authenticate with a password.
# Replace 10.42.0.0/16 with the CIDR of your Kubernetes CNI (pod network).
postgresql['md5_auth_cidr_addresses'] = %w[10.42.0.0/16]

# OAK: OpenBao reverse proxy via GitLab NGINX.
oak['enable'] = true
oak['network_address'] = '<SHARED_NETWORK_IP>'

oak['components']['openbao']['enable'] = true

# Replace 'https://openbao.example.com' by the URL with the DNS record
# you configured for OpenBao which resolves to your host's public IP address
oak['components']['openbao']['external_url'] = 'https://openbao.example.com'

# Example of service clusterIP. Replace <CLUSTER_IP> with the IP taken
# from the previous step.
#
# A nodePort would look similar. You could just specify the Cluster node
# IP with the port of your choosing when you deployed OpenBao.
#
# If behind a load balancer, it would look more like: 'http://openbao-internal.example.com'
oak['components']['openbao']['internal_url'] = 'http://<CLUSTER_IP>:8200'
```

各項目の説明は以下のとおりです: 

- `postgresql['listen_address']`: 共有ネットワークIP。`trust_auth_cidr_addresses`または`md5_auth_cidr_addresses`に記載されていないCIDRからの接続はPostgreSQLによって拒否されます。
- `postgresql['trust_auth_cidr_addresses']`: これらのアドレス（ローカルホストのみ）からの接続はパスワードなしで受け入れられます。これらはGitLabサービスによって使用されます。
- `postgresql['md5_auth_cidr_addresses']`: ポッドCIDRからの接続にはパスワード認証が必要です。OpenBaoのポッドによって使用されます。
- `oak['network_address']`: 共有ネットワークIP。NGINXのlistenディレクティブによって使用されます。
- `oak['components']['openbao']['internal_url']`: GitLabアプリケーションがOpenBaoと通信するために使用するURL。

### TLS設定 {#tls-configuration}

GitLabの`external_url`設定で`https://`を使用している場合、Let's Encryptはすでに有効になっています。OpenBaoの`external_url`スキームを`https://`に設定するだけで十分です。GitLabは、既存のLet's Encrypt証明書にOpenBaoドメインをサブジェクト代替名（SAN）として自動的に追加します。

代わりにカスタム証明書を使用するには、以下を追加します:

```ruby
oak['components']['openbao']['ssl_certificate']     = '/etc/gitlab/ssl/openbao.example.com.crt'
oak['components']['openbao']['ssl_certificate_key'] = '/etc/gitlab/ssl/openbao.example.com.key'
```

## 設定の変更を適用する {#apply-configuration-changes}

設定の変更を適用します:

```shell
sudo gitlab-ctl reconfigure
```

これにより、すべての設定が1回のパスで適用されます:

- PostgreSQLはKubernetesポッドからのTCP接続の受け入れを開始します。
- NGINXは、TLS終端およびHTTPからHTTPSへのリダイレクトを含むOpenBao仮想ホストで設定されます。
- 該当する場合、Let's Encrypt証明書が発行または更新されます。

## OpenBaoの準備が整うまで待機する {#wait-for-openbao-to-become-ready}

以前`CrashLoopBackOff`状態だったポッドは、再設定後に正常になるはずです。

ロールアウトが完了するまで待機します:

```shell
kubectl -n openbao rollout status deployment openbao
```

## インストールを検証する {#verify-the-installation}

HTTPSプロキシ経由でOpenBaoに到達可能であることを確認します:

```shell
curl "https://openbao.example.com/v1/sys/health"
```

成功した応答は次のようになります:

```json
{
  "initialized": true,
  "sealed": false,
  "standby": false,
  "version": "2.0.0"
}
```

次に、[GitLab Secrets Managerを有効](../../ci/secrets/secrets_manager/_index.md#enable-or-disable-the-gitlab-secrets-manager)にします。
