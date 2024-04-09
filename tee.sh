- name: Identify Values Files
        id: identify-values-files
        run: |
          echo "Searching for values*.yaml files..."
          # Get the paths of the changed files
          changed_files="${{ steps.diff.outputs.diff }}"

          # Filter the paths to include only values*.yaml files
          values_files=$(echo "$changed_files" | grep 'values.*\.yaml')

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
                      latestTags=()  # Clearing the latestTags array
                      continue
                  fi
                  if [[ $line =~ latestTag:\ (.+) ]]; then
                      if [[ -z "$overrideTag" ]]; then
                          latestTags+=("${BASH_REMATCH[1]}") # Append the latestTag to the array
                          echo "Latest Tag: ${BASH_REMATCH[1]}"
                      fi
                  fi
              done < "$file"
          done

          # Set outputs
          echo "::set-output name=overrideTag::$overrideTag"
          echo "::set-output name=image::$image"
          echo "::set-output name=latestTags::$latestTags"
          - name: List ECR Repos
  run: |
    echo "Listing ECR repositories..."
    ecr_repositories=$(aws ecr describe-repositories --query 'repositories[*].[repositoryName, repositoryUri]' --output json | jq -r 'unique')
    echo "::set-output name=ecr_repositories::$ecr_repositories"

- name: Describe ECR Images
  run: |
    # Get the output from the List ECR Repos step
    # Iterate through each repository
    #ecr_repositories_output="${{ steps.list_ecr_repos.outputs.ecr_repositories }}"
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
