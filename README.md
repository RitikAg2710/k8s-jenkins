Jenkins + Minikube Setup & Troubleshooting Notes

1️⃣ Docker Jenkins Container Run
docker run -d -p 8080:8080 -p 50000:50000 \
  -v C:\Users\bhumi\Jenkins:/var/jenkins_home/k8s-config \
  -v jenkins_home:/var/jenkins_home \
  --name jenkins1 jenkins/jenkins:lts


Purpose:

-p 8080:8080 → Jenkins UI

-v C:\Users\bhumi\Jenkins:/var/jenkins_home/k8s-config → Share local kubeconfig/certs

-v jenkins_home:/var/jenkins_home → Jenkins persistent data

2️⃣ Git Checkout in Pipeline
git branch: 'main', 
    url: 'https://github.com/RitikAg2710/k8s-jenkins.git', 
    credentialsId: 'git-jen-id'


git-jen-id → GitHub authentication

Ensures Jenkins can checkout code without manual credentials

3️⃣ Kubernetes Deployment in Pipeline
withEnv(["KUBECONFIG=/var/jenkins_home/k8s-config/config"]) {
    sh 'kubectl apply -f deployment.yaml -f nodeport.yaml'
}


Initially failed due to missing or misconfigured certificate paths

4️⃣ Copy Certificates to Jenkins

Required files from local Minikube:

client.crt
client.key
ca.crt
config


Copied / volume-mounted to Jenkins container:

C:\Users\bhumi\Jenkins → /var/jenkins_home/k8s-config

5️⃣ Edit kubeconfig Paths in Jenkins
client-certificate: /var/jenkins_home/k8s-config/client.crt
client-key: /var/jenkins_home/k8s-config/client.key
certificate-authority: /var/jenkins_home/k8s-config/ca.crt


Ensures kubectl reads correct certificate files inside container

6️⃣ Test kubectl inside Jenkins Container
docker exec -it jenkins1 bash
kubectl --kubeconfig=/var/jenkins_home/k8s-config/config get pods -A


Error:

dial tcp 192.168.49.2:8443: i/o timeout


Reason: Jenkins container cannot reach Minikube API directly → network isolation

7️⃣ Workaround: kubectl proxy

On host (Windows):

kubectl proxy --address=0.0.0.0 --accept-hosts='.*'


Optionally, update kubeconfig to use proxy address:

server: http://host.docker.internal:8001


Allows Jenkins container to reach Minikube API through host proxy

8️⃣ Volume Mount Explanation
-v C:\Users\bhumi\Jenkins:/var/jenkins_home/k8s-config


Purpose: Share local kubeconfig + certs with Jenkins container

Alternative (secure): Use Jenkins secret file credential (k8-jen-id) + withCredentials

9️⃣ Credentials vs Config
Credential	Purpose	Pipeline use
git-jen-id	GitHub authentication	Git checkout step
k8-jen-id	Kubeconfig secret file	Optional: can be used with withCredentials
🔟 Final Pipeline Structure
pipeline {
    agent any
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', 
                    url: 'https://github.com/RitikAg2710/k8s-jenkins.git', 
                    credentialsId: 'git-jen-id'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withEnv(["KUBECONFIG=/var/jenkins_home/k8s-config/config"]) {
                    sh '''
                        echo "🚀 Deploying to Kubernetes..."
                        kubectl apply -f deployment.yaml -f nodeport.yaml
                        kubectl get pods
                        kubectl get svc
                    '''
                }
            }
        }
    }
    post {
        success { echo '✅ Deployment Successful!' }
        failure { echo '❌ Deployment Failed!' }
    }
}

Key Notes / Learnings

Jenkins container cannot directly reach Minikube on Windows → i/o timeout

Certificates and kubeconfig must have correct paths inside container

Volume mount vs Jenkins secret:

Volume mount → simple, direct access

Secret file → secure, use withCredentials

GitHub checkout requires git-jen-id credentials

kubectl inside Jenkins requires working network to Minikube API (via proxy or host networking)

✅ Result:

Mounted kubeconfig is read

kubectl commands only work if network to Minikube API is accessible

Pipeline can deploy and check pods once proxy / networking is set
