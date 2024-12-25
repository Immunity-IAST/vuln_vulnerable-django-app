pipeline {
    agent any
    environment {
        DIRECTORY = './vda/'
        IMMUNITY_HOST = 'immunity'
        IMMUNITY_PORT = '8000'
        IMMUNITY_PROJECT = 'vuln_vulnerable-django-app'
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
                sh "python3 -m bandit -r ${DIRECTORY} -f xml -o bandit_sast.xml || true"

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
                sh "semgrep --json ${DIRECTORY} > semgrep_sast.json"

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

                echo 'Running DAST...'
                sh 'zap-baseline.py -t http://test:8000 -x zap_dast_baseline.xml || true'
                sh 'cp /zap/wrk/zap_dast_baseline.xml .'

                echo 'Running DAST...'
                sh 'zap-full-scan.py -t http://test:8000 -x zap_dast_full.xml || true'
                sh 'cp /zap/wrk/zap_dast_full.xml .'

                echo 'Here is the report...'
                sh 'cat /zap/wrk/zap_dast_full.xml'

                archiveArtifacts artifacts: 'zap_dast_baseline.xml', allowEmptyArchive: true, fingerprint: true
                archiveArtifacts artifacts: 'zap_dast_full.xml', allowEmptyArchive: true, fingerprint: true
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
                sh 'nikto -h http://test:8000 -Format XML -output nikto_dast.xml || true'

                archiveArtifacts artifacts: 'nikto_dast.xml', allowEmptyArchive: true, fingerprint: true
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
                sh "faraday-cli tool report semgrep_sast.json -w ${FARADAY_WORKSPACE}"
                sh "faraday-cli tool report zap_dast_baseline.xml -w ${FARADAY_WORKSPACE}"
                sh "faraday-cli tool report zap_dast_full.xml -w ${FARADAY_WORKSPACE}"
                sh "faraday-cli tool report nikto_dast.xml -w ${FARADAY_WORKSPACE}"
            }
        }
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
