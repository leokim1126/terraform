## 목적
이 파일은 AI 기반 코딩 에이전트(예: Copilot, GPT 에이전트)가 이 Terraform 학습/샘플 리포지토리에서 빠르게 생산적으로 작업할 수 있도록 핵심 컨텍스트와 규칙을 제공합니다.

## 프로젝트 개요 (한 문장 요약)
- 이 레포지토리는 여러 실습(labs)과 모듈 예제들로 구성된 Terraform 학습 저장소입니다. 주요 작업 단위는 디렉터리별 Terraform 구성(`main.tf`, `provider.tf`, `variables.tf`, `outputs.tf`)입니다.

## 주요 디렉터리 및 파일(참고용)
- `minipro1/` : 실습형 전체 VPC+EC2 구성 예제 (`provider.tf`, `main.tf`, `user_data.sh`, `make_config.sh`).
- `04/vpc-create/modules/` : 재사용 가능한 모듈 예제 (`vpc/`, `ec2/`) — 모듈 인터페이스는 `variables.tf`/`outputs.tf`로 정의됩니다.
- `03/global/s3/main.tf` : S3 버킷 및 DynamoDB 테이블 생성(원격 상태/잠금에 사용될 수 있음).
- 각 실습 폴더에 `terraform.tfstate`와 `terraform.tfstate.backup`가 체크인되어 있는 경우가 있으니 수정/삭제하지 마세요.

## 아키텍처/패턴 (발견 가능한 규칙)
- 인프라 구성은 디렉터리 단위로 분리되어 있으며 각 디렉터리에서 `terraform init` → `plan` → `apply` 흐름을 기대합니다.
- 모듈 패턴: `04/vpc-create/modules/vpc/main.tf` 와 `.../ec2/main.tf` 처럼 리소스를 작게 묶어 모듈로 재사용합니다. 실제 호출 코드는 상위 폴더(예: `dev/`, `prod/`)에 위치합니다.
- AMI 선택: 여러 곳에서 `data "aws_ami"`로 Canonical Ubuntu AMI(owners = `099720109477`)를 필터링하여 사용합니다 (`04/modules/ec2`, `minipro1`).
- 프로비저너/유저데이터: `minipro1/main.tf`는 `user_data_base64`와 `provisioner "local-exec"`을 사용합니다. 변경 시 재실행/부작용을 주의하세요.

## 개발자 워크플로(구체적 명령 예시)
- 로컬 실습 디렉터리에서 기본 흐름:
```
cd minipro1
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```
- 원격 상태가 구성된 경우(예: `03/global/s3`)에는 해당 백엔드 설정을 읽고 `terraform init`으로 초기화하세요. 이 레포지토리에는 S3 버킷/ DynamoDB 리소스 정의가 포함되어 있어 백엔드로 사용될 가능성이 있습니다.

## 보안·상태 주의사항 (필수)
- 리포지터리에 체크인된 `terraform.tfstate` 파일이 존재합니다. 상태 파일을 직접 편집하거나 삭제하지 마세요.
- 개인 키(`~/.ssh/*.pub`/private)나 민감한 값을 리포지터리에 추가하지 마십시오. 예: `minipro1`는 로컬 `~/.ssh/mykeypair.pub`를 참조합니다.

## 프로젝트 특이 규약(구체적)
- AWS 프로바이더 버전 고정: `minipro1/provider.tf`는 `hashicorp/aws` 버전 `6.26.0`을 요구합니다. 프로바이더 버전이나 프로필(region/profile) 설정을 변경할 때는 연관된 폴더 전체를 확인하세요.
- 리소스 태그: 각 리소스에 `Name` 태그를 일관되게 사용합니다(예: `Name = "myVPC"`). 새 리소스를 만들 때 태깅 관행을 따르세요.
- 네이밍: 예제에서는 리소스 id 대신 `aws_vpc.myVPC` 같은 로컬 이름을 사용합니다. 자동 생성된 이름 대신 명확한 로컬 식별자를 유지합니다.

## 에이전트 작업 규칙 (요청/수정 시)
- 변경 범위를 좁게 유지: 단일 디렉터리(예: `minipro1/` 또는 `04/vpc-create/dev/`)에만 변경을 적용하세요.
- 상태 파일은 건드리지 마세요. 상태 변경이 필요한 작업(예: 리소스 이름 변경)은 `terraform plan` 결과를 먼저 확인한 뒤 적용하세요.
- 로컬 프로비저너(`local-exec`)나 파일 참조(`file(...)`, `filebase64(...)`)를 수정하면 로컬 환경(SSH 키, 파일 경로 등)에 의존성이 생깁니다. 변경사항을 제안할 때는 대체 방법(예: remote-exec, null_resource+remote provisioner 등)을 함께 제시하세요.

## 참고 파일(예시 확인용)
- `minipro1/provider.tf`, `minipro1/main.tf` — 전체 예제 흐름과 로컬-exec 사용 사례
- `04/vpc-create/modules/vpc/main.tf`, `04/vpc-create/modules/ec2/main.tf` — 모듈 작성 패턴
- `03/global/s3/main.tf` — 원격 상태 백엔드로 사용 가능한 리소스 정의

## 변경 후 확인사항(체크리스트)
- `terraform init` 성공 여부
- `terraform plan`에서 의도치 않은 삭제/재생성 여부 없음
- 민감 정보(키, 비밀번호)가 커밋되지 않았는지 확인

---
피드백: 이 파일에서 더 보강할 항목(예: 특정 디렉터리의 백엔드 사용 예시, 테스트/검증 스크립트 추가)이 있으면 알려주세요.
