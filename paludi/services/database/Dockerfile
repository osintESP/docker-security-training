FROM postgres:16-alpine
LABEL maintainer="Paludi Team"
COPY init/ /docker-entrypoint-initdb.d/
USER postgres
