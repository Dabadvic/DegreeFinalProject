# TrabajoFinGrado

## Synopsis

Application for the extraction of descriptive rules. Applies different Subgroup Discovery algorithms for the extraction of interesting groups within a dataset.

The project is made using JRuby on Rails mainly. The implementation of the algorithms is taken from the project [KEEL](http://www.keel.es/)(Knowledge Extraction based on Evolutionary Learning).

Gems that also makes use of: [resque](https://github.com/resque/resque) for queing jobs, [puma](http://puma.io/) as server and [carrierwave](https://github.com/carrierwaveuploader/carrierwave) for file upload, among others.

## Motivation

The main motivation of this project is to simplify the use of Subgroup Discovery, specially applied to medical datasets. With this application, analists would not need of any other program with everything that it implies, e.g., installation and execution of experiments (which can take a lot of time depending on the dataset).

This project also exists as a result of my final project for my Computer Science Degree.

## Installation

Provide code examples and explanations of how to get the project.

**Step 1**. First we need to install JRuby, you can use whatever mean you want, I went with [RVM](https://rvm.io/) which you can easily install following the instructions from their webpage. Anyway I did it like this using the command line in Ubuntu 15.04:
```
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
```
```
\curl -sSL https://get.rvm.io | bash -s stable
```
For the latest version of RVM, which includes the latest version of JRuby.:
```
rvm get head
```
Installing everything that Ruby needs:
```
rvm requirements
```
Finally, install JRuby:
```
rvm install jruby
```
And set JRuby to use:
```
rvm use jruby (include --default if you will only use JRuby)
```
Remember to install also Rails:
```
gem install rails
```

**Step 2**. Next step is to install Apache:
```
sudo apt-get install apache2
```

**Step 3**. Install Passenger, web server for JRuby on Rails:
```
# Install PGP key and add HTTPS support for APT
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
sudo apt-get install -y apt-transport-https ca-certificates

# Add APT repository
sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list'
sudo apt-get update

# Install Passenger + Apache module
sudo apt-get install -y libapache2-mod-passenger
```

**Step 4**. With this repository downloaded, install all the gems and migrate the database. Firs move to the repository folder:
```
cd ./myrepository
bundle install
rake db:migrate
```
Also install *Redis* for the *Resque* gem to work:
```
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make
make test (it is a good idea to test if it worked)
sudo make install
cd utils
sudo ./install_server.sh (to run the configuration file)
```

Now we can test if the application works localy, just make:
```
rails s
```
Remember to set up at least one worker (more info at [resque](https://github.com/resque/resque)):
```
jruby -S rake resque:work QUEUE='*'
```

Yendo a la dirección que nos indica, normalmente localhost:3000, podremos comprobar que funciona correctamente.

**Step 5**. Deploy the application. First I created a new file in:
```
/etc/apache2/sites-available/app_name.conf (where app_name is the name I chose for the application)
```
And I put this there:
```
PassengerRuby /home/david/.rvm/gems/jruby-9.0.4.0/wrappers/ruby
PassengerSpawnMethod direct

<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	DocumentRoot /path/to/project/public
	RailsEnv development

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined

	<Directory "/path/to/project/public">
		Options FollowSymLinks
		Require all granted
	</Directory>
</VirtualHost>
```
You can add this if you have a server name:
```
ServerName example.com
ServerAlias www.example.com
```
But it is okay if you do not, as you will have it available at your IP address.

Edit the config/environments/development.rb file, adding this for the use of a gmail account for email sending. It is used when a new user is registered, to send an activation link:
```
# Configuración de correo
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.default_url_options = { :host => "your_hostname_or_ip" }
    config.action_mailer.smtp_settings = {
      address:              'smtp.gmail.com',
      port:                 587,
      domain:               'example.com',
      user_name:            'your_gmail_user',
      password:             'your_gmail_password',
      authentication:       'plain',
      enable_starttls_auto: true  }
```
You will have to change the host, user_name and password fields, and put your own information. There are other methods, but I preferred the gmail account as it seemed easier at the moment.

**Step 6**. Activate the web application, remembering that you should set your router to forward the port 80 so it can be accesible from anywhere. Then just deactivate default (unless you have already done it) and activate the wep application in apache:
```
sudo a2dissite 000-default
sudo a2ensite app_name (the same name you put before to the config file)
sudo service apache2 reload
```

**Step 7**. We are finally there! Just go to your IP address or external name domain (if you set it) to try the application.

## Tests

If you make any change and you want to be sure that everything will work, besides trying it you can also run this command in the application root directory:
```
bundle exec rake test
```
Note: This can have some errors in the account activation step, as tests have difficulties with the host name.

## Contributors

You can fork this project or contribute as long as you mention it.

## License

[GPLv3](http://www.gnu.org/licenses/licenses.html#GPL)
