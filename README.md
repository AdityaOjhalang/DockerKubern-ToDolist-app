# Kubernetes and Docker (HW-2)

### Submitted By- 
Aditya Ojha (ao2612)
Ananya Kumar Gangver (akk8368)

---

### Containerizing the application

For this part of the assignment we need to have `docker` and `docker-compose` installed on the machine.

```jsx
$ docker --version
Docker version 25.0.3, build 4debf41

$ docker compose version
Docker Compose version v2.24.5-desktop.1
```

To containerize the application, we need to create a `DockerFile` with the following steps to create the image.

```yaml
# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the current directory contents into the container at /usr/src/app
COPY . .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Define environment variables
ENV FLASK_APP=app.py FLASK_RUN_HOST=0.0.0.0

# Expose port 3000
EXPOSE 3000

# Run the application
CMD ["flask", "run", "--host=0.0.0.0", "--port=3000"] 
```

1. `FROM python` : This line specifies the base image for the container. In this case, it's using the official Python image as the base for the container.
2. `WORKDIR /usr/src/app` : It sets the working directory within the container to /app . This is where subsequent commands will be executed.
3. `COPY . .` : This line copies the contents of the local directory named web into the current working directory of the container. The dot . represents the current directory in the container.
4. `RUN pip install -r requirements.txt` : This command runs the pip install command inside the container. It installs the Python packages listed in the requirements.txt file, assuming that the file exists in the current working directory of the container.
5. `EXPOSE 3000` : This line informs Docker that the container will listen on port 3000. However, it doesn't actually publish the port to the host system. We'll need to map this port when running the container.
6. `CMD ["flask", "run", "--host=0.0.0.0", "--port=3000"]`: Specifies the command to run when the container starts. It launches the Flask application using the `flask run` command, specifying the host as `0.0.0.0` and the port as `3000`. This command starts the Flask development server and makes the application accessible on port `3000`.

Once the `DockerFile` has been created, the next step is to build the image.

`docker build -t adityaojhalang/flask-app:latest .`

---

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled.png)

### Pushing to Dockerhub

We can run the following command to push our image to Dockerhub

`docker push adityaojhalang/flask-app .`    

We can see on `DockerHub` that image was pushed successfully.

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%201.png)

---

### Testing the application locally

We will utilize `docker-compose` to create containers for both the Flask application and a MongoDB instance. The Docker Compose file is written using YAML.

```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      - mongodb
    environment:
      - FLASK_ENV=development
      - MONGO_HOST=mongodb
  mongodb:
    image: mongo:latest
    volumes:
      - mongo-data:/data/db

volumes:
  mongo-data:

```

- `service` : This is a the top-level key in Docker Compose File, and it defines the list of services or containers we want to create and manage.
- `web` : This is the name of the first service, which is called “web”.
- `build` : `.` It specifies the Docker image to use for the “web” service. In this case, Docker builds the image using a Dockerfile, typically for local development or when you need to customize the image.
- `ports` : This section defines port mapping for the container. Here, it maps the host port 3000 to the container port 3000. So that we can access the Flask application on out host machine at port 3000, and Docker will forward the traffic to the Flask application running inside the container port 3000.
- `depends_on` : This specifies that the “web” service depends on “mongodb” service. It ensures that the “mongodb” service is started before the “web” service. This is important since our Flask application relies on the MongoDB service.
- `environment` : In this section, we can set environment variables for the “web” service. Here, it’s setting the MONGO_HOST environment variable to “mongodb”. This tells the Flask application where to find the MongoDB service.
- `mongodb` : This is the name of the second service, which is called “mongodb”.
- `image`: `mongo:latest` This specifies the Docker image to use for the “mongodb” service. It’s using the official MongoDB image.
- `volumes` :  This is used to define a data volume for the "mongodb" service. This is typically used to persist data outside the container, ensuring that data is not lost when the container is stopped or removed.

In summary, this Docker Compose file configures two services: one for our Flask web application and another for a MongoDB database. It specifies their respective Docker images, port mappings, dependencies, environment variables, and data volume to create a complete and interrelated application environment.

`docker compose up`   We will see the following output for docker compose up we can see that our application is running on [localhost](http://localhost):3000

![Screenshot 2024-03-18 at 8.59.07 PM.png](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Screenshot_2024-03-18_at_8.59.07_PM.png)

Here is the website’s user interface when I visit `localhost:3000`

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%202.png)

---

### Deploying the application on MiniKube

