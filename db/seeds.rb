# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.create!(name: "Example User",
			 email: "example@railstutorial.org",
			 password: "foobar",
			 password_confirmation: "foobar",
			 activated: true,
			 activated_at: Time.zone.now)

User.create!(name: "Usuario Ejemplo",
			 email: "usuario@ejemplo.org",
			 password: "usuario",
			 password_confirmation: "usuario",
			 activated: true,
			 activated_at: Time.zone.now)

User.create!(name: "David Abad",
			 email: "davidabad10@gmail.com",
			 password: "davidabad",
			 password_confirmation: "davidabad",
			 activated: true,
			 activated_at: Time.zone.now)


usuario = User.find(2)
usuario.queries.create!(description: "Consulta reciente", created_at: 10.minutes.ago)
usuario.queries.create!(description: "Consulta ya finalizada", created_at: 2.years.ago, 
						status: 2, finished_at: 20.minutes.ago)
usuario.queries.create!(description: "Consulta todavía en espera", created_at: 1.year.ago, 
						status: 1)