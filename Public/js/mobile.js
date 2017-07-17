var player;


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

    $("#playhead .refresh").on('click', function () {
        player.dispatch("update");
    });

    $("#playhead .queue-list").on('click', function () {

    })

    $("#main-player").on('ended', function () {
        console.log("Song has ended naturally");
        player.nextSong();
    })
}

$(function () {
    player = new Player();

    player.dispatch("greetings");

    updatePlayheadEventListeners();

    $("#debug-button").on('click', function () {
        window.location.reload(true);
    });
});
