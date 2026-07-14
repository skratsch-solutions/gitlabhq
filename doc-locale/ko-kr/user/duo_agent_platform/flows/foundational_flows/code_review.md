---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Code Review 플로우
---

{{< details >}}

- 티어:  [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- LLM: Anthropic Claude Sonnet 4.6 Vertex
- [다른 모델 선택](../../model_selection.md)을 사용하여 **Agentic Code Review** 설정에서 선택합니다.
- [자가 호스팅 모델이 포함된 GitLab Duo](../../../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- [베타](../../../../policy/development_stages_support.md)로 GitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645)에서 도입되었으며 [플래그](../../../../administration/feature_flags/_index.md) `duo_code_review_on_agent_platform`로 명명되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 18.8에서 [정식 출시(GA)](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273). 기능 플래그 `duo_code_review_on_agent_platform`이 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209)되었습니다.
- GitLab 18.10부터 GitLab.com의 Free 티어에서 GitLab Credits를 사용하여 이용 가능.
- LLM이 GitLab 19.1에서 Claude Sonnet 4.6 Vertex로 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876)되었습니다.

{{< /history >}}

> [!note]
> 추가 기능에 따라 GitLab은 두 가지 코드 검토 기능 중 하나를 실행합니다:
>
> - Code Review 플로우: 에이전트 버전으로 GitLab Duo Agent Platform의 일부입니다.
> - GitLab Duo 코드 리뷰: 비에이전트 버전으로 GitLab Duo Enterprise 추가 기능이 있는 사용자만 사용할 수 있습니다.
>
> 이 페이지는 에이전트 버전을 설명합니다. [두 기능의 비교](../../../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)를 확인하세요.

Code Review 플로우는 에이전트 AI로 코드 검토를 간소화하는 데 도움이 됩니다.

이 플로우:

- 코드 변경 사항을 분석합니다.
- 리포지토리 구조 및 파일 간 종속성에 대한 향상된 문맥적 이해를 제공합니다.
- 실행 가능한 피드백이 포함된 상세한 검토 주석을 제공합니다.
- 프로젝트에 맞게 조정된 사용자 지정 검토 지침을 지원합니다.

이 플로우는 GitLab UI에서만 사용할 수 있습니다.

## 전제 조건 {#prerequisites}

