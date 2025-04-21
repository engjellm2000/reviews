def namespace = "production"
def serviceName = "reviews"
def service = "Reviews"
def m1 = System.currentTimeMillis()

def groovyMethods

pipeline {
  agent {
    label 'Jenkins-Agent'
  }

  tools {
    nodejs "NodeJS"
    dockerTool "Docker"
  }

  environment {
    DOCKER_CREDENTIALS = credentials("dockerhub")
    IMAGE_NAME = "engjellm2000/reviews"
    IMAGE_TAG = "stable-${BUILD_NUMBER}"
  }

  stages {
    stage("Cleanup Workspace") {
      steps {
        cleanWs()
      }
    }

    stage("Prepare Environment") {
      steps {
        sh "[ -d pipeline ] || mkdir pipeline"
        dir("pipeline") {
          git branch: 'main', credentialsId: 'github', url: 'https://github.com/engjellm2000/jenkins'
          script {
            groovyMethods = load("functions.groovy")
            echo "groovyMethods loaded? => ${groovyMethods != null}"
          }
        }

        git branch: 'main', credentialsId: 'github', url: 'https://github.com/engjellm2000/reviews'
        sh 'npm install'
      }
    }

    stage("Build and Push") {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
          sh "docker build -t $IMAGE_NAME ."
          sh "docker tag $IMAGE_NAME $IMAGE_NAME:$IMAGE_TAG"
          sh "docker tag $IMAGE_NAME $IMAGE_NAME:stable"
          sh "docker push $IMAGE_NAME:$IMAGE_TAG"
          sh "docker push $IMAGE_NAME:stable"
        }
      }
    }

    stage("Clean Artifacts") {
      steps {
        sh "docker rmi $IMAGE_NAME:$IMAGE_TAG || true"
        sh "docker rmi $IMAGE_NAME:stable || true"
      }
    }

    stage("Create New Pods") {
      steps {
        withKubeCredentials(kubectlCredentials: [[
          caCertificate: '',
          clusterName: 'minikube',
          contextName: 'minikube',
          credentialsId: 'jenkins-k8s-token',
          namespace: '',
          serverUrl: 'https://172.22.18.25:8443'
        ]]) {
          script {
            def pods = groovyMethods.findPodsFromName("${namespace}", "${serviceName}")
            echo "Found pods: ${pods}"
            if (pods && pods.size() > 0) {
              for (podName in pods) {
                sh """
                  kubectl delete -n ${namespace} pod ${podName}
                  sleep 10s
                """
              }
            } else {
              echo "No pods found for deletion in namespace '${namespace}' with app=${serviceName}"
            }
          }
        }
      }
    }
  }

  post {
    success {
      script {
        def m2 = System.currentTimeMillis()
        def durTime = groovyMethods.durationTime(m1, m2)
        def author = groovyMethods.readCommitAuthor()
        slackSend(
          channel: '#jenkins-automation',
          color: 'good',
          message: """✅ *BUILD SUCCEEDED*
            *Service:* ${service}
            *Build:* #${env.BUILD_NUMBER}
            *Duration:* ${durTime}
            *Author:* ${author}
            <${env.BUILD_URL}|View Build>"""
        )
      }
    }

    failure {
      script {
        def m2 = System.currentTimeMillis()
        def durTime = groovyMethods.durationTime(m1, m2)
        def author = groovyMethods.readCommitAuthor()
        slackSend(
          channel: '#jenkins-automation',
          color: 'danger',
          message: """❌ *BUILD FAILED*
            *Service:* ${service}
            *Build:* #${env.BUILD_NUMBER}
            *Duration:* ${durTime}
            *Author:* ${author}
            <${env.BUILD_URL}|View Build>"""
        )
      }
    }
  }
}
