`sol` <- function(c){
  if(missing(c)){  # return SOL
    jj <- getOption("c")
    if(!is.null(jj)){
      return(jj)
    } else {
      return(1)
    }
  } else { # set SOL
    options("c" = c)
    if(isTRUE(getOption("showSOL"))){
        options("prompt" = paste(c, "> "))
    }
    return(c)
  }
}

`coordnames` <- function(...){c("t","x","y","z")}

`flob` <- function(x){
  if(all(dim(x)==c(4,4))){
    jj <- coordnames()
  } else if(all(dim(x)==c(3,3))){
    jj <- coordnames()[-1]
  } else {
    stop("matrix must be either 3x3 or 4x4")
  }
  rownames(x) <- jj
  colnames(x) <- jj
  return(x)
}

`eta` <- function(downstairs=TRUE){
  if(downstairs){
    return(diag(c(-sol()^2,1,1,1)))
    } else {
      return(diag(c(-1/sol()^2,1,1,1)))
    }
}

`as.3vel` <- function(x){
  x <- unclass(x)
  if(length(x)==1){
    if(x==0){
      x <- c(0,0,0)
    } else {
      stop("not defined")
    }
  }

  if(is.vector(x)){x <- t(x)}
  if(ncol(x) == 4){   # assumed to be a 4-velocity
    out <- to3(as.4vel(x))
  } else if(ncol(x)==3){
    if(all(rowSums(x^2)<sol()^2)){
      out <- x
    } else {
      stop("speed > c")
    }
  } else {
    stop("should have 3 or 4 columns")
  }
  class(out) <- c("3vel","vec") # this is the only place where the class is set
  return(out)
}

`3vel` <- function(n){ as.3vel(matrix(0,n,3))  }
`4vel` <- function(n){ as.4vel(matrix(0,n,3))  }

`threevel` <- `3vel`
`fourvel` <- `4vel`

`is.3vel` <- function(x){inherits(x,"3vel")}
`is.4vel` <- function(x){inherits(x,"4vel")}

`c.3vel` <- function(...){ as.3vel(do.call("rbind",list(...))) }
`c.4vel` <- function(...){ as.4vel(do.call("rbind",list(...))) }

`print.3vel` <- function(x, ...){
  x <- unclass(x)
  if(is.null(colnames(x)) & ncol(x)==3){
    colnames(x) <- coordnames()[-1]
  }
  return(invisible(print(x)))
}

`print.4vel` <- function(x, ...){
  x <- rbind(unclass(x))
  if(is.null(colnames(x)) & ncol(x)==4){ 
    colnames(x) <- coordnames()
  }
  return(invisible(print(x)))
}

`length.vec` <- function(x){nrow(x)}
`names.vec` <- function(x){rownames(x)}

`names<-.vec` <- function(x,value){
  rownames(x) <- value
  return(x)
}

`r3vel` <- function(n=7,r=NA){
  z <- runif(n,-1,1)
  phi <- runif(n,0,2*pi)
  u <- sqrt(1-z^2)
  out <- cbind(x=u*sin(phi),y=u*cos(phi),z=z)  # Cartesian coords on unit sphere
  if(is.na(r)){
    out <- out*runif(n)^(1/3)*sol()
  }  else {
    out <- out*r
  }
  return(as.3vel(out))
}

r4vel <- function(...){as.4vel(r3vel(...))}

`rboost` <- function(r=NA){
  O <- svd(matrix(rnorm(9),3,3))$v
  if(det(O)<0){O <- -O} # det(O) either 1 or -1
  crossprod(adiag(1,O),boost(r3vel(1,r=r)))
}

`massage3` <- function(u,v){
  lu <- length(u)
  lv <- length(v)
  if( (lu >= lv) & (!is.null(names(u)))){
    names.out <- names(u)
  } else {
    names.out <- names(v)
  }

  jj <- rbind(seq(length.out=lu),seq(length.out=lv))
  if(length(names.out) != ncol(jj)){names.out <- NULL}
  return(list(
      u = (unclass(u))[jj[1,],,drop=FALSE],
      v = (unclass(v))[jj[2,],,drop=FALSE],
      names=names.out))
}


`speed` <- function(u){UseMethod("speed",u)}

`speed.3vel` <- function(u){sqrt(rowSums(unclass(u)^2))}
`speed.4vel` <- function(u){speed(as.3vel(u))}

`speedsquared` <- function(u){rowSums(unclass(u)^2)}

`gam` <- function(u){
  UseMethod("gam",u)
}

`gam.3vel` <- function(u){
  1/sqrt(1-rowSums(unclass(u)^2)/sol()^2)  #inline code avoids taking unnecessary sqrt()
}

`gam.4vel` <- function(u){
  u[,1]
}

`gam.default` <- function(u){
  1/sqrt(1-u^2/sol()^2)
}

`gamm1` <- function(u){   # gamm1() named in analogy to expm1()
  UseMethod("gamm1",u)
}

`gamm1.3vel` <- function(u){
  jj <- log1p(-rowSums(unclass(u)^2/sol()^2))/2
  return(-expm1(jj)/exp(jj))
}

`gamm1.4vel` <- function(u){ # should not be here
  u[,1]-1
}

`gamm1.default` <- function(u){  # 'u' is a speed
  jj <- log1p(-u^2/sol()^2)/2
  return(-expm1(jj)/exp(jj))
}

`gam_ur` <- function(d){  # d=1-speed, d<<c
  d <- d/sol()
  return(1/sqrt(2*d-d^2))
}

`rapidity` <- function(u){ UseMethod("rapidity",u) }

`rapidity.default` <- function(u){  # 'u' is a speed
    sol()*atanh(u/sol())
}

`rapidity.3vel` <- function(u){
    rapidity(speed(u))
}

`rapidity.4vel` <- function(u){
    g <- u[,1] # gamma
    log(2*g*(g+sqrt(g^2-1))-1)/2
}

`rapidity_ur` <- function(d){# d=1-speed, d<<c
    d <- d/sol()
    sol()*log((2-d)/d)/2
}

`celerity` <- function(u){ UseMethod("celerity",u) }

`celerity.default` <- function(u){  # 'u' is a speed
    u*gam(u)
}

`celerity.3vel` <- function(u){
    celerity(speed(u))
}

`celerity.4vel` <- function(u){
    g <- u[,1] # gamma
    sqrt(g^2-1)
}

`celerity_ur` <- function(d){# d=1-speed, d<<c
    d <- d/sol()
    sol()*(1-d)/sqrt(d*(2-d))
}

`add3` <- function(u,v){  # eq 2
  jj <- massage3(u,v)
  u <- jj[[1]]
  v <- jj[[2]]
  gu <- gam.3vel(u)
  uv <- rowSums(u*v)/sol()^2  # u.v/c^2
  out <- u + sweep(v,1,gu,"/") + sweep(u,1,uv*gu/(1+gu),"*")
  out <- sweep(out,1,1+uv,"/")
  rownames(out) <- jj$names
  return(as.3vel(out))
}

`neg3` <- function(u){as.3vel(-unclass(u))}

`dot3` <- function(v,r){
  if(is.infinite(sol())){ return(as.3vel(unclass(v)*r)) }
    jj <- cbind(seq_along(v),seq_along(r))
    v <- v[jj[,1]]
    r <- r[jj[,2]]


    vc <- sqrt(prod3(v))/sol()
    out <- sweep(unclass(v),1,tanh(r*atanh(vc))/vc,"*")
    out[vc==0,] <- 0
    return(as.3vel(out))
}

`prod3` <- function(u,v=u){
  jj <- massage3(u,v)
  out <- rowSums(jj[[1]]*jj[[2]])
  names(out) <- jj$names
  return(out)
}

`[.vec` <- function(x,i,j,drop=TRUE,...){
    a <- class(x)
    x <- unclass(x)
    if(missing(i) & !missing(j)){ # x[,j]
      return(x[,j,drop=drop])
    } else if(!missing(i) & !missing(j)){  # x[i,j]
      return(x[i,j,drop=drop])  # NB: unclassed
    } else if(missing(i) & missing(j)){  # x[]
      out <- x
    } else if(!missing(i) & missing(j)){  # meat of function: idiom x[i]; x[i,]
      out <- x[i,,drop=FALSE]  # NB: overrides method default
      if(ncol(out)==3){return(as.3vel(out))}
    } else {
      stop("this cannot happen")
    }
    class(out) <- a
    return(out)
}

`[<-.3vel` <- function(x,i,j,value){
    x <- unclass(x)
    value <- unclass(value)
    if(missing(i) & missing(j)){  # x[] <- value
      stop("'x[] <- value' meaningless for 3-velocities")
    } else if(missing(i) & !missing(j)){ # x[,j] <- value
        x[,j] <- value
        return(as.3vel(x))  # NB checks for speed>c
    } else if(!missing(i) & !missing(j)){  # x[i,j] <- value
        x[i,j] <- value
        return(x)  # NB no class, just a matrix
    } else if(!missing(i) & missing(j)){  # x[i,];  x[i] <- value
        if(length(value)==1){
          if(value==0){
          x[i,] <- 0
          return(as.3vel(x))
          } else {
            stop("3vel scalar replacement method only defined for special value 0")
          }
        } else {  # length(value) > 0
          jj <- t(x)
          jj[,i] <- t(value)
          x <- t(jj)
          return(as.3vel(x))
        }
    } else {
      stop("3vel replacement error: this cannot happen")
    }
}
  
`[<-.4vel` <- function(x,i,j,value){
    x <- unclass(x)
    if(missing(i) & missing(j)){  # x[] <- value
        stop("'x[] <- value' meaningless for 4-velocities")
    } else if(missing(i) & !missing(j)){ # x[,j]
        stop("'x[,j] <- value' meaningless for 4-velocities")
    } else if(!missing(i) & !missing(j)){  # x[i,j]
        x[i,j] <- value
        return(x)
    } else if(!missing(i) & missing(j)){  # x[i,] == x[i]
        if(is.4vel(value)){
            jj <- t(x)
            jj[,i] <- t(value)
            x <- t(jj)
            return(as.4vel(x))
        } else if(length(value)==1){
            if(value==0){
                x[i,1] <- 1
                x[i,-1] <- 0
                return(as.4vel(x))
            } else {
                stop("4vel scalar replacement method only defined for special value 0")
            }
        } else {  # length(value) > 0
            stop("replacement value not acceptable")
        }
    } else {
        stop("4vel replacement error: this cannot happen")
    }
}
  
`equal3` <- function(u,v){
  jj <- massage3(u,v)
  u <- jj[[1]]
  v <- jj[[2]]
  rowSums(unclass(u)!=unclass(v))==0
  }

`Ops.4vel` <- function(e1,e2){
  if(nargs() == 1){
    stop("Unary operator '", .Generic, "' is not implemented for 4vel objects")
  } else {
    stop("Operator '", .Generic, "' is not implemented for 4vel objects (four-velocities do not constitute a vector space).")
  }
}

`Ops.3vel` <- function(e1,e2){
  f <- function(...){stop("odd---neither argument has class 3vel?")}
  unary <- nargs() == 1
  lclass <- nchar(.Method[1]) > 0
  rclass <- !unary && (nchar(.Method[2]) > 0)
  
  if(unary){
    if (.Generic == "+") {
      return(e1)
    } else if (.Generic == "-") {
      return(neg3(e1))
    } else {
      stop("Unary operator '", .Generic, "' is not implemented for 3vel objects")
    }
  }
  if (!is.element(.Generic, c("+", "-",  "==", "!=", "*","/")))
    stop("operator '", .Generic, "' is not implemented for 3vel objects")
  
  if (.Generic == "*"){
    if(lclass & !rclass){
      return(dot3(e1,e2))
    }  else if (!lclass & rclass){
      return(dot3(e2,e1))
    } else {
      stop(" '*' requires a three-vector and a scalar")
    }
  }

  if (.Generic == "/"){
    if(lclass & !rclass){  # e.g. u/2
      return(dot3(e1,1/e2))
    } else {
      stop(" '/' requires a three-vector and a scalar")
    }
  }

  stopifnot(lclass & rclass)
    
  if (.Generic == "+") { 
    return(add3(e1, e2)) 
  } else if (.Generic == "-") { 
    return(add3(e1, neg3(e2)))
  } else if (.Generic == "==") {
    return(equal3(e1,e2))
  } else if (.Generic == "!=") {
    return(!equal3(e1,e2))
  } else {
    stop("should not reach here")
  }
}

## Equation numbers refer to Ungar 2006


`gyr` <- function(u,v,x){  # eq 6
  add3(neg3(add3(u,v)),add3(u,add3(v,x)))
}

`gyr.a` <- function(u,v,x){  # eq 6
  -(u+v) + (u+(v+x))
}

`gyrfun` <- function(u,v){
  return(function(x){gyr(u,v,x)})
}

`as.4vel` <- function(u){  # takes a 3vel, returns a 4vel
  u <- unclass(u)
  if(length(u)==1){
    if(u==0){
      u <- c(0,0,0)
    } else {
      stop("not defined")
    }
  }

  if(is.vector(u)){u <- t(u)}
  
  if(ncol(u)==3){
    u <- as.3vel(u) # checks for speed>c
    out <- cbind(t=1,u)*gam(u) # convert to a four-vector
    } else if(ncol(u)==4) { # assumes a 4-vector
      if(all(is.consistent.4vel(u))){
        out <- u
      } else {
        stop("inconsistent 4-velocity")
      }
    } else {
      stop("not recognised")
    }
  
  colnames(out) <- coordnames()
  class(out) <- c("4vel","vec")  # this is the only place class 4vel is assigned
  return(out)
}

`to3` <- function(U){  # takes a 4velocity, returns a 3vel
    stopifnot(is.4vel(U))
    return(as.3vel(sweep(U[, -1, drop = FALSE],1,U[,1],"/")))
}

`inner4` <- function(U,V=U){
  quad.3tdiag(eta(),unclass(U),unclass(V))
}

`is.consistent.4vel` <- function(U,give=FALSE, TOL=1e-10){

    out <- (inner4(U) + sol()^2)/sol()^2
    if(give){
        return(out)
    } else {
        return(abs(out)<TOL*sol()^2)
    }
}

`is.consistent.boost.galilean` <- function(L, give=FALSE, TOL=1e-10){
  stopifnot(all(dim(L) == 4))
  out <- crossprod(L[-1,-1])
  if(give){
    return(out)
  } else {
    return(
        all(L[1,] == c(1,0,0,0)) &&
        all(abs(out-diag(3)) < TOL)
    )
  }
}

`is.consistent.boost` <- function(L, give=FALSE, TOL=1e-10){
  if(is.infinite(sol())){return(is.consistent.boost.galilean(L, give=give, TOL=TOL))}
  out <- quad.form(eta(),L) # should be eta()
  if(give){
    return(out)
  } else {
    return(all(abs(out-eta())<TOL*sol()^2))
  }
}

`my_seg` <- function(u,start=as.3vel(0), bold=5, ...){
  start <- unclass(start)[,1:2,drop=FALSE]
  u <- unclass(u)
  u <- u[,1:2,drop=FALSE]   # now a two-column matrix
  
  for(i in seq_len(nrow(u))){
    if(i==bold | nrow(u)==1){
      lwd <- 4
      length <- 0.3
    } else {
      lwd <- 1
      length <- 0.1
    }
    arrows(
        x0=start[i,1],
        y0=start[i,2],
        x1=u[i,1],
        y1=u[i,2],
        angle=10,
        length=length,
        lwd=lwd,
        ...
    )
  }
}

`comm_fail1` <- function(u,v,bold=5,r=1){
    plot(NA, xlim=c(0,1), ylim=c(-0.2,1),
         type='n', asp=1,
         xlab='', ylab='', axes=FALSE,
         main="Failure of the parallelogram law")
    my_seg(u,start=0*u,col='purple',bold=bold)
    my_seg(u+v,start=u+v*0,col='black',bold=bold)
    my_seg((u+v)-u,start=u+v,col='red',bold=bold)
    my_seg(((u+v)-u)-v,start=(u+v)-u,col='blue',bold=bold)
    points(((u+v)-u)-v,pch=16,col='blue')
    legend("topright",lty=c(1,1,1,1,2),
           col=c("purple","black","red","blue","green"),
           legend=c("leg 1","leg 2","leg 3","leg 4", "c=1"))
    points(0,0,pch=16)
    
    theta <- seq(from=0,to=2*pi,len=100)
    points(r*sin(theta),cos(r*theta),type='l',lty=2,col='green')
}

`comm_fail2` <- function(u,v,bold=5,r=1){
    plot(NA, xlim=c(-0.2,0.9), ylim=c(-0.2,1),
         type='n',asp=1,
         xlab='',ylab='',axes=FALSE,
         main="Failure of the parallelogram law")
    my_seg(u,start=0*u,col='black',bold=bold)
    my_seg(u+v,start=u+v*0,col='blue',bold=bold)
    
    my_seg(v,start=0*v,col='blue',bold=bold)
    my_seg(v+u,start=v,col='black',bold=bold)
    
    my_seg(u+v,start=v+u,col='red',code=0,bold=bold)
    
    legend("topright",lty=c(1,1,1,2),
           col=c("black","blue","red","green"),
           legend=c("u","v","mismatch","c=1"))
    
    points(0,0,pch=16)
    
    theta <- seq(from=0,to=2*pi,len=100)
    points(r*sin(theta),r*cos(theta),type='l',lty=2,col='green')
}

`ass_fail` <- function(u,v,w,bold=5,r=1){
    plot(c(0,0),c(-0.1,1),xlim=c(0,1),ylim=c(-0.3,1),type='n',
         asp=1,pty='m',xlab='',ylab='',
         axes=FALSE,main='Failure of associative property')
    my_seg(u,start=v*0,col='black',bold=bold)
    my_seg(u+(v+w),start=v*0+u,col='black',bold=bold)
    
    my_seg(u+v,start=v*0,col='blue',bold=bold)
    my_seg((u+v)+w,start=u+v,col='blue',bold=bold)
    
    my_seg(u+(v+w),start=(u+v)+w,col='red',bold=bold)
    legend("topright",lty=c(1,1,1,2),col=c("black","blue","red","green"),legend=c("u+(v+w)","(u+v)+w","mismatch","c=1"))
    
    points(0,0,pch=16,cex=3)
    theta <- seq(from=0,to=2*pi,len=100)
    points(r*sin(theta),r*cos(theta),type='l',lty=2,col='green')
}

`seq.3vel` <- function(from, to, len,...){
  tee <- seq(from=0,to=1,length.out=len)
  return(from + tee*(-from+to))
}

`boost` <- function(u){  # v = (u,v,w)
  u <- as.3vel(u)
  if(is.infinite(sol())){return(flob(rbind(c(1,0,0,0),cbind(t(-u),diag(3)))))}
  g <- gam(u)  
  u <- as.vector(u)/sol()  # convert to c=1 units (NB previous line needs sol())
  jj <- -g*u
  
  out <- rbind(c(g,jj), cbind(jj,diag(3) + g^2*outer(u,u)/(1+g)))

  ## convert units back to SI or whatever:
  out <- quad.3form(out,diag(c(1/sol(),1,1,1)),diag(c(sol(),1,1,1)))

  rownames(out) <- coordnames()
  colnames(out) <- coordnames()

  return(out)
 }

`rot` <- function(u,v,space=TRUE){
  u <- as.3vel(u)
  v <- as.3vel(v)
  out <- boost(-u-v) %*% boost(u) %*% boost(v)
  if(space){
    return(out[2:4,2:4])
  } else {
    return(out)
  }
}
   
`pureboost.galilean` <- function(L,tidy=TRUE){
  stopifnot(is.consistent.boost.galilean(L))
  out <- crossprod(orthog.galilean(L),L)
  if(tidy){out[2:4,2:4] <- diag(3)}
  return(out)
}

`orthog.galilean` <- function(L){
  stopifnot(is.consistent.boost.galilean(L))
  magic::adiag(1,L[-1,-1])
}

`pureboost` <- function(L,include_sol=TRUE){
  if(is.infinite(sol())){return(pureboost.galilean(L))}
  if(include_sol){
    left <- ptm(TRUE)
    right <- ptm(FALSE)
  } else {
    left <- diag(nrow=4)
    right <- diag(nrow=4)
  }
    
  jj <- eigen(crossprod(quad.3form(L,left,right)))
  flob(quad.3form(quad.tform(sqrt(diag(jj$values)),jj$vectors),right,left))
}

`orthog` <- function(L){
  if(is.infinite(sol())){return(orthog.galilean(L))}
  L <- quad.3form(L,ptm(TRUE),ptm(FALSE))  # convert to natural units
  flob(tcrossprod(L, solve(pureboost(L,FALSE))))
} 

`as.matrix.3vel` <- function(x,...){unclass(x)}
`as.matrix.4vel` <- function(x,...){unclass(x)}

`cosines` <- function(u, drop=TRUE){
  out <- sweep(unclass(u),1,speed(u),"/")
  if(drop){out <- drop(out)}
  return(out)
}
