#!/user/bin/env groovy

def gv

pipeline {
    agent any
    tools {
        maven 'maven-3.9'
    }
    environment {
        ECR_REGISTRY = "637739132640.dkr.ecr.us-east-2.amazonaws.com"
        ECR_REPOSITORY = "java-maven-app"
        APP_NAME = "java-maven-app"
        ANSIBLE_SERVER = "YOUR_ANSIBLE_SERVER_IP"
    }
    stages {
        stage('increment version') {
            steps {
                script {
                    echo 'incrementing app version...'
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                    def version = matcher[0][1]
                    env.IMAGE_NAME = "$version-$BUILD_NUMBER"
                    sh '''
                    mvn clean package
                    '''
                }
            }
        }
        stage('build image') {
            steps {
                withCredentials([
                    string(credentialsId: 'jenkins_aws_access_key_id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'jenkins-aws_secret_access_key', variable: 'AWS_SECRET_ACCESS_KEY')
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

        stage('Ansible') {
            steps {
                script {
                    def remote = [:]

                    remote.name = 'ansible-server'
                    remote.host = env.ANSIBLE_SERVER
                    remote.user = 'ec2-user'
                    remote.allowAnyHosts = true

                    sshCommand remote: remote, command: 'mkdir -p ~/ansible-projects'

                    sshPut remote: remote,
                        from: '../ansible-projects-main',
                        into: '~/ansible-projects'

                    sshCommand remote: remote,
                        command: 'chmod +x ~/ansible-projects/prepare-ansible-server.sh'

                    sshCommand remote: remote,
                        command: '~/ansible-projects/prepare-ansible-server.sh'

                    sshCommand remote: remote,
                        command: 'ansible-playbook ~/ansible-projects/my-playbook.yaml'
                }
            }
        }

        stage('deploy') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws_secret_access_key')
                AWS_DEFAULT_REGION = 'us-east-2'
            }
        }
        steps {
            script {
                sh '''
                export AWS_PAGER=""

                aws eks update-kubeconfig \
                --region us-east-2 \
                --name demo-cluster

                envsubst < Kubernetes/deployment.yaml | kubectl apply -f -
                envsubst < Kubernetes/service.yaml | kubectl apply -f -
                '''
            }
        }

        stage('configure with Ansible') {
            steps {
                script {
                    def remote = [:]
                    remote.name = 'ansible-server'
                    remote.host = ANSIBLE_SERVER
                    remote.allowAnyHosts = true

                    sshagent(['ansible-server-key']) {
                        sh '''
                            scp -o StrictHostKeyChecking=no -r ansible-projects/* \
                            ec2-user@$ANSIBLE_SERVER:/home/ec2-user/ansible-projects/
                        '''
                    }

                    sshCommand remote: remote, command: '''
                        cd /home/ec2-user/ansible-projects
                        chmod +x prepare-ansible-server.sh
                        ./prepare-ansible-server.sh
                        ansible-playbook -i inventory_aws_ec2.yaml my-playbook.yaml
                    '''
                }
            }
        }

        stage('commit version update'){
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'gitlab-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]){
                        git remote set-url origin https://$USER:$PASS@gitlab.com/Alkerix/java-maven-app.git
                        sh 'git fetch origin'
                        sh 'git checkout -B Jenkins-jobs origin/Jenkins-jobs'
                        sh 'git add .'
                        sh 'git diff --cached --quiet || git commit -m "ci: version bump"'
                        sh "git push origin Jenkins-jobs"
                    }

                }
            }
        }
    }
}
