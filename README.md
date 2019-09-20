
<!-- README.md is generated from README.Rmd. Please edit that file -->

# pointblank <a href='http://rich-iannone.github.io/pointblank/'><img src="man/figures/logo.svg" align="right" height="250px" /></a>

[![CRAN
status](https://www.r-pkg.org/badges/version/pointblank)](https://cran.r-project.org/package=pointblank)
[![Travis-CI Build
Status](https://travis-ci.org/rich-iannone/pointblank.svg?branch=master)](https://travis-ci.org/rich-iannone/pointblank)
[![Codecov test
coverage](https://codecov.io/gh/rich-iannone/pointblank/branch/master/graph/badge.svg)](https://codecov.io/gh/rich-iannone/pointblank?branch=master)

## Overview

Tables can often be trustworthy. All the data seems to be there and we
may feel we can count on these tables to deliver us the info we need.
Still, sometimes, the tables we trust are hiding things from us.
Malformed strings, numbers we don’t expect, missing values that ought
not to be missing. These abberations can be hiding almost in plain
sight. Such inconsistencies can be downright insidious, and with time
all of this makes us ask ourselves, “can we really trust any table?”

Sure, we can sit down with a table during a long interrogation session
and rough it up with a little **SQL**. The problem is we have lots of
tables, and we usually have a lot of columns in every one of these
tables. Makes for long hours with many suspect tables…

We need a tool like **pointblank**. It lets us get up close with tables
and unleash a fury of validation checks. Are some tables in remote
databases? That’s no problem, we’ll interrogate them from afar. In
essence, your DB tables can get the same line of questioning as your
local data frames or those innocent-looking tibbles. Trust me, they’ll
start to talk and then they’ll surely reveal what they’re hiding after
an intense **pointblank** session.

You don’t have to type up a long report either, **pointblank** will take
care of the paperwork. At the very least, you can get a `yes` or `no` as
to whether everything checked out. With a little bit of planning, a very
informative validation report can be regularly produced. We can even
fire off emails or send messages to Slack if things get out of hand.

### Validating Local Data Frames

The **pointblank** package can validate data in local data frames, local
tibble objects, in CSV and TSV files, and in database tables
(**PostgreSQL** and **MySQL**). First, let’s look at local tables with…

<img src="man/figures/example_workflow.png">

The above workflow relies on these code blocks:

1.  Create 2 very simple **R** **tibble** objects:
    
    ``` r
    tbl_1 <-
      dplyr::tribble(
        ~a, ~b,   ~c,
        1,   6,   "h2",
        2,   7,   "h2",
        3,   8,   "h2",
        4,   9,   "d3",
        5,  10,   "h2")
    
    tbl_2 <-
      dplyr::tribble(
        ~d,   ~e,  ~f,
        "a",   0,  32,
        "b",   0,  31,
        "a",   1,  30,
        "a",   1,  32,
        "ae", -1,  39)
    ```

2.  Create a **pointblank** pipeline for validating both the `tbl_1` and
    `tbl_2` tables (ending with `interrogate()`):
    
    ``` r
    agent <- 
      create_agent() %>%             # (1)
      focus_on(
        tbl_name = "tbl_1") %>%      # (2)
      col_vals_gt(
        column = a,
        value = 0) %>%               # (3)
      rows_not_duplicated(
        cols = a & b & c) %>%        # (4)
      col_vals_gte(
        column = a + b,
        value = 7) %>%               # (5)
      col_vals_lte(
        column = b,
        value = 10) %>%              # (6)
      col_vals_regex(
        column = c,
        regex = "[a-z][0-9]") %>%    # (7)
      col_vals_in_set(
        column = c,
        set = c("h2", "d3")) %>%     # (8)
      focus_on(
        tbl_name = "tbl_2") %>%      # (9)
      col_vals_in_set(
        column = d,
        set = c("a", "b")) %>%       # (10)
      col_vals_not_in_set(
        column = d,
        set = c("a", "b")) %>%       # (11)
      col_vals_gte(
        column = e,
        value = 0) %>%               # (12)
      col_vals_null(
        column = f) %>%              # (13)
      col_vals_not_null(
        column = d) %>%              # (14)
      interrogate()                  # (15)
    ```

We can get a detailed summary report of the interrogation, showing how
many individual tests in each validation step had passed or failed. The
validation steps are classified with an `action` which indicates the
type of action to perform based on user-defined thresholds (thresholds
can be set globally, or, for each validation step).

``` r
get_interrogation_summary(agent)[, c(1, 3, 4, 7)]
#> # A tibble: 11 x 4
#>    tbl_name assertion_type      column   all_passed
#>    <chr>    <chr>               <chr>    <lgl>     
#>  1 tbl_1    col_vals_gt         a        TRUE      
#>  2 tbl_1    rows_not_duplicated a & b, c TRUE      
#>  3 tbl_1    col_vals_gte        a + b    TRUE      
#>  4 tbl_1    col_vals_lte        b        TRUE      
#>  5 tbl_1    col_vals_regex      c        TRUE      
#>  6 tbl_1    col_vals_in_set     c        TRUE      
#>  7 tbl_2    col_vals_in_set     d        FALSE     
#>  8 tbl_2    col_vals_not_in_set d        FALSE     
#>  9 tbl_2    col_vals_gte        e        FALSE     
#> 10 tbl_2    col_vals_null       f        FALSE     
#> 11 tbl_2    col_vals_not_null   d        TRUE
```

A self-contained HTML report can be generated. It provides detailed
information on the validation outcomes and it can be used as web
content.

``` r
library(pointblank)

get_html_summary(agent)
```

### Constraining Data in Validation Steps

Every validation function has a common set of options for constraining
validations to certain conditions. This can occur through the use of
computed columns (e.g, `column = col_a / col_b`) and also through
`preconditions` that can allow you to target validations on only those
rows that satisfy one or more conditions. When validating database
tables, we have the option of modifying the table of focus more
radically by supplying an SQL statement to `initial_sql`.

<img src="man/figures/function_options.png">

### Validating Tables in a Database

We can easily validate tables in a **PostgreSQL** or **MySQL**. To
facilitate access to DB tables, we create a credentials file and supply
it to each `focus_on()` step. The `create_creds_file()` allows for the
creation of this file.

``` r
library(pointblank)

# Create a credentials file for
# accessing a database
create_creds_file(
  file = ".db_creds",
  dbname = ***********,
  host = ***********************,
  port = ***,
  user = ********,
  password = **************)
```

The functional pipeline to validate database tables is not very
different than that for local tables. With database tables, however, we
have the additional option to supply an SQL statement (as `initial_sql`)
to either the `focus_on()` function (this applies the SQL statement to
table-in-focus for every subsequent validation step), or, to a specific
validation step (this overrides any SQL supplied in `focus_on()`). For
convenience, you can either supply an SQL fragment (usually a single
`WHERE` statement), or a full-fledged SQL statement that can more
greatly transform the table (e.g., using `GROUP BY`, performing table
joins, creating new columns, etc.). Any new columns generated via
`initial_sql` can be used as a column to validate. Below is an example
of what could be done with a mix of `initial_sql` and `preconditions` on
a hypothetical **PostgreSQL** table.

``` r
library(glue)
library(lubridate)

agent <- 
  create_agent() %>%
  focus_on(
    tbl_name = "table_1",
    db_type = "PostgreSQL",
    creds_file = ".db_creds",
    initial_sql = 
      glue(
        "WHERE date > '{date}'",
        date = today() - days(10))) %>%
  col_vals_gte(
    column = a,
    value = 2) %>%
  col_vals_between(
    column = b + c + d,
    left = 50,
    right = 100,
    preconditions = 
      c > d & !is.na(b)) %>%
  col_vals_lte(
    column = sum_c,
    value = 100,
    initial_sql = "
      SELECT date, a, b, SUM(c) AS sum_c
      FROM table_1
      WHERE a < 10 AND b IS NOT NULL
      GROUP BY date, a") %>%
  interrogate()
```

### Creating and Accessing Row Data that Failed Validation

We can collect row data that didn’t pass a validation step. The amount
of non-passing row data collected can be configured in the
`interrogate()` function call. When validating local data (data frames,
tibbles, CSVs/TSVs), we can set `get_problem_rows = TRUE` and provide
values to either of:

  - `get_first_n`: Get the first `n` non-passing rows from each
    validation step.
  - `sample_n`: Sample `n` non-passing rows from each validation step.
  - `sample_frac`: Sample a fraction of the total non-passing rows from
    each validation step.

For remote tables, we cannot use any of the `sample_*` arguments to
collect non-passing rows (only `get_first_n` currently works). In order
to avoid sampling more rows than could reasonably be handled with
`sample_frac`, the `sample_limit` argument allows us to provide a
sensible limit to the number of rows returned.

The amount of row data available depends on both the fraction of rows
that didn’t pass a validation step and the level of sampling or explicit
collection from that set of rows (this is defined within the
`interrogate()` call).

Here is an example of how rows that didn’t pass a validation step can be
collected and accessed:

``` r
library(pointblank)

# Set a seed
set.seed(23)

# Create a simple data frame with a
# column of numerical values
df <-
  data.frame(
    a = rnorm(
      n = 100,
      mean = 5,
      sd = 2))

# Create 2 simple validation steps
# that test values of column `a`
agent <-
  create_agent() %>%
  focus_on(tbl_name = "df") %>%
  col_vals_between(
    column = a,
    left = 4,
    right = 6) %>%
  col_vals_lte(
    column = a,
    value = 10) %>%
  interrogate(
    get_problem_rows = TRUE,
    get_first_n = 10)
  
# Find out which of the two
# validation steps contain sample
# row data (it is step 1)
get_row_sample_info(agent)[, 1:5]
#>   step tbl             type n_fail n_sampled
#> 1    1  df col_vals_between     65        10

# Get row sample data for those rows
# in `df` that did not pass the first
# validation step (where column values
# for `col_vals_between()` were not
# between 4 and 6); the leading column,
# `pb_step_`, has been added to provide
# context on the validation step for
# which these rows failed to pass 
agent %>%
  get_row_sample_data(step = 1)
#> # A tibble: 10 x 2
#>    pb_step_        a
#>       <int>    <dbl>
#>  1        1 6.826534
#>  2        1 8.586776
#>  3        1 6.993210
#>  4        1 7.214981
#>  5        1 7.038411
#>  6        1 8.151559
#>  7        1 2.906929
#>  8        1 2.567247
#>  9        1 3.959643
#> 10        1 3.801374
```

### Functions Available in the Package

These workflow examples provided a glimpse of some of the functions
available. For sake of completeness, here’s the entire set of functions:

<img src="man/figures/pointblank_functions.png">

## Installation

**pointblank** is used in an **R** environment. If you don’t have an
**R** installation, it can be obtained from the [**Comprehensive R
Archive Network (CRAN)**](https://cran.r-project.org/).

The **CRAN** version of this package can be obtained using the following
statement:

``` r
install.packages("pointblank")
```

You can install the development version of **pointblank** from
**GitHub** using the **devtools** package.

``` r
devtools::install_github("rich-iannone/pointblank")
```

If you encounter a bug, have usage questions, or want to share ideas to
make this package better, feel free to file an
[issue](https://github.com/rich-iannone/pointblank/issues).

## Code of Conduct

[Contributor Code of
Conduct](https://github.com/rich-iannone/pointblank/blob/master/CONDUCT.md).
By participating in this project you agree to abide by its terms.

## License

MIT © Richard Iannone
