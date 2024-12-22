pipeline {
    agent any
    environment {
        IMMUNITY_HOST = 'immunity'
        IMMUNITY_PORT = '8000'
        IMMUNITY_PROJECT = 'test'
        FARADAY_URL = credentials('FARADAY_URL')
        FARADAY_LOGIN = credentials('FARADAY_LOGIN')
        FARADAY_PASSWORD = credentials('FARADAY_PASSWORD')
        FARADAY_WORKSPACE = "django_vulnapp"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
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

                echo 'Running SAST...'
                sh 'python3 -m bandit -r . -f xml -o bandit_sast.xml || true'

                echo 'Here is the report...'
                sh 'cat bandit_sast.xml || true'

                archiveArtifacts artifacts: 'bandit_sast.xml', allowEmptyArchive: true, fingerprint: true
            }
        }
        stage('SAST (Semgrep)') {
            agent {
                docker {
                    image 'python:3.10'
                    reuseNode true
                }
            }
            steps {
                echo 'Preparing environment...'
                sh 'pip install semgrep'

                echo 'Running SAST...'
                sh 'semgrep --json ./vda/ > semgrep_sast.json'

                echo 'Here is the report...'
                sh 'cat semgrep_sast.json || true'

                archiveArtifacts artifacts: 'semgrep_sast.json', allowEmptyArchive: true, fingerprint: true
            }
        }
        stage ("Build application") {
            steps {
                sh "docker build \
                        --tag python_vulnapp \
                        --build-arg IMMUNITY_HOST=${IMMUNITY_HOST} \
                        --build-arg IMMUNITY_PORT=${IMMUNITY_PORT} \
                        --build-arg IMMUNITY_PROJECT=${IMMUNITY_PROJECT} \
                        --target iast \
                        ."
            }
        }
        stage('Run application') {
            steps {
                sh 'docker network create dast_scan || true'
                sh 'docker run -d --name test --network dast_scan python_vulnapp'
                sh 'docker network connect iast_global test'
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
                sh 'zap-baseline.py -t http://test:8000 -x zap_dast.xml || echo 0'
                sh 'cp /zap/wrk/zap_dast.xml .'

                echo 'Here is the report...'
                sh 'cat /zap/wrk/zap_dast.xml'

                archiveArtifacts artifacts: 'zap_dast.xml', allowEmptyArchive: true, fingerprint: true
            }
        }
        stage('DAST (Nikto)') {
            agent {
                docker {
                    image 'kalilinux/kali-rolling'
                    args '--network dast_scan'
                    reuseNode true
                }
            }
            steps {
                sh 'apt update && apt install nikto -y'
                sh 'nikto -h http://test:8000 -Format XML -output nikto_dast.xml'

                archiveArtifacts artifacts: 'nikto_dast.xml', allowEmptyArchive: true, fingerprint: true
            }
        }
        stage('DAST (Arachni)') {
            agent {
                docker {
                    image 'kalilinux/kali-rolling'
                    args '--network dast_scan'
                    reuseNode true
                }
            }
            steps {
                sh 'apt update && apt install arachni -y'
                sh 'arachni --report=xml:arachni_dast.xml http://test:8000'

                archiveArtifacts artifacts: 'arachni_dast.xml', allowEmptyArchive: true, fingerprint: true
            }
        }
        stage('Container logs') {
            steps {
                sh 'docker logs test | head -n 100'
            }
        }
        stage('Stop application') {
            steps {
                sh 'docker stop test && docker rm test'
                sh 'docker rmi python_vulnapp'
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
                sh "faraday-cli auth -f ${FARADAY_URL} -i -u ${FARADAY_LOGIN} -p ${FARADAY_PASSWORD}"
                sh "faraday-cli tool report bandit_sast.xml -w ${FARADAY_WORKSPACE}"
                sh "faraday-cli tool report zap_dast.xml -w ${FARADAY_WORKSPACE}"
                sh "faraday-cli tool report nikto_dast.xml -w ${FARADAY_WORKSPACE}"
                sh "faraday-cli tool report arachni_dast.xml -w ${FARADAY_WORKSPACE}"
            }
        }
//         stage('Crowler') {
//             agent {
//                 docker {
//                     image 'python:3.10'
//                     args '--network host'
//                     reuseNode true
//                 }
//             }
//             steps {
//                 sh 'apt install wget'
//                 sh 'wget -r -np -k http://gitea.devops.local || true'
//             }
//         }
//         stage('Selenium') {
//             agent {
//                 docker {
//                     image 'node:18-alpine'
//                     args '--network host'
//                     reuseNode true
//                 }
//             }
//             steps {
//                 sh 'npm install -g selenium-side-runner'
//                 sh 'selenium-side-runner'
//             }
//         }
    }
    post {
        always {
            sh 'docker stop test || true'
            sh 'docker rm test || true'
            sh 'docker rmi python_vulnapp || true'
            cleanWs()
        }
    }
}
