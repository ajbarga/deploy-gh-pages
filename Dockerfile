FROM node:18

COPY ./entrypoint.sh /entrypoint.sh

RUN apt-get -y upgrade &&\
    apt-get -y update &&\
    apt-get -y install curl &&\
    apt-get -y install jq &&\
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
