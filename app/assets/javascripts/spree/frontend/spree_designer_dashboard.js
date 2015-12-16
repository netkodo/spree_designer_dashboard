
window.canvas_crop = null;
function initializeProductSearchForm() {
    /* attach a submit handler to the form */
    $("#product_search_form").submit(function (event) {
        /* stop form from submitting normally */
        event.preventDefault();

        $('#products-preloader').show();
        $('#select-products-box').html('');
        /* get some values from elements on the page: */
        var $form = $(this),
            term = $form.find('input[name="product_keywords"]').val(),
            supplier_id = $form.find('select[name="supplier_id"]').val(),
            department_taxon = $form.find('select[name="department_taxon"]').val(),
            url = $form.attr('action');
        bid = $('#canvas').data('boardId');

        //alert(taxon);
        /* Send the data using post */
        var posting = $.post(url, { keywords: term, department_taxon_id: department_taxon, supplier_id: supplier_id, per_page: 50, board_id: bid });

        /* Put the results in a div */
        posting.done(function (data) {
            $('#products-preloader').hide();
            url = $('.solr-filter-products').data('search-url');
            keywords = $('#product_keywords').val();
            $.ajax({
                dataType: 'html',
                method: 'POST',
                url: url,
                data: {keywords: keywords},
                success: function (response) {
                    $('.solr-filter-products').html(response);
                }
            });


        });
    });
}

$(window).load(function(){
    $(".products_flexi_box").flexisel({
        autoPlay: true,
        autoPlaySpeed: 3000,
        pauseOnHover: true
    });
});

$(document).on({
    click: function(e){
        e.preventDefault();
        obj = canvas.getActiveObject();

        if(!isBlank(obj)) {
            $('#crop-modal').lightbox_me({
                centered: true,
                closeClick: true,
                closeEsc: false,
                onLoad: function () {
                    generateModalCrop(obj);
                },
                onClose: function () {

                }
            });
        }
    }
}, "#bp-crop");

$(document).on({
    click: function (e) {
        var obj, value;
        e.preventDefault();
        obj = canvas.getActiveObject();
        hash_id = obj.get('hash_id');
        canvas.remove(obj);
        value = $('.js-input-hash-product').val();
        if (value.length > 0) {
            hash = JSON.parse(value);
            delete hash[hash_id];
            $('.js-input-hash-product').val(JSON.stringify(hash));
        }
    }
}, '#js-remove-new-product-from-room');

$(document).on({
    click: function(e) {
        e.preventDefault();
        options = {};
        v = $crop_image.cropper('getCroppedCanvas');
        obj = canvas.getActiveObject();
        obj.set('width', v.width);
        obj.set('height', v.height);
        obj.set('save_url', v.toDataURL());
        obj.set('cropped', true);
        obj.setElement(v);
        canvas.renderAll();
        value = $('.js-input-hash-product').val();
        hash =  JSON.parse(value);
        ha_id = '';
        if (!isBlank(hash)) {
            if (obj.get('action') === 'create') {
                ha_id = obj.get('hash_id');
            } else {
                ha_id = obj.get('id');
            }
            hash[ha_id]["image"] = v.toDataURL();
            $('.js-input-hash-product').val(JSON.stringify(hash));
        }
        $('#crop-modal').trigger('close');
    }
}, '#btnCropRoom');

$(document).on({
    click: function(e) {
        var obj;
        e.preventDefault();
        obj = canvas.getActiveObject();
        if(!isBlank(obj)){
            renderMirror(obj);
            hash = generateHash(obj);
            $('.js-input-hash-product').val(JSON.stringify(hash));
        }
    }
}, "#bp-mirror");

$(document).on({
    click: function(e){
        e.preventDefault();
        selectedImage = canvas.getActiveObject();
        if(!isBlank(selectedImage)) {
            moveLayer(selectedImage, "top")
        }
    }
}, '#bp-move-front');

$(document).on({
    click: function(e){
        e.preventDefault();
        selectedImage = canvas.getActiveObject();
        if(!isBlank(selectedImage)) {
            moveLayer(selectedImage, "forward")
        }
    }
}, '#bp-move-forward');

$(document).on({
    click: function(e){
        e.preventDefault();
        selectedImage = canvas.getActiveObject();
        if(!isBlank(selectedImage)) {
            moveLayer(selectedImage, "bottom")
        }
    }
}, '#bp-move-back');

