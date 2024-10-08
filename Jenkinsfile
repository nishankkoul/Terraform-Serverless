pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        FUNCTION_VERSION_FILE = 'version.txt'
        S3_BUCKET             = credentials('S3_BUCKET')
        LAMBDA_CODE_KEY       = 'lambda_function_code'
        AWS_REGION            = 'ap-south-1'
        STATE_BACKUP_KEY      = 'terraform-backend.tfstate'
    }

    stages {
        stage('Retrieve Version') {
            steps {
                script {
                    // Retrieve the version from S3
                    def result = sh(script: "aws s3 cp s3://${S3_BUCKET}/${FUNCTION_VERSION_FILE} version.txt --region ${AWS_REGION}", returnStatus: true)
                    
                    if (result == 0) {
                        // Read the version from file
                        env.FUNCTION_VERSION = readFile('version.txt').split('\\|')[0].trim()
                    } else {
                        // Set default version if file does not exist
                        env.FUNCTION_VERSION = '1.0'
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    // Initialize Terraform and store both state and backend in S3
                    sh '''
                    terraform init -upgrade \
                        -reconfigure \
                        -backend-config="bucket=${S3_BUCKET}" \
                        -backend-config="key=terraform.tfstate" \
                        -backend-config="region=${AWS_REGION}" \
                        -force-copy
                    '''
                    
                    // Backup the state backend file in S3
                    sh '''
                    aws s3 cp .terraform/terraform.tfstate s3://${S3_BUCKET}/${STATE_BACKUP_KEY} --region ${AWS_REGION}
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -var="function_version=${FUNCTION_VERSION}" -out=tfplan'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }

        stage('Backup and Update Lambda Code') {
            steps {
                script {
                    def currentVersion = env.FUNCTION_VERSION
                    def result = sh(script: "aws s3 ls s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}.zip", returnStatus: true)
                    
                    if (result == 0) {
                        echo "Updating existing object for version ${currentVersion}"
                        def newVersion = (currentVersion.toFloat() + 0.1).toString()
                        def timestamp = sh(script: "date +'%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
                        
                        sh "aws s3 cp lambda_function.zip s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}.zip"
                        
                        // Store version and timestamp in version.txt
                        writeFile(file: 'version.txt', text: "${newVersion} | ${timestamp}")
                        sh "aws s3 cp version.txt s3://${S3_BUCKET}/${FUNCTION_VERSION_FILE} --region ${AWS_REGION}"
                    } else {
                        echo "Uploading new object for version ${currentVersion}"
                        def newVersion = (currentVersion.toFloat() + 0.1).toString()
                        def timestamp = sh(script: "date +'%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
                        
                        sh "aws s3 cp lambda_function.zip s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}.zip"
                        
                        // Store version and timestamp in version.txt
                        writeFile(file: 'version.txt', text: "${newVersion} | ${timestamp}")
                        sh "aws s3 cp version.txt s3://${S3_BUCKET}/${FUNCTION_VERSION_FILE} --region ${AWS_REGION}"
                    }
                }
            }
        }

        stage('Output Function URL') {
            steps {
                sh 'echo "Function URL: $(terraform output -raw function_url)"'
            }
        }
    }
}
