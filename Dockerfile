FROM amazoncorretto:17-alpine-jdk

EXPOSE 8080

WORKDIR /usr/app

COPY ./target/java-maven-app-*.jar app.jar
WORKDIR /usr/app

CMD java -jar app.jar
