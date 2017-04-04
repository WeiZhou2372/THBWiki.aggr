library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Aggregate search result in THBWiki"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      textInput("lookname", "Search", value = "logical emotion", placeholder = "社团名称"),
      actionButton("go", "Show me"),
      hr(),
      checkboxGroupInput("options", label = "Options", 
                         choices = list("Inspect list before parsing" = 1, 
                                        "Use proxy" = 2),
                         selected = 1),
      h4("Proxy"),
      textInput("IP", "IP", value = "125.88.74.122"),
      textInput("port", "port", value = "85"),
      hr(),
      verbatimTextOutput("test")
    ),
    
    mainPanel(
      splitLayout(
        uiOutput("ui1"),
        uiOutput("ui2")
      )
    )
  )
))
