
library(logger)
log_appender(appender_file("log.txt"))
log_threshold(INFO)
library(plumber)
PORTEnv <- Sys.getenv("FUNCTIONS_CUSTOMHANDLER_PORT",unset = NA)
if(is.na(PORTEnv)){PORTEnv <- 80}
PORT <- strtoi(PORTEnv , base = 0L)
log_info("Running on port {PORT}")
pr("handle_this.R") %>%
  pr_run(port=PORT)