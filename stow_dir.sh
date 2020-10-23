for app in ./*; do
    if [ -d "$app" ]; then
        stow -v -R  ${app##*/}
    fi
done
