module AutoSessionTimeoutWarningHelper
  def auto_session_timeout_js(options={})
    frequency = options[:frequency] || 60
    timeout = options[:timeout] || 60
    start = options[:start] || 60
    warning = options[:warning] || 20
    logoutURL = options[:logoutURL]
    code = <<JS
if(typeof(jQuery) != 'undefined'){
  $("#logout_dialog").dialog({
    modal: true,
    width: 500,
    height: 180,
    autoOpen: false,
    dialogClass: "no-close",
    closeOnEscape: false
  });

  $(".logout_dialog").click(function (e) {
    e.preventDefault();
    clearTimeout(timeout);

    $("#logout_dialog").dialog('option', 'buttons',
      [
        {
          text: "Log Out",
          icons: {
            primary: "ui-icon-heart"
          },
          click: function () {
            window.location.href = "#{logoutURL}"
          }
        },
        {
          text: "Stay Logged In",
          icons: {
            primary: "ui-icon-heart"
          },
          click: function () {
            $.get('/renew_session');
            $("#logout_dialog").dialog("close");
            timeout = setTimeout(PeriodicalQuery, (#{start} * 1000));
          }
        }
      ]
    );

    $("#logout_dialog").dialog("open");

    // Remove focus on all buttons within the
    // div with class ui-dialog
    $('.ui-dialog :button').blur();
  });

  function PeriodicalQuery() {
    $.ajax({
      url: '/active',
      success: function(data) {
        if(new Date(data.timeout).getTime() < (new Date().getTime() + #{warning} * 1000)){
          showDialog();
          setTimeout(autoLogout, #{warning} * 1000)
        }
        else {
          timeout = setTimeout(PeriodicalQuery, (#{frequency} * 1000));
        }
        // TODO: Remove, this may not be needed
        if(data.live == false){
          window.location.href = '/timeout';
        }
      }
    });
  }

  var timeout = setTimeout(PeriodicalQuery, (#{start} * 1000));

  function showDialog(){
    $('.logout_dialog').trigger('click');
  }

  function autoLogout() {
    if ($("#logout_dialog").dialog('isOpen')) {
      window.location.href = "#{logoutURL}";
      $("#logout_dialog").dialog("close");
    }
  }
}
JS
    javascript_tag(code)
  end

  # Generates viewport-covering dialog HTML with message in center
  #   options={} are output to HTML. Be CAREFUL about XSS/CSRF!
  def auto_session_warning_tag(options={})
    default_message = "You are about to be logged out due to inactivity.<br/><br/>Please click &lsquo;Continue&rsquo; to stay logged in."
    html_message = options[:message] || default_message
    warning_title = options[:title] || "Logout Warning"
    warning_classes = !!(options[:classes]) ? ' class="' + options[:classes] + '"' : ''

    # Marked .html_safe -- Passed strings are output directly to HTML!
    "<div id='logout_dialog' title='#{warning_title}' style='display:none;'#{warning_classes}>
      #{html_message}
    </div>
    <div class='logout_dialog'></div>".html_safe
  end
end

ActionView::Base.send :include, AutoSessionTimeoutWarningHelper
