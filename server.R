library(shiny)
rm(list = ls())
Sys.setlocale("LC_CTYPE","chinese")
require(rvest, stringr, RCurl)
extraction = function(url){ #重复的提取图片和保存的工作
  library(rvest)
  library(stringr)
  page = read_html(url, encoding = "utf-8")
  
  #获得名字
  nametag = page %>%
    html_nodes("#content h1") #保留网页格式
  
  #获得封面(在线)
  img = page %>%
    html_nodes("#nav a img") %>%
    as.character()
  
  #获得下载地址
  dld = page %>%
    html_nodes("#holder #content p") %>%
    as.character() %>%
    str_subset('a rel') %>%
    paste(collapse = '\n\n')
  
  message(html_text(nametag))
  
  return(paste(as.character(nametag), img, dld, sep="\n\n"))
}

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
  
  foobar = reactiveValues()
  foobar$searched = 0
  foobar$parsed = 0
  output$ui1 = renderUI({wellPanel()})
  output$ui2 = renderUI({wellPanel()})

  observeEvent(input$go, {
    ####初始页面####
    init.link = "http://down.thwiki.cc/"
    
    #### 获取搜索页面####
    pgsession <- html_session(url = init.link)
    pgform <- html_form(read_html(pgsession))[[1]]
    filled_form <- set_values(pgform, t = 'c', k = input$lookname)
    result <- submit_form(pgsession, filled_form)
    page.search = read_html(result)
    
    ####提取页面内的链接####
    links.raw = page.search %>%
      html_nodes("body script:nth-child(3)") %>%
      html_text() %>% 
      str_match_all('<a href="(.*?)" title="(.*?)"')
    
    links = data.frame(name = links.raw[[2]][,3], link = links.raw[[2]][,2])
    output$ui1 = renderUI({
        wellPanel(
          actionButton("analyze", "Reconstruct"),
          verbatimTextOutput("value")
        )
    })
    foobar$searched = foobar$searched + 1
    
    foobar$pullcontent = links
  })
  
  
  
  observeEvent(input$analyze, {
    ####使用代理获取详细内容####
    page.grow = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh" lang="zh">\n
<head>\n
    <meta content="text/html;charset=gb2312" http-equiv="Content-Type">\n
    <link type="text/css" href="http://down.thwiki.cc/style/item.css" rel="stylesheet">\n
    </head>\n
    <body>\n
    <div id="holder">\n
    <div id="content">\n'
    
    x = nrow(foobar$pullcontent)
    withProgress(message = 'Getting content...\n', value = 0,{
    for(i in 1:x){
      if (2 %in% input$options) {
        opts = list(
          proxy = input$IP,
          proxyport = as.numeric(input$port)
        )
        link = getURL(foobar$pullcontent$link[i], .opts = opts)
      } else {
        link = getURL(foobar$pullcontent$link[i])
      }
      page.grow = paste(page.grow, extraction(link), '<br />\n')
      incProgress(1/x, detail = foobar$pullcontent$name[i])
    }
    })
    page.grow = paste(page.grow, '\n</div>\n</div>\n</body>\n</html>')
    write(page.grow, file = "test.html")
    
    output$ui2 = renderUI({
        wellPanel(
          downloadButton('download', 'Download'),
          verbatimTextOutput("Ready")
        )
    })
    
    foobar$parsed = 1
  })
  
  output$value <- renderPrint({
    a = sapply(foobar$pullcontent$name, paste0, "\n")
    cat(as.character(a)) 
  })
  output$download = downloadHandler(filename = "test.html", content = function(file) {
    src = normalizePath("test.html")
    file.rename(src, file)
  })
  
  output$test = renderPrint({
    foobar$pullcontent
  })
})