```bash
minikube version
minikube version: v1.32.0
commit: 8220a6eb95f0a4d75f7f2d7b14cef975f050512d

kubectl version
Client Version: v1.29.2
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.28.3
```

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%203.png)

Next, we create the deployment and service for both the Flask app and MongoDB.

**→ This is the `flask-app-deployment.yaml` file and its explanation below.**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
spec:
  replicas: 2 # Specify the number of replicas
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
      - name: flask-app
        image: adityaojhalang/flask-app:latest 
# Replace with your Docker Hub image
        ports:
        - containerPort: 3000
        env:
        - name: FLASK_ENV
          value: "development"
        - name: MONGO_HOST
          value: "mongodb"
```

1. `apiVersion: apps/v1`: Defines the Kubernetes API version for the Deployment resource.
2. `kind: Deployment`: Specifies that this YAML file defines a Deployment resource, which is responsible for managing multiple instances (replicas) of a containerized application.
3. `metadata: name: flask-app`: Provides metadata for the Deployment, including its name, which is set as `flask-app`.
4. `spec: replicas: 2`: Specifies the desired state for the Deployment. In this case, it indicates that the Deployment should maintain two replicas of the application.
5. `selector: matchLabels: app: flask-app`: Defines how Kubernetes selects which Pods to manage with this Deployment. Pods with the label ‘app: flask-app’ will be managed by this Deployment.
6. `template: metadata: labels: app: flask-app`: Defines the template for the Pods managed by this Deployment. It sets the label ‘app: flask-app’ for all Pods created based on this template.
7. `spec.containers: - name: flask-app image: adityaojhalang/flask-app:latest ports: - containerPort: 3000`: Specifies the container(s) to be run within each Pod. Here, it defines a single container named flask-app using the specified Docker image (adityaojhalang/flask-app:latest) and exposes port `3000` within the container.
8. `env: - name: FLASK_ENV value: "development" - name: MONGO_HOST value: "mongodb"`: Sets environment variables within the container. It defines two environment variables: FLASK_ENV with a value of "development" and MONGO_HOST with a value of `"mongodb"`. These variables can be accessed by the application running inside the container.

**→ This is `flask-app_service.yaml` file and its explanation below.**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-app-service
spec:
  type: LoadBalancer
  ports:
  - port: 3000
    targetPort: 3000
    protocol: TCP
  selector:
    app: flask-app
```

- `apiVersion` : Specifies the API version of Kubernetes resource being defined.
- `kind` : Defines the kind of Kubernetes resource being created, which is a Service in this case. Services provide networking and IP address abstraction to Pods.
- `metadata` : Metadata section contains information about the Service, inclusing its name.
- `spec` : Section defines desired state of the Service. ‘type : LoadBalancer’ specifies that the Service should be exposed externally using a cloud providers load balancer.
- `ports` : specifies the ports that the Service will listen on and how traffic will be forwarded. Here, it defines a single port mapping where port `3000` on the Pods. The `protocol` is TCP.
- `selector` : specifies which Pods will be targeted by the Service. Here, it selects Pods with the label ‘app: flask-app’, menaing that the Service will forward traffic to Pods that have this label applied.

**→ This `mongodb-deployment.yaml` service and its explanation.**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:latest
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongo-storage
          mountPath: /data/db
      volumes:
      - name: mongo-storage
        emptyDir: {}
```

- `apiVersion: apps/v1` : Specifies the Kubernetes API version for the Deployment resource.
- `kind` : Defines a deployment, which manages a replicated application.
- `metadata : name : mongodb` : sets the metadata for the deployment, specifying its name as ‘mongodb’.
- `spec : replicas : 1` : specifies that deployment should have one replica.
- `selector` : select Pods with label ‘app : mongodb’ to manage.
- `template` : defines the Pod template with the label ‘app: mongodb’
- `spec.containers: - name: mongodb image: mongo:latest ports` : specifies a container named ‘mongodb’ using the ‘mongo: latest’ image, listening on port ‘27017’.
- `volumeMounts` : mounts an emptyDir volume names ‘mongo-storage’ to the container’s ‘/data/db’ directory.
- `volumes` : defines an emptyDir volume named ‘mongo-storage’ for temporary storage with the Pod.

For the PersistentVolumeClaim (`mongo-pvc`):

1. `apiVersion: v1`: Specifies the Kubernetes API version for the PersistentVolumeClaim resource.
2. `kind: PersistentVolumeClaim`: Defines a PersistentVolumeClaim, which is used to request storage resources.
3. `metadata: name: mongo-pvc`: Sets the metadata for the PersistentVolumeClaim, specifying its name as `mongo-pvc`.
4. `spec: accessModes: - ReadWriteOnce`: Specifies the access mode for the PersistentVolumeClaim, allowing read-write access from a single node.
5. `resources: requests: storage: 1Gi`: Requests storage resources for the PersistentVolumeClaim, specifying a size of 1 gigabyte.

**→ This is `mongodb-service.yaml`  service and its explanation.**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mongodb
spec:
  ports:
  - port: 27017
    targetPort: 27017
  selector:
    app: mongodb
```

