# Docker Java Tutorial

## Java 이미지 생성

아래와 같이 Dockerfile을 작성한다.

```dockerfile
# syntax=docker/dockerfile:1

FROM openjdk:16-alpine3.13

WORKDIR /app

COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline

COPY src ./src

CMD ["./mvnw", "spring-boot:run"]
```

`# syntax=docker/dockerfile:1`  
Parser Directives(파서 지시문)의 syntax diriective(구문 지시문) 이다. BuildKit이 허용되는 환경에서만 동작하며 Dockerfile 빌드시 사용할 Dockerfile syntax위치를 정의한다.
