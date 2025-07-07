#!/bin/bash

set -e  
#스크립트 실행 중에 에러가 나면 즉시 중단해라
#안 붙이면 에러가 나도 다음 줄을 실행해버려서 오류를 못 찾을 수 있음

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "🚀 Docker 이미지 빌드 중..."
docker build -t lambda-builder .

echo "📦 zip 추출 중..."
docker run --rm -v "$DIR":/out --entrypoint "/bin/bash" lambda-builder -c "cp /lambda_function.zip /out/"
# --entrypoint 옵션을 추가하여 이미지의 기본 ENTRYPOINT를 무시하고 bash를 실행
# -c는 bash 명령어를 직접 실행하기 위한 옵션
# ENTRYPOINT는 Dockerfile 명령어 중 하나로, 컨테이너가 시작될 때 항상 실행될 명령을 설정 
# 마치 운영체제의 부팅 스크립트나 프로그램의 메인 함수와 같음

echo "✅ 빌드 완료: $DIR/lambda_function.zip"

# 유저데이터: EC2를 부팅할 때 설정 & 초기화
# build.sh: 로컬에서 Docker 빌드 & zip 추출 자동화

# bash로 실행 가능하게 하려면 → #!/bin/bash : 셸 스크립트의 표준 첫 줄
# ✅ 에러를 바로 잡으려면 → set -e
# ✅ 진행상황 확인하려면 → echo로 출력