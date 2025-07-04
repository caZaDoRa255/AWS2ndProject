#!/bin/bash

set -e  
#스크립트 실행 중에 에러가 나면 즉시 중단해라
#안 붙이면 에러가 나도 다음 줄을 실행해버려서 오류를 못 찾을 수 있음

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "🚀 Docker 이미지 빌드 중..."
docker build -t lambda-builder .

echo "📦 zip 추출 중..."
docker run --rm -v "$DIR":/out lambda-builder cp /lambda_function.zip /out/

echo "✅ 빌드 완료: $DIR/lambda_function.zip"

# 유저데이터: EC2를 부팅할 때 설정 & 초기화
# build.sh: 로컬에서 Docker 빌드 & zip 추출 자동화

# bash로 실행 가능하게 하려면 → #!/bin/bash : 셸 스크립트의 표준 첫 줄
# ✅ 에러를 바로 잡으려면 → set -e
# ✅ 진행상황 확인하려면 → echo로 출력