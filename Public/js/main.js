var player;

function updateTableEventListeners() {
    //Changes Ordering
    $(".songs-table .orderable-header").on('click', function (e) {
        var ele = $(e.currentTarget);
        var col_name = ele.data('col');
        var omap = {'': 'asc', 'asc': 'desc', 'desc': ''};
        var ordering = omap[ele.data('order')];
        var query_string = ordering != '' ? ("?by=" + col_name + "&order=" + ordering) : '';
        var url = $(".table-container").data('url') + query_string;
        replace_table_content(url);
    });

    //Plays a song that's clicked on.
    $(".songs-table tbody tr").on('dblclick', function (e) {
        e.preventDefault();
        var id = $(e.currentTarget).data('id');
        player.enqueueNow(id);
    });
    $(".songs-table tbody tr td.row-name").on('click', function (e) {
        e.preventDefault();
        var id = $(e.currentTarget).parent().data('id');
        player.enqueueNow(id);
    });

    //Open song info modal.
    $(".songs-table tbody td.row-track").on('click', function (e) {
        var id = $(e.currentTarget).parent().data('id');
        $.ajax({
            url: "/i/song/" + id + "/info",
            success: function (data) {
                $("#modal-container").html(data);
                $("#modal-container .modal").modal('show');
            }
        });
    });

    //Tag edit replacement
    $("i.tag-edit").on('click', function (e) {
        var ele = $(e.currentTarget).parents(".row-tags");
        console.log(ele);
        ele.children(".tags-list").hide();
        ele.children(".tags-edit").show();
    });

    //Tag edit replacement
    $("button.tag-edit-done").on('click', function (e) {
        var ele = $(e.currentTarget).parents(".row-tags");
        console.log(ele);
        $.ajax({
            url: "/i/song/" + ele.parent().data("id") + "/tags",
            method: "post",
            data: ele.find(".tag-edit-form").serialize(),
            success: function (data) {
                ele.children(".tags-edit").hide();
                ele.children(".tags-list").html(data);
                ele.children(".tags-list").show();
            }
        });
    });


    // //Info button hover on
    // $(".songs-table tbody td.row-track").on('mouseenter', function (e) {
    //     var ele = $(e.currentTarget);
    //     ele.data('normal-contents', ele.html());
    //     ele.html('<i class="fa fa-info-circle"></i>');
    // });
    //
    // //Info button hover off
    // $(".songs-table tbody td.row-track").on('mouseleave', function (e) {
    //     var ele = $(e.currentTarget);
    //     ele.html(ele.data('normal-contents'));
    // });

    //Rank select activate
    $(".songs-table tbody td.row-rank").on('mouseenter', function (e) {
        var select = $(e.currentTarget).find('select.rank-select');
        select.show().focus();
        select.siblings('i').hide();
    });

    //Rank select deactivate
    $(".songs-table tbody td.row-rank").on('mouseleave', function (e) {
        var select = $(e.currentTarget).find('select.rank-select');
        select.hide();
        select.siblings('i').show();
    });

    //Rank select update backend
    $(".songs-table tbody td.row-rank select").on('change', function (e) {
        var ele = $(e.currentTarget);
        $.ajax({
            url: "/i/song/" + ele.parent().parent().data('id') + "/rank",
            data: {'rank': ele[0].value},
            method: 'post',
            success: function (data) {
                var faClasses = ['close', 'chevron-down', 'minus', 'chevron-up'];
                $.each(faClasses, function (i, c) {
                    ele.siblings('i').removeClass("fa-" + c);
                });
                ele.siblings('i').addClass('fa-' + faClasses[+data]);
            }
        });
    });

    //Rating change
    $(".songs-table tbody td.row-rating .rating-active span").on('click', function (e) {
        var ele = $(e.currentTarget);
        $.ajax({
            url: "/i/song/" + ele.parents("tr").first().data("id") + "/rating",
            data: {'rating': ele.data('num')},
            method: 'post',
            success: function (data) {
                console.log(data);
                ele.parents("div.rating").first().attr('data-value', data);
            }
        })
    });

    //$('[data-toggle="popover"]').popover() //?
}

function updateCategoryEventListeners() {
    $("li.category-list-item").on('click', function (e) {
        var list_item = $(e.currentTarget);
        replace_table_content("/b/" + list_item.data('type') + "/" + list_item.attr('data-id'), function () {
            $("li.category-list-item.active").removeClass('active');
            list_item.addClass('active');
            $("#split-right-col").data('url', "/b/" + list_item.data('type') + "/" + list_item.data('id'));
        });
    });

    //Open category info modal.
    $(".category-list-item .fa-info-circle").on('click', function (e) {
        e.preventDefault();
        console.log("Category Info");
        var list_item = $(e.currentTarget).parents(".category-list-item").first()
        var id = list_item.data('id');
        $.ajax({
            url: "/i/" + list_item.data('type') + "/" + id + "/info",
            success: function (data) {
                $("#modal-container").html(data);
                $("#modal-container .modal").modal('show');
            }
        });
    });
}

function updatePlayheadEventListeners() {
    $("#playhead #view-toggle button").on('click', function (e) {
        var ele = $(e.currentTarget);
        ele.siblings().each(function (i, e) {
            $(e).removeClass('active');
        });
        replace_browse_content(ele.data('url'));
        ele.addClass('active');
    });

    $("#playhead .prev").on('click', function () {
        player.prevSong();
    });

    $("#playhead .next").on('click', function () {
        player.nextSong();
    });

    $("#playhead .play").on('click', function () {
        player.togglePP();
    });

    $("#playhead .shuffle").on('click', function () {
        player.shuffle_toggle();
    });

    $("#main-player").on('ended', function () {
        console.log("Song has ended naturally");
        player.nextSong();
    })
}


function replace_browse_content(url) {
    replace_content(url, $(".browse-container"), function () {
        updateCategoryEventListeners();
        updateTableEventListeners();
    });
}

function replace_table_content(url, callback) {
    replace_content(url, $(".table-container"), function () {
        updateTableEventListeners();
        if (callback) {
            callback();
        }
    });
}

function replace_content(url, ele, callback) {
    ele.html("Loading...");
    $.ajax({
        url: url,
        success: function (data) {
            ele.html(data);
            ele.find(".table-container").data('url', url);
            if (callback)
                callback();
        },
        error: function (j, s, e) {
            alert("Error replacing content: " + e);
        }
    })
}

$(function () {
    player = new Player();

    player.dispatch("greetings");

    updatePlayheadEventListeners();

    if ($(".table-container").data('url')) {
        replace_browse_content($(".table-container").data('url'));
    }

    updateTableEventListeners();
    updateCategoryEventListeners();

    $("#debug-button").on('click', function () {
        $.ajax('/debug');
        player.dispatch('greetings');
    });
});
