#' Import magrittr pipe
#'
`%>%` <- magrittr::`%>%`

#' Get versions of an RMD
#' Modified from the workflowr package, credit John Blischak
self_get_versions <- function(input) {

  path <- here::here()
  rmd <- file.path(path, input)
  output_dir <- workflowr:::get_output_dir(file.path(path))
  r <- git2r::repository(path)
  blobs <- git2r::odb_blobs(r)
  github <- workflowr:::get_host_from_remote(path)

  blobs$fname <- file.path(workflowr:::git2r_workdir(r), blobs$path, blobs$name)
  blobs$fname <- workflowr:::absolute(blobs$fname)
  blobs$ext <- tools::file_ext(blobs$fname)

  html <- workflowr:::to_html(rmd, outdir = output_dir)
  blobs_file <- blobs[blobs$fname %in% c(rmd, html), c("ext", "commit", "author", "when")]
  # Ignore blobs that don't map to commits (caused by `git commit --amend`)
  git_log <- git2r::commits(r)
  git_log_sha <- vapply(git_log, function(x) workflowr:::git2r_slot(x, "sha"), character(1))
  blobs_file <- blobs_file[blobs_file$commit %in% git_log_sha, ]

  # Exit early if there are no past versions
  if (nrow(blobs_file) == 0) {
    text <-
      "<p>There are no previous revisions.</p>"
    return(text)
  }
  colnames(blobs_file) <- c("File", "Version", "Author", "Date")
  blobs_file <- blobs_file[order(blobs_file$Date, decreasing = TRUE), ]
  blobs_file$Date <- as.Date(blobs_file$Date)
  blobs_file$Message <- vapply(blobs_file$Version,
                               workflowr:::get_commit_title,
                               "character(1)",
                               r = r)
  workdir_w_trailing_slash <- paste0(workflowr:::git2r_workdir(r), "/")
  git_html <- stringr::str_replace(html, workdir_w_trailing_slash, "")
  git_rmd <- stringr::str_replace(input, workdir_w_trailing_slash, "")

  if (is.na(github)) {
    blobs_file$ShortSHA <- shorten_sha(blobs_file$Version)
  } else {
    blobs_file$short_sha <- workflowr:::shorten_sha(blobs_file$Version)
    blobs_file$url <- sprintf(
      "%s/blob/%s/%s",
      github,
      blobs_file$Version,
      git_rmd,
      workflowr:::shorten_sha(blobs_file$Version)
    )
  }

  return(blobs_file)
}

#' @title self_install_remotes
#' @description Install Remotes
self_install_remotes <- function() {
  remotes <- remotes::local_package_deps(dependencies = "Remotes")

  if (!is.null(remotes)) {
    purrr::walk(
      .x = strsplit(
        x = remotes::local_package_deps(dependencies = "Remotes"),
        split = "::"
      ),
      .f = ~rlang::exec(
        .fn = utils::getFromNamespace(x = paste0("install_", .x[1]), ns = "remotes"),
        repo = .x[2],
        upgrade = "never"
      )
    )
  }

}
