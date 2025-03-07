# Copyright (C) 2015  onox
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#io.include("Aircraft/ExpansionPack/Nasal/init.nas");
srand();# seed the random generator with systime
#with("updateloop");

# Number of iterations per second
var frequency = 20.0;

# Change in heading per second at full rudder deflection
var heading_ps = 0.1;

time_last = 0;
sim_speed = 1;

sink_rate = .025;
pitch_rate = .007;
roll_rate = .007;

setprop("/carrier/pitch-deg",0);
setprop("/carrier/pitch-offset",0);
setprop("/carrier/roll-deg",0);
setprop("/carrier/roll-offset",0);
setprop("/carrier/sunk",0);

var arrived = 0;

var PositionUpdater = func () {
	
	settimer( PositionUpdater, 1/frequency );

	var position = geo.aircraft_position();

	if ( arrived == 0 and getprop("/carrier/sunk") == 0 and getprop("/autopilot/route-manager/wp-last/dist") != nil and getprop("/autopilot/route-manager/wp-last/dist") < 1 ) {
		setprop("/sim/multiplay/chat",getprop("sim/multiplay/callsign") ~ " has arrived safely!");
		print("arrived");
		arrived = 1;
		#return;
	}	
	
	var time_now = getprop("/sim/time/elapsed-sec");
	var dt = (time_now - time_last) * sim_speed;
	if (dt == 0) return;

	time_last = time_now;

	var rudder  = getprop("/surface-positions/rudder-pos-norm");

	
	if ( getprop("/carrier/sunk") == 0 and getprop("/autopilot/route-manager/active") == 1 ) {

		#for event
		var speed = 15;
		var cur_waypoint = getprop("/autopilot/route-manager/current-wp");
		var cur_wp_lon = getprop("/autopilot/route-manager/route/wp[" ~ cur_waypoint ~ "]/longitude-deg");
		var cur_wp_lat = getprop("/autopilot/route-manager/route/wp[" ~ cur_waypoint ~ "]/latitude-deg");
		var rm_destination = geo.Coord.new().set_latlon(cur_wp_lat,cur_wp_lon);
		
		
		var heading = position.course_to(rm_destination);
		
		var distance = speed * globals.KT2MPS * dt;
		position.apply_course_distance(heading, distance);
		
		# Set new position
		setprop("/position/latitude-deg", position.lat());
		setprop("/position/longitude-deg", position.lon());
		var g_alt = getprop("/position/ground-elev-ft");
		setprop("/position/altitude-ft",g_alt);

		
		

		# Update heading
		var course = heading + rudder * heading_ps * dt;
		setprop("/orientation/heading-deg", course);
		setprop("velocities/groundspeed-kt",speed);
	} elsif ( getprop("/carrier/sunk") == 1 ) {
		setprop("/carrier/fbw/target/groundspeed-kt",0);
		setprop("/controls/engines/engine/throttle",0);

		# Set new position
		setprop("/position/latitude-deg", position.lat());
		setprop("/position/longitude-deg", position.lon());
		
		#calculate sinking.
		setprop("/position/altitude-ft",getprop("/position/altitude-ft") - ( sink_rate ));
		setprop("/carrier/pitch-offset",getprop("/carrier/pitch-offset") + ( pitch_rate ));
		setprop("/carrier/roll-offset",getprop("/carrier/roll-offset") + ( roll_rate ));
		setprop("velocities/groundspeed-kt",0);
		print("sunk");
	}
	
	#set pitch
	setprop("/orientation/pitch-deg",getprop("/carrier/pitch-deg") + getprop("/carrier/pitch-offset"));
	
	#set roll
	setprop("/orientation/roll-deg",getprop("/carrier/roll-deg") + getprop("/carrier/roll-offset"));	
	
};

PositionUpdater();