$(document).on({
    click: function(e){
        e.preventDefault();
        selectedImage = canvas.getActiveObject();
        if(!isBlank(selectedImage)) {
            moveLayer(selectedImage, "backward")
        }
    }
}, '#bp-move-backward');

$(document).on({
    click: function(e){
        e.preventDefault();
        canvas.getActiveObject();
        rotateObject(90);
    }
}, '#bp-rotate-left');

//function initCrop(){
//    dataImg = canvas.getActiveObject();
//    options = {
//        thumbBox: '.thumbBoxRoom',
//        spinner: '.spinnerRoom',
//        imgSrc: dataImg.toDataURL()
//    };
//    cropper = $('.imageBoxRoom').cropbox(options);
//    return [dataImg, cropper]
//}

function generateModalCrop(dataImg){
    $('.croppedRoom').html('');
    delete dataImg.filters[0];
//    dataImg.set('scaleX', 1.1);
//    dataImg.set('scaleY', 1.1);

//    dataImg.getElement().src = dataImg.save_url;
    $('.croppedRoom').append('<img src='+dataImg.toDataURL('image/jpeg')+'>');
    $crop_image = $('.croppedRoom img');
    var options = {
        aspectRatio: NaN,
        minCanvasWidth: 270,
        minCanvasHeight: 270,
        minContainerHeight: 290
    };

    $crop_image.on().cropper(options);
}

function rotateObject(angleOffset) {
    var obj = canvas.getActiveObject(),
        resetOrigin = false;

    if (!obj) return;

    var angle = obj.getAngle() + angleOffset;

    if ((obj.originX !== 'center' || obj.originY !== 'center') && obj.centeredRotation) {
        obj.setOriginToCenter && obj.setOriginToCenter();
        resetOrigin = true;
    }

    angle = angle > 360 ? 90 : angle < 0 ? 270 : angle;
    obj.setAngle(angle).setCoords();
    if (resetOrigin) {
        obj.setCenterToOrigin && obj.setCenterToOrigin();
    }

    hash = generateHash(obj);
    $('.js-input-hash-product').val(JSON.stringify(hash));

    canvas.renderAll();
}

function cropImage(cropper, dataImg, callback){
    img = cropper.getDataURL();
    window.canvas_tab = img;
    image_element = dataImg.getElement();
    dataImg.set('save_url', img);
    dataImg.set('flipX', false);
    $(this).removeClass('spinner');
    value = $('.js-input-hash-product').val();
    hash =  JSON.parse(value);
    ha_id = '';
    if (!isBlank(hash)){
        if (dataImg.get('action') === 'create') {
            ha_id = dataImg.get('hash_id');
        } else {
            ha_id = dataImg.get('id');
        }
        hash[ha_id]["image"] = img;
        $('.js-input-hash-product').val(JSON.stringify(hash));
    }
    callback(dataImg);
}

function isBlank( object ) {
    if ( typeof object !== "undefined" && object !== null ){
        if ( typeof object === "object" ){
          if ( Object.keys(object).length > 0 ) {
              return false;
          }  else {
              return true;
          }
        } else if  ( typeof object !== "object" &&  object.length > 0 ) {
            return false;
        } else if ( typeof object === "boolean" || typeof object === "number" ) {
            return false ;
        } else {
            return true;
        }
    } else {
      return true;
    }
}

function renderMirror( object ) {
    object.set('flipX', !object.flipX);
    canvas.renderAll();
}

fabric.Object.prototype.setOriginToCenter = function () {
    this._originalOriginX = this.originX;
    this._originalOriginY = this.originY;

    var center = this.getCenterPoint();

    this.set({
        originX: 'center',
        originY: 'center',
        left: center.x,
        top: center.y
    });
};

fabric.Object.prototype.setCenterToOrigin = function () {
    var originPoint = this.translateToOriginPoint(
        this.getCenterPoint(),
        this._originalOriginX,
        this._originalOriginY);

    this.set({
        originX: this._originalOriginX,
        originY: this._originalOriginY,
        left: originPoint.x,
        top: originPoint.y
    });
};

