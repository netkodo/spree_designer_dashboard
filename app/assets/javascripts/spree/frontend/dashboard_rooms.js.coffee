$ ->
  addToHistory = (user_id,board_id,action) ->
    $.ajax
      dataType: 'json'
      method: 'POST'
      url: '/create_board_history'
      data: { board_history: {action: action, board_id: board_id, user_id: user_id} }
      success: (response) ->

      error: (response) ->


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

  changeTableView = (type) ->
    if type == true
      $(".table.table-board-listing thead").html("<th class='status'>&nbsp;</th><th colspan='2'>Rooms</th>")
      $(".table.table-board-listing colgroup").html(
        "   <col style='width: 5%' />
            <col style='width: 20%' />
            <col style='width: 75%' />"
      )
      $(".designer_commission_style").addClass('hidden')
    else
      $(".table.table-board-listing thead").html(
        "     <th class='status'>&nbsp;</th>
              <th colspan='2'>Rooms</th>
              <th class='align-center'># Products</th>
              <th class='align-center'># Views</th>
              <th class='align-center'>Revenue</th>"
      )
      $(".table.table-board-listing colgroup").html(
        "   <col style='width: 5%' />
            <col style='width: 20%' />
            <col style='width: 40%' />
            <col style='width: 12%' />
            <col style='width: 10%' />
            <col style='width: 10%' />"
      )
      $(".designer_commission_style").removeClass('hidden')

  generateInvoiceHash = (invoice) ->
    hash = {}
    $(".table-invoice.#{invoice} tbody tr[changed=true]").each ->
      id = $(@).data('id')
      hash[id]={}
      hash[id]["custom"]=$(@).data('custom')
      $('td[changed=true]',@).each ->
        $.each($(@).data(),(k,v) ->
          hash[id][k]=v
        )
    hash

  $(document).on
    click: (e)->
      e.preventDefault()
      getRoomsDependsOnType($(@).data('private'))
      changeTableView($(@).data('private'))
  ,'.js-get-room-type'

  $(document).on
    click: (e)->
      e.preventDefault()
      $(".table.table-board-listing tbody tr.true").not(".board#{$( $(".table-invoice") , $(@).parents('tr.invoice')).data('board_id')}").removeClass('hidden')
      $(@).parents('tr.invoice').remove()
  ,'.close-invoice'

  $(document).on
    click: (e)->
      e.preventDefault()
      switch $(@).parent().attr('class')
        when 'edit-name'
          val = $(@).parent().data('name')
        when 'edit-sku'
          val = $(@).parent().data('sku')
        when 'edit-cost'
          val = $(@).parent().data('cost')
      $(@).parent().html("<input type='text' class='form-control' value=\"#{val}\"><i class='fa fa-check save-edit'></i> <i class='fa fa-times cancel-edit'></i>")
  ,'.edit-name .edit, .edit-sku .edit, .edit-cost .edit'

  $(document).on
    click: (e)->
      e.preventDefault()
      val = $(@).parent().find('input').val()
      switch $(@).parent().attr('class')
        when 'edit-name'
          if val != $(@).parent().data('name')
            $(@).parents('tr').attr('changed',true)
            $(@).parents('td').attr('changed',true)
            $(@).parent().data('name',val)
        when 'edit-sku'
          if val != $(@).parent().data('sku')
            $(@).parents('tr').attr('changed',true)
            $(@).parents('td').attr('changed',true)
            $(@).parent().data('sku',val)
        when 'edit-cost'
          if val != $(@).parent().data('cost')
            $(@).parents('tr').attr('changed',true)
            $(@).parents('td').attr('changed',true)
            $(@).parent().data('cost',val)
      $(@).parent().html("#{val} <span class='edit'>edit</span>")
  ,'.save-edit'

  $(document).on
    click: (e) ->
      invoice = generateInvoiceHash($(@).data('board_id'))
      console.log invoice
      obj = $(@).parents('tr.invoice')
      $.ajax
        dataType: 'json'
        method: 'POST'
        url: '/save_invoice'
        data: {invoice, board_id: $(@).data('board_id'), user_id: $(@).data('user_id') }
#        ,board_id: $(@).data('board_id')
        beforeSend: ()->
          $(@).html('Saving..')
        success: (response) ->
          $(".table.table-board-listing tbody tr.true").not(".board#{$(@).data('board_id')}").removeClass('hidden')
          obj.html("<td class='no-border' colspan='6'><div class='text-center'><i class='fa fa-check save-edit'></i> Saved</div></td>")
          setTimeout () ->
            obj.remove()
          ,'3000'
          console.log response
        error: (response) ->
          $(@).html('Save')
          console.log 'error'
          console.log response
  ,'.save-invoice'

  $(document).on
    click: (e)->
      e.preventDefault()
      val = $(@).parent().data('cost') || $(@).parent().data('name') || $(@).parent().data('sku')
      $(@).parent().html("#{val} <span class='edit'>edit</span>")
  ,'.cancel-edit'

  $(document).on
    click: (e)->
      e.preventDefault()
      my_this = $(@)
      $.ajax
        dataType: 'html'
        method: 'POST'
        url: '/private_invoice'
        data: {id: $(@).parents('.board-actions').data('board_id')}
        success: (response)->
          $(".table.table-board-listing tbody tr.true").not(".board#{$(my_this).parents('.board-actions').data('board_id')}").addClass('hidden')
          my_this.parents('tr').after("<tr class='invoice'><td class='no-border' colspan='6'>#{response}</td></tr>")
        error: (response) ->
          my_this.parents('tr').after("<tr class='notification-to-remove'><td class='no-border text-center' colspan='6'>Board is empty</td></tr>")
          setTimeout () ->
            $('.notification-to-remove').remove()
          ,'3000'
  ,'.js-private-invoice'


  $(document).on
    click: (e) ->
      my_this = $(@)
      e.preventDefault()
      $.ajax
        dataType: 'json'
        method: 'POST'
        url: '/send_invoice_email'
        data: {id: $(@).parents('.board-actions').data('board_id')}
        success: (response) ->
          my_this.parent().append("<div class='notification-to-remove'><i class='fa fa-check success'></i> Email sent</div>")
          setTimeout () ->
            $( $('.notification-to-remove'), my_this.parent() ).remove()
          ,'2000'
        error: (response) ->
          console.log 'error'
          console.log response
  ,'.js-private-email'

  $(document).on
    click: (e) ->
      my_this = $(@)
      e.preventDefault()
      $.ajax
        dataType: 'html'
        method: 'POST'
        url: '/board_history'
        data: {user_id: $(@).parents('.board-actions').data('user_id'), board_id: $(@).parents('.board-actions').data('board_id')}
        success: (response) ->
          $("#board-history-modal-handler").html(response)
          $("#board-history").modal()
        error: (response) ->
          console.log 'error'
          console.log response
  ,'.js-histroy'