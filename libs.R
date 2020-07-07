library(knitr)
library(data.table)
library(bigrquery)
library(DBI)
library(vlbuildr)
library(glue)
library(digest)
library(logging)
set.seed(0)

tablename <- glue("`moz-fx-data-shared-prod`.analysis.sguha_tmp_deleteme","_", paste(sample(letters,5),collapse=""))


bq <- function(project = 'moz-fx-data-derived-datasets'
              ,dataset = 'telemetry'){
    require(data.table)
    #bq_auth()
    bq_auth(email='sguha@mozilla.com' ,use_oob =TRUE ) #path = "~/mz/confs/gcloud.json")
    ocon <- dbConnect(
        bigrquery::bigquery(),
        project = project,
        dataset = dataset)
    w <- dbListTables(ocon)
    adhoc <- function(s,n=200,con=NULL){
        ## be careful with n=-1 !!
        if(is.null(con)) con <- ocon
        data.table(dbGetQuery(con, s, n = n))
    }
    f <- list(w=w,con=ocon, query=adhoc)
    class(f) <- "bqh"
    return(f)
}

getData <- function(vars, where,table=tablename,g=NULL,debug=FALSE){
    base1 <- glue("
CREATE OR REPLACE TABLE {table}
OPTIONS(
  expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 2 HOUR)
) AS
(
with
myclients AS (
select
client_id as id,
substr(application.build_id,1,8) as buildid,
{vars}
from telemetry.main
{where}
)
select * from myclients
)
")
    message(base1)
    list(base1,g$q(base1))
}

dirch <- function(v, REP){
    ## Generate dirichlet samples
    t(replicate(REP,{
        a <- sapply(v, function(s) rgamma(1,shape=s,scale=1))
        a/sum(a)
    }))
}
donedone=TRUE
h.compute <- function(table,H='x', n=-1,g,debug=FALSE){
    base1 <- "a as (
select
id, buildid,
udf.json_extract_int_map({H[2]}) as x
from {table}
),
b0 as ( select  buildid,id,key,sum(coalesce(value,0)) as value from a cross join unnest(x)  group by 1,2,3 ),
b1 as ( select  buildid,id, sum(value) as npings from b0 group by 1,2),
b  as ( select  b0.buildid,b0.id, key, value/npings as p from b1 join b0 on
        b0.id=b1.id  and b0.buildid = b1.buildid
      ),
c1 as ( select buildid,count(distinct(id)) as nreporting,count(distinct(key)) as K, sum(CAST( value as FLOAT64)) as nping  from b0 group by 1 ),
c  as ( select b.buildid,key, max(nreporting) as nreporting,max(K) as K,--max is just to get one value
        max(nping) as nmeas,
        sum(p) as psum
        from b join c1
        on b.buildid = c1.buildid
        group by 1,2),
d  as (select buildid,key, nmeas,nreporting,1/K+psum as psum,K as K,
              (1/K+psum)/(1+nreporting)  as p
      from c ),
k as (select buildid,key, nmeas, nreporting,K,psum, p, p*nmeas as pcounts
       from d 
     )
"
    query1 <- glue("with ", base1, "select * from k")
    if(donedone){
        message(query1)
        cat(query1)
        donedone <<- FALSE
    }
    r=g$q(query1,n)
    r = r[,buildid := as.Date(as.character(buildid),'%Y%m%d')]
    r[order(buildid,key),]
}

h.bucket.err <- function(histo,REP=1000){
   z <-  histo[,{
        mean_estimates <- dirch(psum, REP)
        stats <- data.table(key,
                            lower = as.numeric(apply(mean_estimates,2,quantile,0.05/2)),
                            upper=as.numeric(apply(mean_estimates,2,quantile,1-0.05/2)))
    },buildid][order(buildid),]
   merge(histo,z, by=c("buildid","key"))[order(buildid,key),]
}

h.summary <- function (histo, REP=500,sm = list(t= mean,i=function(s) s),smooth=NULL)
{
    br <- histo[, {
        D <- dirch(psum, REP)
        mean_estimates <- as.numeric(apply(D, 1, function(k) {
            if(!is.null(smooth)){
              J=jitter(key,factor=smooth)
              J=pmax(min(key),J)
              S = sample(J,10000, prob=k, replace=TRUE)
            } else{
              S = sample(key,10000, prob=k, replace=TRUE)
            }
            sm$t(S)
            }))
        I = sm$i;
        if(is.null(I)) I = function(s) s
        stats <- c(avg = I(mean(mean_estimates)),
                   lower = I(as.numeric(quantile(mean_estimates,0.05/2))),
                   upper = I(as.numeric(quantile(mean_estimates, 1-0.05/2))))
        data.table(nreporting = nreporting[1], 
            low = stats[["lower"]], est = stats[["avg"]], high = stats[["upper"]])
    },buildid][order(buildid),]
    br
}


plotHistogram = function(h,he){
   he = copy(he)
   he[, key := 1+key]
  vl_chart(title=glue("{h} for buildid {he$buildid[1]}"),
         width=500,height=200) %>%
    vl_add_data(values = he) %>%
    vl_mark_bar() %>%
    vl_encode_x("key") %>%
    vl_encode_y("p") %>% 
    vl_encode_tooltip(c("key","p")) %>%
    vl_axis_y(title = "prob") %>%
    vl_axis_x(title = "bucket") %>%
##    vl_scale_x(domain=c(0,max(he$key)),padding=0,type='log') %>%
    vl_scale_x(type='log') %>%
    vl_add_interval_selection("brush",bind='scales', type='interval')

}



plotLineFigure = function(h,he,ytit){

vl_chart(title=glue("{h} "),ytit,
         width=500,height=200) %>%
  vl_add_data(values = he) %>%
    vl_mark_line() %>%
    vl_encode_x("buildid") %>%
    vl_encode_y("est") %>% 
    vl_encode_tooltip(c("buildid","est")) %>%
  vl_axis_x(title = "buildid") %>%
  vl_axis_y(title = glue("{ytit} ")) %>%
  vl_scale_y(zero=FALSE) %>%
  vl_add_interval_selection("brush",bind='scales', type='interval')
}

