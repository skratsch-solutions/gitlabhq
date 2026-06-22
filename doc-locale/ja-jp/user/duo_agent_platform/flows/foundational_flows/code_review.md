---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コードレビューフロー
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic Claude Sonnet 4.6 Vertex
- [別のモデルを選択](../../model_selection.md)するには、**Agentic Code Review**設定を使用します。
- [セルフホストモデル対応のGitLab Duo](../../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645)で`duo_code_review_on_agent_platform`[フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。機能フラグ`duo_code_review_on_agent_platform`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209)されました。
- GitLab 18.10で、GitLab.comのFreeプランでGitLabクレジットとともに利用可能になりました。
- LLMはGitLabバージョン19.1でClaude Sonnet 4.6 Vertexに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876)されました。

{{< /history >}}

> [!note]
> アドオンに応じて、GitLabは以下の2つのコードレビュー機能を実行します:
>
> - コードレビューフロー: GitLab Duo Agent Platformの一部であるエージェント型バージョン。
> - GitLab Duoコードレビュー: GitLab Duo Enterpriseアドオンを持つユーザーのみが利用できる非エージェント型バージョン。
>
> このページでは、エージェント型バージョンについて説明します。[2つの機能の比較説明](../../../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)をご覧ください。

コードレビューフローは、エージェント型AIを活用してコードレビューを効率化します。

このフローには次の特長があります:

- コードの変更を分析します。
- リポジトリ構造やファイル間の依存関係を踏まえて、より高度にコンテキストを理解します。
- 実行可能なフィードバックを含む、詳細なレビューコメントを提供します。
- プロジェクトに合わせて調整されたカスタムレビュー指示をサポートします。