- `apiVersion` : Specifies the Kubernetes API version for the Deployment resource. It is specifying the use of ‘v1’ API version.
- `kind` : defines the kind of Kubernetes resource being created, which is a Service in this case. Services provide networking and IP address abstraction to Pods.
- `Metadata` : metadata contains information about the Service, including its name(’mongodb’ in this case).
- `spec` : section defines the desired state of the service. ‘ports’ specifies the ports that the service will listen on and how traffic will be forwarded. Service is mapped to ‘27017’.
- `selector` : specifies which Pods will be targeted by the service. Here, it selects Pods with the label ‘app: mongodb’, meaning that the Service will forward traffic to Pods that have this label applied.

```yaml
kubectl apply -f flask-app-deployment.yaml
kubectl apply -f flask-app-service.yaml
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f mongodb-service.yaml
```

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%204.png)

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%205.png)

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%206.png)

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%207.png)

---

### Adding Load Balancer

To include `LoadBalancer` for web application, we need to update spec.type to LoadBalancer under `flask-app-service.yaml` .

```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-app-service
spec:
  type: LoadBalancer
  ports:
    - port: 3000
      targetPort: 3000
      protocol: TCP
  selector:
    app: flask-app
```

---

### Deploying the application on EKS

Instead of setting up EKS cluster through UI, we can easily do this by `eksctl CLI` which automates the creation using CloudFormation scripts.

```jsx
eksctl version
0.173.0

```

But before creating any cluster I needed to push a image to my Dockerhub using the command 

```yaml
docker build build --platform Linux/amd64 -t 
adityaojhalang/flask-app: latest --push =

```

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%208.png)

I created my cluster on EKS  using this command

```jsx
eksctl create cluster --name TodoListCluster 
--node-type=t2.large --nodes=4 --region=us-east-2
```

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%209.png)

This created a cluster on my AWS EKS as follows:

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2010.png)

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2011.png)

![Screenshot 2024-03-18 at 10.45.15 PM.png](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Screenshot_2024-03-18_at_10.45.15_PM.png)

Applying all the changes in the flask-app and mongodb files on eks.

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2012.png)

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2013.png)

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2014.png)

Running it on same external IP as mentioned in the Kubectl get svc command:

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2015.png)

We can see that our app is running on
[`http://aa22c19d2ff324d0ebb472c6c3d073ea-2017342896.us-east-2.elb.amazonaws.com:3000/`](http://aa22c19d2ff324d0ebb472c6c3d073ea-2017342896.us-east-2.elb.amazonaws.com:3000/)

---

### Adding Persistent Volume

Install the EBS CSI driver and controller on the nodes.

Then attach IAM role.

```jsx
eksctl code for create and utils associate iam-oidc-provider
```

We will create a claim for the persistent column, which will be fulfilled once a pod is attached to it.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

After this we will attach mongodb-deployment pod to the persistent volume and mount the location where data is saved.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
        - name: mongodb
          image: mongo:latest
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo-storage
              mountPath: /data/db
      volumes:
        - name: mongo-storage
          persistentVolumeClaim:
            claimName: mongo-pvc

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

For this to work I also needed to give some IAM permissions to my Node IAM Role arn
`arn:aws:iam::471112913653:role/eksctl-TodoListCluster-nodegroup-n-NodeInstanceRole-uKL6yA3tCxLi`

I added the following policies to my role:

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2016.png)

---

And these are all the policies attached to it:

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2017.png)

Once this was done I was able to get Bound status on my mongo-pvc.

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2018.png)

---

### Replacing Deployments with Replication Controller

To test the replication controller, we will delete the deployment that we previously applied. here is the replication controller yaml file that is applied.

`flaskapp-rc.yaml`

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: flask-app-rc  
# Adjusted to closely match the app naming convention
spec:
  replicas: 3
  selector:
    app: flask-app  
# Adjusted to match the application name
  template:
    metadata:
      labels:
        app: flask-app  
