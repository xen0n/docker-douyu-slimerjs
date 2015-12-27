var args = require('system').args;
var page = require('webpage').create();


/*
page.onConsoleMessage = function(msg) {
  console.log(msg);
};
*/


page.onInitialized = function() {
  page.evaluate(function() {
    document.addEventListener('DOMContentLoaded', function() {
      var RE = /^type@=setmsggroup\/rid@=(\d+)\/gid@=(\d+)\/$/;

      window.onDouyuSideChannelMsgS = function(msg) {
        var result = RE.exec(msg);
        if (!result) {
          return;
        }

        var rid = result[1];
        var gid = result[2];
        window.callPhantom(rid + "," + gid);
      };

      // force quit after 30 seconds
      window.setTimeout(function() {
       window.callPhantom("-1,-1");
      },30000);
    }, false);
  });
};


page.onCallback = function(data) {
  var result = /^(-?\d+),(-?\d+)$/.exec(data);
  var rid = parseInt(result[1]);
  var gid = parseInt(result[2]);

  console.log("/******** DOUYU rid=" + rid + " gid=" + gid + " ********/");
  phantom.exit(rid === -1 && gid === -1 ? 1 : 0);
};


page.open('http://www.douyutv.com/' + args[1], function() {
});


// vim:set ai et ts=2 sw=2 sts=2 fenc=utf-8:
