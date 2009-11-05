Bigwig
======

Bigwig is a daemon process that listens to a RabbitMQ queue and processes messages that it receives, along with some simple command-line tools to place messages on the queue.   

Typical Usage
-------------

* Install the bigwig gem
* Start an AMQP server
* Create a folder of plugins
* Create a bigwig configuration file
* Start bigwig - `bigwig start -c config -l logs`

Configuration
-------------

Bigwig expects you to give it a configuration file detailing how it is to connect to the AMQP server and how it should respond to incoming messages.  

When invoking bigwig, it looks for a file called bigwig.yml in the current folder.  Alternatively you can specify the configuration file using the `-c` command line option (note that you must supply an absolute path to the file, relative paths will fail).  

A typical configuration file looks like this: 

        user: rabbit-user
        password: crunchycarrots
        vhost: /
        server: my.amqpserver.com
        port: 5672
        queue: myqueue
        warren_logging: false
        plugins_folder: /full/path/to/a/folder

The first six items tell bigwig how to connect to the AMQP server.  The next item specifies whether you want warren (the lower-level AMQP processor) to log its output.  Lastly, you tell bigwig where to find its plugins.  

Logging
-------

When invoking bigwig you should pass it the full path to a folder in which to write its log and pid files.  If not specified, it will use the current folder.  This is done using the `-l` command line option.  

Messages
--------

Bigwig expects messages to be a string which can be deserialised into a Ruby Hash.  The Hash is split into two sections - the "header" and the "data".  

A typical message will look something like this: 

        message = { 
          :id => '123', 
          :method => 'my_command', 
          :data => { 
            :field => 'value', 
            :another_field => 'another_value'
          }
        }

The most important of these is the `:method` key.  Bigwig unpacks this and uses that to lookup which plugin it should invoke (see below).  

Plugins
-------

When bigwig starts it looks through the plugins folder specified within the configuration file (and all its sub-directories).  It then loads all plugins that it finds.  

For example, a plugin, which we shall call LoggingPlugin, would look like this: 

* it should live in a file called `logging_plugin.rb` that is somewhere within your plugins folder
* it should define a class called `LoggingPlugin` that descends from `BigWig::Plugin`
* it should define a class method called `method`
* it should define a class method called `call`

        class LoggingPlugin < BigWig::Plugin
          def self.method
            "logging"
          end
          
          def self.call(task_id, args)
            BigWig.logger.info "LoggingPlugin was invoked with #{args.inspect} as parameters"
          end
        end

When bigwig receives a message where the `:method` parameter == 'logging' it will then invoke `LoggingPlugin#call`, passing it the `:id` and `:data` from the original message as task_id and args respectively.  

If your plugin needs to know where it is on the filesystem (for example, so that it can shell out to run a script) it can access `BigWig::Plugins.root` which returns the folder reference you specified within the configuration file.  

Pings
-----

There is a plugin built-in to bigwig called PingPlugin, that registers itself under the name "ping".  If you place a message onto the queue with :method => 'ping', the PingPlugin responds by writing a message to the log file.  This is useful for monitoring bigwig - another system places ping messages onto the queue at regular intervals and we watch to ensure that the log file's update time is changing.  

Command-line Interface
----------------------

There are two command-line scripts that push messages on to the queue.  

The simplest is `bigwig-ping`.  

This pushes a ping message onto the queue - ideal for calling from a cron job.  This takes two parameters: `-t` (or `--timeout`) which is the connection timeout in seconds (defaulting to 5 if not supplied) and `-c` (or `--config`) which is the path to a Bigwig configuration file (defaulting to bigwig.yml in the current directory if not supplied).  

        bigwig-ping -c /path/to/config -t 10

There is also `bigwig-push`.  

This pushes an arbitrary message onto the queue - ideal for testing, or just manually poking Bigwig to make something happen.  It takes the same `--config` and `--timeout` parameters as bigwig-ping, plus a few more for specifying the message itself.  These are `-m` (or `--method`) which is the method name (for selecting which plugin responds), `-i` (or `--id`) which is the optional task id (useful when linking to an external system) and `-d` (or `--data`) for a hash of values that becomes the `:data` parameter.  

        bigwig-push -m my_message -d '{:key => "value", :key2 => "something else"} -i 123 -c /path/to/config -t 10

License
-------

(c) 2009 Brightbox Systems Ltd.  Released under the MIT License - see LICENSE for more details.  


