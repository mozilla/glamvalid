FROM rocker/verse:3.5.0

RUN apt-get update && apt-get install -y \
        bzr \
        gnupg2 \
        cvs \
        git \
        curl \
        mercurial \
        subversion\
        zlib1g

RUN apt-get update -y

RUN echo "options(repos =  list(CRAN = 'https://cran.microsoft.com/snapshot/2020-06-15/'))\n" >> /root/.Rprofile
RUN Rscript -e "install.packages('remotes',dep=TRUE)"
RUN Rscript -e "remotes::install_github('AliciaSchep/vlbuildr')"
RUN Rscript -e "install.packages('vlbuildr',dep=TRUE)"
RUN Rscript -e "install.packages('logging',dep=TRUE)"
RUN Rscript -e "install.packages('glue',dep=TRUE)"
RUN Rscript -e "install.packages('DBI',dep=TRUE)"
RUN Rscript -e "install.packages('bigrquery',dep=TRUE)"
RUN Rscript -e "install.packages('data.table',dep=TRUE)"
RUN Rscript -e "install.packages('knitr',dep=TRUE)"
RUN Rscript -e "install.packages('rmarkdown',dep=TRUE)"
RUN Rscript -e "install.packages('digest',dep=TRUE)"


RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y

COPY . /project/

CMD  /bin/bash /project/run.sh


    

