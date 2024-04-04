FROM rocker/shiny-verse:latest 
RUN apt-get update && apt-get install -y --no-install-recommends \ 
    sudo \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    && rm -rf /var/lib/apt/lists/*

RUN Rscript -e 'install.packages(c("AzureStor", "scales"))'
RUN echo "local(options(shiny.port = 3838, shiny.host = '0.0.0.0'))" > /usr/local/lib/R/etc/Rprofile.site
RUN addgroup --system app \
    && adduser --system --ingroup app app
RUN RIMPORT=$(env) && echo $RIMPORT > /home/.Renviron 
RUN mkdir /root/runApp
COPY . /root/app
WORKDIR /home/app
EXPOSE 3838
CMD ["R", "-e", "shiny::runApp('/root/app')"]