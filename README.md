# wideops-task 

* creating SSH key in order to make VM's ssh to each other:

 ssh-keygen -f /tmp/temp_id_rsa -C ubuntu@mongodb-rs

* creating instance template:

   gcloud compute instance-templates create mongodb-replicaset-template --machine-type e2-medium --image-family ubuntu-1804-lts --image-project ubuntu-os-cloud --boot-     disk-type pd-ssd --boot-disk-size 25GB --tags mongodb-replicaset --scopes=https://www.googleapis.com/auth/cloud-platform --metadata mongodb_ssh_priv_key="$(cat          /tmp/temp_id_rsa)",mongodb_ssh_pub_key="$(cat /tmp/temp_id_rsa.pub)"

* creating instance group:

  gcloud compute instance-groups managed create mongodb-replicaset --base-instance-name mongodb-rs --size 3 --region europe-west1 --template mongodb-replicaset-template

* install mongoDB,set ssh key and set up the MongoDB server config file on each VM:
   
   connect to VM's:

   gcloud compute ssh --zone "europe-west1-b" "mongodb-rs-wsq8"  --project "wideops-task-devops"
   
   gcloud compute ssh --zone "europe-west1-d" "mongodb-rs-0swq"  --project "wideops-task-devops"
   
   gcloud compute ssh --zone "europe-west1-c" "mongodb-rs-2b1c"  --project "wideops-task-devops"
   
  
  set ssh:
  
  curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/mongodb_ssh_priv_key -H "Metadata-Flavor: Google" > /home/ubuntu/.ssh/id_rsa
  chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
  chmod 600 /home/ubuntu/.ssh/id_rsa
  
  install mongoDB: 
  
  sudo apt-get install gnupg
  
  sudo wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
  
  echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.com/apt/ubuntu bionic/mongodb-enterprise/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-   enterprise.list
  
  sudo apt-get update
  
  sudo apt-get install -y mongodb-enterprise
  
  echo "mongodb-enterprise hold" | sudo dpkg --set-selections
  
  echo "mongodb-enterprise-server hold" | sudo dpkg --set-selections
  
  echo "mongodb-enterprise-database hold" | sudo dpkg --set-selections
  
  echo "mongodb-enterprise-shell hold" | sudo dpkg --set-selections
  
  echo "mongodb-enterprise-mongos hold" | sudo dpkg --set-selections
  
  echo "mongodb-enterprise-tools hold" | sudo dpkg --set-selections
  
  
  
