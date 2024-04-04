FROM mcr.microsoft.com/azure-functions/dotnet:4-appservice 
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

RUN apt-get update && apt-get install -y gnupg
RUN apt-key adv --keyserver keyserver.ubuntu.com \
    --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7'
RUN echo "deb http://cloud.r-project.org/bin/linux/debian bullseye-cran40/" > /etc/apt/sources.list.d/backports.list
RUN apt-get update && \
    apt-get install -y \
     libxml2-dev \
     libsodium-dev \
     libsodium23 \ 
     -t bullseye-cran40 r-base
     
RUN apt-get install -y --no-install-recommends \
 libcurl4-openssl-dev \
 libssl-dev libxt6 libglpk-dev libx11-dev && \
 mkdir -p ~/.local/share/renv && \
 R -e "install.packages('renv', repos='http://cran.rstudio.com/')"

### splitted the copying into parts so the rebuiliding times are quicker
COPY renv.lock /home/site/wwwroot/renv.lock
WORKDIR /home/site/wwwroot
RUN R -e "renv::restore(prompt=FALSE)"
COPY image_timer_predict_trigger/ /home/site/wwwroot/image_timer_predict_trigger
COPY host.json /home/site/wwwroot/host.json
COPY handler.R /home/site/wwwroot/handler.R
COPY handle_this.R /home/site/wwwroot/handle_this.R
COPY run_job.R /home/site/wwwroot/run_job.R

  
