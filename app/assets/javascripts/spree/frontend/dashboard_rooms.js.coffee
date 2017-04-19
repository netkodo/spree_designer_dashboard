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

  changeMenu = (type) ->
    if type == true
      $('.menu-public').addClass('hidden')
      $('.menu-private').removeClass('hidden')
    else
      $('.menu-public').removeClass('hidden')
      $('.menu-private').addClass('hidden')

  hideNotSelectedProjects = (type,activeProject) ->
    if type == true
      $('.table-board-listing tbody .true').addClass('hidden')

  changeTableView = (type) ->
    if type == true
      $(".table.table-board-listing thead tr").html("<th class='status'>&nbsp;</th><th colspan='2'></th>")
      $(".table.table-board-listing colgroup").html(
        "   <col style='width: 5%' />
            <col style='width: 20%' />
            <col style='width: 75%' />"
      )
      $(".designer_commission_style").addClass('hidden')
    else
      $(".table.table-board-listing thead tr").html(
        "     <th class='status'>&nbsp;</th>
              <th colspan='2'></th>
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
      changeMenu($(@).data('private'))
      hideNotSelectedProjects($(@).data('private'),$("#project_select").val())
      $(".btn-tab.js-get-room-type").each ->
        $(@).removeClass('active')
      $(@).addClass('active')
      $('#project_select').val("")
      $(".project-managment").addClass('hidden')
      $('#h1_project_name').html("")
  ,'.js-get-room-type'

  $(document).on
    click: (e)->
      e.preventDefault()
      $(".table.table-board-listing tbody.dashboard tr.true").not(".board#{$( $(".table-invoice") , $(@).parents('tr.invoice')).data('board_id')}").removeClass('hidden')
      $(".table.table-board-listing tbody.project tr.true.project#{$( $(".table-invoice") , $(@).parents('tr.invoice')).data('project_id')}").not(".board#{$( $(".table-invoice") , $(@).parents('tr.invoice')).data('board_id')}").removeClass('hidden')
      board_id = $(@).parents('tr.invoice').find('table').data('board_id')
      $("##{board_id}").find(".js-private-invoice").removeClass('disabled')
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
      board_id = obj.find('table').data('board_id')
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
          $("##{board_id}").find(".js-private-invoice").removeClass('disabled')
          obj.html("<td class='no-border' colspan='6'><div class='text-center'><i class='fa fa-check save-edit'></i> Saved</div></td>")
          setTimeout () ->
            obj.remove()
          ,'3000'
          console.log response
        error: (response) ->
          $(@).html('Save')
          $("##{board_id}").find(".js-private-invoice").removeClass('disabled')
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
      my_this.addClass('disabled')
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
      console.log "review"
  ,".js-preview-contract"

  $(document).on
    click: (e) ->
      $("#send-contract").modal()
  ,".js-send-contract"

  $(document).on
    click: (e) ->

      $.ajax
        dataType: 'json'
        method: 'POST'
        url: $(@).data('url')
        beforeSend: () ->
          $('.js-send-contract-confirmation').addClass('disabled').text('Sending...')
        success: (response) ->
#          console.log response
          $("#modal-location-body .confirmation").addClass("hidden")
          $('.js-send-contract-confirmation').removeClass('disabled').text('YES')
          $("#modal-location-body .success-sent").removeClass("hidden")
          $(".project-history-group").prepend(response.history_item)
          if response.location != undefined
            obj = $(".js-send-contract")
            obj.text("Client haven't signed contract yet.").removeClass('js-send-contract').addClass('disabled')
          setTimeout () ->
            $("#send-contract").modal('hide')
            $("#modal-location-body .confirmation").removeClass("hidden")
            $("#modal-location-body .success-sent").addClass("hidden")
          ,'1000'
        error: (response) ->
          $("#modal-location-body .confirmation").addClass("hidden")
          $("#modal-location-body .error").removeClass("hidden")
          setTimeout () ->
            $("#send-contract").modal('hide')
            $("#modal-location-body .confirmation").removeClass("hidden")
            $("#modal-location-body .error").addClass("hidden")
          ,'1000'
          console.log 'error'
#          console.log response
  ,".js-send-contract-confirmation"

  $(document).on
    click: (e) ->
      $("#send-contract").modal('hide')
  ,".close-modal"

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
    click: (e) ->
      my_this = $(@)
      e.preventDefault()
      $.ajax
        dataType: 'json'
        method: 'POST'
        url: $(@).attr('href')
        success: (response) ->
          my_this.parent().append("<div class='notification-to-remove'><i class='fa fa-check success'></i>#{response.message}</div>")
          setTimeout () ->
            $( $('.notification-to-remove'), my_this.parent() ).remove()
          ,'2000'
          my_this.parents('tr').removeClass('true').addClass('false hidden').append(response.columns)
          my_this.parents('.board-actions').html(response.actions)
        error: (response) ->
          res=JSON.parse(response.responseText);
          my_this.parent().append("<div class='notification-to-remove'><i class='fa fa-times error'></i>#{res.message}</div>")
          setTimeout () ->
            $( $('.notification-to-remove'), my_this.parent() ).remove()
          ,'2000'
  ,".js-make-public"

  $(document).on
    change: (e) ->
      if $(@).val() == "new_project"
        window.location.href = "/projects/new"
      else
        $('.project-managment').removeClass('hidden')
        $("#project_action").data('id',$(@).val())
        $('#h1_project_name').html("#{$(@).find('option:selected').text()} Project")
        $('.create-contract').attr('href',"/projects/#{$(@).val()}/contracts/new")
        $('.close-project').data('url',"/projects/#{$(@).val()}/close_open")
        $(".table.table-board-listing tbody tr.true.project#{$(@).val()}").removeClass('hidden')
        $(".table.table-board-listing tbody tr.true").not(".project#{$(@).val()}").addClass('hidden')
        $('.edit-project').attr('href',"/projects/#{$(@).val()}")
        $(".add-project-room").attr('href',"/rooms/new?private=true&project_id=#{$(@).val()}")
  ,'#project_select'

  $(document).on
    click: (e) ->
      status = $('#project_action').data('status')
      id = $('#project_action').data('id')
      switch $("#project_action").val()
        when "remove-project"
          if confirm("Are you sure?")
            my_this = $(@)
            $.ajax
              method: 'DELETE'
              url: "/projects/#{id}"
              beforeSend: () ->
                my_this.addClass('disabled').text('Processing...')
              success: (response) ->
                window.location.href = response.location
#                my_this.removeClass('disabled').text('Submit')
              error: (response) ->
                my_this.removeClass('disabled').text('Submit')
        when "project-details"
          $(@).addClass('disabled').text('Processing...')
          window.location.href = "/projects/#{id}"
        when "add-room"
          $(@).addClass('disabled').text('Processing...')
          window.location.href = "/rooms/new?private=true&project_id=#{id}"
        when "add-project"
          $(@).addClass('disabled').text('Processing...')
          window.location.href = "/projects/new"
        when "end-project"
          my_this = $(@)
          $.ajax
            dataType: 'json'
            method: 'POST'
            url: "/projects/#{id}/close_open"
            data: {project: {status: status}}
            beforeSend: () ->
              my_this.addClass('disabled').text('Processing...')
            success: (response) ->
              my_this.removeClass('disabled').text('Submit')
              $('.project-managment').append("<div class='text-center project-information success'>#{response.message}</div>")
              setTimeout () ->
                $('.project-information').remove()
              ,'2000'
            error: (response) ->
              res=JSON.parse(response.responseText);
              my_this.removeClass('disabled').text('Submit')
              $('.project-managment').append("<div class='text-center project-information error'>#{res.message}</div>")
              setTimeout () ->
                $('.project-information').remove()
              ,'2000'
  ,"#submit-action"

  $(document).on
    change: (e) ->
      $(@).removeClass('select-placeholder')
  ,"#project_charge_percentage, #project_customer_billing_cycle, #project_charge_on, #project_upfront_deposit, #pass_discount"

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
          #{$('#project_description').val().substring(0,100)}<br><br>
          #{$('#project_address1').val()}, #{$('#project_address2').val()}<br>
          #{$('#project_city').val()}, #{$('#project_state').val()}, #{$('#project_zip_code').val()}
          </p>
          <p>
          #{$('#project_email').val()}<br>
          #{$('#project_phone').val()}
          </p>")
      else if step == 3
        if $('#project_upfront_deposit').val() == 'true'
          upfront_deposit = "Upfront deposit: #{$('#project_deposit_amount').val()}"
        else
          upfront_deposit = "Upfront deposit: No"
        str = "<p>
          #{$('#project_rate_type').find('option:selected').text().toLowerCase()}<br>
          #{$('#project_rate').val()}<br>
          #{upfront_deposit}<br>
          #{$('#project_customer_billing_cycle').find('option:selected').text().toLowerCase()}
          </p>"
        $('.step2 .data').html(str)
      else if step == 4
        if $("#create_project_form").length
          url = $("#preview_contract").attr("href")
          serialize = $("#create_project_form").serialize()
          $("#preview_contract").attr("href", "#{url}?#{serialize}")
        else if $("#update_project_form").length
          url = "/preview_contract/-1.pdf"
          serialize = $("#update_project_form").serialize()
          $("#preview_contract").attr("href", "#{url}?#{serialize}")
        if $('#project_pass_discount').val() == 'true'
          pass_discount = "Pass discount: #{$('#project_discount_amount').val()}%"
        else
          pass_discount = "Pass discount: No"

        if $('#project_charge').val() == 'true'
          if $("#project_charge_on").val() == 'all_products'
            charge_on = "On all products"
          else
            charge_on = "On alternate products"
          str = "<p>
              #{$('#contract_type').find('option:selected').text().toLowerCase()}<br>
              Percentage: Yes<br>
              #{charge_on}<br>
              Charge: #{$('#project_charge_percentage').val()}%<br>
              #{pass_discount}
            </p>"
        else
          str = "<p>
              #{$('#contract_type').find('option:selected').text()}<br>
              Percentage: No<br>
              #{pass_discount}
            </p>"
        $('.step3 .data').html(str)

  ,".project-next-step, .project-prev-step"

  $(document).on
    change: (e) ->
      $('#project_customer_billing_cycle').parents('.form-group').show()
      if $(@).val() == 'hourly_rate'
        $('#project_rate').parents('.form-group').find('.info').show()
      else
        $('#project_rate').parents('.form-group').find('.info').hide()

      if $(@).val() == "flat_rate_project" or $(@).val() == 'hourly_rate'
        $('#project_customer_billing_cycle').html('
          <option value="placeholder" selected="selected" disabled="disabled">Customer Billing Cycle</option>
          <option value="weekly" class="option-color">WEEKLY</option>
          <option value="bi_weekly" class="option-color">BI-WEEKLY</option>
          <option value="monthly" class="option-color">MONTHLY</option>
          <option value="at_completion" class="option-color">AT PROJECT COMPLETION</option>
        ')
      else
        $('#project_customer_billing_cycle').html('
          <option value="placeholder" selected="selected" disabled="disabled">Customer Billing Cycle</option>
          <option value="at_start" class="option-color">BILL AT START OF PROJECT</option>
          <option value="at_completion" class="option-color">BILL AT PROJECT COMPLETION</option>
          ')
  ,"#project_rate_type"

  $(document).on
    change: (e) ->
      if $(@).val() == 'true'
        $('#project_deposit_amount').parents('.form-group').show()
      else
        $('#project_deposit_amount').parents('.form-group').hide()
  ,"#project_upfront_deposit"

  $(document).on
    change: (e) ->
      if $(@).val() == 'true'
        $('#project_discount_amount').parents('.form-group').show()
      else
        $('#project_discount_amount').parents('.form-group').hide()
  ,"#project_pass_discount"