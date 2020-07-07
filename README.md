On OS X at least,inside the repo, run

```
 docker build -t glamval .
```

This will take some time (R packages take _so_ long to install, so many
dependencies). Once done, 

```
mkdir outputs
docker run -it   -v ~/.config:/root/.config  --mount type=bind,source="$(pwd)"/outputs,target=/tmp/ \
                -e OS=Windows_NT -e CHANNEL=nightly -e BUILD_START=20200615 -e BUILD_END=20200619   \
                -e HISTOS="payload.histograms.fx_session_restore_file_size_bytes,payload.histograms.telemetry_compress,payload.histograms.cycle_collector_worker_visited_ref_counted" \
                glamval
```

- inspect `run.sh` to see environment variables, but in summary they are
  - `OS`, defaults is Windows_NT
  - `CHANNEL`, default is nightly
  - `BUILD_START`, `BUILD_END`, YYYYMMDD version of first end buildid. Use this
    for pre-release.
  - `DATE_START`,`DATE_END` for release channels. For pre-release, there isn't a
    need for this as it's computed from `BUILD_START` and `BUILD_END` variables.
  - `HISTOS` is a comma separated fully qualified histograms name
  - `MAJOR_VER` is optional, but you can specify something like 70 to restrict
    to major versions
- the arg `--mount type=bind,source="$(pwd)"/outputs,target=/tmp/` will allow
  the Docker app to write output to the folder `output/` in which the resultant
  html file be created
- Importantly the `-v ~/.config:/root/.config` will mount your BigQuery
  credentials into the Docker app so the SQL queries can be made. Without this
  it cannot connect to BigQuery.
  
As the program runs, you will see SQL written to the screen (they will also be
  in the HTML file) to give you an idea of the queries being run.
  
  
