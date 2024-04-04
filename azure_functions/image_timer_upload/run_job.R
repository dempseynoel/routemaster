### Upload images to BLOB
library(AzureStor)
library(logger)

# Get secrets about Azure
blob_endpoint_key <- storage_endpoint(
  endpoint = Sys.getenv("LONDON_BUS_STORAGE_ENDPOINT"),
  key = Sys.getenv("LONDON_BUS_STORAGE_KEY"))
bus_image_container <- storage_container(blob_endpoint_key, Sys.getenv("LONDON_BUS_CONTAINER_NAME"))

# Upload image to blob
upload_image_storage <- function(camera_df) {
  
  destination <- paste0(camera_df$camera_id, "_", as.numeric(Sys.time()))
  
  # Upload images storage
  multicopy_url_to_storage(
    container = bus_image_container,
    src = camera_df$camera_image_url,
    dest = destination)
  
  # Attach metadata
  for (i in 1:nrow(camera_df)) {
    df <- camera_df[i,]
    set_storage_metadata(
      bus_image_container,
      destination[i],
      latitude = df$latitude,
      longitude = df$longitude,
      camera_name = df$camera_name)
  }
}

df <- read.csv("jam_cams.csv")
upload_image_storage(df)
log_info("Image uploaded")



