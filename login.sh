- name: Identify Values Files
  id: identify-values-files
  run: |
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

- name: Debug Step Output
        run:  echo "Step output: ${{ steps.identify-values-files.outputs.values_files }}"

- name: Login to Amazon ECR
  run: |
    images=$(yq eval-all '.image' ${{ steps.identify-values-files.outputs.values_files }})
    for image_uri in $images; do
        account_id=$(echo "$image_uri" | cut -d'.' -f1)
        region=$(echo "$image_uri" | cut -d'.' -f4)   
        echo "Logging in to Amazon ECR for image: $image_uri"
        aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$account_id.dkr.ecr.$region.amazonaws.com"
    done

- name: List ECR Repositories
  id: list-ecr-repos
  run: |
    echo "Listing ECR repositories..."
    aws ecr describe-repositories --query 'repositories[*].[repositoryName, repositoryUri]'
    echo "::set-output name=ecr_repositories::$(aws ecr describe-images --query 'repositories[*].[repositoryName, repositoryUri, imageTags[*]]' --output table)"