このフローはGitLab UIでのみ使用できます。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../../_index.md#prerequisites)を満たしていること。
- **基本フローを許可**と**コードレビュー**を[トップレベルグループ向け](_index.md#turn-foundational-flows-on-or-off)に有効にします。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロールを持っていること。
- 複数のGitLab Duoネームスペースに属している場合は、[デフォルトのGitLab Duoネームスペースを設定](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)します。
- プロジェクトで[独自のRunnerを設定](../execution.md#configure-runners)しているか、[GitLabホストRunner](../../../../ci/runners/hosted_runners/_index.md)を有効にしていること。

## フローを使用する {#use-the-flow}

マージリクエストでコードレビューフローを使用するには:

1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
1. 次のいずれかの方法でレビューをリクエストします:
   - `@GitLabDuo`をレビュアーとして割り当てます。
   - コメントボックスに、クイックアクション`/assign_reviewer @GitLabDuo`を入力します。
   - コメントボックスで`@GitLabDuo`にメンションし、レビューをリクエストします。

レビューをリクエストすると、コードレビューフローが[セッション](../../sessions/_index.md)を開始します。レビューが完了するまでその状況を監視できます。

## レビューでGitLab Duoとやり取りする {#interact-with-gitlab-duo-in-reviews}

{{< history >}}

- コメントのインタラクションは、GitLabバージョン19.1でGitLab Duo Agent Platformを使用するように[更新](https://gitlab.com/gitlab-org/gitlab/-/work_items/601102)されました。

{{< /history >}}

レビュアーとしてGitLab Duoを割り当てるだけでなく、次の方法でGitLab Duoとやり取りできます:

- レビューコメントに返信して、明確化や代替アプローチを求めます。
- ディスカッションスレッドで`@GitLabDuo`をメンションし、フォローアップの質問を行う。

コメントでのGitLab Duoとのディスカッションは、Agentic Chatリクエストとしてカウントされ、[クレジットを消費](../../../../subscriptions/gitlab_credits.md)します。

GitLab Duoに提供されたフィードバックは、他のマージリクエスト以降のレビューには影響しません。この機能は[イシュー560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116)で提案されています。

## コンテキスト認識 {#contextual-awareness}

コードレビューフローは2つのステージで実行されます:

1. プレスキャン: このフローはマージリクエストの差分を検査し、それらを使用して、プロジェクトリポジトリからフェッチする関連コンテキストを特定します。プレスキャンには通常、ディレクトリリストと、変更によって参照されるテストや依存関係などの関連ファイルのコンテンツが含まれます。フェッチされる正確なコンテキストは、差分分析によって異なります。
1. レビュー: このフローは、大規模言語モデルで以下のデータを使用してレビューを実行します。レビューステージでは、オンデマンドで追加のコンテキストをフェッチできません。

   - プレスキャンステップの結果。
   - マージリクエストのタイトル。
   - マージリクエストの説明。
   - マージリクエストの差分。
   - ファイルの元のバージョン。
   - ファイル名。
   - カスタムレビュー指示。

除外するコンテンツを指定するには、[GitLab Duoからコンテキストを除外する](../../context.md#exclude-context-from-gitlab-duo)を参照してください。

### ファイルとコンテキストの制限 {#file-and-context-limits}

コードレビューフローは、プロンプトを実用的なサイズに保つために2つの制限を適用します:

- 10,000行を超えるファイルの場合、差分のみがモデルに送信されます。ファイル全体の内容は含まれません。
- プレスキャンが収集する合計コンテキストは、約1 MiBに制限されます。上限を超えると、レビューステージが実行される前にコンテキストが約800 KiBに切り詰められます。

これらの制限は、フローが収集するデータに適用され、[選択されたモデル](../../model_selection.md)のコンテキストウィンドウとは別個のものです。

非常に大規模なマージリクエストの場合、レビューによって切り詰められたコンテキストが見落とされる可能性があります。リスクを軽減するには:

- マージリクエストをより小さなマージリクエストに分割します。
- レビューに関連のないファイルについては、[コンテキストを除外](../../context.md#exclude-context-from-gitlab-duo)します。

## カスタムコードレビュー指示 {#custom-code-review-instructions}

`mr-review-instructions.yaml`ファイルを使用してコードレビューフローの動作をカスタマイズします。

リポジトリ固有のレビュー指示でGitLab Duoをガイドできます:

- 特定のコード品質の側面（セキュリティ、パフォーマンス、保守性など）に重点を置く。
- プロジェクトに固有のコーディング標準やベストプラクティスを適用する。
- 特定のファイルパターンを対象に、カスタマイズされたレビュー基準を適用する。
- 特定の種類の変更について、より詳細な説明を提供する。

コードレビューフローは、`AGENTS.md`と`SKILL.md`ファイルを参照しません。

カスタム指示を設定するには、[GitLab Duoのレビュー指示をカスタマイズ](../../customize/review_instructions.md)を参照してください。

## プロジェクトのGitLab Duoによる自動レビュー {#automatic-reviews-from-gitlab-duo-for-a-project}

{{< history >}}

- GitLab 18.0でUI設定に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/506537)されました。

{{< /history >}}

GitLab Duoの自動レビューにより、プロジェクト内のすべてのマージリクエストが初期レビューを受けるようになります。マージリクエストが作成されると、次の場合を除き、GitLab Duoがレビューします: 

- ドラフトとしてマークされている場合。GitLab Duoにマージリクエストをレビューさせるには、準備完了とマークします。
- 変更が含まれていない場合。GitLab Duoにマージリクエストをレビューさせるには、変更を追加します。

前提条件: 

- プロジェクトの[メンテナーロール](../../../permissions.md)以上が必要です。

`@GitLabDuo`がマージリクエストを自動的にレビューできるようにするには、以下の手順に従います: 

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**設定** > **マージリクエスト**を選択します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

自動レビューのクレジット使用状況がどのように割り当てられるかについては、[実行されるコードレビュー機能を決定する](../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs)を参照してください。

## グループとアプリケーションのGitLab Duoによる自動レビュー {#automatic-reviews-from-gitlab-duo-for-groups-and-applications}

{{< history >}}

- GitLab 18.4で`cascading_auto_duo_code_review_settings`[機能フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)されました。デフォルトでは無効になっています。
- 機能フラグ`cascading_auto_duo_code_review_settings`は、GitLab 18.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240)されました。
- GitLabバージョン19.1以降、GitLab Duoの新規トライアルにおいてGitLab.comで[デフォルト](https://gitlab.com/gitlab-org/gitlab/-/work_items/592822)で有効化されました。

{{< /history >}}

グループまたはアプリケーションの設定を使用して、複数のプロジェクトで自動レビューを有効にします。

GitLabバージョン19.1以降、GitLab.comでの新規GitLab Duoトライアルでは、グループの自動レビューはデフォルトで有効になっています。

前提条件: 

- グループの自動レビューをオンにするには、グループのオーナーロールが必要です。
- すべてのプロジェクトで自動レビューをオンにするには、管理者である必要があります。

グループの自動レビューを有効にするには、以下の手順に従います: 

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **マージリクエスト**セクションを展開します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

すべてのプロジェクトで自動レビューを有効にするには、以下の手順に従います: 

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

設定は、アプリケーションからグループ、プロジェクトへとカスケードします。より具体的な設定は、より広範な設定をオーバーライドします。

自動レビューのクレジット使用状況がどのように割り当てられるかについては、[実行されるコードレビュー機能を決定する](../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs)を参照してください。

## トラブルシューティング {#troubleshooting}

### `Error DCR4000` {#error-dcr4000}

`Code Review Flow is not enabled. Contact your group administrator to enable the foundational flow in the top-level group. Error code: DCR4000`というエラーが表示されることがあります。

このエラーは、[基本フロー](_index.md)またはコードレビューフローのいずれかが無効になっている場合に発生します。

管理者に連絡し、トップレベルグループのコードレビューフローを有効にするよう依頼してください。

### `Error DCR4001` {#error-dcr4001}

`Code Review Flow is enabled but the service account needs to be verified. Contact your administrator. Error code: DCR4001`というエラーが表示されることがあります。

このエラーは、コードレビューフローは有効になっているものの、トップレベルグループのサービスアカウントが準備できていないか、まだ作成中の場合に発生します。

サービスアカウントがアクティブになるまで数分待ってから、もう一度お試しください。エラーが続く場合は、管理者に連絡し、トップレベルグループにデベロッパーロールを持つサービスアカウントが作成されていることを確認するよう依頼してください。

### `Error DCR4002` {#error-dcr4002}

`No GitLab Credits remain for this billing period. To continue using Code Review Flow, contact your administrator. Error code: DCR4002`というエラーが表示されることがあります。

このエラーは、現在の請求期間に割り当てられたGitLabクレジットをすべて使い切った場合に発生します。

管理者に追加のクレジットの購入を依頼するか、次の請求期間の開始時にクレジットがリセットされるまで待ってください。

### `Error DCR4003` {#error-dcr4003}

`<User>, you don't have permission to create a pipeline for Code Review Flow in this project. Contact your administrator to update your permissions. Error code: DCR4003`というエラーが表示されることがあります。

このエラーは、コードレビューフローがCI/CDパイプライン上で実行され、このプロジェクトでパイプラインを作成する権限がないために発生します。

管理者に連絡し、必要な[パイプラインを実行する権限](../../../permissions.md)を付与するよう依頼してください。

### `Error DCR4004` {#error-dcr4004}

`<User>, you need to set a default GitLab Duo namespace to use Code Review Flow in this project. Please set a default GitLab Duo namespace in your preferences. Error code: DCR4004`というエラーが表示されることがあります。

このエラーは、GitLab Duoがレビューを開始したユーザーのデフォルトGitLab Duoネームスペースを識別できない場合に発生します。

[設定](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)でデフォルトGitLab Duoネームスペースを設定し、もう一度レビューをリクエストしてください。

### `Error DCR4005` {#error-dcr4005}

`Code Review Flow could not obtain the required authentication tokens to connect to the GitLab AI Gateway and the GitLab API. Please request a new review. If the issue persists, contact your administrator. Error code: DCR4005`というエラーが表示されることがあります。

コードレビューフローがGitLab AIゲートウェイおよびGitLab APIに接続するには、認証トークンが必要です。このエラーは、トークンを生成できない場合に発生します。これは通常、GitLab Duoの設定が正しくないか、一時的なインフラストラクチャの問題が原因です。

Self-Managedインスタンスの場合、管理者に[GitLab Duoの設定](../../../../administration/gitlab_duo/configure/_index.md)を確認するよう依頼してください。

### `Error DCR4006` {#error-dcr4006}

`Code Review Flow could not add the service account to this project. Contact your administrator to verify that the service account has the required project access. Error code: DCR4006`というエラーが表示されることがあります。

このエラーは、サービスアカウントをプロジェクトのメンバーとして追加できない場合に発生します。これは、グループメンバーシップのロックが有効になっている場合や、サービスアカウントに必要なアクセス権がない場合に発生する可能性があります。

管理者に連絡し、サービスアカウントがデベロッパーとしてプロジェクトに追加できることを確認するよう依頼してください。

### `Error DCR4007` {#error-dcr4007}

`Code Review Flow is not available for this project. Contact your administrator to verify that the flow is enabled and the required configuration is in place. Error code: DCR4007`というエラーが表示されることがあります。

このエラーは、フローが無効になっているか、プロジェクトに必要な設定がない場合に発生します。

管理者に連絡し、プロジェクトで[フローが有効になっている](_index.md#turn-foundational-flows-on-or-off)ことを確認するよう依頼してください。

### `Error DCR4008` {#error-dcr4008}

`Code Review Flow could not create the required CI/CD pipeline. Please request a new review. If the problem persists, contact your administrator. Error code: DCR4008`というエラーが表示されることがあります。

このエラーは、コードレビューフローがRunnerの可用性の問題や内部の設定の問題により、レビューを実行するためのCI/CDパイプラインを作成または設定できない場合に発生します。

レビューを再試行してください。エラーが解決しない場合は、管理者に連絡してください。

### `Error DCR4009` {#error-dcr4009}

`Code Review Flow could not retrieve the source branch for this merge request. Please request a new review. Error code: DCR4009`というエラーが表示されることがあります。

このエラーは、コードレビューフローがマージリクエストのソースブランチを取得することができない場合に発生します。

レビューを再試行してください。

### `Error DCR5000` {#error-dcr5000}

`Something went wrong while starting Code Review Flow. Please try again later. Error code: DCR5000`というエラーが表示されることがあります。

このエラーは、GitLab Duo Agent Platformが内部エラーによりコードレビューフローを開始できない場合に発生します。

レビューを再試行してください。エラーが解決しない場合は、管理者に連絡してください。

### 大規模なマージリクエストのレビューにおけるコンテキストの欠落 {#missing-context-in-large-merge-request-reviews}

マージリクエストに多数の大きな変更ファイルが含まれている場合、コードレビューフローはコンテキストを見落とす可能性があります。

これは、プレスキャン結果が[ファイルとコンテキストの制限](#file-and-context-limits)を超え、レビューステージが実行される前にデータが切り詰められる場合に発生する可能性があります。

レビューを改善するには:

- マージリクエストをより小さなマージリクエストに分割します。
- レビューに関連のないファイルについては、[コンテキストを除外](../../context.md#exclude-context-from-gitlab-duo)します。
- メンテナーまたはオーナーに、**Agentic Code Review**設定を使用して[別のモデルを選択](../../model_selection.md)するように依頼します。

### 設定診断スクリプト {#configuration-diagnostic-script}

文書化されているエラーコードからコードレビューフローの問題の原因を特定できない場合は、診断スクリプトを実行してGitLab Duo設定を確認できます。

このスクリプトは、コードレビューフローに必要な完全な設定チェーンをチェックし、すべてのGitLab Duo Agent Platform機能に適用されるチェックを含みます。

詳細については、[設定診断スクリプトを実行](../../troubleshooting.md#run-the-configuration-diagnostic-script)を参照してください。

## 関連トピック {#related-topics}

- [マージリクエストにおけるGitLab Duo](../../../project/merge_requests/duo_in_merge_requests.md)
- [Agent PlatformのAIモデル](../../model_selection.md)
