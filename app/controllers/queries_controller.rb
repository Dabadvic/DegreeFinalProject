require "algorithms_job"

class QueriesController < ApplicationController
	before_action :logged_in_user, only: [:create, :destroy, :list, :new]

	def create
		@user = current_user
		@query = @user.queries.build(query_params)

		if @query.save
			flash[:success] = "Nueva consulta creada con éxito"

			# Añade la consulta a la cola de espera y pasa el id para actualizarla al acabar
			Resque.enqueue(Algorithms, @query.id)

			redirect_to queries_path
		else
	  		render 'new'
	  	end
	end

	def destroy	
		# Se borra también la carpeta y archivos relacionados
		query = Query.find(params[:id])
		direccion = File.dirname(query.queryfile.current_path.to_s)

		query.destroy
		FileUtils.rm_rf(direccion)
		
		flash[:success] = "Consulta eliminada"
		redirect_to request.referrer
	end

	def new
	  	@query = Query.new
	  	@options = [['- Requieren discretizar:', "re_dis"], ['Apriori', "apriori"], ['CN2-SD', "cn2"], ['SD-Map', "sdmap"], 
	  				['SD-Algorithm', "sd"], ['- No requieren discretizar:', "no_dis"], ['MESDIF', "mesdif"], 
	  				['SDIGA', "sdiga"]]
	 end

	def list
		@user = current_user
		@queries = @user.queries
	end

	def show
		@query = Query.find(params[:id])
		if @query.result?
			@resultado = @query.result
		end
	end

	private

	  def query_params
	  	params.require(:query).permit(:description, :queryfile, :algorithm)
	  end

end
