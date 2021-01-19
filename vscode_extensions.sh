extensions=(
    arcticicestudio.nord-visual-studio-code
    artlaman.chalice-icon-theme
    bradlc.vscode-tailwindcss
    dbaeumer.vscode-eslint
    eg2.vscode-npm-script
    formulahendry.auto-rename-tag
    ms-python.python
    ms-python.vscode-pylance
    ms-toolsai.jupyter
    ms-vsliveshare.vsliveshare
    ricard.postcss
    richie5um2.vscode-sort-json
    robertrossmann.remedy
    sharat.vscode-brewfile
    slevesque.vscode-hexdump
    vscodevim.vim
    WakaTime.vscode-wakatime
    yzhang.markdown-all-in-one
)

for i in ${extensions[@]}; do
    code --install-extension $i
done
