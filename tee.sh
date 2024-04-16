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
  id: describe-ecr-images
  run: |
    # Get the output from the List ECR Repos step
    ecr_repositories_output=$(aws ecr describe-repositories --query 'repositories[*].[repositoryName, repositoryUri]' --output json)
    # Check if the JSON output is not null
    if [ -n "$ecr_repositories_output" ]; then
      # Ensure that the ecr_repositories_output is properly formatted JSON
      echo "$ecr_repositories_output" | jq -e . >/dev/null || { echo "Invalid JSON output from List ECR Repos step"; exit 1; }
      
      # Initialize an empty array to store repository details
      declare -a repositories
      
      # Iterate through each repository and store its details in the array
      while IFS=$'\t' read -r repo_name repo_uri; do
        if [ -n "$repo_uri" ]; then
          registry_id=$(echo "$repo_uri" | cut -d'.' -f1)
          region=$(echo "$repo_uri" | cut -d'.' -f4)
          if [ -n "$registry_id" ] && [ -n "$region" ]; then
            repositories+=("$repo_name:$repo_uri:$registry_id:$region")
          else
            echo "Unable to extract Registry ID and Region for repository: $repo_name ($repo_uri)"
          fi
        else
          echo "Skipping empty repository URI."
        fi
      done < <(echo "$ecr_repositories_output" | jq -r '.[] | @tsv')
      
      # Parallelize the execution of 'aws ecr describe-images' command for each repository
      parallel_output=$(parallel --jobs 4 'aws ecr describe-images --registry-id {3} --repository-name {1} | jq -c .' ::: "${repositories[@]}")
      
      # Set the output with merged images
      echo "::set-output name=images::$parallel_output"
    else
      echo "No output received from List ECR Repos step. Skipping Describe ECR Images step."
    fi
