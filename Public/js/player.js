function Player() {
    this.status = {};
    this.audio = document.getElementById("main-player");
    this.infobox = $("#playhead .infobox");
    this.playing = false;

    this.update = function (json_string) {
        this.status = JSON.parse(json_string);
        src = "/i/song/" + this.status.current + "/url";
        if (src != $(this.audio).attr('src')) {
            $(this.audio).attr('src', src);
        }
        if (this.status.current != undefined) {
            replace_content("/i/song/" + this.status.current + "/infobox", this.infobox, undefined);
        } else {
            this.infobox.html(
                '<div class="infobox-inner"><img src="http://alextdavis.me/favicon.ico"></div>');
        }

        console.log("Shuffle status:" + this.status.shuffle);
        if (this.status.shuffle) {
            ele = $("#playhead .shuffle");
            ele.removeClass('shuffle-off');
            ele.addClass('shuffle-on');
        } else {
            ele = $("#playhead .shuffle");
            ele.removeClass('shuffle-on');
            ele.addClass('shuffle-off');
        }

        //TODO: put queue, history, now playing, shuffle & repeat in DOM.
    };

    this.dispatch = function (message, id, shouldPlay) {
        var self = this;
        $.ajax({
            url: "/q/dispatch",
            method: "post",
            data: {message: message, id: id},
            success: function (data) {
                self.update(data);
                console.log("Recieved success. shouldPlay:" + shouldPlay);
                if (shouldPlay) {
                    self.play();
                }
            }
        })
    };

    this.play = function () {
        console.log('playing');
        ele = $("#playhead .play i");
        ele.removeClass('fa-play');
        ele.addClass('fa-pause');
        this.playing = true;
        this.audio.play();
    };

    this.pause = function () {
        console.log('pausing');
        ele = $("#playhead .play i");
        ele.removeClass('fa-pause');
        ele.addClass('fa-play');
        this.playing = false;
        this.audio.pause();
    };

    this.togglePP = function () {
        if (this.playing) {
            this.pause();
        } else {
            this.play();
        }
    };

    this.currentTime = function (time) {
        if (time != undefined) {
            this.audio.currentTime = time;
        } else {
            return this.audio.currentTime;
        }
    };

    this.nextSong = function () {
        this.dispatch("next", undefined, true);
    };

    this.prevSong = function () {
        if (this.currentTime() > 5) {
            this.currentTime(0);
        } else {
            this.dispatch("prev", undefined, true);
        }
    };

    this.shuffle_toggle = function () {
        this.dispatch("shuffle", undefined, false);
    };

    this.enqueueNow = function (id) {
        this.dispatch("enqueue_now", id, true);
    };

    this.enqueueNext = function (id) {
        this.dispatch("enqueue_next", id);
    };

    this.enqueueAppend = function (id) {
        this.dispatch("enqueue_append", id);
    };
}
