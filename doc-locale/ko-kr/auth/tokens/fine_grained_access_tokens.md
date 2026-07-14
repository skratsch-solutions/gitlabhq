---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 개인 액세스 토큰의 상세조정 권한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/18555)되었으며 [베타](../../policy/development_stages_support.md#beta) 상태입니다.

{{< /history >}}

상세조정 개인 액세스 토큰은 정의된 특정 리소스와 권한만 액세스하도록 범위가 설정됩니다. 토큰을 생성할 때 다음 특성을 정의합니다:

- 리소스: API 작업의 집합입니다. 리소스는 더 큰 범위 중 하나로 그룹화됩니다( `Group and project` 및 `User`).
- 권한: 토큰이 리소스에서 수행할 수 있는 특정 작업입니다. 일반적으로 만들기, 읽기, 업데이트 및 삭제 작업을 준수합니다.

## 상세조정 개인 액세스 토큰 생성 {#create-a-fine-grained-personal-access-token}

상세조정 개인 액세스 토큰을 생성하려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **개인 액세스 토큰**을 선택합니다.
1. **토큰 생성** 드롭다운 목록에서 **상세조정 토큰**을 선택합니다.
1. **토큰 이름**에 토큰의 이름을 입력합니다.
1. **토큰 설명**에 토큰에 대한 설명을 입력합니다.
1. **만료일**에 토큰의 만료 날짜를 입력합니다.
   - 토큰은 그 날짜의 자정 UTC에 만료됩니다.
   - 날짜를 입력하지 않으면 만료일이 오늘로부터 365일로 설정됩니다.
   - 기본적으로 만료일은 오늘로부터 365일을 초과할 수 없습니다. GitLab 17.6 이상에서는 관리자가 [액세스 토큰의 최대 수명을 수정](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)할 수 있습니다.
1. 개인 액세스 토큰의 범위를 정의합니다.
   1. 왼쪽 패널에서 하나 이상의 리소스를 선택합니다.
   1. 그룹 또는 프로젝트 리소스를 포함하는 경우 `Group and project access` 섹션에서 옵션을 선택합니다.
   1. 오른쪽 패널에서 각 리소스에 사용 가능한 권한을 선택합니다.
1. **토큰 생성**을 선택합니다.

개인 액세스 토큰이 표시됩니다. 개인 액세스 토큰을 안전한 위치에 저장합니다. 페이지를 떠나거나 새로 고친 후에는 다시 볼 수 없습니다.

## 사용 가능한 세분화된 권한 {#available-fine-grained-permissions}

상세조정 개인 액세스 토큰이 사용할 수 있는 권한은 토큰이 호출하는 API에 따라 다릅니다:

- [상세조정 개인 액세스 토큰 지원이 포함된 REST API 엔드포인트](fine_grained_access_tokens_rest.md)
- [상세조정 개인 액세스 토큰 지원이 포함된 GraphQL 필드](fine_grained_access_tokens_graphql.md)
