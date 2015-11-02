QR.oekaki =
  init: ->
    return unless Conf['Quick Reply'] and Conf['Oekaki Links']
    Post.callbacks.push
      name: 'Oekaki Links'
      cb:   @node

  node: ->
    return unless @file and (@file.isImage or @file.isVideo)
    if @isClone
      link = $ '.file-oekaki', @file.text
    else
      link = $.el 'a',
        className: 'file-oekaki'
        href: 'javascript:;'
        title: 'Edit in Tegaki'
      $.extend link, <%= html('<i class="fa fa-edit"></i>') %>
      $.add @file.text, [$.tn('\u00A0'), link]
    $.on link, 'click', QR.oekaki.editFile

  editFile: ->
    return unless QR.postingIsEnabled
    QR.quote.call @
    post = Get.postFromNode @
    {isVideo} = post.file
    currentTime = post.file.fullImage?.currentTime or 0
    CrossOrigin.file post.file.url, (blob) ->
      if !blob
        QR.error "Can't load file."
      else if isVideo
        video = $.el 'video'
        $.on video, 'loadedmetadata', ->
          $.on video, 'seeked', ->
            canvas = $.el 'canvas',
              width: video.videoWidth
              height: video.videoHeight
            canvas.getContext('2d').drawImage(video, 0, 0)
            canvas.toBlob (snapshot) ->
              snapshot.name = post.file.name.replace(/\.\w+$/, '') + '.png'
              QR.handleFiles [snapshot]
              QR.oekaki.edit()
          video.currentTime = currentTime
        video.src = URL.createObjectURL blob
      else
        blob.name = post.file.name
        QR.handleFiles [blob]
        QR.oekaki.edit()

  setup: ->
    $.global ->
      {FCX} = window
      FCX.oekakiCB = ->
        window.Tegaki.flatten().toBlob (file) ->
          source = "oekaki-#{Date.now()}"
          FCX.oekakiLatest = source
          document.dispatchEvent new CustomEvent 'QRSetFile',
            bubbles: true
            detail: {file, name: FCX.oekakiName, source}
      if window.Tegaki
        document.querySelector('#qr .oekaki').hidden = false

  load: (cb) ->
    if $ 'script[src^="//s.4cdn.org/js/painter"]', d.head
      cb()
    else
      style = $.el 'link',
        rel: 'stylesheet'
        href: "//s.4cdn.org/css/painter.#{Date.now()}.css"
      script = $.el 'script',
        src: "//s.4cdn.org/js/painter.min.#{Date.now()}.js"
      n = 0
      onload = ->
        cb() if ++n is 2
      $.on style,  'load', onload
      $.on script, 'load', onload
      $.add d.head, [style, script]

  draw: ->
    $.global ->
      {Tegaki, FCX} = window
      Tegaki.destroy() if Tegaki.bg
      FCX.oekakiName = 'tegaki.png'
      Tegaki.open
        onDone: FCX.oekakiCB
        onCancel: ->
        width:  +document.querySelector('#qr [name=oekaki-width]').value
        height: +document.querySelector('#qr [name=oekaki-height]').value
        bgColor: '#ffffff'

  button: ->
    if QR.selected.file
      QR.oekaki.edit()
    else
      QR.oekaki.toggle()

  edit: ->
    QR.oekaki.load -> $.global ->
      {Tegaki, FCX} = window
      name     = document.getElementById('qr-filename').value.replace(/\.\w+$/, '') + '.png'
      {source} = document.getElementById('file-n-submit').dataset
      error = (content) ->
        document.dispatchEvent new CustomEvent 'CreateNotification',
          bubbles: true
          detail: {type: 'warning', content, lifetime: 20}
      cb = (e) ->
        document.removeEventListener 'QRFile', cb, false
        return error 'No file to edit.' unless e.detail
        return error 'Not an image.'    unless /^(image|video)\//.test e.detail.type
        isVideo = /^video\//.test e.detail.type
        file = document.createElement(if isVideo then 'video' else 'img')
        file.addEventListener 'error', -> error 'Could not open file.', false
        file.addEventListener (if isVideo then 'loadeddata' else 'load'), ->
          Tegaki.destroy() if Tegaki.bg
          FCX.oekakiName = name
          Tegaki.open
            onDone: FCX.oekakiCB
            onCancel: -> Tegaki.bgColor = '#ffffff'
            width:  file.naturalWidth  or file.videoWidth
            height: file.naturalHeight or file.videoHeight
            bgColor: 'transparent'
          Tegaki.activeCtx.drawImage file, 0, 0
        , false
        file.src = URL.createObjectURL e.detail
      if Tegaki.bg and Tegaki.onDoneCb is FCX.oekakiCB and source is FCX.oekakiLatest
        FCX.oekakiName = name
        Tegaki.resume()
      else
        document.addEventListener 'QRFile', cb, false
        document.dispatchEvent new CustomEvent 'QRGetFile', {bubbles: true}

  toggle: ->
    QR.oekaki.load ->
      QR.nodes.oekaki.hidden = !QR.nodes.oekaki.hidden
