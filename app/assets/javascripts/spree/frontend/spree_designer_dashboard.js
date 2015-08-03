function initializeProductSearchForm() {
    /* attach a submit handler to the form */
    $("#product_search_form").submit(function (event) {
        /* stop form from submitting normally */
        event.preventDefault();

        $('#products-preloader').show()
        $('#select-products-box').html('')
        /* get some values from elements on the page: */
        var $form = $(this),
            term = $form.find('input[name="product_keywords"]').val(),
            supplier_id = $form.find('select[name="supplier_id"]').val(),
            department_taxon = $form.find('select[name="department_taxon"]').val(),
            url = $form.attr('action');
        bid = $('#canvas').data('boardId')

        //alert(taxon);
        /* Send the data using post */
        var posting = $.post(url, { keywords: term, department_taxon_id: department_taxon, supplier_id: supplier_id, per_page: 50, board_id: bid });

        /* Put the results in a div */
        posting.done(function (data) {
            $('#products-preloader').hide()
            url = $('.solr-filter-products').data('search-url');
            keywords = $('#product_keywords').val()
            $.ajax({
                dataType: 'html',
                method: 'POST',
                url: url,
                data: {keywords: keywords},
                success: function (response) {
                    $('.solr-filter-products').html(response);
                }
            });


            //var content = $( data ).find( '#content' );
            //$( "#result" ).empty().append( content );
        });
    });
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


    value = $('.js-input-hash-product').val();
//
    if (value.length > 0) {
        hash = JSON.parse(value)
    } else {
        hash = {}
    }

    ha_id = ""
    action = ""
    if (obj.get('action') == 'create') {
        ha_id = obj.get('hash_id');
        action = "create";
    } else {
        ha_id = obj.get('id')
        action = "update";

    }
    hash[ha_id] = {action_board: action, board_id: $('#canvas').data('boardId'), product_id: obj.get('id'), center_point_x: obj.getCenterPoint().x, center_point_y: obj.getCenterPoint().y, width: obj.getWidth(), height: obj.getHeight(), rotation_offset: obj.getAngle(0)}
    if ( obj.z_index >= 0){
        hash[ha_id]['z_index'] =  obj.z_index;
    }
    $('.js-input-hash-product').val(JSON.stringify(hash));

    canvas.renderAll();
}

function showProductAddedState() {
    $('#product-preview-details').addClass('hidden');
    $('#product-preview-added').removeClass('hidden');
}

