### Send images for prediction
library(AzureStor)
library(jsonlite)
library(httr2)
library(dplyr)
library(purrr)
library(tibble)
library(imager)
library(ggplot2)
library(knitr)

# Wait
Sys.sleep(90)

# BLOB STORAGE ----------------------------------------------------------------

# Blob files
blob_endpoint_key <- storage_endpoint(
  endpoint = Sys.getenv("LONDON_BUS_STORAGE_ENDPOINT"),
  key = Sys.getenv("LONDON_BUS_STORAGE_KEY"))

bus_image_container <- storage_container(
  blob_endpoint_key,
  Sys.getenv("LONDON_BUS_CONTAINER_NAME"))

bus_predict_container <- storage_container(
  blob_endpoint_key,
  Sys.getenv("LONDON_BUS_PREDICT_CONTAINER_NAME"))

bus_annotate_container <- storage_container(
  blob_endpoint_key,
  Sys.getenv("LONDON_BUS_ANNOTATE_CONTAINER_NAME"))

bus_data_container <- storage_container(
  blob_endpoint_key,
  Sys.getenv("LONDON_BUS_DATA_CONTAINER_NAME"))

# Model endpoint
model_endpoint <- Sys.getenv("LONDON_BUS_MODEL_ENDPOINT")
request <- request(model_endpoint) |>
  req_headers(
    "Prediction-Key" = Sys.getenv("LONDON_BUS_MODEL_PREDICTION_KEY"),
    "Content-Type" = "application/json")

# Get latest 3 blobs upload
image_info <- list_blobs(bus_image_container, info = "all") |>
  arrange(desc(`Creation-Time`)) |>
  select(name, `Creation-Time`) |>
  top_n(3)

# Blob urls + token
image_info$url <- paste(paste0(
  "https://londonbusstorage.blob.core.windows.net/", Sys.getenv("LONDON_BUS_CONTAINER_NAME"), "/",
  image_info$name), Sys.getenv("LONDON_BUS_BLOB_SAS_TOKEN"), sep = "?")

# PREDICTION ------------------------------------------------------------------

# Send for prediction
predictions_df <- map_df(1:nrow(image_info), function(i) {
  
  response <- request |>
    req_body_json(list(url = image_info$url[[i]])) |>
    req_perform() |>
    resp_body_json()
  
  predictions <- map_df(response$predictions, function(p) {
    predictions <- tibble(
      probability = p[["probability"]],
      tag = p[["tagName"]],
      bb_left = p[["boundingBox"]][["left"]],
      bb_top = p[["boundingBox"]][["top"]],
      bb_width = p[["boundingBox"]][["width"]],
      bb_height = p[["boundingBox"]][["height"]])
    predictions |> filter(probability >= .75)
  })
  
  predictions <- predictions |>
    add_column(image_name = image_info$name[[i]])
})

# Store predictions in blob as csv
storage_write_csv(
  object = predictions_df,
  container = bus_predict_container, 
  file = paste0("predictions_df", "_", as.numeric(Sys.time()), ".csv"))

# DATA SUMMARY UPDATE ---------------------------------------------------------

x <- predictions_df |> 
  mutate(
    camera_id = substr(image_name, 1, 19),
    camera_name = case_when(
      camera_id == "JamCams_00001.02500" ~ "Victoria Embankment",
      camera_id == "JamCams_00001.06503" ~ "Piccadilly",
      camera_id == "JamCams_00001.04502" ~ "Westminster Bridge")) |> 
  group_by(camera_name) |> 
  tally()

download_blob(bus_data_container, src = "prediction_summary_df.csv") 
prediction_summary_df <- readr::read_csv("prediction_summary_df.csv") |> 
  rbind(x) |> 
  group_by(camera_name) |> 
  tally(n)

storage_write_csv(
  object = prediction_summary_df,
  container = bus_data_container, 
  file = "prediction_summary_df.csv")

file.remove("prediction_summary_df.csv")

# IMAGE ANNOTATION ------------------------------------------------------------

if (nrow(predictions_df) == 0) {
  quit(save = "no")
}

