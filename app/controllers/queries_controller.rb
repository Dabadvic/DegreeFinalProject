require "algorithms_job"

class QueriesController < ApplicationController
	before_action :logged_in_user, only: [:create, :confirm, :destroy, :list, :new, :show]
	before_action :can_view, only: [:show]

	def create
		@user = current_user
		@query = @user.queries.build(query_params)

		if @query.save
			flash[:success] = "Nuevo experimento creado con éxito " 

			# Añade la consulta a la cola de espera y pasa el id para actualizarla al acabar
			Resque.enqueue(Algorithms, @query.id, @query.options)

			redirect_to queries_path
		else
	  		render :confirm
	  	end
	end

	def confirm
		@query = Query.new(query_params)

		@query.options = Array.new

		if !@query.description?
			flash.now[:danger] = "Tienes que introducir una descripción"
			render :new
		end
	end

	def destroy	
		# Se borra también la carpeta, el background job y archivos relacionados
		query = Query.find(params[:id])
		direccion = File.dirname(query.queryfile.current_path.to_s)
		Resque::Job.destroy('queries', 'Algorithms', query.id)

		query.destroy
		FileUtils.rm_rf(direccion)
		
		flash[:success] = "Experimento eliminado"
		redirect_to request.referrer
	end

	def new
	  	@query = Query.new
	end

	def list
		@user = current_user
		@queries = @user.queries
	end

	def show
		@query = Query.find(params[:id])
		if @query.result?
			@resultado = eval(@query.result)
		else
			@resultado = nil
		end

		files_path = File.dirname(@query.queryfile.current_path.to_s)
		# Ubicación del fichero resultado de discretizar
		@dis_file = files_path + "/disresult.txt"

		case @query.status
		when "waiting"
			@estado = "Esperando a ser atendido"
		when "processing"
			@estado = "En proceso de ejecución"
		when "finished"
			@estado = "Experimento finalizado"
		end

		case @query.algorithm
		when "cn2"
			@config_file = files_path + "/configuracionCN2.txt"
		when "mesdif"
			@config_file = files_path + "/configuracionMESDIF.txt"
		when "sdmap"
			@config_file = files_path + "/configuracionSDMap.txt"
		when "sd"
			@config_file = files_path + "/configuracionSDAlgorithm.txt"
		when "sdiga"
			@config_file = files_path + "/configuracionSDIGA.txt"
		when "apriorisd"
			@config_file = files_path + "/configuracionAprioriSD.txt"
		else
			@config_file = files_path + "/no_file.txt"
		end
			
	end

	private

	  def query_params
	  	params.require(:query).permit(:description, :queryfile, :algorithm, :discretization, :options => [])
	  end

	  # Confirms the user can see a query.
	  	def can_view
	  		@query = Query.find(params[:id])
	    	@user = current_user

	    	redirect_to(queries_path) unless @user.id == @query.user.id
	  	end

end
