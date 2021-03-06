observe_helpers(help_dir = "help_mds")

BINOMIAL <- reactive({
  
  corrected <- Barplot()$corrected
  target <- pData(corrected)
  
  validate(
    need(length(levels(as.factor(target$Treatment))) == 2, paste0(clisymbols::symbol$cross, " Select two groups in the 'Input Data' panel"))
  )
  
  ### compute means
  
  my_counts <- exprs(corrected) %>% t() %>% as.data.frame() %>% mutate(Treatment = target$Treatment)
  
  means <- data.frame(aggregate(my_counts, by = list(my_counts$Treatment), FUN = mean)) %>% 
    column_to_rownames("Group.1") %>% t() %>% as.data.frame() %>% round(2) %>% filter(rownames(.) != "Treatment")
  
  colnames(means) <- paste0("Mean", colnames(means))
  
  ### Null and alternative model
  null_f <- "y ~ 1"
  alt_f <- paste0("y ~ ", input$h1_3)
  
  ### Normalizing condition
  div <- apply(exprs(corrected), 2, sum)
  
  ### Quasi-likelihood GLM
  binomial_res <- msms.edgeR(corrected, alt_f, null_f, div = div, fnm = "Treatment")
  binomial_res$p.adjust <- p.adjust(binomial_res$p.value, method = input$adjustment_method_binomial)
  
  my_names <- rownames(binomial_res)
  
  binomial_res <- cbind(means, binomial_res) %>% 
    rename(log2FC = LogFC) %>% 
    mutate(log2FC = round(log2FC, 2), 
           log2FC = log2FC*-1,
           LR = round(LR, 3),
           names = my_names,
           GeneName = stringr::str_remove(names, pattern = "^.*GN="),
           GeneName = stringr::str_remove(GeneName, pattern = "(?s) .*"),
           Protein = stringr::str_remove(names, pattern = "^.*;")) %>%
    remove_rownames() %>%
    column_to_rownames("Protein") %>%
    select(GeneName, everything()) %>%
    select(-names) %>%
    filter(.[[2]] > input$sc_cutoff_bin)
  
  return(binomial_res)
  
  })

####

output$binomialResults <- DT::renderDataTable({
  
  DT::datatable(BINOMIAL(),
                filter = 'none',extensions = 'Buttons',
                escape=FALSE,  rownames=TRUE, class = 'cell-border stripe',
                options = list(
                  scrollX = TRUE,
                  dom = 'Bfrtip',
                  buttons = 
                    list("copy", "print", list(
                      extend="collection",
                      buttons=list(list(extend="csv",
                                        filename="POMAcounts_Negative-Binomial"),
                                   list(extend="excel",
                                        filename="POMAcounts_Negative-Binomial"),
                                   list(extend="pdf",
                                        filename="POMAcounts_Negative-Binomial")),
                      text="Dowload")),
                  order=list(list(2, "desc")),
                  pageLength = nrow(BINOMIAL())))
})

output$volcano3 <- renderPlotly({
  
  df <- BINOMIAL()
  
  names <- rownames(df) %>%
    stringr::str_remove(pattern = "^.*;")
  
  df <- df %>% mutate(counts = rowMeans(select(., starts_with("Mean")), na.rm = TRUE))
    
  if(input$pval3 == "raw"){
    
    df <- data.frame(pvalue = df$p.value, FC = round(df$log2FC, 2), names = names, counts = round(df$counts, 2))
    
  }
  
  else {
    
    df <- data.frame(pvalue = df$p.adjust, FC = round(df$log2FC, 2), names = names, counts = round(df$counts, 2))
    
  }
  
  log2FC3 <- 2^(input$log2FC3)
  
  df <- mutate(df, threshold = as.factor(ifelse(df$pvalue >= input$pval_cutoff3,
                                                yes = "none",
                                                no = ifelse(df$FC < log2(log2FC3),
                                                            yes = ifelse(df$FC < -log2(log2FC3),
                                                                         yes = "Down-regulated",
                                                                         no = "none"),
                                                            no = "Up-regulated"))))
  
  ggplotly(ggplot(data = df, aes(x = FC, y = -log10(pvalue), color = threshold, labels = names)) +
             {if(!input$show_counts3)geom_point(size = 1.75, alpha = 0.8)} +
             {if(input$show_counts3)geom_point(aes(size = counts), alpha = 0.8)} +
             xlim(c(-(input$xlim3), input$xlim3)) +
             xlab("log2 Fold Change") +
             ylab("-log10 p-value") +
             scale_y_continuous(trans = "log1p") +
             geom_vline(xintercept = -log2(log2FC3), colour = "black", linetype = "dashed") +
             geom_vline(xintercept = log2(log2FC3), colour = "black", linetype = "dashed") +
             geom_hline(yintercept = -log10(input$pval_cutoff3), colour = "black", linetype = "dashed") +
             theme(legend.position = "none") +
             theme_bw() +
             labs(color = "") +
             scale_color_manual(values = c("Down-regulated" = "#E64B35", "Up-regulated" = "#3182bd", "none" = "#636363")))
  
})

