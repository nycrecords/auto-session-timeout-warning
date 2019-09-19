module AutoSessionTimeoutWarning

  def self.included(controller)
    controller.extend ClassMethods
  end

  module ClassMethods
    def auto_session_timeout(seconds=nil)
      prepend_before_action do |c|
        if c.session[:auto_session_expires_at] && c.session[:auto_session_expires_at] < Time.now
          c.send :before_timedout
          saml_uid = session['saml_uid']
          c.send :reset_session
          session['saml_uid'] = saml_uid
        else
          unless c.request.original_url.start_with?(c.send(:active_url, locale: nil))
            offset = seconds || (current_user.respond_to?(:auto_timeout) ? current_user.auto_timeout : nil)
            c.session[:auto_session_expires_at] = Time.now + offset if offset && offset > 0
          end
        end
      end
    end

    def auto_session_timeout_actions
      define_method(:active) { render_session_status }
      define_method(:timeout) { render_session_timeout }
      define_method(:renew) { render_session_renew }
    end

    def before_timedout_action
      define_method(:before_timedout){}
      send(:protected, :before_timedout)
    end
  end

  def render_session_status
    response.headers["Etag"] = ""  # clear etags to prevent caching
    render json: {live: !!current_user, timeout: session[:auto_session_expires_at]}
  end

  def render_session_timeout
    flash[:notice] = "Your session has timed out."
    redirect_to "/login"
  end

  def render_session_renew; end
end

ActionController::Base.send :include, AutoSessionTimeoutWarning
