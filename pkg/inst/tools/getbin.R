RELEASE <- "r135"
w7ver <- "mingw"
buildbot_base <- "http://www.admb-project.org/buildbot/glmmadmb/glmmadmb-admb-"
## assume are starting from the root of the package directory
platform_str <- c(linux32="ubuntu11-gcc4.5-32bit-",
                  linux64="ubuntu11-gcc4.5-64bit-",
                  macos32="macos10.6-xcode3.2-32bit-",
                  macos64="macos10.6-xcode3.2-64bit-",
                  windows32="windows7-borland-32bit-",
                  windows64="windows7-vc10-64bit-")
  ## c(linux32="linux-gcc4.5.2-32bit",
  ##   linux64="linux-gcc4.5.2-64bit",
  ##   macos32="macos10.6.7-xcode3.2.6-32bit",
  ##   macos64="macos10.6.7-xcode3.2.6-64bit")
if (!file.exists("inst/bin")) {
  setwd("../..")  ## try moving up
  if (!file.exists("inst/bin")) {
    stop("can't find bin directory -- are you in the package root?")
  }
}
setwd("inst/bin")
for (i in names(platform_str)) {
  setwd(i)
  srcext <- if (grepl("windows",i)) ".exe" else ".bin"
  destext <- if (grepl("windows",i)) ".exe" else ""
  fn <- paste(buildbot_base,platform_str[i],RELEASE,
                      srcext,sep="")
  download.file(fn,
                destfile=paste("glmmadmb",destext,sep=""))
  setwd("..")
}
  
## glmmadmb-r107-bcc5.5-32bit 	0B 	[text/html] 	
## glmmadmb-r107-linux-gcc4.4.3-32bit 	1M 	[text/html] 	
## glmmadmb-r107-linux-gcc4.5.2-32bit 	1M 	[text/html] 	
## glmmadmb-r107-linux-gcc4.5.2-64bit 	1M 	[text/html] 	
## glmmadmb-r107-linux-solarisstudio12-32bit 	2M 	[text/html] 	
## glmmadmb-r107-macos10.6.7-xcode3.2.6-32bit 	2M 	[text/html] 	
## glmmadmb-r107-macos10.6.7-xcode3.2.6-64bit 	2M 	[text/html] 

bburl <- "http://admb-project.org/buildbot/glmmadmb/"

get_bbot_versions <- function(os="all",rev="latest",bits="all") {
  require(plyr)
  z <- readLines(url(bburl))
  desc <- z[grep("glmmadmb",z)]
  sizes <- z[grep("[0-9][BKM]",z)]
  desc <- desc[-1]  ## header line
  desc <- gsub(".+\"(([a-z0-9.]|-)+).*","\\1",desc)
  ## assume 0B = 0 -- everything else will be in M
  sizes <- as.numeric(gsub(".+>([0-9.]+).*","\\1",sizes))
  d <- data.frame(desc,sizes)
  d <- subset(d,sizes>0)
  if (os!="all") d <- d[grep(os,d$desc),]
  if (bits!="all") d <- d[grep(paste(d$bits,"bit",sep="")),]
  if (rev=="latest") {
    d$type <- gsub("-r[0-9]+.*$","",d$desc)
    d$ver <- as.numeric(gsub(".*-r([0-9]+).*$","\\1",d$desc))
    d <- droplevels(ddply(d, .(type), function(x) x[which.max(x$ver),]))
  } else if (ver!="all") {
    d <- d[d$ver==ver,]
  }
  d <- transform(d,desc=as.character(desc),type=as.character(type))
  d
}

download_bin <- function(x,quiet=FALSE) {
  download.file(paste(bburl,x,sep=""),x)
}

test_bin <- function(x) {
  Sys.chmod(x)
  v <- try(system(paste("./",x," 1> tmp.log 2>&1",sep=""),intern=TRUE))
  readLines("tmp.log")
}

test_OK <- function(x) length(x)==3 && x[3]==" This is usual caused by a missing DAT file "

test_allbin <- function(...) {
  d <- get_bbot_versions(...)
  z <- lapply(d$desc,function(x) {
    download_bin(x)
    test_bin(x)
  })
  invisible(sapply(d$desc,unlink))
  unlink(c("b1","b2","s1","s2","glmmadmb*.log",
           "tmp.log","variance","eigv.rpt","\001",
           "fmin.log"))
  data.frame(type=d$type,ver=d$ver,OK=sapply(z,test_OK))
}

## test_allbin()