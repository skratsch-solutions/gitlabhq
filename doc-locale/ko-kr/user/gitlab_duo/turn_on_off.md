---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "인스턴스, 그룹 및 프로젝트에 대해 GitLab Duo 기능을 끕니다."
title: GitLab Duo 가용성 제어
---

{{< details >}}

- 계층: Premium, Ultimate
- 추가 기능: GitLab Duo Core, Pro, 또는 Enterprise
- 제공 서비스:  GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [AI 기능을 켜고 끄는 설정이 도입됨](https://gitlab.com/groups/gitlab-org/-/epics/12404) GitLab 16.10.
- [AI 기능을 켜고 끄는 설정이 UI에 추가됨](https://gitlab.com/gitlab-org/gitlab/-/issues/441489) GitLab 16.11.

{{< /history >}}

GitLab Duo는 기본적으로 켜져 있습니다. GitLab Duo에는 [기능 세트](feature_summary.md)가 포함되어 있습니다.

GitLab Duo를 켜거나 끌 수 있습니다:

- GitLab.com:  최상위 그룹, 기타 그룹 또는 하위 그룹 및 프로젝트의 경우.
- GitLab Self-Managed:  인스턴스, 그룹 또는 하위 그룹 및 프로젝트의 경우.

## GitLab Duo 켜짐 잠금 {#lock-gitlab-duo-on}

{{< history >}}

- [GitLab 19.1에서 도입됨](https://gitlab.com/groups/gitlab-org/-/work_items/21844)

{{< /history >}}

그룹 또는 프로젝트 설정에 관계없이 모든 사용자에 대해 GitLab Duo를 켭니다.

GitLab Duo 가용성을 **Always on**으로 설정하면 실험 기능과 베타 기능이 자동으로 켜지지 않습니다. 실험 기능과 베타 기능을 사용하려면 [별도로 켜야 합니다](#turn-on-beta-and-experimental-features).

{{< tabs >}}

{{< tab title="GitLab.com" >}}

전제 조건:

- 최상위 그룹의 Owner 역할.

최상위 그룹에 대해 GitLab Duo를 켜짐으로 잠그려면:

1. 상단 바에서 **Search or go to**를 선택하고 최상위 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **Settings** > **GitLab Duo**를 선택합니다.
1. **Change configuration**를 선택합니다.
1. **GitLab Duo 가용성** 아래에서 **Always on**을 선택합니다.
1. **변경사항 저장**을 선택합니다.

GitLab Duo는 모든 하위 그룹 및 프로젝트에 대해 켜짐으로 잠깁니다. 하위 그룹 또는 프로젝트의 Owner 역할을 가진 사용자는 GitLab Duo를 끌 수 없습니다.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

전제 조건:

- 운영자 액세스

인스턴스에 대해 GitLab Duo를 켜짐으로 잠그려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **Change configuration**를 선택합니다.
1. **GitLab Duo 가용성** 아래에서 **Always on**을 선택합니다.
1. **변경사항 저장**을 선택합니다.

GitLab Duo는 모든 그룹, 하위 그룹 및 프로젝트에 대해 켜짐으로 잠깁니다. 그룹, 하위 그룹 또는 프로젝트의 Owner 역할을 가진 사용자는 GitLab Duo를 끌 수 없습니다.

{{< /tab >}}

{{< /tabs >}}

## GitLab Duo 켜기 또는 끄기 {#turn-gitlab-duo-on-or-off}

### GitLab.com {#on-gitlabcom}

#### 최상위 그룹의 경우 {#for-a-top-level-group}

전제 조건:

- 최상위 그룹의 Owner 역할.

최상위 그룹에 대한 GitLab Duo 가용성을 변경하려면:

1. 상단 바에서 **Search or go to**를 선택하고 최상위 그룹을 찾습니다.
1. **Settings** > **GitLab Duo**를 선택합니다.
1. **Change configuration**를 선택합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **변경사항 저장**을 선택합니다.

GitLab Duo 가용성이 모든 하위 그룹 및 프로젝트에 대해 변경됩니다.

#### 그룹 또는 하위 그룹의 경우 {#for-a-group-or-subgroup}

전제 조건:

- 그룹 또는 하위 그룹의 Owner 역할.

그룹 또는 하위 그룹에 대한 GitLab Duo 가용성을 변경하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 그룹 또는 하위 그룹을 찾습니다.
1. **Settings** > **General**을 선택합니다.
1. **GitLab Duo 기능**을 확장합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **변경사항 저장**을 선택합니다.

GitLab Duo 가용성이 모든 하위 그룹 및 프로젝트에 대해 변경됩니다.

#### 프로젝트의 경우 {#for-a-project}

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.

프로젝트에 대한 GitLab Duo 가용성을 변경하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo**를 확장합니다.
1. **GitLab Duo** 토글을 켜거나 끕니다.
1. **변경사항 저장**을 선택합니다.

### GitLab Self-Managed {#on-gitlab-self-managed}

#### 인스턴스의 경우 {#for-an-instance}

전제 조건:

- 운영자 액세스

인스턴스에 대한 GitLab Duo 가용성을 변경하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **Change configuration**를 선택합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **변경사항 저장**을 선택합니다.

#### 그룹 또는 하위 그룹의 경우 {#for-a-group-or-subgroup-1}

전제 조건:

- 그룹 또는 하위 그룹의 Owner 역할.

그룹 또는 하위 그룹에 대한 GitLab Duo 가용성을 변경하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 그룹 또는 하위 그룹을 찾습니다.
1. **Settings** > **General**을 선택합니다.
1. **GitLab Duo 기능**을 확장합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **변경사항 저장**을 선택합니다.

GitLab Duo 가용성이 모든 하위 그룹 및 프로젝트에 대해 변경됩니다.

#### 프로젝트의 경우 {#for-a-project-1}

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.

프로젝트에 대한 GitLab Duo 가용성을 변경하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo**를 확장합니다.
1. **GitLab Duo** 토글을 켜거나 끕니다.
1. **변경사항 저장**을 선택합니다.

### 이전 GitLab 버전의 경우 {#for-earlier-gitlab-versions}

이전 GitLab 버전에서 GitLab Duo를 켜거나 끄는 방법에 대한 정보는 [이전 GitLab 버전에 대한 GitLab Duo 가용성 제어](turn_on_off_earlier.md)를 참조하세요.

## GitLab Duo Core 켜기 또는 끄기 {#turn-gitlab-duo-core-on-or-off}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/538857)되었습니다.
- GitLab Duo 가용성 설정 및 그룹, 하위 그룹 및 프로젝트 제어가 GitLab 18.2에 [추가됨](https://gitlab.com/gitlab-org/gitlab/-/issues/551895).
- GitLab Duo Non-Agentic Chat이 GitLab 18.3에서 GitLab Duo Core에 [추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721).

{{< /history >}}

GitLab Duo Core는 Premium 및 Ultimate 구독에 포함되어 있습니다.

- GitLab 17.11 이전의 기존 고객인 경우 GitLab Duo Core에 대한 기능을 켜야 합니다.
- GitLab 18.0 이상의 신규 고객인 경우 GitLab Duo Core가 자동으로 켜져 있으며 추가 작업이 필요하지 않습니다.

2025년 5월 15일 이전에 Premium 또는 Ultimate 구독이 있는 기존 고객이었다면, GitLab 18.0 이상으로 업그레이드할 때 GitLab Duo Core를 사용하려면 이를 켜야 합니다.

### GitLab.com {#on-gitlabcom-1}

전제 조건:

- 최상위 그룹의 Owner 역할.

최상위 그룹에 대한 GitLab Duo Core 가용성을 변경하려면:

1. 상단 바에서 **Search or go to**를 선택하고 최상위 그룹을 찾습니다.
1. **Settings** > **GitLab Duo**를 선택합니다.
1. **Change configuration**를 선택합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **GitLab Duo 코어** 아래에서 **Turn on features for GitLab Duo Core** 체크박스를 선택하거나 선택 해제합니다. GitLab Duo 가용성에 대해 **항상 꺼짐**을 선택한 경우 이 설정에 액세스할 수 없습니다.
1. **변경사항 저장**을 선택합니다.

변경 사항이 적용되는 데 최대 10분이 소요될 수 있습니다.

### GitLab Self-Managed {#on-gitlab-self-managed-1}

전제 조건:

- 운영자 액세스

인스턴스에 대한 GitLab Duo Core 가용성을 변경하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **Change configuration**를 선택합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **GitLab Duo 코어** 아래에서 **Turn on features for GitLab Duo Core** 체크박스를 선택하거나 선택 해제합니다. GitLab Duo 가용성에 대해 **항상 꺼짐**을 선택한 경우 이 설정에 액세스할 수 없습니다.
1. **변경사항 저장**을 선택합니다.

## 베타 및 실험 기능 켜기 {#turn-on-beta-and-experimental-features}

실험 및 베타 단계인 GitLab Duo 기능은 기본적으로 꺼져 있습니다. 이 기능들은 [테스팅 계약](https://handbook.gitlab.com/handbook/legal/testing-agreement/)의 적용을 받습니다.

### GitLab.com {#on-gitlabcom-2}

전제 조건:

- 최상위 그룹의 Owner 역할.

최상위 그룹에 대한 GitLab Duo 실험 및 베타 기능을 켜려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **Settings** > **GitLab Duo**를 선택합니다.
1. **Change configuration**를 선택합니다.
1. **기능 미리보기** 아래에서 **실험기능과 베타 GitLab Duo 기능 활성화**를 선택합니다.
1. **변경사항 저장**을 선택합니다.

이 설정은 그룹에 속한 [모든 프로젝트에 적용됨](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group).

### GitLab Self-Managed {#on-gitlab-self-managed-2}

{{< tabs >}}

{{< tab title="17.4 이상" >}}

GitLab 17.4 이상에서는 이 지침을 따라 GitLab Self-Managed 인스턴스에 대한 GitLab Duo 실험 및 베타 기능을 켭니다.

전제 조건:

- 운영자 액세스

인스턴스에 대한 GitLab Duo 실험 및 베타 기능을 켜려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 확장합니다.
1. **기능 미리보기** 아래에서 **Use experiment and beta GitLab Duo features**을 선택합니다.
1. **변경사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="17.3 이전" >}}

전제 조건:

- 운영자 액세스
- [네트워크 연결](../../administration/gitlab_duo/configure/_index.md) 활성화됨.
- [자동 모드](../../administration/silent_mode/_index.md) 꺼짐.

인스턴스에 대한 GitLab Duo 실험 및 베타 기능을 켜려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 확장합니다.
1. **기능 미리보기** 아래에서 **Use experiment and beta GitLab Duo features**을 선택합니다.
1. **변경사항 저장**을 선택합니다.
1. GitLab Duo Chat가 즉시 작동하려면 [수동으로 구독을 동기화](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)합니다.

   구독을 수동으로 동기화하지 않으면 인스턴스에서 GitLab Duo Chat을 활성화하는 데 최대 24시간이 소요될 수 있습니다.

{{< /tab >}}

{{< /tabs >}}