##

output$annotated_volcano3 <- renderPlot({
  
  df <- BINOMIAL()
  
  names <- rownames(df) %>%
    stringr::str_remove(pattern = "^.*;")
  
  df <- df %>% mutate(counts = rowMeans(select(., starts_with("Mean")), na.rm = TRUE))
  
  if(input$pval3 == "raw"){
    
    df <- data.frame(pvalue = df$p.value, FC = round(df$log2FC, 2), names = names, counts = round(df$counts, 2))
    
  }
  
  else {
    
    df <- data.frame(pvalue = df$p.adjust, FC = round(df$log2FC, 2), names = names, counts = round(df$counts, 2))
    
  }
  
  log2FC3 <- 2^(input$log2FC3)
  
  df <- mutate(df, threshold = as.factor(ifelse(df$pvalue >= input$pval_cutoff3,
                                                yes = "none",
                                                no = ifelse(df$FC < log2(log2FC3),
                                                            yes = ifelse(df$FC < -log2(log2FC3),
                                                                         yes = "Down-regulated",
                                                                         no = "none"),
                                                            no = "Up-regulated"))))
  
  ggplot(data = df, aes(x = FC, y = -log10(pvalue), color = threshold, labels = names)) +
    {if(!input$show_counts3)geom_point(size = 1.75, alpha = 0.8)} +
    {if(input$show_counts3)geom_point(aes(size = counts), alpha = 0.8)} +
    xlim(c(-(input$xlim3), input$xlim3)) +
    xlab("log2 Fold Change") +
    ylab("-log10 p-value") +
    scale_y_continuous(trans = "log1p") +
    geom_vline(xintercept = -log2(log2FC3), colour = "black", linetype = "dashed") +
    geom_vline(xintercept = log2(log2FC3), colour = "black", linetype = "dashed") +
    geom_hline(yintercept = -log10(input$pval_cutoff3), colour = "black", linetype = "dashed") +
    theme(legend.position = "none") +
    theme_bw() +
    labs(color = "") +
    ggrepel::geom_label_repel(data = df[df$threshold != "none" ,], aes(label = names), show.legend = F) +
    scale_color_manual(values = c("Down-regulated" = "#E64B35", "Up-regulated" = "#3182bd", "none" = "#636363"))
  
})

##

output$heatmap_binomial <- renderPlot({
  
  corrected <- Barplot()$corrected
  binomial_res <- BINOMIAL()
  binomial_res_names <- rownames(binomial_res[binomial_res$p.adjust < input$pval_cutoff3 ,])
  
  total <- exprs(corrected)
  rownames(total) <- rownames(total) %>%
    stringr::str_remove(pattern = "^.*;")
  
  total <- total[rownames(total) %in% binomial_res_names ,]
  target <- pData(corrected)
  
  ##
  
  ha <- ComplexHeatmap::HeatmapAnnotation(df = data.frame(Group = target[,1]), show_legend = FALSE)
  
  ComplexHeatmap::Heatmap(t(scale(t(total))), name = "Value", top_annotation = ha,
                          show_row_names = input$prot_names3, show_column_names = TRUE, 
                          col = c("green", "black", "red"), show_heatmap_legend = FALSE)

})

##

output$expanded_heatmap_binomial <- downloadHandler(
  
  filename = paste0(Sys.Date(), "_TEST_POMAcounts_Expanded_Heatmap_binomial.pdf"),
  content = function(file) {
    
    corrected <- Barplot()$corrected
    binomial_res <- BINOMIAL()
    binomial_res_names <- rownames(binomial_res[binomial_res$p.adjust < input$pval_cutoff3 ,])
    
    total <- exprs(corrected)
    rownames(total) <- rownames(total) %>%
      stringr::str_remove(pattern = "^.*;")
    total <- total[rownames(total) %in% binomial_res_names ,]
    target <- pData(corrected)
    
    new_corrected <- MSnbase::MSnSet(exprs = as.matrix(total), pData = target)
    
    ####
    
    h <- nrow(exprs(new_corrected))/(2.54/0.35)
    pdf(file = file, width = 7, height = h)
    exp.heatmap(new_corrected, "Treatment", h = h, tit = "") 
    dev.off()
  }
)

