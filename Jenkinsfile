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

    /*
    stage("Lint Check") {
      steps {
        sh 'npm run lint:check'
      }
    }

    stage("Code Format Check") {
      steps {
        sh 'npm run prettier:check'
      }
    }

    stage("Unit Test") {
      steps {
        sh 'npm run test'
      }
    }
    */

    stage("Build and Push") {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub',   // ✅ Your Jenkins credential ID
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
          caCertificate: '''-----BEGIN CERTIFICATE-----
            MIIDBjCCAe6gAwIBAgIBATANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwptaW5p
            a3ViZUNBMB4XDTI1MDQwMjE4NDYwNloXDTM1MDQwMTE4NDYwNlowFTETMBEGA1UE
            AxMKbWluaWt1YmVDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALAi
            z83a9nbRm5bjfx2bEw6cTDdh8z/XWmSSo2FuTdQOSSu3YG42x2wu9oqoBGTr3lkY
            qlbzecThTygsC9mLO1R8QWawBQOWI89CHA5zydm2Gysa2WT82ZAXUyuP322LoKyO
            NEzbZnXb+xPbLDHqKxcSpjNI2E6/99dzTeEpwetsNFVdcIYHSwB9f+5ICed9LMgP
            byA9Y2tcj27zCKS5wWYErWwmJGZ0aOrIdK2AgFhrUutx1Q/6toXXegMajJxJ1ghd
            M2m7pHLZqYHrBQHreTLb9ywlkJDQTc4aw4GRjfE600tdljaLI6I6gjzq5vwLdtgo
            6LB47t/GLX+7DC7vsPUCAwEAAaNhMF8wDgYDVR0PAQH/BAQDAgKkMB0GA1UdJQQW
            MBQGCCsGAQUFBwMCBggrBgEFBQcDATAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQW
            BBQLKoTFoe5dfS2RLf4qqqB5BlxBmDANBgkqhkiG9w0BAQsFAAOCAQEAW8zK264z
            YEVPy+s90TWeUyutqPfaqe4V/z9eZEBz5e5s05ZsDsCOzM2rxMiDowrD0XlDdCpm
            btnrQWRPdHBUJZD3ysqHkTU6LDmFYAauBjitawFe0lGwPrfGsk7BIaLsmtrP3cxl
            nuTHWOeF269ZcjoTrB0yjHdcFOM2cet4eSqrtpOy+KDGiZlZ49QIZPQpAwazi1oy
            UKM4+1pr39n1MZox+XU+md493vPcyJlzU04HPbcO0w8rIdwsWZiol/RonM8Ul1H5
            HePUlrysilE9FM4edeKzqslx5Ng5tsWMmWGH6CF+UU91jVQhQHGzIO6jNDVFk6Cf
            5y9aYbkFXAmluA==
            -----END CERTIFICATE-----
          ''',
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
        groovyMethods.notifySlack("", "jenkins", [[
          title: "BUILD SUCCEEDED: ${service} Service with build number ${env.BUILD_NUMBER}",
          title_link: "${env.BUILD_URL}",
          color: "good",
          text: "Created by: ${author}",
          "mrkdwn_in": ["fields"],
          fields: [
            [
              title: "Duration Time",
              value: "${durTime}",
              short: true
            ],
            [
              title: "Stage Name",
              value: "Production",
              short: true
            ]
          ]
        ]])
      }
    }

    failure {
      script {
        def m2 = System.currentTimeMillis()
        def durTime = groovyMethods.durationTime(m1, m2)
        def author = groovyMethods.readCommitAuthor()
        groovyMethods.notifySlack("", "jenkins", [[
          title: "BUILD FAILED: ${service} Service with build number ${env.BUILD_NUMBER}",
          title_link: "${env.BUILD_URL}",
          color: "error",
          text: "Created by: ${author}",
          "mrkdwn_in": ["fields"],
          fields: [
            [
              title: "Duration Time",
              value: "${durTime}",
              short: true
            ],
            [
              title: "Stage Name",
              value: "Production",
              short: true
            ]
          ]
        ]])
      }
    }
  }
}
