library(shiny)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  require(rvest, stringr, Rcurl)
  
  extraction = function(url, proxy){ #重复的提取图片和保存的工作
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
  
  pullcontent = eventReactive(input$go, {
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
    links
  })
  
  reconstruct = eventReactive(input$analyze, {
    ####使用代理获取详细内容####
    page.grow = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh" lang="zh">\n
<head>\n
    <meta content="text/html;charset=gb2312" http-equiv="Content-Type">\n
    <link type="text/css" href="http://down.thwiki.cc/style/item.css" rel="stylesheet">\n
    </head>\n
    <body>\n
    <div id="holder">\n
    <div id="content">\n'
    
    x = nrow(pullcontent())
    withProgress(message = 'Getting content...', value = 0,{
    for(i in 1:x){
      if (2 %in% input$options) {
        opts = list(
          proxy = input$IP,
          proxyport = as.numeric(input$port)
        )
        link = getURL(pullcontent()$link[i], .opts = opts)
      } else {
        link = getURL(pullcontent()$link[i])
      }
      page.grow = paste(page.grow, extraction(link), '<br />\n')
      incProgress(1/x, detail = pullcontent()$name[i])
    }
    })
    page.grow = paste(page.grow, '\n</div>\n</div>\n</body>\n</html>')
    write(page.grow, file = "test.html")
    page.grow

  })
  output$log = renderPrint({ print(ifelse(reconstruct(), "构建完了", '构建未完成')) })
  output$value <- renderPrint({ pullcontent()$name })
  output$download = downloadHandler(filename = "test.html", content = function(file) {
    src = normalizePath("test.html")
    file.rename(src, file)
  })
})
