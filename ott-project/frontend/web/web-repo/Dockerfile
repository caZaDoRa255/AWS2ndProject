# 베이스 이미지
FROM node:20

# 앱 디렉토리 생성
WORKDIR /app

# 의존성 복사 및 설치
COPY package*.json ./
RUN npm install

# 소스 코드 복사
COPY . .

# 앱 빌드
RUN npm run build

# Nginx로 빌드 결과를 서빙
FROM nginx:alpine
COPY --from=0 /app/build /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]