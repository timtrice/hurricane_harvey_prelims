FROM rocker/rstudio:latest

ARG REPO_URL="https://github.com/timtrice/hurricane_harvey_prelims.git"
ARG DIR="hurricane_harvey_prelims"

ENV ENV_REPO_URL=$REPO_URL
ENV ENV_DIR=$DIR

RUN apt-get update \
  && apt-get install -y \
    libpng-dev \
    libxml2-dev \
    vim

RUN cd /home/rstudio \
  && git clone $ENV_REPO_URL \
  && cd $ENV_DIR \
  && Rscript --verbose R/01_install_packages.R
