
      - name: Login to Amazon ECR
        run: |
          for file in $values_files; do
              echo "Processing $file..."
              # Use awk to filter out special characters
              # Here, we're assuming that the image lines start with 'image: ' and then contain the image URI
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
          ecr_repositories=$(aws ecr describe-repositories --query 'repositories[*].[repositoryName, repositoryUri]' --output json | jq -r 'unique')
          echo "::set-output name=ecr_repositories::$ecr_repositories"
          echo "$ecr_repositories"
      - name: Describe ECR Images
        run: |
          # Get the output from the List ECR Repos step
          # Iterate through each repository
          ecr_repositories_output="${{ steps.list_ecr_repos.outputs.ecr_repositories }}"
          echo "$ecr_repositories" | jq -r '.[] | @tsv' | while IFS=$'\t' read -r repo_name repo_uri; do
            echo "Repo Name: $repo_name, Repo URI: $repo_uri"
            if [ -n "$repo_uri" ]; then
              # Extract registry ID and region from repository URI
              registry_id=$(echo "$repo_uri" | cut -d'.' -f1)
              region=$(echo "$repo_uri" | cut -d'.' -f4)
              if [ -n "$registry_id" ] && [ -n "$region" ]; then
                echo "Describing images for repository: $repo_name ($repo_uri)"
                echo "Extracted Registry ID: $registry_id"
                echo "Extracted Region: $region"
                # Describe images using AWS CLI
                aws ecr describe-images --registry-id "$registry_id" --repository-name "$repo_name" --region "$region"
              else
                echo "Unable to extract Registry ID and Region for repository: $repo_name ($repo_uri)"
              fi
            else
              echo "Skipping empty repository URI."
            fi
          done
      - name: Process ECR Image Details
        if: steps.describe-ecr-images.outputs.images != 'null'
        run: |
          ecr_images_output="${{ steps.describe-ecr-images.outputs.images }}"
          echo "$ecr_images_output" | jq -r '.imageDetails[] | "Registry ID: \(.registryId), Repository Name: \(.repositoryName), Image Tag: \(.imageTags[0])"'
