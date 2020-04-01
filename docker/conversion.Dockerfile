FROM python:3.8
  
ENV HOME /home/col
ENV PATH /home/col/go/bin:$PATH
WORKDIR /home/col

# Install software dependencies
RUN apt-get update -y && apt-get install -y default-libmysqlclient-dev default-mysql-client default-mysql-client-core python3-pip python3-dev mdbtools curl git wget unzip

# Install python dependencies
RUN pip install --upgrade pip && \
    pip install mysql-connector-python requests && \
    pip install --upgrade git+git://github.com/gdower/coldpy.git
