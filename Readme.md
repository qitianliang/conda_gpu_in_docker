# 设置 docker container + conda + vscode
> 本教程旨在完成torch, tensorflow 等依赖于GPU的python虚拟环境
>
> ##  构建镜像（基于torch 官方镜像）
>
> > 如果需要cuda compiler请使用devel版镜像，即`Dockerfile`中改为`FROM pytorch/pytorch:1.6.0-cuda10.1-cudnn7-devel`

* 更新了ubuntu 国内源
* 添加了`黑体`中文
* 更新了ubuntu 时区`亚洲/上海`
* 更新conda更新源码到清华开放镜像。
* 将 tensorflow-gpu 添加到 conda 基础 python 解释器中。

> 在宿主机器上构建脚本如下
```bash
docker build -t gpu/conda-torch-tensorflow:public .
```

> 它提供了一个conda环境，已经包括`pytorch=1.6.0`和`tensorflow=2.2.0`。
> 如果apt更新或conda安装中断，可能是镜像站点在同步过程中，等几分钟再重试。

如果你不需要git凭证，你可以简单地修改你的root密码该公有镜像环境(gpu/conda-torch-tensorflow:public)，可以供你自己使用。在容器中bash终端用`passwd`命令修改密码。


## 构建支持自有git的私有镜像

> 在宿主机器上构建脚本如下
```bash
docker build -f liang.dockerfile -t gpu/conda-torch-tensorflow:liang .
```

> 它从公共镜像添加了一个私有的git环境(添加了`id_rsa`)，并更新了root密码。

> 由`ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa`生成的`id_rsa`和`id_rsa.pub`复制到dockerfile的 相同的文件夹下。

## 创建容器
> 推荐使用[portainer](https://www.portainer.io/) 

### 绑定本地持续目录(可选，强烈推荐)

> 避免在conda创建新的Python环境导致容器尺寸越来越大，占用物理机的docker安装目录。

* 首先在你的服务器上安装 "local persist"（已测试过centos和ubuntu）。

> 在宿主机器上构建脚本如下

```bash
curl -fsSL https://raw.githubusercontent.com/MatchbookLab/local-persist/master/scripts/install.sh | sudo bash
```

* 创建你的本地持久化来挂载卷，而不是仅仅映射卷。

> 使用本地持久化工具创建挂载卷，做目录映射，挂载卷不会覆盖你的容器存在的文件夹及内容。

> 在宿主机器脚本如下
```
#首先为conda目录创建本地持久性。
docker volume create -d local-persist -o mountpoint=/host/folder --name=host_large_folder
```

### 创建你的容器

```bashv
docker run -d -p 10000:8888 -p 20000:22 -v your/host/path:your/container/path -v host_large_folder:/container/large/folder  --name your-container-name --restart always --hostname your_virtual_hostname --runtime nvidia --ipc host gpu/conda-torch-tensorflow:public
```
> 使用portianer配置目录映射时，方式为`volume`


## 额外教程：利用conda创造自己的python环境

创建一个`your_env_file.yaml`这样的文件

```yaml
name : your_env_name
dependencies :
  - python=3.7
  - scikit-learn
  - pip
  - pip:
    - tqdm
```

> 请注意，当你用`vi`命令编辑这个文件时，需要在依赖关系和`:`之间留出空白。

```bash
conda env create -f your_env_file.yaml
conda activate your_env_name
# remove env
conda env remove -n your_env_to_remove_name
```

### conda python 解释器路径
解释器路径是基于conda路径，这个容器是`/opt/conda/bin/python`，如果你创建了你的环境，你的解释器路径应该是`/opt/conda/envs/your_env_name/bin/python`。

你的环境配置完成了。

## 额外教程：发现一个大数据集没有做目录映射？

* 假设数据在宿主机上（可以是网络文件夹）的文件夹`/in/your/host/large/dataset`，c在容器中映射的目录`/your/container/map/directory/dataset`创建一个软链接，链接到大数据集文件夹，这样不额外占空间又能访问。
```
ln -s /in/your/host/large/dataset /your/container/map/directory/dataset
```
## 额外教程：nas存储非常大的数据集

* 启用网络文件夹服务(NFS)并将你的nas挂载到服务器上。
详见 [synology.NFS](https://www.synology.com/en-us/knowledgebase/DSM/tutorial/File_Sharing/How_to_access_files_on_Synology_NAS_within_the_local_network_NFS)

* 永久挂载

```
nano /etc/fstab
# add this line to your fstab file
ip:/volume1/public_dataset /nfs/public_dataset nfs defaults 0 0
```

## 在vscode中设置远程开发环境。

### 插件: Remote Development(可能包含了 WSL, Container, SSH and e.t.c)

![plugin](./pngs/plugins_.png)

### 保存ssh key

1. `remote explorer` > `SSH Targets` > `Configure`(cursor on SSH TARGETS)>`~\.ssh\config`, 添加以下内容

```config
Host your-server
    User root
    ControlMaster auto
    ControlPersist yes
    IdentityFile ~/.ssh/id_rsa_your-server
    Port 22
    HostName 255.255.255.255
```

![ssh_key](./pngs/ssh_key_.png)
![ssh_key1](./pngs/ssh_key1_.png)
![ssh_key2](./pngs/ssh_key2_.png)
![ssh_key3](./pngs/ssh_key3_.png)



2. 创建你的RSA文件来保存密钥(避免远程连接时重新输入密码)。

```
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_your-server
ssh-copy-id -f -i ~/.ssh/id_rsa_your-server your-server
# input root password, public Dockerfile default is needupdate

```

![ssh_key4](./pngs/ssh_key4_.png)


现在可以不用重新输入密码进行连接了。



## vscode 容器环境（ssh到容器）

插件: Python, Pylance(AI for python autocomplete)

## vscode 技巧

* 创建一个扩展名为 "*.ipynb "的文件，将得到一个jupyter notebook交互式python环境。

* 插入`#%%`将`*.py`文件转换为互动模式。
![vscode_tip](./pngs/vscode_tip_.png)

你的vscode配置完成了。



