FROM gpu/conda-torch-tensorflow:public
LABEL maintainer="qitianliang@outlook.com"
# my self file
WORKDIR /root/.ssh/
COPY  id_rsa.pub .
COPY id_rsa .
# temp password for root
RUN echo "root:yourownpassword" | chpasswd
WORKDIR /workspace

# CMD ["/usr/sbin/sshd", "-D"]
# docker build -f liang.dockerfile -t gpu/conda-torch-tensorflow:liang .