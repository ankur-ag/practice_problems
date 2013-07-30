require "time"

# Ruby Challenge : http://rubylearning.com/blog/2010/05/25/rpcfn-business-hours-10/

class BusinessHours

	def initialize open_time, closing_time
		@open_time = Time.parse(open_time)
		@closing_time = Time.parse(closing_time)
		@special_days = {}	# hash of days that could be a holiday or have a different business hours
		@special_dates = {} # hash of dates that could be a holiday or have different business hours
	end

	def update day, open_time, closing_time
		open_time = Time.parse(open_time)
		closing_time = Time.parse(closing_time)

		if day.is_a? Symbol
			@special_days[day] = { :on => true, :open => open_time, :close => closing_time }
		else
			day = Time.parse(day).strftime("%m/%d/%Y")
			@special_dates[day] = { :on => true, :open => open_time, :close => closing_time }
		end

	end

	def closed *days
		days.each do |day|
			if day.is_a? Symbol
				@special_days[day] = {:on => false, :open => nil, :close => nil}
			else
				day = Time.parse(day).strftime("%m/%d/%Y")
				@special_dates[day] = {:on => false, :open => nil, :close => nil}
			end
		end
	end

	def calculate_deadline interval, starting_time
		# iteration start date
		starting_time = Time.parse(starting_time)
		ot = @open_time.in_context_of starting_time
		st = starting_time

		# start iterating from the start date
		while true
			date = ot.strftime("%m/%d/%Y")
			day = ot.strftime("%a").downcase.to_sym

			# check if its a special date
			if @special_dates.has_key? date
				# check if its an off day
				if not @special_dates[date][:on]
					ot = next_day ot
					next
				else
					ot = @special_dates[date][:open].in_context_of ot
					ct = @special_dates[date][:close].in_context_of ot
				end
			# check if its a special day
			elsif @special_days.has_key? day
				# check if its an off day
				if not @special_days[day][:on]
					ot = next_day ot
					next
				else
					ot = @special_days[day][:open].in_context_of ot
					ct = @special_days[day][:close].in_context_of ot
				end
			else	# regular day
				ot = @open_time.in_context_of ot
				ct = @closing_time.in_context_of ot
			end

			# adjust the open time for the first day to calculate
			if st != nil
				diff = time_diff ot, st
				# if starting_time is after the open time
				if diff > 0
					diff2 = time_diff ct, st
					# if the day has passed already, continue
					if diff2 > 0
						st = nil # need not consider starting_time again
						next
					# reset the open time to starting_time for calculations
					else
						ot = st
						st = nil # need not consider starting_time again
					end
				end
				
			end
			
			# calculate the time utilized on this day
			diff = time_diff ot, ct
			if interval < diff
				deadline = ot + interval
				puts deadline.strftime("%b %-d, %Y %l:%M %p")
				return deadline
			else
				interval = interval - diff
				ot = next_day ot
			end
		end
	end

	private

	def next_day time
		time + 24*60*60
	end

	# to compare time ignoring the date part
	def time_diff start_date, end_date
		t1 = Time.at(start_date.hour * 60 * 60 + start_date.min * 60 + start_date.sec)
		t2 = Time.at(end_date.hour * 60 * 60 + end_date.min * 60 + end_date.sec)
		t2 - t1
	end
end

class Time
	def in_context_of t
		Time.new t.year, t.month, t.day, self.hour, self.min, self.sec
	end
end


require 'test/unit'

class BusinessHoursTest < Test::Unit::TestCase
	def setup
		@hours = BusinessHours.new("9:00 AM", "3:00 PM")
		@hours.update :fri, "10:00 AM", "5:00 PM"
		@hours.update "Dec 24, 2010", "8:00 AM", "1:00 PM"
		@hours.closed :sun, :wed, "Dec 25, 2010"
	end

	def test_a
		a = @hours.calculate_deadline(2*60*60, "Jun 7, 2010 9:10 AM")
		b = Time.parse("Jun 7, 2010 11:10 AM")
		assert_equal a, b
	end

	def test_b
		a = @hours.calculate_deadline(15*60, "Jun 8, 2010 2:48 PM")
		b = Time.parse("Jun 10, 2010 9:03 AM")
		assert_equal a, b
	end

	def test_c
		a = @hours.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM")
		b = Time.parse("Dec 27, 2010 11:00 AM")
		assert_equal a, b
	end
end
