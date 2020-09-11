#! /bin/bash

branch=$1

if [ ! $branch ]; then
    echo "need branch param"
    exit
fi

# if [ ! $WISHPOST_DIR ]; then
#     echo "set WISHPOST_DIR first"
#     exit
# fi

# cd $WISHPOST_DIR

wishpost_dir=$CL_HOME
if [ ! -d $wishpost_dir ]; then
	echo no wishpost dir
	mkdir $wishpost_dir
	cd $wishpost_dir
	git init
	git remote add origin git@github.com:ContextLogic/wishpost.git 
	git remote add clroot git@github.com:ContextLogic/clroot.git
else
	cd $wishpost_dir
fi

git remote add origin https://$GIT_USERNAME:$GIT_TOKEN@github.com.cnpmjs.org/ContextLogic/wishpost.git
git remote add clroot https://$GIT_USERNAME:$GIT_TOKEN@github.com.cnpmjs.org/ContextLogic/clroot.git
git remote set-url origin https://$GIT_USERNAME:$GIT_TOKEN@github.com.cnpmjs.org/ContextLogic/wishpost.git 
git remote set-url clroot https://$GIT_USERNAME:$GIT_TOKEN@github.com.cnpmjs.org/ContextLogic/clroot.git 

echo ""
echo "fetching and pruning remote clroot and remote wishpost branches, deleting the branches that no longer exist.."
echo ""
git fetch -p clroot && git fetch -p origin

clroot_branch=$(git branch --remote | grep clroot/$branch)
if [ ! -n "$clroot_branch" ]; then
	echo "remote clroot branch - ($branch) no longer exists, deleting that branch in remote wishpost"
	wishpost_branch=$(git branch --remote | grep origin/$branch)
	if [ -n "$wishpost_branch" ]; then
		git push origin :$branch
	fi
	continue
fi 

echo ""
echo "filtering remote clroot branch - ($branch), focusing on commits related to wishpost.."
echo ""
# git filter-branch --prune-empty --subdirectory-filter wishpost -f clroot/$branch 
# git filter-repo --to-subdirectory-filter wishpost --refs remotes/clroot/$branch --force
git filter-repo --path wishpost --refs remotes/clroot/$branch --force

echo ""
echo "switching to the required local branch - ($branch).."
echo ""
local_branch=$(git branch | grep $branch)
if [ -n "$local_branch" ]; then
	git checkout $branch
else
    git checkout -b $branch
fi

echo ""
echo "replacing commits on local branch - ($branch) with filtered remote clroot branch's commits.."
echo ""
git reset --hard $(cat .git/refs/remotes/clroot/$branch)

echo ""
echo "pushing commits on filtered branch - ($branch) to remote wishpost.."
echo ""
git push origin $branch -f
