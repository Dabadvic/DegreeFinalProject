# encoding: utf-8

require "java"
require "libraries/weka.jar"
require "libraries/conversorWeka2Keel.jar"
require "discretizers"

java_import "weka.associations.Apriori"

java_import "weka.core.Instances"
java_import "java.io.BufferedReader"
java_import "java.io.FileReader"
java_import "java.lang.System"

java_import "conversor.WekaToKeel"

# Clase usada para contener los diferentes algoritmos
class Algorithms
	def self.queue
    	:queries
  	end

  	def self.perform(query_id)
  		puts 'Query: ' + query_id.to_s
        query = Query.find(query_id)
        file_path = query.queryfile.current_path.to_s

        puts '¿Hay que aplicar discretizador?' + query.discretization
        if query.discretization != "none"
            puts 'Sí, comprobando si hay que convertir el archivo a .dat'
            convertedInput = conversorKeel(file_path)
            file_path = Discretizers.apply_discretizer(convertedInput, query.discretization)
        end
  		
  		puts 'Inicia algoritmo: ' + query.algorithm
  		query.status = 1
  		puts 'Estado: ' + query.status
  		query.save
  		query.result = aplicar(file_path, query.algorithm)
  		puts 'Finaliza algoritmo'
  		query.status = 2
  		puts 'Estado: ' + query.status
  		query.save

        # Si estamos en la página de consultas, recargar al acabar
  	end

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
			when "mesdif"
				toRet = mesdif(file)
				return toRet
            when "sdmap"
                toRet = sdmap(file)
                return toRet
            when "sd"
                toRet = sd(file)
                return toRet
            when "sdiga"
                toRet = sdiga(file)
                return toRet
		end
	end

    # Función auxiliar para escribir un archivo de configuración
    def self.writeFile(path, toWrite)
        config_file = open(path, "w")
        toWrite.each { |line| config_file.write(line) }
        config_file.close
    end

	# Comprueba si hay que convertir el archivo a Keel, devolviendo la ubicación final del archivo en un string
	def self.conversorKeel(file)
		# Comprobación previa del fichero para realizar conversión o no
		
	  	case File.extname(file)
	  	
	  	when ".arff"
	  		# Convertir a .dat de Keel
	  		fileTrans = WekaToKeel.new();
	  		fileInput = file
	  		fileOutput = File.dirname(file) + "/" + File.basename(file, ".*").downcase + ".dat"
	        fileTrans.Start(fileInput, fileOutput)
	  	when ".dat"
	  		# no hacer nada
	  		fileOutput = file
	  	end

	  	return fileOutput
	end

	# Función Apriori, aplica el alogirtmo apriori de Weka
	  def self.apriori(file)
	  	# Se leen los datos
		reader = BufferedReader.new(FileReader.new(file))
        data = Instances.new(reader)
        reader.close()

		# Algoritmo Apriori
		_model = Apriori.new()
		
		# Se construye el modelo
		_model.buildAssociations(data)

		# Obtenemos el resultado
		toWrite = Array.new
        toWrite.push(_model.toString())

        toRet = Array.new
        toRet.push(File.dirname(file) + "/result0.txt")

        writeFile(toRet[0], toWrite)

		return toRet

	  end

	  # Función CN2, aplica el algoritmo CN2-SD de Keel
	  def self.cn2sd(file)
	  	# Comprobamos si hay que convertirlo, devolviendo un string con la ubicación final
	  	convertedInput = conversorKeel(file)

        toWrite = Array.new
        toRet = Array.new

	  	# Se definen los parámetros del algoritmo
	  	toWrite.push("algorithm = CN2 Algorithm for Subgroup Discovery\n") 
	  	toWrite.push("inputData = " + "\"" + convertedInput + "\" " + "\"" + convertedInput + "\" " +"\"" + convertedInput + "\"\n")
        output = File.dirname(file) + "/result"
        toWrite.push("outputData = " + "\"" + output + ".tra\" " + "\"" + output + ".tst\" " + "\"" + output + ".txt\"\n")
        toWrite.push("\n")        
        toWrite.push("Nu_Value = 0.5\n")
        toWrite.push("Percentage_Examples_To_Cover = 0.95\n")
        toWrite.push("Star_Size = 5\n")
        toWrite.push("Use_multiplicative_weights = YES\n")
        toWrite.push("Use_Disjunt_Selectors = NO")


        # Preparar el archivo de configuración
        configuracion = File.dirname(file) + "/configuracionCN2.txt"
        writeFile(configuracion, toWrite)

        # Ejecutar el comando para aplicar el algoritmo
        comando = "java -jar " + Rails.root.to_s + "/app/jobs/libraries/CN2SD.jar " + configuracion
        ejecucion = system( comando )

        if ejecucion == true
            toRet.push(output + ".txt")
        else
        	toRet = "error"
        end

        return toRet
	  end

	  # Función MESDIF, aplica el algoritmo MESDIF-SD de Keel
	  def self.mesdif(file)
	  	# Comprobamos si hay que convertirlo, devolviendo un string con la ubicación final
	  	convertedInput = conversorKeel(file)

        toWrite = Array.new
        toRet = Array.new

	  	# Se definen los parámetros del algoritmo
	  	toWrite.push("algorithm = MESDIF for Subgroup Discovery\n")
	  	toWrite.push("inputData = " + "\"" + convertedInput + "\" " + "\"" + convertedInput + "\" " +"\"" + convertedInput + "\"\n")
        output = File.dirname(file) + "/result"
        toWrite.push("outputData = " + "\"" + output + "0.tra\" " + "\"" + output + "0.tst\" " + "\"" + output + "0e0.txt\" " + 
        							   "\"" + output + "0e1.txt\" " + "\"" + output + "0e2.txt\" " + "\"" + output + "0e3.txt\"\n")
        toWrite.push("\n")
        toWrite.push("RulesRep = can\n")
		toWrite.push("nLabels = 3\n")
		toWrite.push("nEval = 10000\n")
		toWrite.push("popLength = 100\n")
		toWrite.push("crossProb = 0.6\n")
		toWrite.push("mutProb = 0.01\n")
		toWrite.push("eliteLength = 3\n")
		toWrite.push("Obj1 = comp\n")
		toWrite.push("Obj2 = unus\n")
		toWrite.push("Obj3 = fcnf\n")
		toWrite.push("Obj4 = null\n")


        # Preparar el archivo de configuración
        configuracion = File.dirname(file) + "/configuracionMESDIF.txt"
        writeFile(configuracion, toWrite)

        # Ejecutar el comando para aplicar el algoritmo
        comando = "java -jar " + Rails.root.to_s + "/app/jobs/libraries/MESDIF.jar " + configuracion
        ejecucion = system( comando )

        if ejecucion == true
            toRet.push(output + "0e0.txt")
            toRet.push(output + "0e1.txt")
            toRet.push(output + "0e2.txt")
            toRet.push(output + "0e3.txt")
        else
        	toRet = "error"
        end

        return toRet
	  end

      # Función sdmap, aplica el algoritmo SDMap-SD de Keel
      def self.sdmap(file)
        # Comprobamos si hay que convertirlo, devolviendo un string con la ubicación final
        convertedInput = conversorKeel(file)

        toWrite = Array.new
        toRet = Array.new

        # Se definen los parámetros del algoritmo
        toWrite.push("algorithm = SDMap for Subgroup Discovery\n")
        toWrite.push("inputData = " + "\"" + convertedInput + "\" " + "\"" + convertedInput + "\" " +"\"" + convertedInput + "\"\n")
        output = File.dirname(file) + "/result"
        toWrite.push("outputData = " + "\"" + output + "0.tra\" " + "\"" + output + "0.tst\" " + "\"" + output + "0e0.txt\" " + 
                                       "\"" + output + "0e1.txt\" " + "\"" + output + "0e2.txt\" " + "\"" + output + "0e3.txt\"\n")
        toWrite.push("\n")
        toWrite.push("MinimumSupport = 0.1\n")
        toWrite.push("MinimumConfidence = 0.8\n")
        toWrite.push("RulesReturn = 10\n")
        toWrite.push("algorithm = SD-Map\n")


        # Preparar el archivo de configuración
        configuracion = File.dirname(file) + "/configuracionSDMap.txt"
        writeFile(configuracion, toWrite)

        # Ejecutar el comando para aplicar el algoritmo
        comando = "java -jar " + Rails.root.to_s + "/app/jobs/libraries/SDMap.jar " + configuracion
        ejecucion = system( comando )

        if ejecucion == true
            toRet.push(output + "0e0.txt")
            toRet.push(output + "0e1.txt")
            toRet.push(output + "0e2.txt")
            toRet.push(output + "0e3.txt")
        else
            toRet = "error"
        end

        return toRet
      end

      # Función sd, aplica el algoritmo SD de Keel
      def self.sd(file)
        # Comprobamos si hay que convertirlo, devolviendo un string con la ubicación final
        convertedInput = conversorKeel(file)

        toWrite = Array.new
        toRet = Array.new

        # Se definen los parámetros del algoritmo
        toWrite.push("algorithm = SDAlgorithm for Subgroup Discovery\n")
        toWrite.push("inputData = " + "\"" + convertedInput + "\" " + "\"" + convertedInput + "\" " +"\"" + convertedInput + "\"\n")
        output = File.dirname(file) + "/result"
        toWrite.push("outputData = " + "\"" + output + "0.tra\" " + "\"" + output + "0.tst\" " + "\"" + output + "0e0.txt\" " + 
                                       "\"" + output + "0e1.txt\" " + "\"" + output + "0e2.txt\" " + "\"" + output + "0e3.txt\"\n")
        toWrite.push("\n")
        toWrite.push("algorithm = SDAlgorithm\n")
        toWrite.push("g = 10\n")
        toWrite.push("minSupp = 0.1\n")
        toWrite.push("beamWidth = 5\n")
        toWrite.push("numRules = 0\n")

        # Preparar el archivo de configuración
        configuracion = File.dirname(file) + "/configuracionSDAlgorithm.txt"
        writeFile(configuracion, toWrite)

        # Ejecutar el comando para aplicar el algoritmo
        comando = "java -jar " + Rails.root.to_s + "/app/jobs/libraries/SDAlgorithm.jar " + configuracion
        ejecucion = system( comando )

        if ejecucion == true
            toRet.push(output + "0e0.txt")
            toRet.push(output + "0e1.txt")
            toRet.push(output + "0e2.txt")
            toRet.push(output + "0e3.txt")
        else
            toRet = "error"
        end

        return toRet
      end

      # Función sdiga, aplica el algoritmo SDIGA de Keel
      def self.sdiga(file)
        # Comprobamos si hay que convertirlo, devolviendo un string con la ubicación final
        convertedInput = conversorKeel(file)

        toWrite = Array.new
        toRet = Array.new

        # Se definen los parámetros del algoritmo
        toWrite.push("algorithm = SD-SDIGA for Subgroup Discovery\n")
        toWrite.push("inputData = " + "\"" + convertedInput + "\" " + "\"" + convertedInput + "\" " +"\"" + convertedInput + "\"\n")
        output = File.dirname(file) + "/result"
        toWrite.push("outputData = " + "\"" + output + "0.tra\" " + "\"" + output + "0.tst\" " + "\"" + output + "0e0.txt\" " + 
                                       "\"" + output + "0e1.txt\" " + "\"" + output + "0e2.txt\" " + "\"" + "\"" + output + "0e3.txt\" " + 
                                       "\"" + output + "0e4.txt\" " + "\"" +"\"" + output + "0e5.txt\"\n")
        toWrite.push("\n")
        toWrite.push("RulesRep = can\n")
        toWrite.push("nLabels = 3\n")
        toWrite.push("nEval = 10000\n")
        toWrite.push("popLength = 100\n")
        toWrite.push("crossProb = 0.6\n")
        toWrite.push("mutProb = 0.01\n")
        toWrite.push("minConf = 0.6\n")
        toWrite.push("lSearch = yes\n")
        toWrite.push("Obj1 = comp\n")
        toWrite.push("Obj2 = fcnf\n")
        toWrite.push("Obj3 = unus\n")
        toWrite.push("w1 = 0.4\n")
        toWrite.push("w2 = 0.3\n")
        toWrite.push("w3 = 0.3\n")


        # Preparar el archivo de configuración
        configuracion = File.dirname(file) + "/configuracionSDIGA.txt"
        writeFile(configuracion, toWrite)

        # Ejecutar el comando para aplicar el algoritmo
        comando = "java -jar " + Rails.root.to_s + "/app/jobs/libraries/SDIGA.jar " + configuracion
        ejecucion = system( comando )

        if ejecucion == true
            toRet.push(output + "0e0.txt")
            toRet.push(output + "0e1.txt")
            toRet.push(output + "0e2.txt")
            toRet.push(output + "0e3.txt")
            toRet.push(output + "0e4.txt")
            toRet.push(output + "0e5.txt")
        else
            toRet = "error"
        end

        return toRet
      end
end