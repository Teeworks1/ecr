          #!/bin/bash

          echo "Searching for values*.yaml files..."
          values_files=$(find . -type f -name "values*.yaml")

          if [ -n "$values_files" ]; then
              echo "Values*.yaml files found:"
              echo "$values_files"
              echo "::set-output name=values_files::$values_files"
          else
              echo "No values*.yaml files found."
              exit 1
          fi
          
          overrideTag=""
          image=""
          latestTags=()

          for file in $values_files; do
              echo "Processing $file..."
              while IFS= read -r line; do
                  if [[ $line =~ image:\ (.+) ]]; then
                      image="${BASH_REMATCH[1]}"
                      echo "Image: $image"
                  fi
                  if [[ $line =~ overrideTag:\ (.+) ]]; then
                      overrideTag="${BASH_REMATCH[1]}"
                      echo "Override Tag: $overrideTag"
                      echo "Image: $image"
                      # If overrideTag is found, no need to search for latestTag
                      latestTags=()  # Clearing the latestTags array
                      continue
                  fi
                  if [[ $line =~ latestTag:\ (.+) ]]; then
                      if [[ -z "$overrideTag" ]]; then
                          latestTag+=("${BASH_REMATCH[1]}") # Append the latestTag to the array
                          echo "Latest Tag: ${BASH_REMATCH[1]}"
                      fi
                  fi
              done < "$file"
              
              # Check if overrideTag is found before breaking the loop
              if [[ -n "$overrideTag" ]]; then
                  break
              fi
          done
          # Set outputs
          echo "::set-output name=overrideTag::$overrideTag"
          echo "::set-output name=image::$image"
          echo "::set-output name=latestTags::$latestTag"

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
    ecr_repositories=$(aws ecr describe-repositories --query 'repositories[*].[repositoryName, repositoryUri]' --output text)
    echo "::set-output name=ecr_repositories::$ecr_repositories"

  ecr_repositories="${{ steps.list-ecr-repos.outputs.ecr_repositories }}"
  #while IFS=$'\t' read -r repo_name repo_uri; do
    #echo "Repo Name: $repo_name, Repo URI: $repo_uri"
    #if [ -n "$repo_name" ]; then
      #echo "Describing images for repository: $repo_name ($repo_uri)"
      aws ecr describe-images --repository-name "$repo_name"
    else
      echo "Skipping empty repository name."
    fi
  done <<< "$ecr_repositories"
    else
      echo "Skipping empty repository name."
    fi
  done <<< "$ecr_repositories"

