 - name: Login to Amazon ECR
        run: |
          for file in $values_files; do
              echo "Processing $file..."
              # Use awk to filter out special characters
              # Here, we're assuming that the image lines start with 'image: ' and then contain the image URI
              # Adjust this pattern according to your YAML file's structure
              awk '/image:/ {gsub(/[^[:alnum:]._-]/, "", $2); print $2}' "$file" | while read -r image_uri; do
                  if [ -n "$image_uri" ]; then
                      account_id=$(echo "$image_uri" | cut -d'.' -f1)
                      region=$(echo "$image_uri" | cut -d'.' -f4)
                      echo "Logging in to Amazon ECR for image: $image_uri"
                      aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$account_id.dkr.ecr.$region.amazonaws.com"
                  fi
              done
          done

      - name: List ECR Repos
        run: |
          echo "Listing ECR repositories..."
          aws ecr describe-repositories --query 'repositories[*].[repositoryName, repositoryUri]'
          echo "::set-output name=ecr_repositories::$(aws ecr describe-repositories --query 'repositories[*].[repositoryName, repositoryUri]' --output json)"

      - name: Describe Images per Repository
        run: |
          ecr_repositories="${{ steps.list-ecr-repos.outputs.ecr_repositories }}"
          echo "$ecr_repositories" | jq -r '.[] | "\(.repositoryName) \(.repositoryUri)"' | while read -r repo_name repo_uri; do
            echo "Repo Name: $repo_name, Repo URI: $repo_uri"
            if [ -n "$repo_name" ]; then
              echo "Describing images for repository: $repo_name ($repo_uri)"
              
              # Extract registry ID and region from repository URI
              registry_id=$(echo "$repo_uri" | cut -d'.' -f1)
              region=$(echo "$repo_uri" | cut -d'.' -f4)
              
              # Describe images using AWS CLI
              aws ecr describe-images --registry-id "$registry_id" --repository-name "$repo_name" --region "$region"
            else
              echo "Skipping empty repository name."
            fi
          done
