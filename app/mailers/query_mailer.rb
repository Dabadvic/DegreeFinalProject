class QueryMailer < ApplicationMailer

  def query_finished(user, query_id)
  	@user = user
  	@query = Query.find(query_id)
    mail to: user.email, subject: "Consulta finalizada"
  end

end