SW.jschan =
  isOPContainerThread: true
  mayLackJSON: false
  threadModTimeIgnoresSage: true
  
  disabledFeatures: [
    'Resurrect Quotes'
    'Quick Reply Personas'
    'Quick Reply'
    'Cooldown'
    'Report Link'
    'Delete Link'
    'Edit Link'
    'Quote Inlining'
    'Quote Previewing'
    'Quote Backlinks'
    'Comment Expansion'
    'Thread Expansion'
    'Quote Threading'
    'Banner'
    'Flash Features'
    'Reply Pruning'
  ]

  detect: ->
    for small in $$ 'small'
      if /<small\b[^>]*>.*<div\b[^>]*>.*<a\b[^>]*href=["'][^"']*["'][^>]*>.*<\/a>.*<\/div>.*<\/small>/i.test(small.outerHTML)
      # If the structure is found, extract the content of the <a> tag
     aTagMatch = small.textContent.match(/<a\b[^>]*href=["'][^"']*["'][^>]*>([^<]*)<\/a>/i)
      if aTagMatch
        properties = $.dict()
        properties.root = aTagMatch[1]
        return properties
  false

  urls:
    thread: ({siteID, boardID, threadID}) ->
      "https://#{siteID}/#{boardID}/thread/#{threadID}.html"
    post: ({postID})                   -> "##{postID}"
    index: ({siteID, boardID})         -> "https://#{siteID}/#{boardID}/index.html"
    indexJSON: ({siteID, boardID})     -> "https://#{siteID}/#{boardID}/index.json"
    catalog: ({siteID, boardID})       -> "https://#{siteID}/#{boardID}/catalog.html"
    catalogJSON: ({siteID, boardID})   -> "https://#{siteID}/#{boardID}/catalog.json"
    file: ({siteID}, filename)         -> "https://#{siteID}/file/#{filename}"
    thumb: ({siteID}, filename)         -> "https://#{siteID}/file/thumb/#{filename}"