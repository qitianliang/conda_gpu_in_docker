# create local persist
sudo mkdir /local/persist/path/your_name
docker volume create -d local-persist -o mountpoint=/local/persist/path/your_name --name=your_name_devel_conda_env
# create container
docker run -d -p 20001-20003:20001-20003 -p 20000:22 -v /local/workspace:/workspace -v your_name_devel_conda_env:/opt/conda  --name your_conda_gpu_env --restart always --hostname your_host_name --runtime nvidia --ipc host gpu/conda-torch-tensorflow:public