---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: トリガー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3で`ai_flow_triggers`[フラグ](../../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは有効になっています。
- GitLab 18.8で追加の`ai_catalog_create_third_party_flows`[フラグ](../../../administration/feature_flags/_index.md)が必要になるように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217634)されました。デフォルトでは無効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

> [!flag]
> フローの設定ファイルの場所を変更するには、機能フラグを有効にする必要があります。詳細については、履歴を参照してください。

トリガーは、フローがいつ実行されるかを決定します。

たとえば、ディスカッションで言及されたときや、レビュアーとして割り当てられたときにトリガーするフローを指定できます。

## トリガーを作成する {#create-a-trigger}

{{< history >}}

- GitLab 18.5で、**割り当て**イベントタイプと**レビュアーを割り当てる**イベントタイプが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/567787)されました。
- パイプラインイベントのトリガーイベントタイプは、GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212797)され、`ai_flow_trigger_pipeline_hooks`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[実験](../../../policy/development_stages_support.md)として提供されています。デフォルトでは無効になっています。

{{< /history >}}

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

トリガーを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **トリガー**を選択します。
1. **新しいフロートリガー**を選択します。
1. **説明**に、トリガーの説明を入力します。
1. **イベントタイプ**ドロップダウンリストから、1つ以上のイベントタイプを選択します:
   - **メンション**: イシューまたはマージリクエストのコメントでサービスアカウントユーザーがメンションされたとき。
   - **割り当て**: サービスアカウントユーザーがイシューまたはマージリクエストに割り当てられたとき。
   - **レビュアーを割り当てる**: サービスアカウントユーザーがレビュアーとしてマージリクエストに割り当てられたとき。
   - **パイプラインイベント**: パイプラインのステータスが変更されたとき。可能なステータスは`created`、`started`、`succeeded`、および`failed`です。
1. **サービスアカウント**ドロップダウンリストから、[the composite identity](../composite_identity.md)とするユーザーを選択します。
1. **設定ソース**で、次のいずれかを選択します:
   - **AIカタログ**: このプロジェクト用に設定されているフローの中から、トリガーで実行するフローを選択します。
   - **設定パス**: フロー設定ファイルのパスを入力します（例: `.gitlab/duo/flows/claude.yaml`）。このオプションを表示するには、`ai_catalog_create_third_party_flows`フラグを有効にする必要があります。
1. **フロートリガーを作成**を選択します。

作成したトリガーが、**自動化** > **トリガー**に表示されるようになります。

### トリガーを編集する {#edit-a-trigger}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **トリガー**を選択します。
1. 変更するトリガーで、**フロートリガーを編集**（{{< icon name="pencil" >}}）を選択します。
1. 変更を加えて、**変更を保存**を選択します。

### トリガーを削除する {#delete-a-trigger}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **トリガー**を選択します。
1. 変更するトリガーで、**フロートリガーを削除**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**OK**を選択します。
