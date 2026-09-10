pipeline {
	agent any
	triggers { pollSCM('H/2 * * * *') }

	environment {
		IMAGE_NAME = 'ghcr.io/drakura/portfolio-project'
		IMAGE_TAG = "${BUILD_NUMBER}"
		CONTAINER_NAME = 'portfolio-project-application'
		APPLICATION_PORT = '8080'
	}

	stages {
		stage('Checkout') {
			steps { checkout scm }
		}
		
		stage('Verify Tools') {
			steps {
				sh '''
				git --version
				docker version
				terraform version
				'''
			}
		}

		stage('Build and Push ARM64 Image') {
			steps {
				withCredentials([usernamePassword(
				credentialsId: 'github-ghcr-token',
				usernameVariable: 'GHCR_USER',
				passwordVariable: 'GHCR_TOKEN')]) {
					sh '''
						echo "$GHCR_TOKEN" | docker login ghcr.io \
						-u "$GHCR_USER" \
						--password-stdin

						docker buildx build \
						--platform linux/arm64 \
						-t ${IMAGE_NAME}:${IMAGE_TAG} \
						-t ${IMAGE_NAME}:latest \
						--push .

						docker logout ghcr.io
						'''
				}
			}
		}

		stage('Terraform Format') {
			steps { dir('terraform') { sh 'terraform fmt -check' } }
		}

		stage('Terraform Initialize') {
			steps { dir('terraform') { sh 'terraform init -input=false' } }
		}

		stage('Terraform Validate') {
			steps { dir('terraform') { sh 'terraform validate' } }
		}

		stage('Terraform Plan') {
			steps {
				withCredentials([
					string(credentialsId: 'oci-tenancy-ocid', variable: 'OCI_TENANCY_OCID'),
					string(credentialsId: 'oci-user-ocid', variable: 'OCI_USER_OCID'),
					string(credentialsId: 'oci-fingerprint', variable: 'OCI_FINGERPRINT'),
					string(credentialsId: 'oci-region', variable: 'OCI_REGION'),
					string(credentialsId: 'oci-compartment-ocid', variable: 'OCI_COMPARTMENT_OCID'),
					file(credentialsId: 'oci-api-private-key', variable: 'OCI_PRIVATE_KEY')
				]) {
					dir('terraform') {
						sh '''
						terraform plan \
						-input=false \
						-out=tfplan \
						-var="tenancy_ocid=${OCI_TENANCY_OCID}" \
						-var="user_ocid=${OCI_USER_OCID}" \
						-var="fingerprint=${OCI_FINGERPRINT}" \
						-var="private_key_path=${OCI_PRIVATE_KEY}" \
						-var="region=${OCI_REGION}" \
						-var="compartment_ocid=${OCI_COMPARTMENT_OCID}" \
						-var="image_name=${IMAGE_NAME}:${IMAGE_TAG}" \
						-var="container_name=${CONTAINER_NAME}" \
						-var="external_port=${APPLICATION_PORT}"
						'''
				
					}
				}
			}
		}

		stage('Terraform Apply') {
			steps { dir('terraform') { sh 'terraform apply -input=false -auto-approve tfplan' } }
		}

		stage('Verify Deployment') {
			steps { sh '''
				docker ps --filter "name=${CONTAINER_NAME}"
				'''
			}
		}
	}

	post {
		success {
			echo 'Pipeline completed successfully.'
			echo 'Application deployed via Terraform.'
		}
	
		failure {
			echo 'Pipeline failed. Review the console output.'
		}

		always {
			sh 'docker ps || true'
		}
	}

}
