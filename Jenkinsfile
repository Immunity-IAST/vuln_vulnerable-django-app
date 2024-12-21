pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                sh 'git clone https://github.com/jinghao1/DockerVulspace || true'
            }
        }
        stage('SAST (Bandit)') {
            agent {
                docker {
                    image 'python:3.10'
                    reuseNode true
                }
            }
            steps {
                echo 'Preparing environment...'
                sh 'pip install bandit'
                sh 'ls -la'

                echo 'Runnig SAST...'
                sh 'python3 -m bandit -r . -f xml -o bandit_sast.xml || true'

                echo 'Here is the report...'
                sh 'cat bandit_sast.xml || true'

                archiveArtifacts artifacts: 'bandit_sast.xml', allowEmptyArchive: true, fingerprint: true
            }
        }
        stage('Run application') {
            steps {
                sh 'docker network create dast_scan || true'
                sh 'docker run -d --name test --network dast_scan nginx'
            }
        }
        stage('DAST (OWASP ZAP)') {
            agent {
                docker {
                    image 'zaproxy/zap-stable'
                    args '--network dast_scan'
                    reuseNode true
                }
            }
            steps {
                echo 'Preparing environment...'
                sh 'mkdir /zap/wrk/'
                sh 'cp -r * /zap/wrk/'

                echo 'Runnig DAST...'
                sh 'zap-baseline.py -t http://test -x zap_dast.xml || echo 0'
                sh 'cp /zap/wrk/zap_dast.xml .'

                echo 'Here is the report...'
                sh 'cat /zap/wrk/zap_dast.xml'

                archiveArtifacts artifacts: 'zap_dast.xml', allowEmptyArchive: true, fingerprint: true
            }
        }
        stage('Stop application') {
            steps {
                sh 'docker stop test && docker rm test'
            }
        }
        stage('Upload reports') {
                agent {
                    docker {
                        image 'python:3.10'
                        args '--network host'
                        reuseNode true
                    }
                }
                steps {
                    sh 'pip install faraday-cli'
                    sh 'faraday-cli auth -f http://faraday.devops.local -i -u faraday -p faraday_test'
                    sh 'faraday-cli tool report bandit_sast.xml -w test_workspace'
                    sh 'faraday-cli tool report zap_dast.xml -w test_workspace'
                }
        }
        stage('Crowler') {
                agent {
                    docker {
                        image 'python:3.10'
                        args '--network host'
                        reuseNode true
                    }
                }
                steps {
                    sh 'apt install wget'
                    sh 'wget -r -np -k http://gitea.devops.local || true'
                }
        }
        stage('Selenium') {
                agent {
                    docker {
                        image 'node:18-alpine'
                        args '--network host'
                        reuseNode true
                    }
                }
                steps {
                    sh 'npm install -g selenium-side-runner'
                    sh 'selenium-side-runner'
                }
        }
    }
    post {
        always {
            sh 'docker stop test || true'
            sh 'docker rm test || true'
        }
    }
}
