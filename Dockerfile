FROM eclipse-temurin:8-jdk-alpine

WORKDIR /app

COPY target/timesheet-devops-1.0.jar app.jar

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "app.jar"]
