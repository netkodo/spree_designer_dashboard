$ ->
  $("#signature-client").bind 'change', () ->
    $("#signature_client_code").val( $("#signature-client").jSignature("getData","default") )
    console.log 'chaged'

  $("#signature-designer").bind 'change', () ->
    $("#signature_designer_code").val( $("#signature-designer").jSignature("getData","default") )
    console.log 'chaged'

  $("#signature-client").jSignature({width:340,height: 150});
  $("#signature-designer").jSignature({width:340,height: 150});

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
      $("form[id*='-contract'] .btn").addClass('disabled')
    success: (response) ->
      window.location.href = response.location
    error: (response) ->
      $("form[id*='-contract'] .btn").removeClass('disabled')
      console.log response.message

  $('#js-sign-contract').ajaxForm
    dataType: 'json'
    method: 'post'
    beforeSend: () ->
      $("form[id*='-contract'] .btn").addClass('disabled')
    success: (response) ->
      window.location.href = response.location
    error: (response) ->
      $("form[id*='-contract'] .btn").removeClass('disabled')
      console.log response.message

  $('#js-update-contract').ajaxForm
    dataType: 'json'
    method: 'post'
    beforeSend: () ->
      $("form[id*='-contract'] .btn").addClass('disabled')
    success: (response) ->
      window.location.href = response.location
    error: (response) ->
      $("form[id*='-contract'] .btn").removeClass('disabled')
      console.log response.message