function buildImageLayer(canvas, bp, url, slug, id, active, hash_id, callback ) {
    callback = callback || null;
     fabric.Image.fromURL(url, function (oImg) {
        oImg.scale(1).set({
            save_url: url,
            left: bp.center_point_x,
            top: bp.center_point_y,
            originX: 'center',
            originY: 'center',
            flipX: bp.flip_x,
            width: bp.width,
            height: bp.height,
            lockUniScaling: true,
            minScaleLimit: 0.5,
            hasRotatingPoint: true
        });
        oImg.set('id', id);
        oImg.set('action', active);
        oImg.set('product_permalink', slug);
        oImg.set('hash_id', hash_id);
        if (!isBlank(oImg.cropped)){
        oImg.set('cropped', true)
        }
        canvas.add(oImg);
        canvas.setActiveObject(oImg);
        if (bp.rotation_offset >= 0) {
            rotateObject(bp.rotation_offset);
            canvas.renderAll();
        }
     callback(oImg);
    });
    obj = find_object(id);
    if (!isBlank(obj)) {
        hash = generateHash(bp);
        $('.js-input-hash-product').val(JSON.stringify(hash));
    }
}


function addProductToBoard(event, ui) {

    // add the image to the board through jquery drag and drop in order to get its position
    cloned = $(ui.helper).clone();
    $(this).append(cloned.removeClass('board-lightbox-product').addClass('board-lightbox-product-cloned'));

    //calculate the origin based on the position and size
    center_x = cloned.position().left + parseFloat(cloned.width()) / 2.0
    center_y = cloned.position().top + parseFloat(cloned.height()) / 2.0

    random = Math.floor((Math.random() * 10) + 1);
    image_url = ui.helper.data('canvas-img-base');
    base_url = $('#board-container').data('url');
    $.ajax({
        dataType: 'html',
        method: 'POST',
        url: base_url,
        data: {image: image_url},
        success: function (resp) {
            url = resp;
            canvas_url = ui.helper.data('canvas-img-base');
            slug = ui.helper.data('product-slug');
            canvas_id = ui.helper.data('canvas-id');
            board_product = {
                board_id: $('#canvas').data('boardId'),
                product_id: cloned.data('productId'),
                center_point_x: center_x,
                center_point_y: center_y,
                width: cloned.width(),
                height: cloned.height()
            };
            buildImageLayer(canvas, board_product, url, slug, cloned.data('productId'), 'create', cloned.data('productId') + '-' + random, createObjectImage);
            setTimeout((function () {
                if ($.cookie("active_image") === undefined || $.cookie("active_image").toString() !== canvas.getActiveObject().get('hash_id').toString()) {
                    $.cookie("active_image", canvas.getActiveObject().get('hash_id'));
                    getProductDetails(slug, $('#canvas').data('boardId'), cloned.data('productId'))
                }
            }), 1000)

        }
    });
    canvas.discardActiveObject();
    canvas.renderAll();
    cloned.hide();
}

function moveLayer(layer, direction) {
    switch (direction) {
        case "top":
            canvas.bringToFront(layer);
            break;
        case "forward":
            canvas.bringForward(layer);
            break;
        case "bottom":
            canvas.sendToBack(layer);
            break;
        case "backward":
            canvas.sendBackwards(layer);
            break;
    }
    //it's possible all z indices have changed.  update them all
    canvas.forEachObject(function (obj) {
        obj.set('z_index', canvas.getObjects().indexOf(obj));
        hash = generateHash(obj);
        $('.js-input-hash-product').val(JSON.stringify(hash));
    });

}

function getSavedProducts(board_id) {
    var url = '/rooms/' + board_id + '/board_products.json'

    $.ajax({
            url: url, dataType: "json",
            beforeSend: function (xhr) {
                xhr.setRequestHeader("Accept", "application/json")
            },
            success: function (data) {
                // add the products to the board
                $.each(data, function (index, board_product) {
                    buildImageLayer(canvas, board_product, board_product.product.image_url, board_product.product.slug, board_product.id, 'update', board_product.id,  createObjectImage);
                    canvas.renderAll();
                    canvas.discardActiveObject();
                });
                canvas.discardActiveObject();

                // detect which product has focus
                canvas.on('mouse:down', function (options) {
                    if (options.target) {

                        selectedImage = options.target;
                        // pass the product id and board_id (optional) and BoardProduct id (optional)
                        if ($.cookie("active_image") === undefined || $.cookie("active_image").toString() !== selectedImage.get('hash_id').toString()) {
                            $.cookie("active_image", selectedImage.get('hash_id'))
                            getProductDetails(selectedImage.get('product_permalink'), board_id, selectedImage.get('id'), canvas.getActiveObject().get('variant_image'))
                        }
                    }
                    else {
                        selectedImage = null;
                        $('#board-product-preview').html('');
                        $.cookie("active_image", "");
                    }
                });

                canvas.on({
                    'object:modified': function (e) {

                        if (canvas.getActiveGroup() === null || canvas.getActiveGroup() === undefined) {
                            activeObject = e.target
                            createObjectImage(activeObject);
                        }
                    }
                });
            },
            error: function (objAJAXRequest, strError, errorThrown) {
                alert("ERROR: " + strError);
            }
        }
    );
}

