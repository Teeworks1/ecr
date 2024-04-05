- name: Identify Values Files
  id: identify-values-files
  run: |
    echo "Searching for values*.yaml files..."
    # Get the paths of the changed files in the pull request
    changed_files=$(git diff --name-only ${{ github.event.before }} ${{ github.sha }})

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
