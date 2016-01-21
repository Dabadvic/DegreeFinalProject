class Discretizers

	# Función que aplica un discretizador dado
	def self.apply_discretizer(path_to_file, discretizer)
		case discretizer
			when "cluster_analysis"
				toRet = cluster_analysis(path_to_file)
				return toRet
		end
	end

	# Función que aplica el algoritmo de análisis de cluster para la discretización de un dataset
	def self.cluster_analysis(path_to_file)
		toWrite = Array.new

		# Definir parámetros
		toWrite.push("algorithm = Cluster Analysis Discretizer\n")
		toWrite.push("inputData = \"" + path_to_file + "\" \"" + path_to_file + "\"\n")
		output = File.dirname(path_to_file) + "/"
		toWrite.push("outputData = \"" + output + "distra.dat\" " +
						"\"" + output + "distst.dat\" " +
						"\"" + output + "disresult.txt\"\n")

		# Preparar el archivo de configuración
        configuracion = output + "configcluster.txt"
        writeConfigFile(configuracion, toWrite)

		# Ejecutar el comando
		comando = "java -jar " + Rails.root.to_s + "/app/jobs/libraries/Disc-ClusterAnalysis.jar " + configuracion
		ejecucion = system( comando )

		if ejecucion == true
        	toRet = output + "distra.dat"
        else
        	toRet = "error"
        end

        return toRet

	end

	# Función auxiliar para escribir un archivo de configuración
    def self.writeConfigFile(path, toWrite)
        config_file = open(path, "w")
        toWrite.each { |line| config_file.write(line) }
        config_file.close
    end
end