FROM python:3.11

ENV HOME /home/col
ENV PATH /home/col/go/bin:$PATH
WORKDIR /home/col

# Install software dependencies
RUN apt-get update -y && apt-get install -y default-libmysqlclient-dev default-mysql-client default-mysql-client-core python3-pip python3-dev curl git wget unzip zip

# Install python dependencies
RUN pip install --upgrade pip setuptools wheel
RUN pip install mysql-connector-python requests pyyaml
RUN pip install --pre --upgrade git+https://github.com/gdower/coldpy.git#egg=coldpy&version=0.1
