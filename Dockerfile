FROM node:18

COPY ./entrypoint.sh /entrypoint.sh

RUN sudo apt update &&\
    sudo apt upgrade &&\
    sudo apt install curl &&\
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