function createObjectImage(activeObject) {
    new_image = activeObject.get('save_url');
    activeObject.getElement().src = new_image;

    activeObject.getElement().load = function () {
        var theImage = new fabric.Image(activeObject.getElement(), {top: Number(activeObject.get('top').toFixed(0)), left: Number(activeObject.get('left').toFixed(0))});
        theImage.scaleX = Number(activeObject.get('scaleX').toFixed(1));
        theImage.scaleY = Number(activeObject.get('scaleY').toFixed(1));
        theImage.angle = activeObject.get('angle');
        theImage.originX = 'center';
        theImage.originY = 'center';
        theImage.lockUniScaling = true;
        theImage.minScaleLimit = 0.5;
        theImage.hasRotatingPoint = true;
        theImage.set('width', Number(activeObject.get('width').toFixed(0)));
        theImage.set('height', Number(activeObject.get('height').toFixed(0)));
        theImage.set('id', activeObject.get('id'));
        theImage.set('action', activeObject.get('action'));
        theImage.set('product_permalink', activeObject.get('product_permalink'));
        theImage.set('hash_id', activeObject.get('hash_id'));
        theImage.set('flipX', activeObject.get('flipX'));
        theImage.set('save_url', activeObject.get('save_url'));
        theImage.set('variant_image', activeObject.get('variant_image'));
        theImage.set('stroke', '#fff');
        if (!isBlank(activeObject.cropped)){
            theImage.set('cropped', true)
        };

        canvas.add(theImage);
        if ((activeObject.scaleX < 2.3 || isBlank(activeObject.scaleX)) && (isBlank(activeObject.cropped)) ) {
            theImage.filters.push(generateFilter());
            theImage.applyFilters(canvas.renderAll.bind(canvas));
        }
        hash = generateHash(theImage);
        $('.js-input-hash-product').val(JSON.stringify(hash));
        canvas.remove(activeObject);
        canvas.renderAll();
        canvas.setActiveObject(theImage);
    };
    activeObject.getElement().load();
}

function generateFilter(){
var filter = new fabric.Image.filters.Convolute({
    matrix: [ 1 / 9, 1 / 9, 1 / 9,
            1 / 9, 1 / 9, 1 / 9,
            1 / 9, 1 / 9, 1 / 9 ]
    });
    return filter
}

function find_object(id){
    $.each(canvas.getObjects(), function(index, obj){
        if (obj.get('id') === id ){
          return value;
        }
    });
}

function generateHash(object) {
    board_id = $('#canvas').data('boardId');
    value = $('.js-input-hash-product').val();
    if (value.length > 0) {
        hash = JSON.parse(value)
    } else {
        hash = {}
    }

    ha_id = "";
    action = "";
    if (object.get('action') === 'create') {
        ha_id = object.get('hash_id');
        action = "create";
    } else {
        ha_id = object.get('id');
        action = "update";
    }
    image = "";
    if (!isBlank(hash[ha_id]) && !isBlank(hash[ha_id]['image'])) {
        image = hash[ha_id]['image']
    }else{
        image = null
    }
    hash[ha_id] = {
        action_board: action,
        board_id: board_id,
        product_id: object.get('id'),
        center_point_x: object.getCenterPoint().x,
        center_point_y: object.getCenterPoint().y,
        width: object.getWidth(),
        height: object.getHeight(),
        rotation_offset: object.getAngle(0),
        flip_x: object.get('flipX'),
        image: image
    };

    if (object.get('z_index') >= 0) {
        hash[ha_id]['z_index'] = object.get('z_index');
    }
    return hash
}

