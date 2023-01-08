# **wideops-task** 

## Creating SSH key in order to make VM's ssh to each other:

    ssh-keygen -f /tmp/temp_id_rsa -C ubuntu@mongodb-rs

## Creating instance template:

    gcloud compute instance-templates create mongodb-replicaset-template1 --machine-type e2-medium --image-family ubuntu-1804-lts --image-project ubuntu-os-cloud --boot-disk-type pd-ssd --boot-disk-size 25GB --tags mongodb-replicaset --scopes=https://www.googleapis.com/auth/cloud-platform --metadata mongodb_ssh_priv_key="$(cat /tmp/temp_id_rsa)",mongodb_ssh_pub_key="$(cat /tmp/temp_id_rsa.pub)"

  <img width="999" alt="image" src="https://user-images.githubusercontent.com/58177069/211147408-2da7abbc-6b1b-46bf-b6a9-e35cb44be7ef.png">

## Creating instance group:

    gcloud compute instance-groups managed create mongodb-replicaset --base-instance-name mongodb-rs --size 3 --region europe-west1 --template mongodb-replicaset-template1
  
  <img width="999" alt="image" src="https://user-images.githubusercontent.com/58177069/211147483-97c65a0f-ea38-4aca-8aea-615c2370f623.png">


## Install mongoDB,set ssh key and set up the MongoDB server config file on each VM:
   
   * **connect to VM's**:

    gcloud compute ssh --zone "europe-west1-b" "mongodb-rs-wsq8"  --project "wideops-task-devops"
   
    gcloud compute ssh --zone "europe-west1-d" "mongodb-rs-0swq"  --project "wideops-task-devops"
   
    gcloud compute ssh --zone "europe-west1-c" "mongodb-rs-2b1c"  --project "wideops-task-devops"
   
  
  * **Set SSH**:
  
        curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/mongodb_ssh_pub_key -H "Metadata-Flavor: Google" >> /home/ubuntu/.ssh/authorized_keys
        curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/mongodb_ssh_priv_key -H "Metadata-Flavor: Google" > /home/ubuntu/.ssh/id_rsa
        chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
        chmod 600 /home/ubuntu/.ssh/id_rsa
  
  * **Install mongoDB**: 
  
        sudo apt-get install gnupg
  
        sudo wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
  
        echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.com/apt/ubuntu bionic/mongodb-enterprise/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-    enterprise.list
  
        sudo apt-get update
  
        sudo apt-get install -y mongodb-enterprise
  
        echo "mongodb-enterprise hold" | sudo dpkg --set-selections
  
        echo "mongodb-enterprise-server hold" | sudo dpkg --set-selections
  
        echo "mongodb-enterprise-database hold" | sudo dpkg --set-selections
  
        echo "mongodb-enterprise-shell hold" | sudo dpkg --set-selections
  
        echo "mongodb-enterprise-mongos hold" | sudo dpkg --set-selections
  
        echo "mongodb-enterprise-tools hold" | sudo dpkg --set-selections
  
 * **set up the MongoDB server config**:
  
       sed -i 's/bindIp: 127\.0\.0\.1/bindIp: 0.0.0.0/g' /etc/mongod.conf
  
       cat >> /etc/mongod.conf <<EOF
       replication:
        replSetName: replicaset01
       EOF
    
    
## Set secondary node to arbiter node:
  connecting to first instance
    Mongo
  
    rs.initiate({ _id: "replicaset01", members: [ { _id: 0, host: "34.76.48.76" }, { _id: 1, host: "35.189.229.167" }, { _id: 2, host: "35.189.198.91" } ] })
  
    rs.remove("35.189.198.91:27017")
  
    rs.addArb("35.189.198.91:27017")
  
    Mongo
  
    rs.conf() 
 
    rs.conf().members[2].priority = 0
  
    rs.conf().members[0].priority = 5
  
    rs.conf().members[1].priority = 10
  
    rs.conf().members[2].arbiterOnly=true
  
    rs.conf().members[0].arbiterOnly=false
  
    rs.conf().members[1].arbiterOnly=false
  
    rs.reconfig(rs.conf())
  
    sudo service mongod restart
  
    mongo --norc --quiet --eval 'rs.status().members.forEach(function(member) {print(member["name"] + "\t" + member["stateStr"] + " \tuptime: " + member["uptime"] + "s")})'
  
  <img width="888" alt="image" src="https://user-images.githubusercontent.com/58177069/211147117-09db9106-2dc8-4daf-9e90-8f62ec3c893c.png">
  
  Update server on nodeapp.js:
  
   <img width="888" alt="image" src="https://user-images.githubusercontent.com/58177069/211147656-cfea594d-895a-49a3-b3e9-d0d992c834db.png">
   
## Deploy app on GKE:
   * **Build and push the Image to Container Registry:**
    
    gcloud builds submit --tag gcr.io/wideops-task-devops/nodeapp1
      
   * **create cluster:**
    
    gcloud container clusters create nodeapp-cluster --machine-type e2-medium--num-nodes 3 \
    
   * **connect to cluster:**
   
    gcloud container clusters get-credentials nodeapp-cluster --zone europe-west4-a --project wideops-task-devops
    
   * **Install kubectl**
   
    gcloud components install kubectl
  
   * **Create Deployment**
    
    kubectl create deployment nodeapp1 --image=gcr.io/wideops-task-devops/nodeapp1

    kubectl expose deployment nodeapp1 --type=LoadBalancer --port 80 --target-port 3000
    
    kubectl autoscale deployment nodeapp1 --max 10 --min 2

    
   <img width="443" alt="image" src="https://user-images.githubusercontent.com/58177069/211149213-9a5a1249-94fe-4cee-84f5-ebcde8072158.png">
   
   * **for https:**
   
   create ssl
   
    openssl req -x509 -nodes -days 9999 -newkey rsa:2048 -keyout ingress-tls.key -out ingress-tls.crt
    
   create secret
    
    kubectl create secret tls ingress-cert --key=ingress-tls.key --cert=ingress-tls.crt -o yaml
    
   <img width="443" alt="image" src="https://user-images.githubusercontent.com/58177069/211175228-aeafdad8-5378-4cf2-a1ba-e515165bb998.png">
   
   <img width="443" alt="image" src="https://user-images.githubusercontent.com/58177069/211175341-1168208a-67b0-4d49-a064-f0d4ecd5f11a.png">

    kubectl apply -f Ingress.yaml


   
   <img width="333" alt="image" src="https://user-images.githubusercontent.com/58177069/211172897-cd91c896-e039-4c46-90e6-00f78c2bbd29.png">


## Resources

 https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu/
 
 https://nodejs.org/en/docs/guides/nodejs-docker-webapp/
 
 https://www.mongodb.com/docs/manual/core/security-mongodb-configuration/
 
 https://hevodata.com/learn/mongodb-replica-set-config/
 
 https://subscription.packtpub.com/book/big-data-and-business-intelligence/9781787126480/4/ch04lvl1sec41/changing-priority-to-replica-set-nodes
 
 https://snyk.io/blog/setting-up-ssl-tls-for-kubernetes-ingress/
    
  
  


  
  
  
     
      
  
  
  
  
