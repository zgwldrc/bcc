#!/bin/bash
brew install pyenv pyenv-virtualenv
cat >> ~/.bash_profile <<-EOF
eval '$(pyenv init -)'
eval '$(pyenv virtualenv-init -)'
EOF
