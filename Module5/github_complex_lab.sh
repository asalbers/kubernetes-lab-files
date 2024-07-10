#!/usr/bin/env sh

# Create repos 
create__remote_repos(){

    echo "==========================MT3Chained-Step$i=========================="
    gh repo create "MT3Chained-Step$i" --template tech-brief-template-repo
    


}

# push files to repo

push_repos(){
    git init
    git add .
    git commit -m "Initial check-in"
    git remote add origin "git@github.com:$GITHUB_ALIAS/MT3Chained-Step$i.git"
    git branch -M main
    git push -u origin main
}

# Create github secrets

create_gh_secrets(){
    test
}

# create github workflows 

create_gh_workflows(){
    test
}

# configure SP to access keyvault

config_sp_access(){
    test
}

# create build tags in github

# create build pipeline for web and nodejs service 

# Create release pipeline


