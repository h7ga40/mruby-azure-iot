
module WeatherStation
	class ContosoAnemometer
		attr_reader :windSpeed, :temperature, :humidity

		def initialize
			@fanSpeed = 28
		end

		def quit(peyload)
			puts "execute quit " + peyload
			"{\"Message\":\"quit with Method\"}"
		end

		def turnFanOn(peyload)
			puts "execute turnFanOn " + peyload
			"{\"Message\":\"Turning fan on with Method\"}"
		end

		def turnFanOff(peyload)
			puts "execute turnFanOff " + peyload
			"{\"Message\":\"Turning fan off with Method\"}"
		end

		def get_temperature_alert
			(@temperature > 30) ? 'true' : 'false'
		end

		def set_fan_speed(fanSpeed)
			@fanSpeed = fanSpeed
			puts "set fan speed " + fanSpeed.to_s
		end

		def recv_twin(peyload)
			json = JSON.parse(peyload)
			desired = json["desired"]
			if desired == nil
				desired = json
			end
			desired.each{|key, obj|
				case key
				when "fanSpeed"
					value = obj["value"]
					if value != nil
						set_fan_speed(value)
						desired[key] = {value: @fanSpeed, status: "success"}
					else
						desired[key] = nil
					end
				else
					desired[key] = nil
				end
			}

			desired.to_json
		end

		def get_message
			data = {
				windSpeed: @windSpeed,
				temperature: @temperature,
				humidity: @humidity,
			}.to_json
			message = AzureIoT::Message.new(data)
			message.add_property('temperatureAlert', get_temperature_alert())
			return message
		end

		def measure
			@windSpeed = 10 + (rand() * 4) + 2
			@temperature = 20 + (rand() * 15)
			@humidity = 60 + (rand() * 20)
		end
	end
end

twin = WeatherStation::ContosoAnemometer.new

connectionString = AzureIoT.get_connection_string
protocol = AzureIoT::MQTT

client = AzureIoT::DeviceClient.new(connectionString, protocol)
client.set_twin(twin)

while true do
	twin.measure
	message = twin.get_message

	done = false
	client.send_event(message) do
		puts "sent message"
		done = true
	end

	count = 5000
	while !done do
		client.do_work
		sleep(0.001)
		if count > 0 then
			count -= 1
		end
	end

	if count > 0 then
		sleep(0.001 * count)
	end
end

