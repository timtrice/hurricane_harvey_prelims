install.packages("remotes")
remotes::install_deps(dependencies = "Depends")

# Get and install Remotes
source(here::here("./R/functions.R"))
self_install_remotes()
