$ ->
  clearHidden = () ->
    $('.table-board-listing tbody tr').each ->
      $(@).removeClass('hidden')

  getRoomsDependsOnType = (type) ->
    clearHidden()
    if type == true
      console.log('private')
      $('.table-board-listing tbody .false').each ->
        $(@).addClass('hidden')
    else
      console.log('public')
      $('.table-board-listing tbody .true').each ->
        $(@).addClass('hidden')

  $(document).on
    click: (e)->
      e.preventDefault()
      getRoomsDependsOnType($(@).data('private'))
  ,'.js-get-room-type'