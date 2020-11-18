FROM pytorch/pytorch:1.6.0-cuda10.1-cudnn7-runtime
LABEL maintainer="qitianliang@outlook.com"

# update source
RUN sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu\//https:\/\/mirrors.tuna.tsinghua.edu.cn\/ubuntu\//g' /etc/apt/sources.list

# noninteractive 
ENV DEBIAN_FRONTEND=noninteractive
# clean some mismatch (cuda or machine learning version mismatch) update sources.
RUN rm -rf /etc/apt/sources.list.d/

# install necessary package
RUN apt-get update && apt-get install -y sudo openssh-server curl wget git fontconfig
# update the locale
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# add Chinese fonts
WORKDIR /usr/share/fonts
COPY SimHei.ttf .
RUN fc-cache -f -v

# set up ssh 
## allow sftp connection(for file transfer in pycharm)
RUN mkdir /var/run/sshd
RUN sed -ri 's@^Subsystem\s+.*@Subsystem sftp internal-sftp@' /etc/ssh/sshd_config
RUN sed -ri 's@^#PermitRootLogin\s+.*@PermitRootLogin yes@' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
## disable the ascii art text(for history version pycharm can not  connect remote bash which start with ascii art text )
# RUN rm /etc/bash.bashrc
# temp password for root
RUN echo "root:needupdate" | chpasswd
# conda environment
RUN echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc

WORKDIR /root
# tsinghua source
COPY .condarc .
RUN conda install -y tensorflow-gpu
RUN ln -s -f /opt/conda/bin/python /usr/bin/python
RUN ln -s -f /opt/conda/bin/python3 /usr/bin/python3
# ensure the known_host file can be created in ~/.ssh/ folder, root user may  not encounter this problem(no test),
# however, when you creat non-root user, this folder ~/.ssh/ can not be create by ssh connection process.
# As a result, you would retype ssh password each time you connect to this container.
WORKDIR /root/.ssh/
WORKDIR /workspace

CMD ["/usr/sbin/sshd", "-D"]
#docker build -t gpu/conda-torch-tensorflow:public .