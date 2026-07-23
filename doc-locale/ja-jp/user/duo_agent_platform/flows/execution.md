---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: フロー実行を設定する
---

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477166)されました。

{{< /history >}}

フローはエージェントを使用してタスクを実行します。

- GitLab UIから実行されるフローは、CI/CDを使用します。
- IDEで実行されるフローは、ローカルで実行されます。

フローがCI/CD経由で実行される環境を設定できます。[独自のRunnerを使用](#configure-runners-to-execute-flows)したり、[ジョブに変数を指定](execution_variables.md)することもできます。

## フローのセキュリティ {#flow-security}

フローがGitLab CI/CDで実行される場合:

- アクセスを制限するために、フローは[複合アイデンティティ](../composite_identity.md)を使用します。
- それらは一時的な[ワークロードパイプライン](../../../ci/pipelines/pipeline_types.md#workload-pipeline)を作成し、フローが完了すると削除されます。
- フローが使用できるツールは、フローの目的に応じて制限されます。これらのツールには、マージリクエストの作成、実行環境でのローカルShellコマンドの実行などが含まれます。

デフォルトでは、フローはGitLabインスタンスにのみネットワークアクセスできます。ネットワークアクセスルールに関する詳細は、[ネットワークポリシーを設定する方法](../environment_sandbox.md#configure-a-network-policy)を参照してください。この分離された環境により、Shellコマンドの実行による意図しない結果から保護されます。

GitLab UIでフローが自律的に実行されるのを防ぐため、[フローの実行をオフ](foundational_flows/_index.md#turn-foundational-flows-on-or-off)にすることができます。

### `agent-config.yml`のセキュリティ上の影響 {#security-implications-of-agent-configyml}

`.gitlab/duo/agent-config.yml`ファイルは、`setup_script`で実行されるコマンドを含め、フローがCI/CDでどのように実行されるかを制御します。フローの実行方法により、このファイルへの変更は、コミットしたユーザー以外のユーザーにも影響を与えます。

#### クロスユーザー実行 {#cross-user-execution}

フローは、[コンポジットアイデンティティ](../composite_identity.md)を通じてトリガーするユーザーのIDで実行されます。`setup_script`のコマンドは、トリガーしたユーザーのコンポジットアイデンティティ認証情報で実行され、設定をコミットしたユーザーの認証情報ではありません。

`.gitlab/duo/agent-config.yml`への書き込みアクセス権を持つユーザーは、別のユーザーのRunner環境で何が実行されるかに影響を与える可能性があります。このファイルへの変更は、その後プロジェクトでフローをトリガーするすべてのユーザーの実行コンテキストに影響を与えます。

#### 公開される環境変数 {#exposed-environment-variables}

Anthropic Sandbox Runtime（SRT）の外部で実行される`setup_script`の実行中、以下の機密性の高い変数が環境内に存在します:

- `GITLAB_OAUTH_TOKEN`と`GITLAB_TOKEN`: トリガーするユーザーのコンポジットアイデンティティを通じたOAuthトークン。
- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTPパスワード。
- `DUO_WORKFLOW_SERVICE_TOKEN`: サービストークン。
- `DUO_WORKFLOW_GIT_USER_EMAIL`と`DUO_WORKFLOW_GIT_USER_NAME`: トリガーするユーザーのメールと名前。

公開される変数の完全なリストについては、[フロー実行変数](execution_variables.md)を参照してください。

#### 推奨される保護 {#recommended-protections}

`.gitlab/duo/agent-config.yml`ファイルへの不正な変更のリスクを軽減するには、次の操作を行います:

- 直接的なプッシュを防ぐために、[デフォルトブランチを保護](../../../user/project/repository/branches/protected.md)します。
- [コードオーナー](../../../user/project/codeowners/_index.md)を使用して、`.gitlab/duo/agent-config.yml`への変更がマージされる前に、特定のオーナーからの承認を必須にします。例えば、`CODEOWNERS`ファイルに以下を追加します:

  ```plaintext
  .gitlab/duo/agent-config.yml @your-group/security-reviewers
  ```

- このファイルを変更するマージリクエストについて、信頼できるメンテナーによるレビューを必要とする[承認ルール](../../../user/project/merge_requests/approvals/rules.md)を設定します。

## Executorアーキテクチャ {#executor-architecture}

フローがCI/CDで実行されると、Runnerは次のように動作します:

1. `@gitlab/duo-cli`パッケージをnpmレジストリからダウンロードします。
1. GitLab Duo CLIを実行します。これはWebSocketを使用してGitLab Duoワークフローサービスに接続します。
1. AIモデルの指示に従ってツール（ファイル操作、Gitコマンド）を実行します。

ExecutorのバージョンはGitLabによって管理され、定期的なリリースの一部として更新されます。

## CI/CD実行を設定する {#configure-cicd-execution}

フローがCI/CDでどのように実行されるかをカスタマイズするには、プロジェクトにエージェント設定ファイルを作成します。

サポートされているキーとその型については、[`agent-config.yml`の参照](agent_config_yml.md)を参照してください。

> [!note]
> このシナリオでは、事前に定義されたCI/CD変数を使用できません。[利用可能な変数のリスト](execution_variables.md#available-variables)を参照してください。

## 設定ファイルを作成する {#create-the-configuration-file}

1. プロジェクトのリポジトリに`.gitlab/duo/`フォルダーが存在しない場合は作成します。
1. そのフォルダー内に、`agent-config.yml`という名前の設定ファイルを作成します。
1. 必要な設定オプションを追加します（以下のセクションを参照）。
1. ファイルをデフォルトブランチにコミットしてプッシュします。

プロジェクトのCI/CDでフローが実行されると、設定が適用されます。

> [!note]
> この設定ファイルは、プロジェクトのデフォルトブランチからのみ読み取られます。他のブランチにコミットされたファイルは、それらのブランチからフローが実行されても無視されます。

### デフォルトのDockerイメージを変更する {#change-the-default-docker-image}

デフォルトでは、CI/CDで実行されるすべてのフローは、GitLabが提供する標準のDockerイメージを使用します。このDockerイメージは、[Anthropic Sandbox Runtime（`srt`）](https://github.com/anthropic-experimental/sandbox-runtime)を使用して、ネットワーク保護を自動的に組み込みます。

Dockerイメージを変更し、独自のものを指定できます。独自のイメージは、特定の依存関係やツールを必要とする複雑なプロジェクトに役立ちます。イメージでネットワーク保護を使用するには、希望するバージョンで`srt`をDockerイメージに追加します:

```Docker
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.20
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version
```

SRTおよびカスタムイメージへのインストール方法の詳細については、[リモート実行環境サンドボックス](../environment_sandbox.md)を参照してください。

デフォルトのDockerイメージを変更するには、`agent-config.yml`ファイルに以下の設定を追加します:

```yaml
image: YOUR_DOCKER_IMAGE
```

例: 

```yaml
image: python:3.11-slim
```

または、Node.jsプロジェクトの場合:

```yaml
image: node:20-alpine
```

#### 強化されたUBI 9 Minimalイメージ {#hardened-ubi-9-minimal-image}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/merge_requests/12)されました。

{{< /history >}}

GitLabは、Red Hat Universalベースイメージ（UBI）9 Minimalに基づく、強化された最小限のイメージバージョンも提供します。このイメージは、ネットワークが制限された、FedRAMPスタイル、またはその他のセキュリティに敏感な環境向けに設計されており、より小さいアタックサーフェス、非root実行、およびRed Hat UBIベースが求められます。

強化されたイメージは次の場所で公開されています: `registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened`

これは`linux/amd64`と`linux/arm64`の両方でビルドされ、デフォルトイメージと同じタグスキームを使用します:

- `:<short-sha>`ビルドごと
- `:<git-tag>`リリースごと

##### 強化されたイメージを使用する {#use-the-hardened-image}

前提条件: 

- GitLab 18.10以降

強化されたイメージを使用するには、`agent-config.yml`で設定します:

```yaml
image: registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>
```

##### イメージのコンテンツ {#image-contents}

| コンポーネント           | バージョン                           |
|---------------------|-----------------------------------|
| ベースイメージ          | Red Hat UBI 9 Minimal             |
| `git`               | UBI 9 stock                       |
| `git-lfs`           | UBI 9 stock                       |
| Node.js             | 20（UBI 9モジュールストリーム）          |
| `npm`               | Node.js 20とバンドル           |
| `@gitlab/duo-cli`   | プリインストール済み                     |
| `glab`（GitLab CLI） | プリインストール済み                     |
| ランタイムユーザー        | 非root、UID 1001（`duo-runner`） |

イメージには`@gitlab/duo-cli`と`glab`が含まれているため、`registry.npmjs.org`または`registry.gitlab.com`への送信アクセスはフロー実行時に不要です。

##### 追加のパッケージでイメージを拡張する {#extend-the-image-with-additional-packages}

強化されたイメージはUID 1001（`duo-runner`）として実行されます。`agent-config.yml`内の`setup_script`もこの非rootユーザーとして実行されるため、`microdnf`でシステムパッケージをインストールすることはできません。

言語ランタイムまたはシステムパッケージを追加するには:

1. 独自の`FROM`レイヤーでイメージを拡張します:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>

   USER root
   RUN microdnf install -y python3.12 python3.12-pip && microdnf clean all
   USER 1001
   ```

1. rootアクセスを必要としないプロジェクトの依存関係には、`setup_script`を使用します。例: `pip install --user`、`npm install`。

##### 強化されたイメージを使用するタイミング {#when-to-use-the-hardened-image}

環境で以下が必要な場合に、強化されたイメージを使用します:

- Red Hat UBIベースイメージ。例えば、FedRAMPまたは企業コンプライアンスの場合。
- デフォルトでの非rootコンテナ実行。
- Agent Platform自体が必要とする以上の言語ランタイムを持たない最小限のアタックサーフェス。
- フロー実行時の送信インターネットアクセスなし（Agent Platformのすべての依存関係はプリインストール済み）。

複数の言語ランタイムをすぐに必要とする接続された環境での汎用フローには、[デフォルトイメージ](#change-the-default-docker-image)を使用します。

#### カスタムイメージの要件 {#custom-image-requirements}

カスタムDockerイメージを使用する場合は、エージェントが正しく機能するために、次のコマンドが利用可能であることを確認してください:

- `git`
- `npm`と互換性のあるNode.jsバージョンを持つ`@gitlab/duo-cli`。詳細については、[GitLab Duo CLIの前提条件](../../gitlab_duo_cli/_index.md#install)を参照してください。

ほとんどのベースイメージには、デフォルトでこれらのコマンドが含まれています。ただし、最小構成イメージ（`alpine`バリアントなど）では、明示的にインストールする必要がある場合があります。必要に応じて、[セットアップスクリプトの設定](#configure-setup-scripts)で不足しているコマンドをインストールできます。

> [!note]
> GitLab 18.9以前では、カスタムイメージ内の新しい`git`のバージョンでフローが失敗する可能性があるという[既知のイシュー（587996）](https://gitlab.com/gitlab-org/gitlab/-/work_items/587996)があります。このイシューは、`@gitlab/duo-cli`バージョン8.71.0で解決されました。
>
> `@gitlab/duo-cli`バージョン8.71.0以前を使用している場合、新しいGitのバージョンでフローが失敗するのを避けるために、以下のいずれかを実行できます:
>
> - カスタムイメージでGitバージョン`2.43.7`または以前のものを使用します
> - `@gitlab/duo-cli`バージョン8.71.0を使用します。

さらに、フロー実行中にエージェントが行うツール呼び出しによっては、他の一般的なユーティリティが必要になる場合があります。

たとえば、Alpineベースのイメージを使用する場合:

```yaml
image: python:3.11-alpine
setup_script:
  - apk add --update git nodejs npm
```

#### セキュリティとパフォーマンス {#security-and-performance}

カスタムDockerイメージを使用する場合、[環境サンドボックス](../environment_sandbox.md)は、Anthropic Sandbox Runtime（SRT）がカスタムイメージに含まれている場合にのみ適用されます。SRTが含まれていない場合、フローはRunnerから到達可能な任意のドメインと完全なファイルシステムにアクセスできます。

カスタムイメージでネットワーク分離が必要な場合は、[イメージにSRTをインストール](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)し、[ネットワークポリシーを設定](../environment_sandbox.md#configure-a-network-policy)するか、Runnerでネットワークレベルの制御（ファイアウォールルールやネットワークポリシーなど）を設定します。

ジョブの起動時間を約15〜20秒短縮するには、`@gitlab/duo-cli` npmパッケージと`glab`CLIをカスタムイメージに含めます。強化されたイメージには、両方のツールがプリインストールされています。

### セットアップスクリプトを設定する {#configure-setup-scripts}

フローの実行前に実行されるセットアップスクリプトを定義できます。これは、依存関係のインストール、環境の設定、必要な初期化を行う場合に役立ちます。

セットアップスクリプトを追加するには、`agent-config.yml`ファイルに以下のコマンドを追加します:

```yaml
setup_script:
  - apt-get update && apt-get install -y curl
  - pip install -r requirements.txt
  - echo "Setup complete"
```

これらのコマンドは以下のアクションを実行します:

- メインのワークフローコマンドの前に実行されます。
- 指定された順序で実行されます。
- 単一のコマンドまたはコマンド配列として指定できます。

`setup_script`のユーザーコンテキストは、Dockerイメージによって異なります。デフォルトのGitLabイメージは`root`として実行されます。カスタムイメージは、イメージの`USER`ディレクティブで定義されたユーザーとして実行されます。`setup_script`がrootアクセスを必要とする場合（例えば、システムパッケージをインストールするため）、カスタムイメージがそれに応じて設定されていることを確認してください。

> [!warning]
> `setup_script`コマンドは、SRTが適用される前に実行され、その外部で実行されます。これらのコマンドは、フロー内のすべての環境変数にアクセスできます。これには、トリガーするユーザーのOAuthトークン、サービストークン、およびIDの詳細が含まれます。セキュリティモデルと推奨される保護については、[`agent-config.yml`のセキュリティ上の影響](#security-implications-of-agent-configyml)を参照してください。

### オフライン環境でカスタムイメージを使用する {#use-a-custom-image-in-an-offline-environment}

Runnerが外部レジストリに到達できないオフライン環境では、`@gitlab/duo-cli`を含むカスタムexecutorイメージをプリビルドできます。GitLab DuoCLIがイメージにすでに含まれている場合、フロー起動はnpmダウンロードステップをスキップします。

前提条件: 

- 管理者アクセス権。
- GitLab 18.9以降。
- イメージをビルドし、アーティファクトをダウンロードするためのオンラインマシンへのアクセス。

オフライン環境用にフローを設定するには:

1. オンラインマシンで、GitLab DuoCLIを使用してカスタムイメージをビルドします:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   RUN npm install -g @gitlab/duo-cli@8.86.0
   ```

   あるいは、npmを完全に回避するには、[GitLabパッケージレジストリ](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/packages)からスタンドアロンのバイナリをダウンロードします:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   COPY duo-linux-x64 /usr/bin/duo
   RUN chmod +x /usr/bin/duo
   ```

   スタンドアロンのバイナリをダウンロードするには、次のコマンドを実行します:

   ```shell
   curl --location "https://gitlab.com/api/v4/projects/46519181/packages/generic/duo-cli/8.86.0/duo-linux-x64" \
     --output duo-linux-x64
   ```

1. イメージをオフライン環境に転送します。例えば、Dockerを使用して、次のコマンドを実行します:

   ```shell
   # On an online machine
   docker save my-duo-executor:latest -o duo-executor.tar

   # Transfer `duo-executor.tar` to the offline environment

   # On an offline machine
   docker load -i duo-executor.tar
   ```

1. イメージを内部コンテナレジストリにプッシュします。
1. カスタムイメージレジストリを設定します:
   1. 右上隅で、**管理者**を選択します。
   1. 左側のサイドバーで、**GitLab Duo**を選択します。
   1. **設定の変更**を選択します。
   1. **イメージレジストリ**テキストボックスに、内部レジストリのURL（例えば、`registry.internal.example.com`）を入力します。
1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. カスタムイメージを使用するには、`agent-config.yml`ファイルを更新します:

   ```yaml
   image: registry.internal.example.com/duo-executor:latest
   ```

### キャッシュを設定する {#configure-caching}

後続のフローの実行を高速化するためにキャッシュを設定するには、`agent-config.yml`ファイルが実行間でファイルとディレクトリを保持するように設定します。キャッシュは、`node_modules`などの依存関係フォルダーや、Python仮想環境に役立ちます。

#### 基本的なキャッシュ設定 {#basic-cache-configuration}

特定のパスをキャッシュするには、次の内容を`agent-config.yml`ファイルに追加します:

```yaml
cache:
  paths:
    - node_modules/
    - .npm/
```

#### キーを使用したキャッシュ {#cache-with-keys}

キャッシュキーを使用すると、異なるシナリオに応じてさまざまなキャッシュを作成できます。キャッシュキーは、キャッシュがプロジェクトの状態に基づいていることを保証するのに役立ちます。

##### 文字列キーを使用する {#use-a-string-key}

```yaml
cache:
  key: my-project-cache
  paths:
    - vendor/
    - .bundle/
```

##### ファイルシステムベースのキャッシュキーを使用する {#use-file-based-cache-keys}

ファイルの内容（ロックファイルなど）に基づいて動的なキャッシュキーを作成します。これらのファイルが変更されると、新しいキャッシュが作成されます。これにより、指定されたファイルからSHAチェックサムが生成されます:

```yaml
cache:
  key:
    files:
      - package-lock.json
      - yarn.lock
  paths:
    - node_modules/
```

##### ファイルベースのキーとプレフィックスを組み合わせる {#use-a-prefix-with-file-based-keys}

キャッシュキーのファイルから計算されたSHAと、プレフィックスを組み合わせます:

```yaml
cache:
  key:
    files:
      - package-lock.json
    prefix: $CI_JOB_NAME
  paths:
    - node_modules/
    - .npm/
```

この例では、ジョブ名が`test`で、SHAチェックサムが`abc123`の場合、キャッシュキーは`test-abc123`になります。

#### キャッシュの制限事項 {#cache-limitations}

- キャッシュキーの生成には、最大2つのファイルを指定できます。3つ以上のファイルが指定されている場合は、最初の2つのみが使用されます。
- キャッシュの`paths`フィールドは必須です。パスが指定されていないキャッシュ設定は効果がありません。
- キャッシュキーの`prefix`フィールドではCI/CD変数をサポートしています。

### IDトークンを設定する {#configure-id-tokens}

{{< history >}}

- GitLab 19.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224940)。

{{< /history >}}

フローからサードパーティサービスを認証するには、[IDトークンを設定](../../../ci/secrets/id_token_authentication.md)します。

IDトークンは、GitLab CI/CDが生成し、フローを実行するジョブに注入するJSONウェブトークン（JWT）であり、長期認証情報を保存せずにキーレスのOpenID Connect（OIDC認証）を可能にします。例えば、IDトークンを使用して、シークレットマネージャーからシークレットを取得したり、バイナリやGitコミットに署名したりできます。

IDトークンを設定するには、`agent-config.yml`ファイルに`id_tokens`ブロックを追加します。各トークンには`aud`（オーディエンス）クレームが必要です:

```yaml
id_tokens:
  VAULT_ID_TOKEN:
    aud: https://vault.example.com

network_policy:
  allowed_domains:
    - vault.example.com
```

`aud`クレームは単一の文字列または文字列のリストにすることができます:

```yaml
id_tokens:
  MY_ID_TOKEN:
    aud:
      - https://first.service.example.com
      - https://second.service.example.com

network_policy:
  allowed_domains:
    - first.service.example.com
    - second.service.example.com
```

各トークンは、フロージョブ内で、トークンの名前を使用する環境変数として利用できます。以前の例では、フローは`$VAULT_ID_TOKEN`と`$MY_ID_TOKEN`を使用できます。

トークン名が設定の他の場所で宣言された変数名と一致する場合、IDトークンが優先されます。

> [!warning]
> IDトークンは、`aud`クレームを信頼するあらゆるサービスへのアクセスを許可する認証情報です。各トークンに可能な限り狭い`aud`値を設定し、不正なトークンが最小限のサービスで認証できるようにします。設定ファイルはデフォルトブランチから読み取られるため、[推奨される保護](#recommended-protections)を適用して、どのトークンをフローがリクエストできるかを変更できるユーザーを制御します。

トークンペイロードとサードパーティサービスとの信頼を設定する方法の詳細については、[IDトークンを使用したOpenID Connect（OIDC認証）](../../../ci/secrets/id_token_authentication.md)を参照してください。

### すべてのオプションを使用した設定例 {#complete-configuration-example}

利用可能なすべてのオプションを使用した`agent-config.yml`ファイルの例を示します:

```yaml
# Custom Docker image
image: python:3.11

# Setup script to run before the flow
setup_script:
  - apt-get update && apt-get install -y build-essential
  - pip install --upgrade pip
  - pip install -r requirements.txt

# Cache configuration
cache:
  key:
    files:
      - requirements.txt
      - Pipfile.lock
    prefix: python-deps
  paths:
    - .cache/pip
    - venv/

# Network configuration
network_policy:
  include_recommended_allowed: true
  allow_all_unix_sockets: true
  allowed_domains:
    - vault.example.com
  denied_domains:
    - malicious.com

# ID tokens for OIDC authentication
id_tokens:
  VAULT_ID_TOKEN:
    aud: https://vault.example.com
```

この設定では:

- Python 3.11をベースイメージとして使用します。
- フローの実行前に、ビルドツールおよびPythonの依存関係をインストールします。
- pipおよび仮想環境のディレクトリをキャッシュします。
- `requirements.txt`または`Pipfile.lock`が変更されたときに、`python-deps`のプレフィックスを使用して新しいキャッシュを作成します。
- HashiCorp VaultによるOIDC認証用の`VAULT_ID_TOKEN` IDトークンを提供します。

## Runnerをフロー実行用に設定する {#configure-runners-to-execute-flows}

CI/CDを使用するフローはRunnerで実行されます。

GitLab.comでは、フローはGitLabが提供する[ホスト型Runner](../../../ci/runners/hosted_runners/_index.md)を使用できます。これらはデフォルトで有効になっています。 

フロー用に独自のRunnerを設定するオプションもあります。

> [!note]
> トップレベルグループで[IPアドレス制限](../../group/access_and_permissions.md#restrict-group-access-by-ip-address)が有効になっている場合、ホスト型Runnerはフローには使用できません。ホストされたRunnerは、クラウドプロバイダーのプールからの動的IPアドレスを使用するため、グループのIP許可リストに追加できません。代わりに、トップレベルグループで独自のグループRunnerを設定します。

フロー用に独自のRunnerを設定するには:

1. [インスタンスRunner](../../../ci/runners/runners_scope.md)またはトップレベルグループに割り当てられたグループRunnerを作成します。フローにプロジェクトRunnerまたはサブグループに割り当てられたグループRunnerを使用させたい場合は、`duo_runner_restrictions`機能フラグをオフにします（GitLab Self-Managedのみ）。
1. `gitlab--duo`タグをRunnerに追加して、フローのジョブをピックアップできるようにします。Runnerにこのタグがない場合、フローを含むジョブは無期限にキューに入ったままになります。以下のいずれかの方法を使用してください:
   - Runnerを作成する際に、**タグ**フィールドに`gitlab--duo`と入力します。
   - 既存のRunnerについては、[Runnerが実行できるジョブを編集](../../../ci/runners/configure_runners.md#control-jobs-that-a-runner-can-run)し、**タグ**フィールドに`gitlab--duo`と入力します。
   - Runnerを`config.toml`ファイルで設定する場合は、`[[runners]]`セクションにタグを追加します:

     <!-- markdownlint-disable MD044 -->
     ```toml
     [[runners]]
       executor = "docker"
       tags = ["gitlab--duo"]
     ```
     <!-- markdownlint-enable MD044 -->

1. RunnerをDockerイメージをサポートする[executor](https://docs.gitlab.com/runner/executors/)（例えば、`docker`、`docker-autoscaler`、または`kubernetes`）を使用するように設定します。`shell` executorはサポートされていません。
1. トップレベルグループで[IPアドレス制限](../../group/access_and_permissions.md#restrict-group-access-by-ip-address)が有効になっている場合、Runnerがグループにアクセスできるように、RunnerのIPアドレスをグループのIP許可リストに追加します。
1. GitLab Self-Managedのみ。Runnerがフローに必要なサービスに到達できることを確認してください:
   - GitLabインスタンスからAgent Platformへの[送信接続を許可](../../../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo)します。
   - RunnerからAgent Platformへの[送信接続を許可](../../../administration/gitlab_duo/configure/_index.md#allow-connections-from-the-runner)します。
   - インスタンスの証明書チェーンに自己署名証明書がある場合は、[追加のGitLab DuoCLI設定](../../gitlab_duo_cli/_index.md#custom-ssl-certificates)を完了してください。

### 実行環境サンドボックスを使用してフローを保護する {#use-the-execution-environment-sandbox-to-secure-flows}

ネットワークとファイルシステムの分離には、Runnerで実行されるフローを保護するために、[実行環境サンドボックス](../environment_sandbox.md)を使用します。

サンドボックスを使用するには、以下のいずれかのイメージを使用する必要があります:

- Agent Platform用のデフォルトDockerベースイメージ
- A [SRTがインストールされたカスタムイメージ](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)

Runnerがサンドボックスを使用するように設定するには、[Runner設定](https://docs.gitlab.com/runner/configuration/advanced-configuration/)で`privileged = true`を設定します。

例: 

<!-- markdownlint-disable MD044 -->
```toml
[[runners]]
  executor = "docker"
  tags = ["gitlab--duo"]
  [runners.docker]
    privileged = true
```
<!-- markdownlint-enable MD044 -->

以下のイメージではサンドボックスを使用できません:

- SRTがインストールされていないカスタムイメージ
- 強化されたUBI 9 Minimalイメージ