function updateBoardProduct(id, product_options) {

    var url = '/board_products/' + id + '.json'

    $.ajax({
            url: url,
            type: "POST",
            dataType: "json",
            data: {_method: 'PATCH', board_product: product_options},
            beforeSend: function (xhr) {
                xhr.setRequestHeader("Accept", "application/json")
            },
            success: function (data) {

            },
            error: function (objAJAXRequest, strError, errorThrown) {
                alert("ERROR: " + strError);
            }
        }
    );
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


function buildImageLayer(canvas, bp, url, slug, id, active, hash_id) {
    fabric.Image.fromURL(url, function (oImg) {
        oImg.scale(1).set({
            left: bp.center_point_x,
            top: bp.center_point_y,
            originX: 'center',
            originY: 'center',
            width: bp.width,
            height: bp.height,
            lockUniScaling: true,
            minScaleLimit: 0.25,
            hasRotatingPoint: false
        });
        oImg.set('id', id);
        oImg.set('action', active);
        oImg.set('product_permalink', slug);
        oImg.set('hash_id', hash_id);
        canvas.add(oImg);
        canvas.setActiveObject(oImg);
        if (bp.rotation_offset >= 0) {
            rotateObject(bp.rotation_offset);
            canvas.discardActiveObject();
            canvas.renderAll();
        }
    });

    value = $('.js-input-hash-product').val()
    if (value.length > 0) {
        hash = JSON.parse(value)
    } else {
        hash = {}
    }
    hash[hash_id] = { action_board: active, board_id: bp.board_id, product_id: id, center_point_x: bp.center_point_x, center_point_y: bp.center_point_y, width: bp.width, height: bp.height}

    if (bp.z_index >= 0){
        hash[hash_id]['z_index'] = bp.z_index;

    }
    $('.js-input-hash-product').val(JSON.stringify(hash));
}

function build_variants_list(variants) {
    var list = document.createElement('ul');
    var json = { items: ['item 1', 'item 2', 'item 3'] };
    $(variants).each(function (index, item) {
        list.append(
            $(document.createElement('li')).text(item)
        );
    });
    return list
}

function addProductToBoard(event, ui) {

    // add the image to the board through jquery drag and drop in order to get its position
    cloned = $(ui.helper).clone();
    $(this).append(cloned.removeClass('board-lightbox-product').addClass('board-lightbox-product-cloned'));

    //calculate the origin based on the position and size
    center_x = cloned.position().left + parseFloat(cloned.width()) / 2.0
    center_y = cloned.position().top + parseFloat(cloned.height()) / 2.0

    //hide the image of the product in the search results to indicate that it is no longer available to others.
    //selector = '#board-product-select-' + cloned.data('productId')
    //$(selector).hide();

    //alert(cloned.position().left + ':' + cloned.position().top)
    //saveProductToBoard($('#board-canvas').data('boardId'),cloned.data('productId'), cloned.position().left, cloned.position().top, 0, cloned.width(), cloned.height(), cloned.data('rotationOffset'));
    random = Math.floor((Math.random() * 10) + 1);
    url = ui.helper.data('img-url');
    slug = ui.helper.data('product-slug');
    canvas_id = ui.helper.data('canvas-id');
    board_product = {board_id: $('#canvas').data('boardId'), product_id: cloned.data('productId'), center_point_x: center_x, center_point_y: center_y, width: cloned.width(), height: cloned.height()}
    buildImageLayer(canvas, board_product, url, slug, cloned.data('productId'), 'create', cloned.data('productId') + '-' + random);
    canvas.renderAll();
    cloned.hide();
    // persist it to the board
//    var url = '/board_products.json'
//    $.ajax({
//            url: url,
//            type: "POST",
//            dataType: "json",
//            data: {board_product: {board_id: $('#canvas').data('boardId'), product_id: cloned.data('productId'), center_point_x: center_x, center_point_y: center_y, width: cloned.width(), height: cloned.height()}},
//            beforeSend: function (xhr) {
//                xhr.setRequestHeader("Accept", "application/json")
//            },
//            success: function (board_product) {
//                //console.log(board_product.product.slug)
//                buildImageLayer(canvas, board_product);
//
//
//                $('#board-canvas').unblock();
//                $('#product_lightbox').unblock();
//                $('.board-lightbox-product.ui-draggable.ui-draggable-dragging').hide();
//                cloned.hide();
//
//                // remove the jquery drag/drop place holder that had been there.
//                // this is a bit of a hack - without the timer, then the graphic disappears for a second...this generally keeps it up until the fabricjs version is added
//                setTimeout(function () {
//                    cloned.hide();
//                }, 1000);
//            },
//            error: function (objAJAXRequest, strError, errorThrown) {
//                alert("ERROR: " + strError);
//            }
//        }
//    );
}

function moveLayer(layer, direction) {
    switch (direction) {
        case "top":
            canvas.bringToFront(layer)
            break;
        case "forward":
            canvas.bringForward(layer)
            break;
        case "bottom":
            canvas.sendToBack(layer)
            break;
        case "backward":
            canvas.sendBackwards(layer)
            break;
    }
    //it's possible all z indices have changed.  update them all
    canvas.forEachObject(function (obj) {
        console.log(canvas.getObjects().indexOf(obj));

        value = $('.js-input-hash-product').val();
//
        if (value.length > 0) {
            hash = JSON.parse(value)
        } else {
            hash = {}
        }

        ha_id = ""
        action = ""
        if (obj.get('action') == 'create') {
            ha_id = obj.get('hash_id');
            action = "create";
        } else {
            ha_id = obj.get('id')
            action = "update";

        }
        obj.set('z_index', canvas.getObjects().indexOf(obj));
        hash[ha_id] = {action_board: action, board_id: $('#canvas').data('boardId'), product_id: obj.get('id'), center_point_x: obj.getCenterPoint().x, center_point_y: obj.getCenterPoint().y, width: obj.getWidth(), height: obj.getHeight(), rotation_offset: obj.getAngle(0), z_index: obj.get('z_index')}
        $('.js-input-hash-product').val(JSON.stringify(hash));
        console.log(JSON.stringify(hash));




//        updateBoardProduct(obj.get('id'), {id: obj.get('id'), z_index: canvas.getObjects().indexOf(obj)})

        //console.log(canvas.getObjects().indexOf(obj))
    });

}


function getSavedProducts(board_id) {
    var url = '/rooms/' + board_id + '/board_products.json'
    //var request = $.getJSON( url );

    $.ajax({
            url: url, dataType: "json",
            beforeSend: function (xhr) {
                xhr.setRequestHeader("Accept", "application/json")
            },
            success: function (data) {

                // add the products to the board
                $.each(data, function (index, board_product) {
                    buildImageLayer(canvas, board_product, board_product.product.image_url, board_product.product.slug, board_product.id, 'update', board_product.id);

                });
                // detect which product has focus
                canvas.on('mouse:down', function (options) {
                    if (options.target) {
                        selectedImage = options.target;
                        // pass the product id and board_id (optional) and BoardProduct id (optional)
                        getProductDetails(selectedImage.get('product_permalink'), board_id, selectedImage.get('id'))
                        //console.log(selectedImage.get('product_permalink'))
                    }
                    else {
                        selectedImage = null;
                        $('#board-product-preview').html('')
                    }
                });

                canvas.on({
                    'object:modified': function (e) {
                        activeObject = e.target
                        value = $('.js-input-hash-product').val();
                        if (value.length > 0) {
                            hash = JSON.parse(value)
                        } else {
                            hash = {}
                        }

                        ha_id = ""
                        action = ""
                        if (activeObject.get('action') == 'create') {
                            ha_id = activeObject.get('hash_id');
                            action = "create";
                        } else {
                            ha_id = activeObject.get('id')
                            action = "update";

                        }
                        hash[ha_id] = {action_board: action, board_id: board_id, product_id: activeObject.get('id'), center_point_x: activeObject.getCenterPoint().x, center_point_y: activeObject.getCenterPoint().y, width: activeObject.getWidth(), height: activeObject.getHeight(), rotation_offset: activeObject.getAngle(0)}

                        if (activeObject.get('z_index') >= 0){
                         hash[ha_id]['z_index'] =  activeObject.get('z_index')

                        }
                        $('.js-input-hash-product').val(JSON.stringify(hash));
                        console.log(activeObject);

//								updateBoardProduct(activeObject.get('id'), {id: activeObject.get('id'), center_point_x: activeObject.getCenterPoint().x, center_point_y: activeObject.getCenterPoint().y, width: activeObject.getWidth(), height: activeObject.getHeight(), rotation_offset: activeObject.getAngle(0)})
                    }
                });

                // listen for toolbar functions
                document.getElementById('bp-move-front').addEventListener('click', function () {
                    moveLayer(selectedImage, "top")
                }, false);
                document.getElementById('bp-move-forward').addEventListener('click', function () {
                    moveLayer(selectedImage, "forward")
                }, false);
                document.getElementById('bp-move-back').addEventListener('click', function () {
                    moveLayer(selectedImage, "bottom")
                }, false);
                document.getElementById('bp-move-backward').addEventListener('click', function () {
                    moveLayer(selectedImage, "backward")
                }, false);
                document.getElementById('bp-rotate-left').addEventListener('click', function () {
                    activeObject = canvas.getActiveObject()
                    rotateObject(90);
//					updateBoardProduct(activeObject.get('id'), {id: activeObject.get('id'), center_point_x: activeObject.getCenterPoint().x, center_point_y: activeObject.getCenterPoint().y, width: activeObject.getWidth(), height: activeObject.getHeight(), rotation_offset: activeObject.getAngle(0)})

                    //console.log('getLeft: '+ activeObject.getLeft())
                    //console.log('getTop: '+ activeObject.getTop())
                    //console.log('getPointByOrigin: '+ activeObject.getPointByOrigin())
                    //console.log('getOriginX: '+ activeObject.getOriginX())
                    //console.log('getOriginY: '+ activeObject.getOriginY())
                    //console.log('getCurrentLeft: '+ getCurrentLeft(activeObject))
                    //console.log('getCurrentTop: '+ getCurrentTop(activeObject))
                    //console.log('getAngle: '+ activeObject.getAngle())
                }, false);

            },
            error: function (objAJAXRequest, strError, errorThrown) {
                alert("ERROR: " + strError);
            }
        }
    );

}

function getCurrentLeft(obj) {

    // if the angle is 0 or 360, then the left should be as is.
    // if the angle is 270 then the original left is in the bottom left and should be left as is
    if (obj.getAngle() == 0 || obj.getAngle() == 270 || obj.getAngle() == 360) {
        return Math.round(obj.getLeft());
    }

    // if the angle is 90, then the original left is in the top right.
    // currentLeft = origLeftPos - height
    else if (obj.getAngle() == 90) {
        return Math.round(obj.getLeft() - obj.getHeight());
    }

    //if the angle is 180 the the original left is in the bottom right.
    // currentLeft = origLeftPos - width
    else if (obj.getAngle() == 180) {
        return Math.round(obj.getLeft() - obj.getWidth());
    }


}
function getCurrentTop(obj) {

    // if the angle is 0 or 360 then the top should be as is
    // if the angle is 90, then the original corner is in the top right and should be left as is
    if (obj.getAngle() == 0 || obj.getAngle() == 90 || obj.getAngle() == 360) {
        return Math.round(obj.getTop());
    }

    // if the angle is 180 then the object is flipped vertically and original corner is in the bottom right
    // currentTop = origTop - height
    else if (obj.getAngle() == 180) {
        return Math.round(obj.getTop() - obj.getHeight());
    }

    // if the angle is 270 then the object is rotated and flipped horizontally and original corner is on bottom left
    // currentTop = origTop - width
    else if (obj.getAngle() == 270) {
        return Math.round(obj.getTop() - obj.getWidth());
    }
}

function getProductDetails(product_id, board_id, board_product_id) {
    $('.board-product-preview-details').hide()
    $('.js_reload_info').show()
    board_id = (typeof board_id === "undefined") ? "defaultValue" : board_id;
    board_product_id = (typeof board_product_id === "undefined") ? "defaultValue" : board_product_id;


    var qstring = "?q"
    if (board_id != null) {
        qstring = qstring + '&board_id=' + board_id
    }
    if (board_product_id != null) {
        qstring = qstring + '&board_product_id=' + board_product_id
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
    var url = '/bookmarks/remove?product_id=' + product_id
    $.post(url, null, "script");


    //$('.unbookmark-link-'+product_id).parent().addClass('hidden')
    //$('.unbookmark-link-'+product_id).parent().parent().children('.bookmark-product-container').removeClass('hidden')
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

    //$('a.button-product-info').popover({
    //    html : true,
    //    content: function() {
    //			$('.button-product-info').popover('hide');
    //      return $('#'+$(this).data('popoverContainer')).html();
    //    }
    //});


}


function getImageWidth(url) {
    var img = new Image();
    img.onload = function () {
        //return "w"
    }
    img.src = url
    return img.width
}

function getImageHeight(url) {
    var img = new Image();
    img.onload = function () {
        //return "h"
    }
    img.src = url
    return img.height
}

//function showProductDetails(item){
//	$('#product-details-pane').html('Loading product details...')
//	getProductDetails(item.data('productPermalink'), $('#canvas').data('boardId'))
//}


function setHeight() {
    var modalHeight = $('#product-modal').height();
    $('.select-products-box').height(modalHeight - 200);
    $('.product-preview-box').height(modalHeight - 200);

}
