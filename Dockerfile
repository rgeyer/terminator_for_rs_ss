FROM python:2.7
ENV PYTHONBUFFERED 1
RUN mkdir /code
WORKDIR /code
ADD . /code/
RUN pip install -r requirements.txt
RUN cd /tmp && curl -O https://binaries.rightscale.com/rsbin/wstunnel/1.0/wstunnel-linux-amd64.tgz && tar -zxf /tmp/wstunnel-linux-amd64.tgz -C /usr/bin
RUN apt-get update && apt-get install -y sqlite3