function getProductDetails(product_id, board_id, board_product_id, variant_url) {
    variant_url = variant_url || 0;
    $('.board-product-preview-details').hide()
    $('.js_reload_info').show()
    board_id = (typeof board_id === "undefined") ? "defaultValue" : board_id;
    board_product_id = (typeof board_product_id === "undefined") ? "defaultValue" : board_product_id;

    if (variant_url === 0 || variant_url === undefined) {
        variant_url = ""
    }

    var qstring = "?q"
    if (board_id != null) {
        qstring = qstring + '&board_id=' + board_id + '&variant_url=' + variant_url
    }
    if (board_product_id != null) {
        qstring = qstring + '&board_product_id=' + board_product_id + '&variant_url=' + variant_url
    }


    var url = '/products/' + product_id + qstring
    var request = $.get(url);

    /* Put the results in a div */
    request.done(function (data) {
        $('.js_reload_info').hide()
        $('.board-product-preview-details').show()
        //var content = $( data ).find( '#content' );
        //$( "#result" ).empty().append( content );
    });
}

function addProductBookmark(product_id) {
    var url = '/bookmarks.json?product_id=' + product_id
    //$('.bookmark-link-'+product_id).parent().addClass('hidden')
    //$('.bookmark-link-'+product_id).parent().parent().children('.unbookmark-product-container').removeClass('hidden')
    $('.bookmark-link-' + product_id).each(function () {
        $(this).parent().addClass('hidden')
        $(this).parent().parent().children('.unbookmark-product-container').removeClass('hidden')
    });


    $.ajax({
            url: url,
            type: "POST",
            dataType: "json",
            data: {},
            beforeSend: function (xhr) {
                xhr.setRequestHeader("Accept", "application/json")
            },
            success: function (bookmark) {
                //alert('u r the one')
            },
            error: function (objAJAXRequest, strError, errorThrown) {
                //alert("ERROR: " + strError);
            }
        }
    );
}

function observeBookmarkChanges() {
    $('.bookmark-product').click(function () {
        addProductBookmark($(this).data('productId'))
    });
    $('.remove-bookmark-product').click(function () {
        removeProductBookmark($(this).data('productId'))
    });

}

function removeProductBookmark(product_id) {
    $('.unbookmark-link-' + product_id).each(function () {
        $(this).parent().addClass('hidden')
        $(this).parent().parent().children('.bookmark-product-container').removeClass('hidden')
    });
    var url = '/bookmarks/remove?product_id=' + product_id;
    $.post(url, null, "script");

}

function getProductBookmarks() {
    $('#bookmark-preloader').removeClass('hidden')
    $('#bookmarks_container').html('')
    var url = '/favorites/'
    var request = $.get(url);
    request.done(function (data) {
    });
}

function initializeBoardManagement() {
    $("#submit_board_button").click(function () {

        $('#board-canvas').block({
            message: null,
            overlayCSS: {
                backgroundColor: '#999',
                opacity: 0.6,
                cursor: 'wait'
            }
        });
        $('#product_lightbox').block({
            message: null,
            overlayCSS: {
                backgroundColor: '#999',
                opacity: 0.6,
                cursor: 'wait'
            }
        });

        if ($('#edit_board_form').parsley('isValid')) {
            $(this).html('Saving...')
            $("#edit_board_form").submit();
        } else {
            $('#edit_board_form').parsley('validate')
        }

    });

    $("#submit_and_publish_board_button").click(function () {

        if ($('#edit_board_form').parsley('isValid')) {
            $('#publish-board-modal').modal()
        } else {
            $('#edit_board_form').parsley('validate')
        }

    });

}

function handleRemoveFromCanvas(el) {
    el.find('a.button-remove-product').click(function () {
        el.hide();
        var product_id = el.data('productId')
        var board_id = $('#board-canvas').data('boardId')
        var url = '/rooms/' + board_id + '/board_products/' + product_id
        $.post(url, {_method: 'delete'}, null, "script");
        $('.board-lightbox-product-cloned').popover('hide');
    });

}

function handleProductPopover(el) {

    $('.board-lightbox-product-cloned').popover({
        html: true,
        trigger: 'manual',
        content: function () {
            //$('.board-lightbox-product-cloned').popover('hide');
            return $('#' + $(this).data('popoverContainer')).html();
        }
    });
}