# Height / width of image
iw <- 352
ih <- 288

# Add bb coordinates for ggplot
predictions_image_df <- predictions_df |>
  mutate(
    x1 = iw * bb_left,
    x2 = x1 + (iw * bb_width),
    y1 = ih * bb_top,
    y2 = y1 + (ih * bb_height),
    probability = round(probability, 2))

unique_image_names <- unique(predictions_image_df$image_name)

# Annotate images with predictions
for (i in 1:length(unique_image_names)) {
  
  # Download image locally container
  image_url <- paste(paste0(
    "https://londonbusstorage.blob.core.windows.net/bus-image-container/", 
    unique_image_names[i]), Sys.getenv("LONDON_BUS_BLOB_SAS_TOKEN"), sep = "?")
  image_file <- paste0(unique_image_names[i], ".jpg")
  download.file(image_url, image_file)
  
  # Load image + mutate
  image <- imager::load.image(image_file)
  image_df <- as.data.frame(image, wide = "c") |> 
    mutate(rgb.val = rgb(c.1, c.2, c.3))
  
  # Filtere predictions df for relevant image
  predictions_image_df_filtered <- predictions_image_df |> 
    filter(image_name == unique_image_names[i])
  
  # Plot image and draw bb
  p <- ggplot() +
    geom_raster(image_df, mapping = aes(x, y, fill = rgb.val)) +
    scale_fill_identity() +
    scale_y_reverse() +
    geom_rect(
      data = predictions_image_df_filtered,
      mapping = aes(
        xmin = x1, 
        xmax = x2,
        ymin = y1,
        ymax = y2, 
        fill = NA),
        color = "yellow",
        linewidth = 0.1) +
    annotate(
      "text",
      x = predictions_image_df_filtered$x1 + (predictions_image_df_filtered$x2 - predictions_image_df_filtered$x1) / 2,
      y = predictions_image_df_filtered$y1 - 5,
      label = predictions_image_df_filtered$probability,
      size = 0.8,
      color = "yellow") +
    theme_void()
  
  # Save image
  ggsave(
    filename = image_file,
    plot = p,
    width = 384,
    height = 296,
    units = "px")
  # Remove white trim
  knitr::plot_crop(image_file)
  
  # Upload annotated image to container
  upload_blob(
    container = bus_annotate_container,
    src = image_file,
    dest = paste0(unique_image_names[i], "_annotated")
  )
  
  # Remove file
  file.remove(image_file)
}

# ANNOTATION DATA SUMMARY -----------------------------------------------------

annotation_info <- list_blobs(bus_annotate_container, info = "all") |>
  arrange(desc(`Creation-Time`)) |>
  select(name, `Creation-Time`) |>
  top_n(9)

# Blob urls + token
annotation_info$url <- paste(paste0(
  "https://londonbusstorage.blob.core.windows.net/", Sys.getenv("LONDON_BUS_ANNOTATE_CONTAINER_NAME"), "/",
  annotation_info$name), Sys.getenv("LONDON_BUS_ANNOTATE_BLOB_SAS_TOKEN"), sep = "?")

storage_write_csv(
  object = annotation_info,
  container = bus_data_container, 
  file = "annotate_summary_df.csv")

# Old code where tried to connect to SQL Server ------------------------------

# # Connect to SQL server
# con <- dbConnect(
#   odbc::odbc(),
#   driver = "ODBC Driver 18 for SQL Server",
#   server = Sys.getenv("LONDON_BUS_SQL_SERVER"),
#   database = Sys.getenv("LONDON_BUS_SQL_DATABASE"),
#   uid = Sys.getenv("LONDON_BUS_SQL_USER"),
#   pwd = Sys.getenv("LONDON_BUS_SQL_PASS"),
#   port = 1433)
# 
# # Update with predictions
# dbWriteTable(
#   conn = con,
#   name = "bus_predictions",
#   value = predictions_df,
#   append = TRUE)

# dbCreateTable(
#   conn = con,
#   name = "bus_predictions",
#   fields = predictions)


