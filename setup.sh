# /bin/bash

lambda_name=amazonses-block-spam
region=us-west-2
account_id=`aws sts get-caller-identity --query 'Account' --output text`

function create_or_update_ecr_repository() {
  if (aws ecr describe-repositories --repository-names "$lambda_name" --region "$region" 2>/dev/null); then
    : # do nothing
  else
    aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$account_id.dkr.ecr.$region.amazonaws.com"
    aws ecr create-repository --repository-name "$lambda_name" --region "$region" --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE
  fi

  docker tag "$lambda_name:latest" "$account_id.dkr.ecr.$region.amazonaws.com/$lambda_name:latest"
  docker push "$account_id.dkr.ecr.$region.amazonaws.com/$lambda_name:latest"
}

function create_or_update_lambda_function() {

  if (aws lambda get-function --function-name "$lambda_name" --region "$region" 2>&1 1>/dev/null); then
    aws lambda update-function-code \
      --function-name "$lambda_name" \
      --image-uri "$account_id.dkr.ecr.$region.amazonaws.com/$lambda_name:latest"
  else
    if (aws iam get-role --role-name "lambda-$lambda_name" 2>&1 1>/dev/null); then
      : # do nothing
    else
      aws iam create-role --role-name "lambda-$lambda_name" --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
      aws iam attach-role-policy --role-name "lambda-$lambda_name" --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    fi
    aws lambda create-function \
      --function-name "$lambda_name" \
      --package-type "Image" \
      --code "ImageUri=$account_id.dkr.ecr.$region.amazonaws.com/$lambda_name:latest" \
      --role "arn:aws:iam::$account_id:role/lambda-$lambda_name"
  fi
}

docker build --platform "linux/amd64" -t "$lambda_name:latest" .
create_or_update_ecr_repository
create_or_update_lambda_function