- [GitLab Duo Agent Platform 전제 조건](../../_index.md#prerequisites)을 충족해야 합니다.
- **파운데이셔널 플로우 허용**과 **코드 리뷰**를 [최상위 그룹](_index.md#turn-foundational-flows-on-or-off)에 대해 켭니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- 여러 GitLab Duo 네임스페이스에 속한 경우 [기본 GitLab Duo 네임스페이스 설정](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)합니다.
- 프로젝트를 위해 [자체 러너를 구성](../execution.md#configure-runners)하거나 [GitLab 호스팅 러너](../../../../ci/runners/hosted_runners/_index.md)를 활성화해야 합니다.

## 플로우 사용 {#use-the-flow}

머지 리퀘스트에서 Code Review 플로우를 사용하려면:

1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 다음 방법 중 하나를 사용하여 검토를 요청합니다:
   - `@GitLabDuo`을 검토자로 할당합니다.
   - 주석 상자에 빠른 작업 `/assign_reviewer @GitLabDuo`을 입력합니다.
   - 주석 상자에 `@GitLabDuo`을 언급하고 검토를 요청합니다.

검토를 요청한 후 Code Review 플로우는 [세션](../../sessions/_index.md)을 시작하고 검토가 완료될 때까지 모니터링할 수 있습니다.

## 리뷰에서 GitLab Duo와 상호 작용 {#interact-with-gitlab-duo-in-reviews}

{{< history >}}

- 주석 상호 작용이 GitLab 19.1에서 GitLab Duo Agent Platform을 사용하도록 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/work_items/601102)되었습니다.

{{< /history >}}

GitLab Duo를 검토자로 할당하는 것 외에도 다음과 같은 방법으로 GitLab Duo와 상호 작용할 수 있습니다:

- 검토 주석에 답장하여 설명이나 대체 방법을 요청합니다.
- 모든 논의 스레드에서 `@GitLabDuo`을 언급하여 후속 질문을 합니다.

주석의 GitLab Duo와의 논의는 GitLab Duo Agent Platform을 사용하고 [크레딧을 사용](../../../../subscriptions/gitlab_credits.md)합니다.

GitLab Duo에 제공된 피드백은 다른 머지 리퀘스트의 나중 검토에 영향을 주지 않습니다. 이 기능 추가는 [이슈 560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116)에서 제안되었습니다.

## 문맥적 인식 {#contextual-awareness}

Code Review 플로우는 두 개의 스테이지에서 실행됩니다:

1. 사전 스캔: 플로우는 머지 리퀘스트 diff를 검사하고 이를 사용하여 프로젝트 리포지토리에서 가져올 관련 문맥을 식별합니다. 사전 스캔은 일반적으로 디렉토리 목록과 변경 사항에서 참조하는 테스트 및 종속성과 같은 관련 파일의 내용을 포함합니다. 가져오는 정확한 문맥은 diff 분석에 따라 달라집니다.
1. 검토: 플로우는 대규모 언어 모델에서 다음 데이터로 검토를 실행합니다. 검토 스테이지는 필요에 따라 추가 문맥을 가져올 수 없습니다.

   - 사전 스캔 단계의 결과입니다.
   - 머지 리퀘스트 제목입니다.
   - 머지 리퀘스트 설명입니다.
   - 머지 리퀘스트 diff입니다.
   - 파일의 원본 버전입니다.
   - 파일 이름입니다.
   - 사용자 지정 검토 지침입니다.

제외할 콘텐츠를 지정하려면 [GitLab Duo에서 문맥 제외](../../context.md#exclude-context-from-gitlab-duo)를 참조하세요.

### 파일 및 문맥 제한 {#file-and-context-limits}

Code Review 플로우는 프롬프트를 작동 가능한 크기로 유지하기 위해 두 가지 제한을 적용합니다:

- 10,000줄보다 긴 파일의 경우 diff만 모델로 전송됩니다. 전체 파일 콘텐츠는 포함되지 않습니다.
- 사전 스캔에서 수집하는 총 문맥은 대략 1 MiB로 제한됩니다. 제한을 초과하면 검토 스테이지가 실행되기 전에 문맥이 약 800 KiB로 잘립니다.

이러한 제한은 플로우가 수집하는 데이터에 적용되며 [선택한 모델의](../../model_selection.md) 문맥 창과는 별개입니다.

매우 큰 머지 리퀘스트의 경우 검토에서 잘린 문맥을 놓칠 수 있습니다. 위험을 줄이려면:

- 머지 리퀘스트를 더 작은 머지 리퀘스트로 분할합니다.
- [문맥 제외](../../context.md#exclude-context-from-gitlab-duo)를 검토와 관련이 없는 파일에 대해 수행합니다.

## 사용자 지정 코드 검토 지침 {#custom-code-review-instructions}

`mr-review-instructions.yaml` 파일을 사용하여 Code Review 플로우의 동작을 사용자 지정합니다.

리포지토리별 검토 지침으로 GitLab Duo를 안내할 수 있습니다:

- 특정 코드 품질 측면(예: 보안, 성능 및 유지 관리)에 집중합니다.
- 프로젝트에 고유한 코딩 표준 및 모범 사례를 시행합니다.
- 특정 파일 패턴을 맞춤형 검토 기준으로 대상 지정합니다.
- 특정 유형의 변경 사항에 대해 더 자세한 설명을 제공합니다.

Code Review 플로우는 `AGENTS.md`과 `SKILL.md` 파일을 참조하지 않습니다.

사용자 지정 지침을 구성하려면 [GitLab Duo에 대한 검토 지침 사용자 지정](../../customize/review_instructions.md)을 참조하세요.

## 프로젝트에 대한 GitLab Duo의 자동 검토 {#automatic-reviews-from-gitlab-duo-for-a-project}

{{< history >}}

- GitLab 18.0에서 UI 설정으로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/506537)되었습니다.

{{< /history >}}

GitLab Duo의 자동 검토는 프로젝트의 모든 머지 리퀘스트가 초기 검토를 받도록 합니다. 머지 리퀘스트가 생성된 후 다음의 경우를 제외하고 GitLab Duo가 검토합니다:

- 드래프트로 표시됩니다. GitLab Duo가 머지 리퀘스트를 검토하려면 이를 준비 상태로 표시합니다.
- 변경 사항이 없습니다. GitLab Duo가 머지 리퀘스트를 검토하려면 변경 사항을 추가합니다.

전제 조건:

- 프로젝트에서 최소한 [유지 관리자 역할](../../../permissions.md)이 있어야 합니다.

`@GitLabDuo`이 머지 리퀘스트를 자동으로 검토하도록 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **머지 리퀘스트**를 선택합니다.
1. **GitLab Duo 코드 리뷰** 섹션에서 **GitLab Duo에서 자동 검토 활성화**를 선택합니다.
1. **변경사항 저장**을 선택합니다.

자동 검토에 대한 크레딧 사용이 어떻게 귀속되는지에 대한 정보는 [실행되는 코드 검토 기능 결정](../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs)을 참조하세요.

## 그룹 및 애플리케이션에 대한 GitLab Duo의 자동 검토 {#automatic-reviews-from-gitlab-duo-for-groups-and-applications}

{{< history >}}

- GitLab 18.4에서 [베타](../../../../policy/development_stages_support.md#beta)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)되었으며 [플래그](../../../../administration/feature_flags/_index.md) `cascading_auto_duo_code_review_settings`로 명명되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 18.7에서 기능 플래그 `cascading_auto_duo_code_review_settings`가 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240).
- GitLab 19.1에서 GitLab.com의 새로운 GitLab Duo 평가판에 대해 기본적으로 [켜졌습니다](https://gitlab.com/gitlab-org/gitlab/-/work_items/592822).

{{< /history >}}

그룹 또는 애플리케이션 설정을 사용하여 여러 프로젝트에 대한 자동 검토를 활성화합니다.

GitLab 19.1 이상에서 GitLab.com의 새로운 GitLab Duo 평가판의 경우 그룹에 대한 자동 검토가 기본적으로 켜져 있습니다.

전제 조건:

- 그룹에 대한 자동 검토를 켜려면 그룹의 소유자 역할이 있어야 합니다.
- 모든 프로젝트에 대한 자동 검토를 켜려면 관리자여야 합니다.

그룹에 대한 자동 검토를 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **머지 리퀘스트** 섹션을 확장합니다.
1. **GitLab Duo 코드 리뷰** 섹션에서 **GitLab Duo에서 자동 검토 활성화**를 선택합니다.
1. **변경사항 저장**을 선택합니다.

모든 프로젝트에 대한 자동 검토를 활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo 코드 리뷰** 섹션에서 **GitLab Duo에서 자동 검토 활성화**를 선택합니다.
1. **변경사항 저장**을 선택합니다.

설정은 애플리케이션에서 그룹으로, 그룹에서 프로젝트로 계단식으로 적용됩니다. 더 구체적인 설정이 더 광범위한 설정을 무시합니다.

자동 검토에 대한 크레딧 사용이 어떻게 귀속되는지에 대한 정보는 [실행되는 코드 검토 기능 결정](../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs)을 참조하세요.

## 문제 해결 {#troubleshooting}

### `Error DCR4000` {#error-dcr4000}

`Code Review Flow is not enabled. Contact your group administrator to enable the foundational flow in the top-level group. Error code: DCR4000`라는 오류가 표시될 수 있습니다.

이 오류는 [기본 플로우](_index.md) 또는 Code Review 플로우가 꺼져 있을 때 발생합니다.

관리자에게 연락하여 최상위 그룹에 대해 Code Review 플로우를 켜달라고 요청합니다.

### `Error DCR4001` {#error-dcr4001}

`Code Review Flow is enabled but the service account needs to be verified. Contact your administrator. Error code: DCR4001`라는 오류가 표시될 수 있습니다.

이 오류는 Code Review 플로우가 켜져 있지만 최상위 그룹의 서비스 계정이 준비되지 않았거나 아직 생성 중일 때 발생합니다.

서비스 계정이 활성화될 때까지 몇 분 기다린 후 다시 시도합니다. 오류가 지속되면 관리자에게 연락하여 개발자 역할로 최상위 그룹에 서비스 계정이 생성되었는지 확인해 달라고 요청합니다.

### `Error DCR4002` {#error-dcr4002}

`No GitLab Credits remain for this billing period. To continue using Code Review Flow, contact your administrator. Error code: DCR4002`라는 오류가 표시될 수 있습니다.

이 오류는 현재 청구 기간에 할당된 GitLab Credits을 모두 사용했을 때 발생합니다.

관리자에게 연락하여 추가 크레딧을 구매하거나 다음 청구 기간이 시작될 때 크레딧이 재설정될 때까지 기다립니다.

### `Error DCR4003` {#error-dcr4003}

`<User>, you don't have permission to create a pipeline for Code Review Flow in this project. Contact your administrator to update your permissions. Error code: DCR4003`라는 오류가 표시될 수 있습니다.

이 오류는 Code Review 플로우가 CI/CD 파이프라인에서 실행되고 이 프로젝트에서 파이프라인을 생성할 권한이 없기 때문에 발생합니다.

관리자에게 연락하여 필요한 [파이프라인 실행 권한](../../../permissions.md)을 부여해 달라고 요청합니다.

### `Error DCR4004` {#error-dcr4004}

`<User>, you need to set a default GitLab Duo namespace to use Code Review Flow in this project. Please set a default GitLab Duo namespace in your preferences. Error code: DCR4004`라는 오류가 표시될 수 있습니다.

이 오류는 GitLab Duo가 검토를 시작한 사용자의 기본 GitLab Duo 네임스페이스를 식별할 수 없을 때 발생합니다.

설정에서 기본 GitLab Duo 네임스페이스를 [설정](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)한 후 검토를 다시 요청합니다.

### `Error DCR4005` {#error-dcr4005}

`Code Review Flow could not obtain the required authentication tokens to connect to the GitLab AI Gateway and the GitLab API. Please request a new review. If the issue persists, contact your administrator. Error code: DCR4005`라는 오류가 표시될 수 있습니다.

Code Review 플로우는 GitLab AI Gateway 및 GitLab API에 연결하기 위해 인증 토큰이 필요합니다. 이 오류는 일반적으로 GitLab Duo 설정이 잘못되었거나 일시적 인프라 문제로 인해 해당 토큰을 생성할 수 없을 때 발생합니다.

자체 관리 인스턴스의 경우 관리자에게 [GitLab Duo 설정](../../../../administration/gitlab_duo/configure/_index.md)을 확인해 달라고 요청합니다.

### `Error DCR4006` {#error-dcr4006}

`Code Review Flow could not add the service account to this project. Contact your administrator to verify that the service account has the required project access. Error code: DCR4006`라는 오류가 표시될 수 있습니다.

이 오류는 서비스 계정을 프로젝트의 멤버로 추가할 수 없을 때 발생합니다. 그룹 멤버십 잠금이 활성화되었거나 서비스 계정에 필요한 액세스 권한이 없을 때 발생할 수 있습니다.

관리자에게 연락하여 서비스 계정을 개발자로서 프로젝트에 추가할 수 있는지 확인해 달라고 요청합니다.

### `Error DCR4007` {#error-dcr4007}

`Code Review Flow is not available for this project. Contact your administrator to verify that the flow is enabled and the required configuration is in place. Error code: DCR4007`라는 오류가 표시될 수 있습니다.

이 오류는 플로우가 비활성화되었거나 프로젝트에 필요한 설정이 없을 때 발생합니다.

관리자에게 연락하여 프로젝트에 대해 [플로우가 활성화](_index.md#turn-foundational-flows-on-or-off)되었는지 확인해 달라고 요청합니다.

### `Error DCR4008` {#error-dcr4008}

`Code Review Flow could not create the required CI/CD pipeline. Please request a new review. If the problem persists, contact your administrator. Error code: DCR4008`라는 오류가 표시될 수 있습니다.

이 오류는 러너 가용성 문제 또는 내부 설정 문제로 인해 Code Review 플로우가 검토를 실행할 CI/CD 파이프라인을 생성하거나 설정할 수 없을 때 발생합니다.

검토를 다시 시작해 봅니다. 오류가 지속되면 관리자에게 연락합니다.

### `Error DCR4009` {#error-dcr4009}

`Code Review Flow could not retrieve the source branch for this merge request. Please request a new review. Error code: DCR4009`라는 오류가 표시될 수 있습니다.

이 오류는 Code Review 플로우가 머지 리퀘스트의 소스 브랜치를 검색할 수 없을 때 발생합니다.

검토를 다시 시작해 봅니다.

### `Error DCR5000` {#error-dcr5000}

`Something went wrong while starting Code Review Flow. Please try again later. Error code: DCR5000`라는 오류가 표시될 수 있습니다.

이 오류는 내부 오류로 인해 GitLab Duo Agent Platform이 Code Review 플로우를 시작할 수 없을 때 발생합니다.

검토를 다시 시작해 봅니다. 오류가 지속되면 관리자에게 연락합니다.

### 큰 머지 리퀘스트 검토에서 누락된 문맥 {#missing-context-in-large-merge-request-reviews}

Code Review 플로우는 머지 리퀘스트에 많은 큰 변경된 파일이 포함될 때 문맥을 놓칠 수 있습니다.

사전 스캔 결과가 [파일 및 문맥 제한](#file-and-context-limits)을 초과하고 검토 스테이지가 실행되기 전에 데이터가 잘릴 때 발생할 수 있습니다.

검토를 개선하려면:

- 머지 리퀘스트를 더 작은 머지 리퀘스트로 분할합니다.
- [문맥 제외](../../context.md#exclude-context-from-gitlab-duo)를 검토와 관련이 없는 파일에 대해 수행합니다.
- 유지 관리자 또는 소유자에게 [다른 모델 선택](../../model_selection.md)을 **Agentic Code Review** 설정을 사용하여 요청합니다.

### 설정 진단 스크립트 {#configuration-diagnostic-script}

문서화된 오류 코드에서 Code Review 플로우 문제의 원인을 식별할 수 없는 경우 진단 스크립트를 실행하여 GitLab Duo 설정을 확인할 수 있습니다.

스크립트는 모든 GitLab Duo Agent Platform 기능에 적용되는 검사를 포함하여 Code Review 플로우에 필요한 전체 설정 체인을 확인합니다.

자세한 정보는 [설정 진단 스크립트 실행](../../troubleshooting.md#run-the-configuration-diagnostic-script)을 참조하세요.

## 관련 항목 {#related-topics}

- [머지 리퀘스트에서의 GitLab Duo](../../../project/merge_requests/duo_in_merge_requests.md)
- [Agent Platform AI 모델](../../model_selection.md)
