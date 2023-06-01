#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
library(caret) 
library(shiny)
library(data.table)
library(reticulate)
library(pROC)
library(jpeg)
library(waiter)
library(shinyvalidate)
python_file <- file.path("C:","Users","cs210","anaconda3","python.exe")
script_file <- file.path('script','train_val_test.py')
use_python(python_file)
source_python(script_file)

# Define UI for application that draws a histogram
ui <- fluidPage(
  waiter::use_waiter(),
  waiterOnBusy(),
  # Application title
  titlePanel("PairNet PRS superlearner"),
  
  
  sidebarLayout(
    sidebarPanel(
      textInput('name','email'),
      fileInput("Z_file","select file", accept = c(".csv", ".txt")),
      actionButton('action',label = "submit")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("readme",tags$div(
          tags$p("Hello,"),
          tags$p("Welcome to the Pairnet super learner demo page. To make our presentation complete, please provide a Z matrix that includes ID, trait, and various PRS. We will normalize the matrix and divide it into three sets: training, validation, and testing, with a ratio of 8:1:1. If you do not have a Z matrix, we will provide demo data."),
          tags$p("We will demonstrate the AUC data of the Pairnet super learner. Thank you very much for your participation, and we hope you will gain valuable insights from this presentation!"),
        ),plotOutput("plot2"),#tags$iframe(style = "width:100%; height:600px;", src = "data_format.pdf"),
        ),
        tabPanel("demo",downloadButton("downloadData","Download"),
                 tags$div(
                   style = "width:100%;height:100%; overflow-y: scroll;",
                   dataTableOutput("Z")
                 )
                 # conditionalPanel(condition = "output.Z!= null",
                 #                    dataTableOutput("Z")
                 #                  ),
                 # conditionalPanel(condition = "output.Z== null",
                 #                  textOutput('data'))
        ),
        tabPanel("AUC",  plotOutput("plot1"))
      )
    )
  )

)

