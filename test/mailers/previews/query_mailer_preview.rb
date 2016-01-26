# Preview all emails at http://localhost:3000/rails/mailers/query_mailer
class QueryMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/query_mailer/query_finished
  def query_finished
  	user = User.find(3)
    query = user.queries.first
    QueryMailer.query_finished(user, query.id)
  end

end
