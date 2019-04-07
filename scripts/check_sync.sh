#!/bin/bash

is_git_dir() {
    # Based on this:
    # https://stackoverflow.com/questions/2180270/check-if-current-directory-is-a-git-repository

    inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"

    if [ "$inside_git_repo" ]; then
        return 1
    else
        return 0
    fi
}


# Check the status of a git repo
# return codes:
#   0: not a git repo
#   1: git repo, but no upstream
#   2: up to date
#   3: need to pull
#   4: need to push
#   5: diverged

check_status() {
    git remote update 2>1 > /dev/null

    # '@' tells git to look at the current branch
    # '@{u}' tells git to look at the upstream branch for this branch
    LOCAL=`git rev-parse @ 2> /dev/null`
    if [ $? -ne 0 ]; then
        return 0
    fi

    REMOTE=`git rev-parse @{u} 2> /dev/null`
    if [ $? -ne 0 ]; then
        return 1
    fi

    BASE=`git merge-base @ @{u} 2> /dev/null`
    if [ $? -ne 0 ]; then
        return 5
    fi
    
    if [ $LOCAL = $REMOTE ]; then
        return 2
    elif [ $LOCAL = $BASE ]; then
        return 3
    elif [ $REMOTE = $BASE ]; then
        return 4
    else
        return 5
    fi
}

DEFAULT="\033[0m"
RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"

for d in */ ; do
    pushd "$d" > /dev/null

    check_status
    RET=$?

    if [ $RET -eq 0 ]; then
        message="not a git repo"
        color=${RED}
    elif [ $RET -eq 1 ]; then
        message="no upstream"
        color=${RED}
    elif [ $RET -eq 2 ]; then
        message="Up to date"
        color=${GREEN}
    elif [ $RET -eq 3 ]; then
        message="need to pull"
        color=${YELLOW}
    elif [ $RET -eq 4 ]; then
        message="need to push"
        color=${YELLOW}
    elif [ $RET -eq 5 ]; then
        message="diverged"
        color=${YELLOW}
    else
        message="unknown status"
        color=${RED}
    fi

    printf "%-35s ${color}${message}${DEFAULT}\n" "$d:"

    popd > /dev/null
done
