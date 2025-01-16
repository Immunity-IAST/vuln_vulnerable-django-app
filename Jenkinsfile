pipeline {
    agent any
    environment {
        DIRECTORY = './vda/'
        APP_PORT = '8000'
        IMMUNITY_HOST = 'immunity'
        IMMUNITY_PORT = '8000'
        IMMUNITY_PROJECT = 'vuln_vulnerable-django-app'
        FARADAY_URL = credentials('FARADAY_URL')
        FARADAY_LOGIN = credentials('FARADAY_LOGIN')
        FARADAY_PASSWORD = credentials('FARADAY_PASSWORD')
        FARADAY_WORKSPACE = "vulnerable-django-app"
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
                        --tag test_vuln_django \
                        --target base \
                        ."
            }
        }
        stage('Run application') {
            steps {
                sh 'docker network create dast_scan || true'
                sh 'docker run -d --name test_vuln_django --network dast_scan test_vuln_django'
                sh 'docker network connect iast_global test_vuln_django'
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
                sh "zap-baseline.py -t http://test_vuln_django:${APP_PORT} -x zap_dast_baseline.xml || true"
                sh 'cp /zap/wrk/zap_dast_baseline.xml .'

                echo 'Running DAST...'
                sh "zap-full-scan.py -t http://test_vuln_django:${APP_PORT} -x zap_dast_full.xml || true"
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
                sh "nikto -h http://test_vuln_django:${APP_PORT} -Format XML -output nikto_dast.xml || true"

                archiveArtifacts artifacts: 'nikto_dast.xml', allowEmptyArchive: true, fingerprint: true
            }
        }
        stage('Container logs') {
            steps {
                sh 'docker logs test_vuln_django | head -n 100'
            }
        }
        stage('Stop application') {
            steps {
                sh 'docker stop test_vuln_django && docker rm test_vuln_django'
                sh 'docker rmi test_vuln_django'
            }
        }
        stage ("Build instrumented application") {
            steps {
                sh "docker build \
                        --tag iast_vuln_django \
                        --build-arg IMMUNITY_HOST=${IMMUNITY_HOST} \
                        --build-arg IMMUNITY_PORT=${IMMUNITY_PORT} \
                        --build-arg IMMUNITY_PROJECT=${IMMUNITY_PROJECT} \
                        --target iast \
                        ."
            }
        }
        stage('Run instrumented application') {
            steps {
                sh 'docker run -d --name iast_vuln_django --network dast_scan test_vuln_django'
                sh 'docker network connect iast_global test_vuln_django'
            }
        }
        stage('PING IT') {
            agent {
                docker {
                    image 'kalilinux/kali-rolling'
                    args '--network dast_scan'
                    reuseNode true
                }
            }
            steps {
                //sh 'apt update && apt install nikto -y'
                //sh "nikto -h http://test_vuln_django:${APP_PORT} -Format XML -output nikto_dast.xml || true"
                //archiveArtifacts artifacts: 'nikto_dast.xml', allowEmptyArchive: true, fingerprint: true
                sh "curl http://iast_vuln_django/ || true"
            }
        }
        stage('Stop application') {
            steps {
                sh 'docker stop iast_vuln_django && docker rm iast_vuln_django'
                sh 'docker rmi iast_vuln_django'
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
    }
    post {
        always {
            sh 'docker stop test_vuln_django || true'
            sh 'docker rm test_vuln_django || true'
            sh 'docker rmi test_vuln_django || true'
            sh 'docker stop iast_vuln_django || true'
            sh 'docker rm iast_vuln_django || true'
            sh 'docker rmi iast_vuln_django || true'
            cleanWs()
        }
    }
}
