
fluidPage(column(width = 3,
                 
                 wellPanel(
                   
                   h4("Test Parameters:") %>% helper(type = "markdown",
                                                     title = "Poisson GLM regression helper",
                                                     content = "poisson",
                                                     icon = "question",
                                                     colour = "green"),
                   
                   textInput("h1_1", "Alternative hypothesis:", value = "Treatment"),
                 
                   selectInput("adjustment_method_poisson", "pvalue Adustment Method:",
                               choices = c("holm", "hochberg", "hommel", "bonferroni", "BH", "BY", "fdr", "none"), selected = "BH"),
                   numericInput("sc_cutoff_poisson", "Spectral counts cut-off", value = 4),
                   helpText("Note that this filter will only be applied to the second column."),
                   
                   br(),
                   
                   h4("Graphical Parameters:"),
                   
                   checkboxInput("show_counts1", "Show counts mean", FALSE),
                   
                   selectInput("pval1", "pvalue type", choices = c("raw", "adjusted"), selected = "raw"),
                   numericInput("pval_cutoff1", "pvalue cutoff (volcano plot and heatmap)", value = 0.05),
                   numericInput("log2FC1", "log2 Fold Change cutoff", value = 1.5),
                   numericInput("xlim1", "x-label limit", value = 5),
                   
                   checkboxInput("prot_names1", "Heatmap rownames", FALSE)
                 
                 )
                 
                 ),
          
          column(width = 9,
                 
                 tabsetPanel(
                   
                   tabPanel("Results", DT::dataTableOutput("poissonResults")),
                   
                   tabPanel("Volcano Plot", plotlyOutput("volcano1")),
                   
                   tabPanel("Annotated Volcano Plot", plotOutput("annotated_volcano1")),
                   
                   tabPanel("Normalized and Batch Corrected Heatmap", 
                            downloadButton("expanded_heatmap_poisson", "Download Expanded Heatmap"),
                            
                            br(),
                            br(),
                            
                            plotOutput("heatmap_poisson", height = "600px"))
                 )
                 
                 ))

