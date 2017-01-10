$ ->
  $("#signature-client").bind 'change', () ->
    $("#signature_client_code").val( $("#signature-client").jSignature("getData","default") )
    console.log 'chaged'

  $("#signature-designer").bind 'change', () ->
    $("#signature_designer_code").val( $("#signature-designer").jSignature("getData","default") )
    console.log 'chaged'

  $("#signature-client").jSignature();
  $("#signature-designer").jSignature();

  $(document).on
    click: (e) ->
      $("#signature-client").jSignature("clear");
  ,'.signature-client-clear'

  $(document).on
    click: (e) ->
      $("#signature-designer").jSignature("clear");
  ,'.signature-designer-clear'

  $('#js-create-contract').ajaxForm
    dataType: 'json'
    method: 'post'
    beforeSend: () ->
      console.log 'b4send'
    success: (response) ->
      console.log 'success'
      console.log response
      window.location.href = response.location
    error: (response) ->
      console.log 'error'
      console.log response

  $('#js-sign-contract').ajaxForm
    dataType: 'json'
    method: 'post'
    beforeSend: () ->
      console.log 'b4send'
    success: (response) ->
      console.log 'success'
      console.log response
      window.location.href = response.location
    error: (response) ->
      console.log 'error'
      console.log response

  $('#js-update-contract').ajaxForm
    dataType: 'json'
    method: 'post'
    beforeSend: () ->
      console.log 'b4send'
    success: (response) ->
      console.log 'success'
      console.log response
      window.location.href = response.location
    error: (response) ->
      console.log 'error'
      console.log response