# syntax=docker/dockerfile:1

FROM openjdk:16-alpine3.13

WORKDIR /app
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline

COPY src ./src

RUN ./mvnw spring-javaformat:apply
CMD ["./mvnw", "spring-boot:run", "-Dspring-boot.run.profiles=mysql"]
