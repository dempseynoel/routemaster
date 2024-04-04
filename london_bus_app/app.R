# Library
library(shiny)
library(AzureStor)
library(scales)

readRenviron(".Renviron")

# Specify the application port
options(shiny.host = "0.0.0.0")
options(shiny.port = 3838)

# Blob files ------------------------------------------------------------------

blob_endpoint_key <- storage_endpoint(
  endpoint = Sys.getenv("LONDON_BUS_STORAGE_ENDPOINT"),
  key = Sys.getenv("LONDON_BUS_STORAGE_KEY"))

bus_annotate_container <- storage_container(
  blob_endpoint_key,
  Sys.getenv("LONDON_BUS_ANNOTATE_CONTAINER_NAME"))

bus_data_container <- storage_container(
  blob_endpoint_key,
  Sys.getenv("LONDON_BUS_DATA_CONTAINER_NAME"))

# UI --------------------------------------------------------------------------

ui <- htmlTemplate(
  
  # Index
  "www/index.html",
  
  # Custom values that appear in index.html
  bus_predictions = textOutput("bus_predictions"),
  piccadilly = textOutput("piccadilly"),
  victoria = textOutput("victoria"),
  westminster = textOutput("westminster"),
  
  time = textOutput("time", inline = T),
  
  image_1 = uiOutput("image_1"),
  image_2 = uiOutput("image_2"),
  image_3 = uiOutput("image_3"),
  image_4 = uiOutput("image_4"),
  image_5 = uiOutput("image_5"),
  image_6 = uiOutput("image_6"),
  image_7 = uiOutput("image_7"),
  image_8 = uiOutput("image_8"),
  image_9 = uiOutput("image_9")
  
)

# Server ----------------------------------------------------------------------

server <- function(input, output, session) {

  prediction_summary_df <- reactive({
    # Update every 15 minutes
    invalidateLater(900000)
    read.csv(paste0(
      Sys.getenv("LONDON_BUS_STORAGE_ENDPOINT"), "/",
      Sys.getenv("LONDON_BUS_DATA_CONTAINER_NAME"), "/",
      Sys.getenv("LONDON_BUS_DATA_FILE"),
      Sys.getenv("LONDON_BUS_DATA_SAS_TOKEN")))
  })
  
  observe({
    prediction_summary_df()
    output$bus_predictions <- renderText({comma(sum(prediction_summary_df()$n))})
  })
  
  observe({
    prediction_summary_df()
    output$piccadilly <- renderText({comma(prediction_summary_df()[1,2])})
  })
  
  observe({
    prediction_summary_df()
    output$victoria <- renderText({comma(prediction_summary_df()[2,2])})
  })
  
  observe({
    prediction_summary_df()
    output$westminster <- renderText({comma(prediction_summary_df()[3,2])})
  })
  
  annotate_summary_df <- reactive({
    # Update every 15 minutes
    invalidateLater(900000)
      read.csv(paste0(
      Sys.getenv("LONDON_BUS_STORAGE_ENDPOINT"), "/",
      Sys.getenv("LONDON_BUS_DATA_CONTAINER_NAME"), "/",
      Sys.getenv("LONDON_BUS_ANNOTATE_FILE"),
      Sys.getenv("LONDON_BUS_DATA_SAS_TOKEN")))
    })
  
  observe({
    annotate_summary_df()
    output$time <- renderText({
      annotate_summary_df()[1, 2]
    })
  })
  
  observe({
    annotate_summary_df()
    output$image_1 <- renderUI({
      imgurl <- annotate_summary_df()[1,3]
      tags$img(
        class = "img-fluid d-block",
        src = imgurl)
    })
  })
  
  observe({
    annotate_summary_df()
    output$image_2 <- renderUI({
      imgurl <- annotate_summary_df()[2,3]
      tags$img(
        class = "img-fluid d-block",
        src = imgurl)
    })
  })
  
  observe({
    annotate_summary_df()
    output$image_3 <- renderUI({
      imgurl <- annotate_summary_df()[3,3]
      tags$img(
        class = "img-fluid d-block",
        src = imgurl)
    })
  })
  
  observe({
    annotate_summary_df()
    output$image_4 <- renderUI({
      imgurl <- annotate_summary_df()[4,3]
      tags$img(
        class = "img-fluid d-block",
        src = imgurl)
    })
  })
  
  observe({
    annotate_summary_df()
    output$image_5 <- renderUI({
      imgurl <- annotate_summary_df()[5,3]
      tags$img(
        class = "img-fluid d-block",
        src = imgurl)
    })
  })
  
  observe({
    annotate_summary_df()
    output$image_6 <- renderUI({
      imgurl <- annotate_summary_df()[6,3]
      tags$img(
        class = "img-fluid d-block",
        src = imgurl)
    })
  })
  
  observe({
    annotate_summary_df()
    output$image_7 <- renderUI({
      imgurl <- annotate_summary_df()[7,3]
      tags$img(
        class = "img-fluid d-block",
        src = imgurl)
    })
  })
  
  observe({
    annotate_summary_df()
    output$image_8 <- renderUI({
      imgurl <- annotate_summary_df()[8,3]
      tags$img(
        class = "img-fluid d-block",
        src = imgurl)
    })
  })
  
  observe({
    annotate_summary_df()
    output$image_9 <- renderUI({
      imgurl <- annotate_summary_df()[9,3]
      tags$img(
        class = "img-fluid d-block",
        src = imgurl)
    })
  })
}

# Run -------------------------------------------------------------------------

shinyApp(ui = ui, server = server)