# wayot-terraform
Terraform for WAYOT

## us-west-2
aws autoscaling group and slack notifications, EC2 and RDS

## gke
google gcp gke build using docker for search and mysql container for read replica db

### gcp setup
* gcloud auth login
* gcloud config set project <projectid>
* export GOOGLE_CLOUD_PROJECT=`gcloud config list project --format="value(core.project)"`
* export TF_VAR_project=$GOOGLE_CLOUD_PROJECT

### terraform
* terraform init
* terraform plan
* terraform apply

### mysql in gke
* gcloud beta container clusters get-credentials <cluster_name> --region <cluster_region> --project $GOOGLE_CLOUD_PROJECT
* kubectl get pods --all-namespaces
* kubectl apply -f mysql-volumeclaim.yaml
* kubectl get pvc
* kubectl create secret generic mysql --from-literal=MYSQL_ROOT_PASSWORD=<root_password>
* kubectl create -f mysql.yaml or kubectl replace -f mysql.yaml --force
* kubectl get pod -l app=mysql
* kubectl create -f mysql-service.yaml
* kubectl get service db
* ?

### kawf in gke
* gcloud beta container clusters get-credentials <cluster_name> --region <cluster_region> --project $GOOGLE_CLOUD_PROJECT
* gcloud auth configure-docker
* (you will need to have built the docker image for kawf
* docker tag kawf us.gcr.io/$GOOGLE_CLOUD_PROJECT/kawf
* docker push us.gcr.io/$GOOGLE_CLOUD_PROJECT/kawf
* kubectl get pods --all-namespaces
* kubectl create secret generic kawf --from-literal=RO_PASSWORD=<ro_password> --from-literal=MYSQL_PASSWORD=<mysql_password>
* kubectl create -f kawf.yaml or kubectl replace -f kawf.yaml --force
* kubectl get pod -l app=kawf
* kubectl create -f kawf-service.yaml
* kubectl get service kawf
* kubectl exec -it kawf... -- /bin/bash
* $ `/var/www/html/docker/init-db.sh`
* ?

### mysql read replica in gke
* gcloud beta container clusters get-credentials <cluster_name> --region <cluster_region> --project $GOOGLE_CLOUD_PROJECT
* kubectl get pods --all-namespaces
* kubectl apply -f mysql-volumeclaim.yaml
* kubectl get pvc
* kubectl create secret generic mysql --from-literal=MYSQL_ROOT_PASSWORD=<root_password>
* kubectl create -f mysql.yaml or kubectl replace -f mysql.yaml --force
* kubectl get pod -l app=mysql
* kubectl get service db
* ?

### search wayot in gke
* gcloud beta container clusters get-credentials <cluster_name> --region <cluster_region> --project $GOOGLE_CLOUD_PROJECT
* gcloud auth configure-docker
* (you will need to have built the docker image for kawf
* docker tag kawf us.gcr.io/$GOOGLE_CLOUD_PROJECT/kawf
* docker push us.gcr.io/$GOOGLE_CLOUD_PROJECT/kawf
* kubectl get pods --all-namespaces
* kubectl create secret generic kawf --from-literal=RO_PASSWORD=<ro_password> --from-literal=MYSQL_PASSWORD=<mysql_password>
* kubectl create -f kawf.yaml or kubectl replace -f kawf.yaml --force
* kubectl get pod -l app=kawf
* kubectl create -f kawf-service.yaml
* kubectl get service kawf
* kubectl exec -it kawf... -- /bin/bash
* $ `/var/www/html/docker/init-db.sh`
*  

