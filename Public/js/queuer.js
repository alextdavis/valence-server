function Queuer() {
    this.directPlay = function (id) {
        this.dispatch("direct_play", id);
    };

    this.enqueueNext = function (id) {
        this.dispatch("enqueue_next", id);
    };

    this.enqueueAppend = function (id) {
        this.dispatch("enqueue_append", id);
    };

    //private
    this.dispatch = function(message, id) {
        var self = this;
        $.ajax({
            url: "/q/dispatch",
            method: "post",
            data: {message: message, id: id}
        });
    }
}
