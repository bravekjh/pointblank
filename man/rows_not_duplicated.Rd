% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rows_not_duplicated.R
\name{rows_not_duplicated}
\alias{rows_not_duplicated}
\title{Verify whether row data are not duplicated}
\usage{
rows_not_duplicated(agent, cols = NULL, report_count = 0, warn_count = 1,
  notify_count = 2, tbl_name = NULL, db_type = NULL, creds_file = NULL,
  initial_sql = NULL)
}
\value{
an agent object.
}
\description{
Set a verification step where
row data should contain no duplicates.
}