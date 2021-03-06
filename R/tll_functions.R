#' Custom function for local likelihood fitting
#'
#' @param udata data
#' @param B bandwidth specification
#' @param deg degree of the polynomial
#'
#' @return a fitted locfit object
#' @noRd
#' @import locfit
my_locfit <- function(udata, B, deg) {
    if (is.list(B))
        return(my_locfitnn(udata, B$B, B$alpha, B$kappa, deg))
    # transform data
    zdata <- qnorm(udata)
    qrs  <- t(solve(B) %*% t(zdata))
    gr <- do.call(expand.grid, lapply(1:ncol(qrs), function(i) c(-4, 4)))
    qgr <- t(solve(B) %*% t(as.matrix(gr)))
    lims <- apply(qgr, 2L, range)
    
    ## fit model
    cl.lst <- split(as.vector(qrs), rep(1:ncol(qrs), each = nrow(qrs)))
    cl.lst$h <- 1
    cl.lst$deg <- deg
    lf.lst <- list(~do.call(lp, cl.lst),
                   maxk = 1000,
                   kern = "gauss",
                   scale = FALSE,
                   ev = lfgrid(mg = 50, 
                               ll = lims[1L, ], 
                               ur = lims[2L, ]))
    suppressWarnings(do.call(locfit, lf.lst))
}

my_locfitnn <- function(udata, B, alpha, kappa, deg) {
    # transform data
    zdata <- qnorm(udata)
    qrs  <- t(solve(B) %*% t(zdata))
    gr <- do.call(expand.grid, lapply(1:ncol(qrs), function(i) c(-4, 4)))
    qgr <-  t(solve(B) %*% t(as.matrix(gr)))
    lims <- apply(qgr, 2L, range)
    
    ## fit model
    cl.lst <- split(as.vector(qrs), rep(1:ncol(qrs), each = nrow(qrs)))
    cl.lst$nn <- alpha
    cl.lst$deg <- deg
    cl.lst$scale <- kappa
    lf.lst <- list(~do.call(lp, cl.lst),
                   maxk = 1024,
                   kern = "gauss",
                   ev = lfgrid(mg = 50, 
                               ll = lims[1L, ], 
                               ur = lims[2L, ]))
    suppressWarnings(do.call(locfit, lf.lst))
}

#' Evaluate the density of the transformation log likelihood estimator
#'
#' @param uev 
#' @param lfit 
#' @param B 
#'
#' @return copula density evalauted at \code{uev}.
#' @noRd
#' @importFrom stats predict
eval_tll <- function(uev, lfit, B) {
    if (NCOL(uev) == 1) 
        uev <- matrix(uev, ncol = 2)
    d <- ncol(uev)
    zev <- qnorm(uev)
    ev  <- t(solve(B) %*% t(zev))
    
    rescale <- pmax(apply(dnorm(zev), 1, prod), 10^(-2 * d)) * abs(det(B))
    suppressWarnings(as.numeric(predict(lfit, ev) / rescale))
}
