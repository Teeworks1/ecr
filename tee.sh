- name: List ECR Repos
  id:   list ecr repos
  run: |
    echo "Listing ECR repositories..."
    ecr_repositories=$(aws ecr describe-repositories --query 'repositories[*].[repositoryName, repositoryUri]' --output json | jq -r 'unique')
    echo "::set-output name=ecr_repositories::$ecr_repositories"

- name: Describe ECR Images
  id:   describe-ecr-images
  run: |
    # Get the output from the List ECR Repos step
    # Iterate through each repository
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
       # Check if any images were found
    echo describe_ecr_images=hello" >> $GITHUB_ENV

- name: Process ECR Image Details
  if: steps.describe-ecr-images.outputs.images != 'null'
  run: |
    # Retrieve the output from the previous step
   
    
    # Process the output using jq to extract relevant information
    echo "$ecr_images_output" | jq -r '.imageDetails[] | "Registry ID: \( .registryId ), Repository Name: \( .repositoryName ), Image Tag: \( .imageTags[0] )"'
 
 cat << EOF
 This is not just a new script
 We started this project a long time ago
 EOF