#' Perform cluster mean centering by calculating the mean of column x
#' within each cluster defined by column g. 
#'
#' A new data.frame is returned with two additional columns,
#'   *_m the mean of x within each cluster
#'   *_s the individual values of x, centered at 0
#'
#' @param df data.frame containing the variables
#' @param x char; label of the column to cluster mean center
#' @param g char; label of the column with cluster ids
#' @param label char; to use for new columns (default=x)
#' @param clobber logical; to control behavior when a column <label>_m or <label>_s already exists. TRUE: overwrite existing column. FALSE: exit function (default=FALSE)
#'
#' @return data.frame,tibble
#'
#' @examples
#' df <- tibble(x=rnorm(10), g=rep(c(0,1),5))
#' df <- cluster_mean(df, 'x', 'g')
#' df
#' # A tibble: 10 x 4
#'           x     g    x_m     x_s
#'       <dbl> <dbl>  <dbl>   <dbl>
#'  1 -0.918       0 -0.565 -0.353 
#'  2  0.355       1  0.280  0.0753
#'  3  0.0313      0 -0.565  0.596 
#'  4  0.858       1  0.280  0.578 
#'  5 -0.201       0 -0.565  0.364 
#'  6  1.88        1  0.280  1.60  
#'  7 -0.907       0 -0.565 -0.342 
#'  8 -1.69        1  0.280 -1.97  
#'  9 -0.830       0 -0.565 -0.265 
#' 10 -0.00634     1  0.280 -0.286 
#'
cluster_mean <- function(df, x, g, label=x, clobber=FALSE) {
  # set up new column names
  m_col = str_c(label, '_m')
  s_col = str_c(label, "_s")
  new_cols = c('mreservedkey', 'sreservedkey')
  names(new_cols) <- c(m_col, s_col)
  
  # check for pre-existing columns to prevent accidental clobbering
  for (col in names(new_cols)) {
    if (col %in% names(df)) {
      if (clobber) {
        warning(str_c('Replacing column: ', col))
        df <- df %>% select(-col)
      } else {
        stop(str_c("Created column [",col,"] already exists. Set clobber=TRUE to overwrite"))
      }
    }
  }
  # calculate cluster means
  dm <- df %>%
    select(g, x) %>%
    group_by(!!as.name(g)) %>%
    summarize(mreservedkey = mean(!!as.name(x), na.rm=TRUE))
  # add means to df, calculate cluster-centered values, then rename new columns
  d <- df %>%
    left_join(dm, by=g) %>%
    mutate(sreservedkey = !!as.name(x) - mreservedkey) %>%
    rename(!!new_cols)
  
  return(d)
}