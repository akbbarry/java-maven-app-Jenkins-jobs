#!/user/bin/env groovy

def gv

pipeline {
    agent any
    tools {
        maven 'maven-3.9'
    }
    environment {
        ECR_REGISTRY = "333968387482.dkr.ecr.us-east-2.amazonaws.com"
        ECR_REPOSITORY = "java-maven-app"
        APP_NAME = "java-maven-app"
        ANSIBLE_SERVER = "18.118.144.168"
    }
    stages {
        stage('increment version') {
            steps {
                script {
                    echo 'incrementing app version...'
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    def version = sh(
                        script: "grep -oPm1 '(?<=<version>)[^<]+' pom.xml",
                        returnStdout: true
                        ).trim()

                    env.IMAGE_NAME = "${version}-${BUILD_NUMBER}"
                    sh '''
                    mvn clean package
                    '''
                }
            }
        }
        stage('build image') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials']
                    ]) {
                        script {
                        sh """
                        export AWS_DEFAULT_REGION=us-east-2

                       aws ecr get-login-password --region us-east-2 | docker login \
                        --username AWS \
                        --password-stdin ${ECR_REGISTRY}
                        pwd

                        docker build -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_NAME} .

                        docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_NAME}
                        """
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials'
                    ]]) {
                        sh '''
                            export AWS_PAGER=""

                            aws sts get-caller-identity

                            aws eks update-kubeconfig \
                            --region us-east-2 \
                            --name demo-cluster

                            envsubst < Kubernetes/deployment.yaml | kubectl apply -f -
                            envsubst < Kubernetes/service.yaml | kubectl apply -f -
                        '''
                    }
                }
            }
        }

        stage('Ansible') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(
                        credentialsId: 'ansible-server-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )]){
                        def remote = [:]

                        remote.name = 'ansible-server'
                        remote.host = env.ANSIBLE_SERVER
                        remote.user = SSH_USER
                        remote.identityFile = SSH_KEY
                        remote.allowAnyHosts = true

                        sshCommand remote: remote, command: 'mkdir -p ~/ansible-projects'

                        dir('ansible-projects') {
                            git branch: 'main',
                                url: 'https://github.com/akbbarry/ansible-projects.git'
                        }

                        sshPut remote: remote,
                            from: 'ansible-projects',
                            into: '/home/ec2-user/'

                        sshPut remote: remote,
                            from: SSH_KEY,
                            into: '/home/ec2-user/target-key.pem'

                        sshCommand remote: remote,
                                command: 'chmod 600 /home/ec2-user/target-key.pem && sed -i "s|/root/ssh-key.pem|/home/ec2-user/target-key.pem|" ~/ansible-projects/ansible.cfg'

                        sshCommand remote: remote,
                                command: 'chmod +x ~/ansible-projects/prepare-ansible-server.sh'

                        sshCommand remote: remote,
                                command: '~/ansible-projects/prepare-ansible-server.sh'

                        sshCommand remote: remote,
                                command: 'cd ~/ansible-projects && ansible-playbook my-playbook.yaml'
                        }
                    }
                }
            }      
        stage('commit version update') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'github-credentials',
                        usernameVariable: 'USER',
                        passwordVariable: 'PASS'
                    )]) {
                        sh '''
                            git remote set-url origin https://$USER:$PASS@github.com/akbbarry/java-maven-app-Jenkins-jobs.git
                            git fetch origin
                            git checkout -B main origin/main
                            git config user.name "$USER"
                            git config user.email "$USER@users.noreply.github.com"
                            git add pom.xml
                            git diff --cached --quiet || git commit -m "ci: version bump"
                            git push origin main
                        '''
                    }
                }
            }
        }        

    }
}
