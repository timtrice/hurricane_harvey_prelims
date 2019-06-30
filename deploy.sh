#!/bin/bash
GH_REPO="@github.com/$TRAVIS_REPO_SLUG.git"
FULL_REPO="https://$GH_TOKEN$GH_REPO"
git config --global user.name "Travis CI"
git config --global user.email "tim.trice@gmail.com"
git clone https://github.com/timtrice/hurricane_harvey_prelims.git
cd hurricane_harvey_prelims
git checkout develop
Rscript -e 'rmarkdown::render_site(".");'

if [ ! -d "docs" ]
then
  echo "Docs directory does not exist"
  exit 1
fi

git add --force docs
MSG="Rebuild website, $(date) [skip ci]"
git commit -m "$MSG"
git push --force $FULL_REPO develop
Rscript -e 'remotes::install_github("karthik/holepunch");'
Rscript -e 'holepunch::build_binder();'
