#!/bin/bash
#!/bin/bash

echo "Listing ECR repositories..."
ecr_repositories=$(aws ecr describe-repositories --query 'repositories[*].[repositoryName, repositoryUri]' --output json | jq -r 'unique')
echo "ecr_repositories=$(echo "$ecr_repositories" | base64)" >> $GITHUB_ENV
