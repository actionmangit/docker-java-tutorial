# Docker Java Tutorial

> powershell 환경에서 작성되었습니다.

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
Parser Directives(파서 지시문)의 syntax diriective(구문 지시문) 이다. BuildKit이 허용되는 환경에서만 동작하며 Dockerfile 빌드하는데 사용할 Dockerfile syntax 위치와 버전을 정의한다. __docker/dockerfile:1__ 의경우 1 version의 minor(1.\*.1), patch(1.1.\*) 버전을 모두 받는 다는 의미이다.

`WORKDIR /app`  
나머지 명령들을 더 쉽게 사용할 수 있도록 이미지내의 작업 디렉토리를 설정한다. 해당 구문 사용시 모든 후속 명령의 기본위치가 __app__ 으로 시작한다.

`COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline`  
maven의 빌드 종속성을 이미지 캐시화 하기위해 maven설정 파일을 copy하고 모든 종속성들을 다운로드한다.

### .dockerignore 파일 만들기

__COPY__ 명령어 사용시 불필요한 파일들이 이미지로 올라갈 수 도 있기 때문에 파일을 만들어 놓는것이 좋다. 해당 프로젝트의 경우 __target__ 폴더를 제외 한는것이 좋다. __context__ 내에 위치 시킨다.

## Build an image

아래 명령어로 이미지를 생성해보자.

```powershell
docker build --tag docker-java-tutorials .
```

`docker build` 명령어 실행시 __Dockerfile__과 __context__ 를 사용하여 이미지를 생성한다. __.__ 는 context를 지정한 것으로 docker build process는 context내 모든 파일들을 접근할 수 있다.

`/bin/sh: ./mvnw: not found` 메시지가 발생하며 build가 실행이 안되는 경우가 있는데 __mvnw__ 파일의 띄어 EOL문제 때문에 발생한다. CRLF -> LF로 변경시켜준다.

`./mvnw spring-javaformat:apply`  
Java 빌드시 Spring formater 오류가 발생할 수 있는데 위 명령어를 사용해서 Spring format을 적용 시킨다.

## Run a database in a container

아래 처럼 __volume__ 을 생성한다.

```powershell
docker volume create mysql_data
docker volume create mysql_config
```

브리지 네트웍크도 생성한다.

```powershell
docker network create mysqlnet
```

Docker hub 내의 mysql이미지를 사용하여 컨테이너를 구동시킨다.

```powershell
docker run -it --rm -d -v mysql_data:/var/lib/mysql `
-v mysql_config:/etc/mysql/conf.d `
--network mysqlnet `
--name mysqlserver `
-e MYSQL_USER=petclinic -e MYSQL_PASSWORD=petclinic `
-e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=petclinic `
-p 3306:3306 mysql:8.0.23
```

Dockerfile의 CMD문을 다음과 같이 수정하여 mysql을 사용하도록 하자.

```dockerfile
CMD ["./mvnw", "spring-boot:run", "-Dspring-boot.run.profiles=mysql"]
```

이미지를 새로 생성하고 다음과 같이 실행 시킨다.

```powershell
docker run --rm -d `
--name springboot-server `
--network mysqlnet `
-e MYSQL_URL=jdbc:mysql://mysqlserver/petclinic `
-p 9292:8080 actionmandocker/docker-java-tutorials
```

정상적으로 동작하는지 확인해보자.

```powershell
(Invoke-WebRequest  -method GET `
  -uri http://localhost:9292/vets `
  -contenttype application/json).Content
```

## Compose를 사용한 개발

`docker-compose.dev.yml` 파일을 생성하고 다음과 같이 입력한다.

```yml
version: '3.8'
services:
  petclinic:
    build:
      context: .
    ports:
      - 9000:8000
      - 9292:8080
    environment:
      - SERVER_PORT=8080
      - MYSQL_URL=jdbc:mysql://mysqlserver/petclinic
    volumes:
      - ./:/app
    command: ./mvnw spring-javaformat:apply spring-boot:run -Dspring-boot.run.profiles=mysql -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8000"

  mysqlserver:
    image: mysql:8.0.23
    ports:
      - 3306:3306
    environment:
      - MYSQL_ROOT_PASSWORD=
      - MYSQL_ALLOW_EMPTY_PASSWORD=true
      - MYSQL_USER=petclinic
      - MYSQL_PASSWORD=petclinic
      - MYSQL_DATABASE=petclinic
    volumes:
      - mysql_data:/var/lib/mysql
      - mysql_config:/etc/mysql/conf.d
volumes:
  mysql_data:
  mysql_config:
```

```yml
version: '3.8'
```

Compose file format 버전을 의미한다.

```yml
volumes:
      - ./:/app
```

바인딩 마운트를 사용하여 로컬PC 경로를 컨테이너 경로로 연결한다.

아래와 같이 실행해보자.

```powershell
docker-compose -f docker-compose.dev.yml up --build
```