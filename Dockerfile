FROM node:18

COPY ./entrypoint.sh /entrypoint.sh

RUN apt-get upgrade &&\
    apt-get update &&\
    apt-get install curl &&\
    apt-get install jq &&\
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
