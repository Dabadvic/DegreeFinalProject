class SleepingJob
  def self.queue
    :sloth
  end

  def self.perform
    puts 'I like to sleep'
    sleep 2
  end
end