# Define server logic required to draw a histogram
server <- function(input, output) {
  iv <- InputValidator$new()
  iv$add_rule("name", sv_required())
  iv$add_rule("name", sv_email())
  iv$add_rule("Z_file", sv_required())
  iv$add_rule("Z_file", function(value) {
    if (!grepl("\\.(csv|txt)$", value$name)) {
      "Only CSV or text files can be uploaded."
    }})
  iv$add_rule("Z_file", function(value) {
    if (file.size(value$datapath) > 5 * 1024 * 1024) {
      "The file size cannot exceed 5MB."
    }})
  iv$add_rule("Z_file", function(value) {
    Z <- fread(value$datapath) |> as.data.frame()
    if (length(unique(Z[,1])) == nrow(Z)) {
      return(NULL)
    }else{
      #return(paste0(unique(Z[,1])))
      return("ID must not be duplicated.")
    }})
  iv$add_rule("Z_file", function(value) {
    Z <- fread(value$datapath) |> as.data.frame()
    if (all(Z[,2] %in% 1:2)) {
      return(NULL)
    }else{
      return("Please use 1 and 2 to represent the trait.")
    }})
  
  # iv$enable()
  demo_Z <- fread(file.path('demo','demo_1.txt'))
  output$Z <- renderDataTable({
    
    demo_Z
  })
  
  output$downloadData <- downloadHandler(
    filename = file.path('demo','demo_1.txt'),
    content = function(file) {
      # Write the dataset to the `file` that will be downloaded
      write.csv(demo_Z, file)
    }
  )
  output$plot2 <- renderImage({


    list(src = file.path('demo','data_format.png'), width = "100%")
  }, deleteFile = FALSE)
  # output$plot2 <- renderUI({
  #   
  #   tags$iframe(style = "width:100%; height:100%;", src = "demo/data_format.pdf")
  # 
  # })
  
  
  observeEvent(input$action,{
    
    if(is.null(input$Z_file)){
      roc_file <- file.path('demo','fig','demo_1_roc.jpeg')
    }else{
      iv$enable()
      req(input$name)
      
      # validate( 
      #   need(!is.null(input$name), "Please provide an email."),
      #   need(grepl("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$",input$name), "The input string is not an email.")
      # )
      
      name <- strsplit(input$name,"@")[[1]][1]
      Z_file <- file.path('temp',name,'data',paste0(name,'_Z.txt'))
      sample_file <- file.path('temp',name,'data',paste0(name,'_sample.txt'))
      train_file <- file.path('temp',name,'data',paste0(name,'_train_sample.txt'))
      test_file <- file.path('temp',name,'data',paste0(name,'_test_sample.txt'))
      val_file <- file.path('temp',name,'data',paste0(name,'_val_sample.txt'))
      out_file <- file.path('temp',name,'fig',name)
      roc_file <- file.path('temp',name,'fig',paste0(name,'_roc.jpeg'))
      model_file <- file.path('temp',name,'model')
      log_file <- file.path('temp',name,'log','log.txt')
      dir.create(file.path('temp',name,'data'), recursive = TRUE,showWarnings = FALSE)
      dir.create(file.path('temp',name,'fig'), recursive = TRUE,showWarnings = FALSE)
      dir.create(file.path('temp',name,'model'), recursive = TRUE,showWarnings = FALSE)
      dir.create(file.path('temp',name,'log'), recursive = TRUE,showWarnings = FALSE)
      write.table(input$name,file.path('temp',name,'email.txt'))



      # validate( 
      #   need(grepl("\\.(csv|txt)$", input$Z_file$name), "Only CSV or text files can be uploaded."),
      #   need(file.size(input$Z_file$datapath) < 5 * 1024 * 1024, "The file size cannot exceed 5MB.")
      # )
      Z <- fread(input$Z_file$datapath)
      # validate( 
      #   need(length(unique(Z[,1])) == nrow(Z), "ID must not be duplicated."),
      #   need(all(Z[,2] %in% 1:2), "Please use 1 and 2 to represent the trait.")
      # )
      colnames(Z) <- c('FID','PHENO',paste0('PRS',1:(ncol(Z)-2)))
      Z[,3:ncol(Z)] <- apply(Z[,3:ncol(Z)],2,function(x){
        (x-min(x))/(max(x)-min(x))
      }) |> as.data.frame() 
      fwrite(Z,Z_file,
             quote = TRUE, sep = ",",
             logical01 = TRUE,
             na = "NA")
      fwrite(Z[,.(FID,PHENO)],sample_file,
             quote = TRUE, sep = ",",
             logical01 = TRUE,
             na = "NA")
      set.seed(1)
      seed = 1L
      
      # w <- waiter::Waiter$new(id = "plot1",html = spin_wave())
      # w$show()
      
      train_id <- createDataPartition(Z[,PHENO],p = 0.8, 
                                      list = FALSE, 
                                      times = 1)
      
      fwrite(Z[train_id,.(FID,PHENO)],train_file, quote = F, sep = " ", row.names = F, col.names = T)
      
      phenos_test = Z[-train_id,]			
      
      test_id <- createDataPartition(phenos_test[,PHENO],p = 0.5, 
                                     list = FALSE, 
                                     times = 1)
      fwrite(phenos_test[test_id,.(FID,PHENO)],test_file, quote = F, sep = " ", row.names = F, col.names = T)
      fwrite(phenos_test[-test_id,.(FID,PHENO)],val_file, quote = F, sep = " ", row.names = F, col.names = T)
      
      train(genotype_file = Z_file,
            sample_file = sample_file,
            train_id_file = train_file,
            OUT_DIR = out_file,
            SEED = seed)
      
      # w$hide()
      
      # waiter::waiter_hide(id = "plot1")

    }
    output$plot1 <- renderImage({
      list(src = roc_file, width = "100%")
    }, deleteFile = FALSE)
  })

}

# Run the application 
shinyApp(ui = ui, server = server)
