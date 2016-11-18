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
      $(".table.table-board-listing tbody.dashboard tr.true").not(".board#{$( $(".table-invoice") , $(@).parents('tr.invoice')).data('board_id')}").removeClass('hidden')
      $(".table.table-board-listing tbody.project tr.true.project#{$( $(".table-invoice") , $(@).parents('tr.invoice')).data('project_id')}").not(".board#{$( $(".table-invoice") , $(@).parents('tr.invoice')).data('board_id')}").removeClass('hidden')
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
      my_this = $(@)
      $.ajax
        dataType: 'json'
        method: 'POST'
        url: '/save_invoice'
        data: {invoice, board_id: $(@).data('board_id'), user_id: $(@).data('user_id') }
#        ,board_id: $(@).data('board_id')
        beforeSend: ()->
          $(@).html('Saving..')
        success: (response) ->
          $(".table.table-board-listing tbody.dashboard tr.true").not(".board#{$(my_this).data('board_id')}").removeClass('hidden')
          $(".table.table-board-listing tbody.project tr.true.project#{$(my_this).data('project_id')}").not(".board#{$(my_this).data('board_id')}").removeClass('hidden')
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
          $(".table.table-board-listing tbody.dashboard tr.true").not(".board#{$(my_this).parents('.board-actions').data('board_id')}").addClass('hidden')
          $(".table.table-board-listing tbody.project tr.true").not(".project#{$(my_this).parents('.board-actions').data('project_id')}.board#{$(my_this).parents('.board-actions').data('board_id')}").addClass('hidden')
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

  $(document).on
    change: (e) ->
      $(".add-project-room").attr('href',"/rooms/new?private=true&project_id=#{$(@).val()}")
      $('#h1_project_name').html("#{$(@).find('option:selected').text()} Project")
      $('.edit-project').attr('href',"/projects/#{$(@).val()}/edit")
      $(".table.table-board-listing tbody.project tr.true.project#{$(@).val()}").removeClass('hidden')
      $(".table.table-board-listing tbody.project tr.true").not(".project#{$(@).val()}").addClass('hidden')
  ,'#project_select'

  $(document).on
    change: (e) ->
      $(@).removeClass('select-placeholder')
  ,"#project_charge_percentage, #project_customer_billing_cycle, #project_charge_on"

  $(document).on
    change: (e) ->
      $(@).removeClass('select-placeholder')
      $('#contract_type').html("
        <option value='placeholder' selected='selected' disabled='disabled'>#{$('#project_rate_type').find('option:selected').text()}</option>
        ")
  ,"#project_rate_type"

  $(document).on
    click: (e) ->
      e.preventDefault()
      step = $(@).data('step')
      $('.step').hide()
      $(".step-#{step}").show()
  ,".js-project-edit"

  $(document).on
    change: (e) ->
      $(@).removeClass('select-placeholder')
      if $(@).val() == 'true'
        $('#project_charge_percentage').parents('.form-group').show()
        $('#project_charge_on').parents('.form-group').show()
      else
        $('#project_charge_percentage').parents('.form-group').hide()
        $('#project_charge_on').parents('.form-group').hide()
  ,"#project_charge"

  $(document).on
    click: (e) ->
      e.preventDefault()
      step = $(@).data('step')
      $('.step').hide()
      $(".step-#{step}").show()
      if step == 2
        $('.step1 .data').html("<p>
          #{$('#project_project_name').val()}<br>
          #{$('#project_address1').val()}, #{$('#project_address2').val()}<br>
          #{$('#project_city').val()}, #{$('#project_state').val()}, #{$('#project_zip_code').val()}
          </p>
          <p>
          #{$('#project_email').val()}<br>
          #{$('#project_phone').val()}
          </p>")
      else if step == 3
        if $('#project_rate_type').val() == "flat_rate"
          str = "<p>
            #{$('#project_rate_type').find('option:selected').text().toLowerCase()}<br>
            #{$('#project_rate').val()}<br>
            #{$('#project_customer_billing_cycle').find('option:selected').text().toLowerCase()}
            </p>"
        else
          str = "<p>
            #{$('#project_rate_type').find('option:selected').text().toLowerCase()}<br>
            #{$('#project_customer_billing_cycle').find('option:selected').text().toLowerCase()}
            </p>"
        $('.step2 .data').html(str)
      else if step == 4
        if $('#project_charge').val() == 'true'
          if $("#project_charge_on").val() == 'all_products'
            charge_on = "On all products"
          else
            charge_on = "On alternate products"
          str = "<p>
              #{$('#contract_type').find('option:selected').text().toLowerCase()}<br>
              Percentage: Yes<br>
              #{charge_on}<br>
              Charge: #{$('#project_charge_percentage').val()}%
            </p>"
        else
          str = "<p>
              #{$('#contract_type').find('option:selected').text()}<br>
              Percentage: No
            </p>"
        $('.step3 .data').html(str)

  ,".project-next-step, .project-prev-step"

  $(document).on
    change: (e) ->
      $('#project_customer_billing_cycle').parents('.form-group').show()
      if $(@).val() == "flat_rate"
        $('#project_rate').parents('.form-group').show()
        $('#project_customer_billing_cycle').html('
          <option value="placeholder" selected="selected" disabled="disabled">Customer Billing Cycle</option>
          <option value="at_start" class="option-color">BILL AT START OF PROJECT</option>
          <option value="at_completion" class="option-color">BILL AT PROJECT COMPLETION</option>
          ')
      else
        $('#project_rate').parents('.form-group').hide()
        $('#project_customer_billing_cycle').html('
          <option value="placeholder" selected="selected" disabled="disabled">Customer Billing Cycle</option>
          <option value="weekly" class="option-color">WEEKLY</option>
          <option value="bi_weekly" class="option-color">BI-WEEKLY</option>
          <option value="monthly" class="option-color">MONTHLY</option>
          <option value="at_completion" class="option-color">AT PROJECT COMPLETION</option>
        ')
  ,"#project_rate_type"