---
stage: Release Notes
group: Monthly Release
title: "GitLab 19.0リリースノート - 未リリース"
description: "19.0に含まれる機能の概要"
---

次の機能はGitLab 19.0で提供されます。これらの機能は現在GitLab.comで利用可能です。

<!-- Copy this template, and paste it into the doc section where it belongs:

Primary feature, Agentic Core, Scale and Deployments, or Unified DevOps and Security.

Update all the information as needed.

### Feature explanation here

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

Now write 125 words or fewer to explain the value of this improvement.
Use phrases that start with, "In previous versions of GitLab, you couldn't... Now you can..."

Use present tense, and speak about "you" instead of "the user."
-->

<!-- ## Primary features

The first person to add a feature in this area, please make the title visible and delete this comment -->

## エージェント型コア {#agentic-core}

### 完全一致コードの検索結果をリポジトリでフィルタリング {#filter-exact-code-search-results-by-repository}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/search/exact_code_search.md#syntax) 、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/488467)

{{< /details >}}

これで完全一致コードの検索結果をリポジトリでフィルタリングできるようになりました。`repo:`構文を使用すると、個々のプロジェクトに移動することなく、検索クエリを特定のリポジトリまたはリポジトリパターンに直接スコープできます。

例えば、`def authenticate repo:my-group/my-project`を検索すると、そのリポジトリからの結果のみが返されます。また、部分的なパスやパターンを使用して、複数のリポジトリを照合することもできます。

<!-- ## Scale and Deployments

The first person to add a feature in this area, please make the title visible and delete this comment -->

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### CI/CDインプットの配列サポートの改善 {#improved-array-support-for-cicd-inputs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/inputs/_index.md#access-individual-array-elements) 、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/587657)

{{< /details >}}

CI/CDインプットは、配列を扱うためのサポートが改善されました。配列入力内の特定の要素にアクセスするには、配列インデックス演算子`[]`を使用します。この機能強化により、パイプラインの設定において、より柔軟で強力な入力補間機能が提供され、追加の処理ステップなしで個々の配列項目を直接参照できるようになります。

### パイプライン入力に複数の値を選択 {#select-multiple-values-for-pipeline-inputs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/inputs/_index.md#array-inputs-with-options) 、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/566155)

{{< /details >}}

以前は、UIで入力オプションを選択する際に単一の値しか選択できず、より複雑なオプションを持つパイプラインの柔軟性が制限されていました。

これで、UIから入力を含むパイプラインを実行する際、ドロップダウンリストから複数の値を選択でき、選択された値は例えば`["option1","option2"]`のように配列に結合されます。これにより、複数のインスタンスでサービスを再起動したり、複数のDockerイメージをビルドしたり、複数のタグの組み合わせでテストを実行したり、単一のパイプライン実行で複数のターゲットにわたるあらゆる操作を簡単に実行できます。

### HMAC署名トークンでWebhookを保護する {#secure-webhooks-with-hmac-signing-tokens}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/integrations/webhooks.md#signing-tokens) 、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/19367)

{{< /details >}}

既存の`X-Gitlab-Token`ヘッダーは静的なシークレットを平文で送信するため、Webhookは傍受やリプレイ攻撃に対して脆弱です。

これで、任意のWebhookに署名トークンを追加できます。GitLabは、署名トークンを使用して以下のHMAC-SHA256署名を算出します:

- 一意のWebhook ID。
- リクエストのタイムスタンプ。
- Webhookペイロード。

GitLabは、[Standard Webhooks](https://www.standardwebhooks.com/)仕様に従い、`webhook-id`および`webhook-timestamp`ヘッダーとともに、結果を`webhook-signature`ヘッダーで送信します。

署名を再計算することで、リクエストがGitLabから真正に送信されたものであり、ペイロードが変更されていないことを確認できます。タイムスタンプも検証することで、リプレイされたリクエストを拒否できます。

[Van Anderson](https://gitlab.com/van.m.anderson)と[Norman Debald](https://gitlab.com/Modjo85)のコミュニティへのコントリビュートに感謝します！
