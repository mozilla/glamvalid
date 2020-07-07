source("libs.R")
basicConfig()

os = Sys.getenv("OS")
channel = Sys.getenv("CHANNEL")
date_start = Sys.getenv("DATE_START")
date_end = Sys.getenv("DATE_END")
build_start = Sys.getenv("BUILD_START")
build_end = Sys.getenv("BUILD_END")
major_ver = Sys.getenv("MAJOR_VER")
histos = Sys.getenv("HISTOS")
histo_path = '/root/histo.txt'

## build the filter string
if(channel != 'release'){
    date_start = strftime(as.Date(build_start,'%Y%m%d'),'%Y-%m-%d')
    date_end= strftime(as.Date(build_end,'%Y%m%d')+7,'%Y-%m-%d')
    fil = glue("
where normalized_channel = '{channel}'
and environment.system.os.name = '{os}'
and substr(application.build_id,1,8)>='{build_start}'
and substr(application.build_id,1,8)<='{build_end}'
and DATE(submission_timestamp)>='{date_start}'
and DATE(submission_timestamp)<='{date_end}'
", if(major_ver!="NG") "and substr(metadata.uri.app_version,1,2)='{major_ver}'" else "")
}else{
    fil = glue("
where normalized_channel = '{channel}'
and environment.system.os.name = '{os}'
and DATE(submission_timestamp)>='{date_start}'
and DATE(submission_timestamp)<='{date_end}'
and sample_id=42
", if(major_ver!="NG") "and substr(metadata.uri.app_version,1,2)='{major_ver}'" else "")
}
if(histos==""){
    histos = paste(readLines(histo_path),collapse="\n")
} 
loginfo(glue("os={os}, channel={channel}, date=({date_start},{date_end}),  major_version={major_ver}"))
if(nchar(histos) > 0){
    loginfo("histograms")
    loginfo(histos)
    k = list(clauz = fil, channel = channel, os=os, h = histos)
    tx = tempfile(pattern='glam_')
    save(k, file=tx)
    nf = sprintf("glam_%s.html",digest(k))
    loginfo(glue("saved variables to {tx}, output html will be written to /tmp/{nf}"))
    rmarkdown::render("./sitegen.Rmd",params=list(f = tx),
                      output_file=sprintf("/tmp/%s",nf))
    loginfo(glue("Otput html will be written to {nf} and if you specified --mount type=bind,source=\"$(pwd)\"/outputs,target=/tmp/ then look inside outputs"))
} else {
    stop(glue("Histograms are empty, neither environment HISTOS and the file {histo_path} did not help"))
}


#payload.histograms.fx_session_restore_file_size_bytes
#payload.histograms.telemetry_compress
#payload.histograms.cycle_collector_worker_visited_ref_counted
