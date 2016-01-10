require "java"
require "libraries/weka.jar"
require "libraries/conversorWeka2Keel.jar"

java_import "weka.associations.Apriori"

java_import "weka.core.Instances"
java_import "java.io.BufferedReader"
java_import "java.io.FileReader"
java_import "java.lang.System"

java_import "conversor.WekaToKeel"

# Clase usada para contener los diferentes algoritmos
class Algorithms

	# Aplica un algoritmo a un archivo y devuelve la ubicación del fichero resultado
	def self.aplicar(file, algorithm)
		# Aplicar SD (En un futuro, añadir a lista de espera para SD)
		case algorithm
			when "apriori"
				toRet = apriori(file)
				return toRet
			when "cn2"
				toRet = cn2sd(file)
				return toRet
		end
	end

	# Función Apriori, aplica el alogirtmo apriori de Weka
	  def self.apriori(file)
	  	# Se leen los datos
		reader = BufferedReader.new(FileReader.new(file.current_path))
        data = Instances.new(reader)
        reader.close()

		# Algoritmo Apriori
		_model = Apriori.new()
		
		# Se construye el modelo
		_model.buildAssociations(data)

		# Obtenemos el resultado
		toRet = _model.toString()

		return toRet

	  end

	  # Función CN2, aplica el algoritmo CN2-SD de Keel, NO REALIZA CONVERSIÓN A FORMATO KEEL
	  def self.cn2sd(file)
	  	sleep(2)

	  	# Comprobación previa del fichero para realizar conversión o no
	  	case File.extname(file.to_s)
	  	
	  	when ".arff"
	  		# Convertir a .dat de Keel
	  		fileTrans = WekaToKeel.new();
	  		fileInput = file.current_path.to_s
	  		fileOutput = File.dirname(file.current_path) + "/" + File.basename(file.to_s) + ".dat"
	        fileTrans.Start(fileInput, fileOutput)
	  	when ".dat"
	  		#no hace nada
	  		
	  	end

	  	# Se definen los parámetros del algoritmo
	  	algorithm = "algorithm = CN2 Algorithm for Subgroup Discovery\n"
	  	inputData = "inputData = " + "\"" + file.current_path + "\" " + "\"" + file.current_path + "\" " +"\"" + file.current_path + "\"\n"
        output = File.dirname(file.current_path) + "/result"
        outputData = "outputData = " + "\"" + output + ".tra\" " + "\"" + output + ".tst\" " + "\"" + output + ".txt\"\n"
        
        nu_value = "Nu_Value = 0.5\n"
        percentage = "Percentage_Examples_To_Cover = 0.95\n"
        star_size = "Star_Size = 5\n"
        multiplicative = "Use_multiplicative_weights = YES\n"
        disjunt = "Use_Disjunt_Selectors = NO"


        # Preparar el archivo de configuración
        configuracion = File.dirname(file.current_path) + "/configuracionCN2.txt"

        config_file = open(configuracion, "w")

        config_file.write(algorithm)
        config_file.write(inputData)
        config_file.write(outputData)
        config_file.write("\n")
        config_file.write(nu_value)
        config_file.write(percentage)
        config_file.write(star_size)
        config_file.write(multiplicative)
        config_file.write(disjunt)

        config_file.close

        # Ejecutar el comando para aplicar el algoritmo
        comando = "java -jar /home/david/Documentos/TFG/proyectoJruby/app/controllers/libraries/CN2SD.jar " + configuracion

        ejecucion = system( comando )

        if ejecucion == true
        	toRet = output + ".txt"
        else
        	toRet = "error"
        end

        return toRet
	  end
end

class QueriesController < ApplicationController
	before_action :logged_in_user, only: [:create, :destroy, :list, :new]

	def create
		@user = current_user
		@query = @user.queries.build(query_params)

		if @query.save
			flash[:success] = "Nueva consulta creada con éxito"

			# Aplicar SD (En un futuro, añadir a lista de espera para SD)
			@query.result = Algorithms.aplicar(@query.queryfile, @query.algorithm)
			
			# Actualizar la consulta?
			@query.save

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
