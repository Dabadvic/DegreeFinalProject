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
java_import "conversor.KeelToWeka"

# Clase usada para contener los diferentes algoritmos
class Algorithms
	def self.queue
    	:queries
  	end

  	def self.perform(query_id, options)
  		puts 'Query: ' + query_id.to_s
        puts 'Options: ' + options.to_s
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
  		puts query.save
        #puts 'errores: ' + query.errors.full_messages.to_s
        
        query.result = aplicar(file_path, query.algorithm, options)
        query.send_finished_email
  		puts 'Finaliza algoritmo'
  		query.status = 2
  		puts 'Estado: ' + query.status
  		query.save

        # Si estamos en la página de consultas, recargar al acabar
  	end

	# Aplica un algoritmo a un archivo y devuelve la ubicación del fichero resultado
	def self.aplicar(file, algorithm, options)
		# Aplicar SD (En un futuro, añadir a lista de espera para SD)
		case algorithm
			when "apriorisd"
				toRet = apriorisd(file, options)
				return toRet
			when "cn2"
				toRet = cn2sd(file, options)
				return toRet
			when "mesdif"
				toRet = mesdif(file, options)
				return toRet
            when "sdmap"
                toRet = sdmap(file, options)
                return toRet
            when "sd"
                toRet = sd(file, options)
                return toRet
            when "sdiga"
                toRet = sdiga(file, options)
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

    def self.conversorWeka(file)
        # Comprobación previa del fichero para realizar conversión o no
        
        case File.extname(file)
        
        when ".arff"
            # no hacer nada
            fileOutput = file
        when ".dat"
            # Convertir a .dat de Keel
            fileTrans = KeelToWeka.new();
            fileInput = file
            fileOutput = File.dirname(file) + "/" + File.basename(file, ".*").downcase + ".arff"
            fileTrans.Start(fileInput, fileOutput)
        end

        return fileOutput
    end

	# Función Apriori, aplica el alogirtmo apriori de Weka
	  def self.apriorisd(file, options)
        # Comprobamos si hay que convertirlo, devolviendo un string con la ubicación final
        convertedInput = conversorKeel(file)

        toWrite = Array.new
        toRet = Array.new

        # Se definen los parámetros del algoritmo
        toWrite.push("algorithm = Apriori Algorithm for Subgroup Discovery\n") 
        toWrite.push("inputData = " + "\"" + convertedInput + "\" " + "\"" + convertedInput + "\" " +"\"" + convertedInput + "\"\n")
        output = File.dirname(file) + "/result"
        toWrite.push("outputData = " + "\"" + output + ".tra\" " + "\"" + output + ".tst\" " + "\"" + output + ".txt\"\n")
        toWrite.push("\n")        
        toWrite.push("MinSupport = " + options[0] + "\n")
        toWrite.push("MinConfidence = " + options[1] + "\n")
        toWrite.push("Number_of_Rules = " + options[2] + "\n")
        toWrite.push("Postpruning_type = SELECT_N_RULES_PER_CLASS\n")


        # Preparar el archivo de configuración
        configuracion = File.dirname(file) + "/configuracionAprioriSD.txt"
        writeFile(configuracion, toWrite)

        # Ejecutar el comando para aplicar el algoritmo
        comando = "java -jar " + Rails.root.to_s + "/app/jobs/libraries/aprioriSD.jar " + configuracion
        ejecucion = system( comando )

        if ejecucion == true
            toRet.push(output + ".txt")
        else
            toRet = "error"
        end

        return toRet
	  end

	  # Función CN2, aplica el algoritmo CN2-SD de Keel
	  def self.cn2sd(file, options)
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
        toWrite.push("Nu_Value = " + options[0] + "\n")
        toWrite.push("Percentage_Examples_To_Cover = " + options[1] + "\n")
        toWrite.push("Star_Size = " + options[2] + "\n")
        toWrite.push("Use_multiplicative_weights = " + options[3] + "\n")
        toWrite.push("Use_Disjunt_Selectors = " + options[4])


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
	  def self.mesdif(file, options)
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
		toWrite.push("nLabels = "+ options[0] +"\n")
		toWrite.push("nEval = "+ options[1] +"\n")
		toWrite.push("popLength = "+ options[2] +"\n")
		toWrite.push("crossProb = "+ options[3] +"\n")
		toWrite.push("mutProb = "+ options[4] +"\n")
		toWrite.push("eliteLength = "+ options[5] +"\n")
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
      def self.sdmap(file, options)
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
        toWrite.push("MinimumSupport = "+ options[0] +"\n")
        toWrite.push("MinimumConfidence = "+ options[1] +"\n")
        toWrite.push("RulesReturn = "+ options[2] +"\n")
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
      def self.sd(file, options)
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
        toWrite.push("g = "+ options[0] +"\n")
        toWrite.push("minSupp = "+ options[1] +"\n")
        toWrite.push("beamWidth = "+ options[2] +"\n")
        toWrite.push("numRules = "+ options[3] +"\n")

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
      def self.sdiga(file, options)
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
        toWrite.push("nLabels = "+ options[0] +"\n")
        toWrite.push("nEval = "+ options[1] +"\n")
        toWrite.push("popLength = "+ options[2] +"\n")
        toWrite.push("crossProb = "+ options[3] +"\n")
        toWrite.push("mutProb = "+ options[4] +"\n")
        toWrite.push("minConf = "+ options[5] +"\n")
        toWrite.push("lSearch = "+ options[6] +"\n")
        toWrite.push("Obj1 = comp\n")
        toWrite.push("Obj2 = fcnf\n")
        toWrite.push("Obj3 = unus\n")
        toWrite.push("w1 = "+ options[7] +"\n")
        toWrite.push("w2 = "+ options[8] +"\n")
        toWrite.push("w3 = "+ options[9] +"\n")


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