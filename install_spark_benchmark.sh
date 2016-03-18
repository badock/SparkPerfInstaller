#!/bin/bash

cd

# Clean installation
rm -rf spark-perf
rm spark-1.6.1-bin-hadoop2.6.tgz
rm -rf spark-1.6.1-bin-hadoop2.6


# Install dependencies
sudo yum install -y maven wget

# <Install ezserver monitor>
sudo yum erase -y httpd mysql-server php php-mysql
## Install Apache2 server
sudo yum install -y httpd
git clone https://github.com/shevabam/ezservermonitor-web.git
mv ezservermonitor-web/ monitor
sudo yum install -y mysql-server
sudo service mysqld start
sudo mysqladmin -u root password 'password'
sudo yum install -y php php-mysql

sudo service httpd start
# </Install ezserver monitor>



# Generate a ssh key
echo -e  'y\n' | ssh-keygen -f ~/.ssh/id_rsa -t rsa -N '' -q
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
sudo sed -i "s/# Host */Host */g" /etc/ssh/ssh_config
sudo sed -i "s/#   StrictHostKeyChecking ask/   StrictHostKeyChecking no/g" /etc/ssh/ssh_config

# Get spark binaries
wget http://apache.cs.utah.edu/spark/spark-1.6.1/spark-1.6.1-bin-hadoop2.6.tgz
tar -zxvf spark-1.6.1-bin-hadoop2.6.tgz
pushd spark*
SPARK_PATH=$(pwd)
popd

# Clone spark-perf repository
git clone https://github.com/databricks/spark-perf.git

pushd spark-perf


# Configure Spark
cp config/config.py.template config/config.py
sed -i "s#SPARK_HOME_DIR = .*#SPARK_HOME_DIR =\"$SPARK_PATH\"#g" config/config.py

sed -i 's#SPARK_CLUSTER_URL = .*#SPARK_CLUSTER_URL = "spark://%s:7077" % socket.gethostname()#g' config/config.py

sed -i 's#SCALE_FACTOR = .*#SCALE_FACTOR = .05#g' config/config.py

mkdir -p /home/cc/spark-perf/conf
touch /home/cc/spark-perf/conf/slaves
echo "127.0.0.1" >> /home/cc/spark-perf/conf/slaves

sed -i 's#SPARK_DRIVER_MEMORY = .*#SPARK_DRIVER_MEMORY = "512M"#g' config/config.py

# echo "spark.executor.memory = \"2g\"" >> config/config.py
# sed -i 's#spark.executor.memory = .*#spark.executor.memory = "2G"#g' config/config.py

popd

# Run Spark perf
bash spark-perf/bin/run

# grep SPARK_HOME_DIR spark-perf/config/config.py
# grep SPARK_CLUSTER_URL spark-perf/config/config.py
# grep SCALE_FACTOR spark-perf/config/config.py
# grep SPARK_DRIVER_MEMORY spark-perf/config/config.py
# grep spark.executor.memory spark-perf/config/config.py
