#!/bin/bash
## builds are YYYYMMDD
## dates are YYYY-MM-DDx
set -e
export BUCKET=${BUCKET:-gs://moz-fx-data-prod-analysis}
export PROJECT_ID=${PROJECT_ID:-moz-fx-data-shared-prod}
export DATASET=${DATASET:-telemetry}
export CHANNEL=${CHANNEL:-nightly}
export OS=${OS:-Windows_NT}
export MAJOR_VER=${MAJOR_VER:-NG}
export BUILD_START=${BUILD_START:-20200601}
export BUILD_END=${BUILD_END:-20200615}
export DATE_START=${DATE_START:-1970-01-01}
export DATE_END=${DATE_START:-1970-01-01}
## also HISTO is an environment variable, "," separated list of histogram names
## if missing, then you _must_ mount newline seprated '#' comments allowed histograms
## in the mount point /root/histo.txt




## Set START_BUILD=YYYYMMDD for the start build from when computations begin

if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS}" ]]; then
    echo "Creds set, not activating"
else
    echo "Activating Credentials"
    gcloud auth activate-service-account --key-file /app/.credentials
fi
    
if [[ -z "${RUNFAST}" ]]; then   
    ## Complete run if RUNFAST environment is missing
    echo "Running SLOW"
    cd /project/
    Rscript runner.R
else
    ## Quick Check if RUNFAST environment is passed
    echo "Running FAST"
    
fi

## If the channel is not release, please provide build_start and build_end (the date starts and ends are computed automatically)
## if channel is release, please provide date_start and date_end
## you can provide major_ver, but if you dont no filter on version
## Example Run
##docker run -it  -v ~/.R:/root/.R  -v ~/.config:/root/.config -e OS=Windows_NT -e CHANNEL=nightly -e BUILD_START=20200615 -e BUILD_END=20200701 \
##       -e HISTOS="payload.histograms.fx_session_restore_file_size_bytes" glamval
