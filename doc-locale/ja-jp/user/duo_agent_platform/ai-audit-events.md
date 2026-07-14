---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: コンプライアンスおよびガバナンス目的で、GitLab Duoエージェントアクティビティの統一された記録を参照およびフィルタリングします。
title: AI監査イベントレポート
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.1で`agent_artifacts_page`[機能フラグ](../../administration/feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md)として[導入](https://gitlab.com/groups/gitlab-org/-/work_items/20237)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!warning]
> この機能は[ベータ](../../policy/development_stages_support.md)版です。予告なく変更される場合があります。詳細については、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)を参照してください。

このAI監査イベントレポートは、セキュリティチームおよびコンプライアンスチームに、GitLab Duoエージェント活動の統合された閲覧可能な記録を提供します。各エージェントセッションは、検査可能な包括的な監査アーティファクトを生成します。

## AI監査イベントを表示 {#view-ai-audit-events}

AI監査イベントは、**ガバナンス**ページで**エージェントアーティファクト**タブとして利用できます。

前提条件: 

- トップレベルグループのオーナーロールが必要です。

グループのAI監査イベントを表示するには:

1. 上部のバーで**検索または移動先**を選択して、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **ガバナンスを変更**を選択します。
1. **エージェントアーティファクト**タブを選択します。

タブにはエージェントセッションのリストが表示されます。各行に表示されるのは次のとおりです:

- エージェントの種類（ワークフロー定義）。
- セッションが実行されたプロジェクト。
- セッション内の監査イベントの数。
- セッションの開始時刻。

## セッションをフィルター {#filter-sessions}

結果を絞り込むために、セッションリストをフィルターできます:

- **プロジェクト**: プロジェクトパスでフィルターするか、特定のプロジェクトを除外する。
- **日付範囲**: 特定の日付以降または以前に作成されたセッションをフィルターする。

## セッションの詳細を表示 {#view-session-details}

セッション内のイベントを検査するには:

1. セッション行を選択して、セッション詳細パネルを開きます。パネルには、セッションメタデータと監査イベントの時系列リストが表示されます。
1. 個々のイベントを選択して、エンティティとターゲット情報を含む完全な詳細を表示します。

## 関連トピック {#related-topics}

- [GitLab Duo Agent Platform](_index.md)
- [監査イベント](../../administration/compliance/audit_event_reports.md)
