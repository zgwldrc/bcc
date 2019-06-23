brew install pipenv

if ! grep -q 'pipenv --completion' ~/.bash_profile;then
    echo 'eval "$(pipenv --completion)"' >> ~/.bash_profile
fi
