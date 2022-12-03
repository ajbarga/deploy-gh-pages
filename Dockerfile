FROM python:3.10

COPY ./entrypoint.sh /entrypoint.sh
COPY ./main.py /main.py

RUN pip install --no-cache-dir pygithub==1.55 &&\
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
