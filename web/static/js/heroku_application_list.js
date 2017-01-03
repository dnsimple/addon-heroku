var HerokuApplicationList = {
  init: function link($) {
    this.$ = $;
    var input = document.getElementById("js-heroku-application-input");
    if (input != null) {
      this.initAwesomplete(input);
      this.loadApplications();
    }
  },

  initAwesomplete: function(input) {
    this.awesomplete = new Awesomplete(input);
    this.awesomplete.minChars = 1;
    this.awesomplete.autoFirst = true;
  },

  loadApplications: function() {
    var that = this;

    this.$.get("/heroku/applications")
    .done(function(response) {
      that.awesomplete.list = response.apps;
    })
    .fail(function(error) {
      console.log(error);
    });
  }
};

module.exports = {
  HerokuApplicationList: HerokuApplicationList
};