# Adjusted to ensure pod labels match the selector
    spec:
      containers:
      - name: flaskapp
        image: adityaojhalang/flask-app
        ports:
        - containerPort: 3000
```

We can see that after applying the changes to my `flask-app.yaml` file it create the desired number of replicas which is 3.

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2019.png)

In the images above, it can be seen that desired number of requested pods is 3, and currently 3 pods are running.

---

### Deleting one of the pods

Now let’s delete one of the replicas and see whether the replication controller is keeping the desired number of replicas or not.

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2020.png)

I deleted the pod `flaskapp-rc-gmfzp` and the replication controller instantly created a new one and replacing the delete one with `flaskapp-rc-vbcg7` , Hence it is working fine.

---

### Scaling up the replicas

Now let’s scale up the number of replicas mention in my replication controller file to 6.

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: flask-app-rc  
# Adjusted to closely match the app naming convention
spec:
  replicas: 6
  selector:
    app: flask-app  
# Adjusted to match the application name
  template:
    metadata:
      labels:
        app: flask-app  
# Adjusted to ensure pod labels match the selector
    spec:
      containers:
      - name: flaskapp
        image: adityaojhalang/flask-app
        ports:
        - containerPort: 3000
```

Now let’s apply these changes and see that whether the replication controller is scaling up the number of replicas or not.

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2021.png)

We can see that the number of replication went up to 6 hence our replication controller is working fine.

### Seeing the whole flow

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2022.png)

---

### Performing Rolling Update

We need to first push a new version of the image. 

```yaml
command similar to this
docker buildx build -platform linux/amd64 -t 
adityaojhalang/flask-app:v2 _ --load
```

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2023.png)

Pushing to Dockerhub

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2024.png)

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2025.png)

Updated `flask-deployment.yaml` file

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
spec:
  replicas: 2 
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
        - name: flask-app
          image: adityaojhalang/flask-app:v2 
# Changed to the latest version
          imagePullPolicy: Always
          ports:
            - containerPort: 3000
          env:
            - name: FLASK_ENV
              value: "development"
            - name: MONGO_HOST
              value: "mongodb"
  strategy: # Added the rolling update 
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
```

Running the command `kubectl rollout status deployment/flask-app`

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2026.png)

Checking the version it is running now through the following terminal command:

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2027.png)

---

### Liveness and Readiness Probes

Liveness and readiness probes which are updated in `flask-app-deployment.yaml` file.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
spec:
  replicas: 2 
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
        - name: flask-app
          image: adityaojhalang/flask-app:v2 
          imagePullPolicy: Always
          ports:
            - containerPort: 3000 
          env:
            - name: FLASK_ENV
              value: "development"
            - name: MONGO_HOST
              value: "mongodb"
          livenessProbe:              #Added Liveliness Probe
            tcpSocket:
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 3
          readinessProbe:            #Added Readiness Probe
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 10
            failureThreshold: 1
            
  strategy: # Define the update strategy
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
```

To evaluate the effectiveness of the readiness probe, I plan to remove the MongoDB service and its associated pod. This action will disrupt the connection between the Flask application and its MongoDB database, leading to a failure in the readiness probe checks with a 500 error code. As a result, traffic will not be directed to the affected pod. Given that all replicas in the set will encounter the same issue in connecting to the MongoDB instance, none of the pods will be eligible to receive incoming traffic. This situation will lead to clients being informed that the site is unavailable.

First lets see the describe pod command:

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2028.png)

We can see that liveliness and readiness is coming in describe pod output
Now let’s bring down the mongodb-service and see what happens:

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2029.png)

We can see that the flask app is now in not ready state and the readiness probe must also show that there is an error in the events section.

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2030.png)

The website should also thrown an error:

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2031.png)

Turning the mongodb service back on:

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2032.png)

Now as our pods are running the site should work just fine now:

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2033.png)

In a similar fashion we can test for the liveness probe as well. One way could be to not start the application and the liveness probe will fail to setup tcp connection on port 3000.

---

### Alerting with AWS Prometheus (Extra Credit)

The procedure involves transferring metrics data from the Metrics Server to the AMP (Application Monitoring Platform) using a Prometheus server installed within Kubernetes cluster via `Helm` . Below is detailed steps how we achieved it.

We can see that our prometheus server is up and running in namespace = prometheus

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2034.png)

- For this we first created `alertmanager-config.yaml` file. It consists of the web-hook url of slack-api, through which we will connect out Prometheus server to the slack channel.
- So that Prometheus server can push notifications to the slack channel whenever a pod crashes, have bad health or is unresponsive.
- Below is `alertmanager-config.yaml` file.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  annotations:
    meta.helm.sh/release-name: prometheus
    meta.helm.sh/release-namespace: prometheus
  creationTimestamp: "2024-03-18T18:44:34Z"
  labels:
    app.kubernetes.io/instance: prometheus
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: alertmanager
    app.kubernetes.io/version: v0.27.0
    helm.sh/chart: alertmanager-1.9.0
  name: prometheus-alertmanager
  namespace: prometheus
  resourceVersion: "243555"
  uid: 97dcdf6c-5e26-42d3-a53c-690e76c057c9
data:
  alertmanager.yml: |
    global:
      resolve_timeout: 1m
      slack_api_url: 'https://hooks.slack.com/services/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'
    route:
      receiver: 'slack-notifications'
      group_interval: 5m
      group_wait: 10s
      repeat_interval: 3h
    receivers:
    - name: 'slack-notifications'
      slack_configs:
      - channel: '#alerts-prometheus'
        send_resolved: true
        icon_url: https://avatars3.githubusercontent.com/u/3380462
        title: |-
          [{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] Monitoring - {{ .CommonLabels.alertname }}
          {{- if gt (len .CommonLabels) (len .GroupLabels) -}}
            {{" "}}(
            {{- with .CommonLabels.Remove .GroupLabels.Names }}
              {{- range $index, $label := .SortedPairs -}}
                {{ if $index }}, {{ end }}
                {{- $label.Name }}="{{ $label.Value -}}"
              {{- end }}
            {{- end -}}
            )
          {{- end }}
        text: >-
          {{ range .Alerts -}}
          *Alert:* {{ .Annotations.title }}{{ if .Labels.severity }} - `{{ .Labels.severity }}`{{ end }}
          *Description:* {{ .Annotations.description }}
          *Details:*
            {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
            {{ end }}
          {{ end }}
    - name: default-receiver
    templates:
    - /etc/alertmanager/*.tmpl
```

Explanation of the above file.

1. `apiVersion: v1`: Specifies the API version of the Kubernetes resource being defined.
2. `kind: ConfigMap`: Defines a ConfigMap, which allows you to store non-confidential data in key-value pairs.
3. `metadata`: Metadata section containing information about the ConfigMap.
    - `annotations`: Additional metadata annotations including Helm release name and namespace.
    - `creationTimestamp`: Timestamp indicating when the ConfigMap was created.
    - `labels`: Labels for categorizing and identifying the ConfigMap.
    - `name`: Name of the ConfigMap, which is `prometheus-alertmanager`.
    - `namespace`: Namespace where the ConfigMap resides, which is `prometheus`.
    - `resourceVersion`: Version of the resource.
    - `uid`: Unique identifier for the ConfigMap.
4. `data`: Data section containing key-value pairs.
    - `alertmanager.yml`: YAML configuration for Alertmanager, containing global settings, route configuration, receivers, and templates.

Here's a breakdown of the `alertmanager.yml` content:

- `global`: Global configurations for Alertmanager.
    - `resolve_timeout`: Timeout for resolving alerts, set to `1m` (1 minute).
    - `slack_api_url`: URL for sending notifications to Slack.
- `route`: Routing configurations for alerts.
    - `receiver`: Specifies the default receiver for alerts, set to `slack-notifications`.
    - `group_interval`: Interval for grouping similar alerts, set to `5m` (5 minutes).
    - `group_wait`: Time to wait before sending a notification for an alert group, set to `10s` (10 seconds).
    - `repeat_interval`: Interval for repeating notifications for the same alert, set to `3h` (3 hours).
- `receivers`: Definitions for notification receivers.
    - `name`: Name of the receiver, set to `slack-notifications`.
    - `slack_configs`: Configuration for sending alerts to Slack.
        - `channel`: Slack channel where notifications will be sent (`#alerts-prometheus`).
        - `send_resolved`: Indicates whether to send notifications when alerts are resolved (set to `true`).
        - `icon_url`: URL for the icon to be used in notifications.
        - `title`: Template for notification titles, including alert status, count, and details.
        - `text`: Template for notification messages, including alert details.
    - `name`: Default receiver name, set to `default-receiver`.
- `templates`: Path to the directory containing notification templates (`/etc/alertmanager/*.tmpl`).

We will now look into `prometheus-config.yaml`   specially the rules section which will be the rules if broken the alertmanager will send us a slack notification for.

```yaml

  rules: |
    groups:
      - name: example
        rules:
        - alert: CrashLoopBackOff
          expr: increase(kube_pod_container_status_restarts_total{job="kubernetes-service-endpoints"}[5m]) >= 1
          for: 1m
          labels:
            severity: critical
          annotations:
            summary: "Pod {{ $labels.pod }} is crashing frequently"
            description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has restarted {{ $value }} times in the last 5 minutes."
```

Certainly, here's a breakdown of the provided YAML configuration for a Prometheus alerting rule:

- `rules:` This begins the section for defining alerting rules.
- `groups:` This starts a list of groups for organizing multiple sets of rules.
- `name: example` This sets the name of the group to "example".
- `rules:` This begins the list of alerting rules within the group.
- `alert: CrashLoopBackOff` This defines a new alert named "CrashLoopBackOff".
- `expr:` This specifies the Prometheus expression that triggers the alert.
- `increase(kube_pod_container_status_restarts_total{job="kubernetes-service-endpoints"}[5m]) >= 1` The expression checks if the number of restarts for any container in the job "kubernetes-service-endpoints" has increased by 1 or more in the last 5 minutes.
- `for: 1m` This sets the condition that the above expression needs to be true for at least 1 minute before the alert is fired.
- `labels:` This begins the section to set labels for the alert.
- `severity: critical` This assigns a severity label with the value "critical" to the alert.
- `annotations:` This begins the section for adding additional information to the alert.
- `summary: "Pod {{ $labels.pod }} is crashing frequently"` This is a templated summary that will show which pod is crashing.
- `description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has restarted {{ $value }} times in the last 5 minutes."` This provides a detailed description and includes the namespace, pod name, and the value of the restart count in the message.

This configuration defines an alert for Prometheus that triggers if any container within a specified job experiences an increase in restarts within the last 5 minutes, and if this condition persists for at least 1 minute. When triggered, it classifies the alert as critical and provides annotations detailing which pod is crashing and how many times it has restarted.

Now let’s create a `crash-pod` which explicitlty hits out rules in the `prometheus-config` file

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: crash-loop-pod
spec:
  containers:
  - name: crash-loop-container
    image: busybox
    command: ["sh", "-c", "echo 'I am going to crash' && exit 1"]
```

Explanation of the above - 

This Kubernetes configuration defines a Pod named `crash-loop-pod`. Inside the Pod, there is a single container called `crash-loop-container` that uses the `busybox` image. When the container starts, it executes a command that prints "I am going to crash" to the console and then exits with a status code of `1`, which indicates an error. Since the container exits with an error, Kubernetes will try to restart it, creating a crash loop.

Let’s see the `kubectl get pods` output:

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2035.png)

Now we can see from the output that out crash-loop-pod is in the status `CrashLoopBackOff` , now we should see an alert in our prometheus UI and alertmanager UI.

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2036.png)

Here we can see that it is working as we expected as the rules is in the `Firing state` . Now the `alertmanager` should show a prompt that it fired the notification to our 

`Slack-channel (**alerts-prometheus**)`

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2037.png)

Alertmanager shows the output we expected and we should have received a notification in out `slack channel`.

![Untitled](Kubernetes%20and%20Docker%20(HW-2)%202ea777ebeed84dfe83ab113a049c70a4/Untitled%2038.png)

Here we can see that we have received a notification from Alertmanager in our slack channel  `(**alerts-prometheus**)` . It also shows all the metadata of the faulty pod, from this we can infer that.

> The "FIRING[1]" message from Alertmanager indicates that an alert has been triggered. In this context, the alert named `CrashLoopBackOff` is active. This particular alert signifies that a pod in the Kubernetes cluster, specifically `crash-loop-pod` in the `default` namespace, has been restarting frequently — it has restarted 219813 times in the last 5 minutes, which is an exceptionally high number and likely indicates a configuration issue or a failing application within the pod. The severity level of this alert is marked as `critical`, implying that immediate attention is required to address the issue.
> 

<aside>
💡 At last we can conclude this project involved containerization with Docker, orchestration with Kubernetes, and monitoring with Prometheus and Alertmanager, with integration to a Slack channel for notifications. It covers the containerization of a Flask application, its deployment using Minikube and EKS, the creation and handling of persistent volumes, and the setup of alerting for monitoring the application’s health and status. The document likely concludes with the successful execution of these tasks and the confirmation that alerts are correctly firing and being notified in Slack when specified conditions are met, such as a pod experiencing a crash loop.

</aside>

---
