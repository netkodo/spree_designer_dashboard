$ ->
  clearHidden = () ->
    $('.table-board-listing tbody tr').each ->
      $(@).removeClass('hidden')

  getRoomsDependsOnType = (type) ->
    clearHidden()
    if type == true
      $('.table-board-listing tbody .false').each ->
        $(@).addClass('hidden')
    else
      $('.table-board-listing tbody .true').each ->
        $(@).addClass('hidden')

  $(document).on
    click: (e)->
      e.preventDefault()
      getRoomsDependsOnType($(@).data('private'))
  ,'.js-get-room-type'

  $(document).on
    click: (e)->
      e.preventDefault()
      my_this = $(@)
      $.ajax
        dataType: 'html'
        method: 'POST'
        url: '/private_invoice'
        data: {id: $(@).data('id')}
        success: (response)->
          my_this.parents('tr').after("<tr><td class='no-border' colspan='6'>#{response}</td></tr>")
        error: (response) ->
          my_this.parents('tr').after("<tr class='notification-to-remove'><td class='no-border text-center' colspan='6'>Board is empty</td></tr>")
          setTimeout () ->
            $('.notification-to-remove').remove()
          ,'3000'
  ,'.js-private-invoice'