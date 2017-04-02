#!/usr/bin/perl -w
package MPL_SNOW_SOAP;
################################################
#                                              #
#          Service-Now custom API              #
#                                              #
# Create by Dwayne Godden for Medibank Private #
#                                              #
#        Lasted Updated 12/11/2014             #
#                                              #
################################################

###########
# Service-Now Server configuration
#	Change 
#		"$Instance" to match instance
#		"$Username" to account with the SOAP and Engineer rols
#		"$Password" to match Username account (Yes I know clear text :(
#
###########
$Username="SolarWinds";
$Password="SolarWinds2!";
$Instance="KAGJCM";
###########


###########
#
#  DANGER DO NOT EDIT BELOW THIS POINT
#
#  But please read the how-to use at the top of each fnction
#
###########
use Data::Dumper();
use ServiceNow;
use ServiceNow::Configuration;
use Exporter qw(import);
our @EXPORT_OK = qw(closeIncident_sub createIncident_sub GetIncidentNo_sub GetIncidentSys_ID_sub GetCMDB_Sysid);
my $CONFIG = ServiceNow::Configuration->new();
$CONFIG->setSoapEndPoint("https://$Instance.service-now.com/");
$CONFIG->setUserName($Username);
$CONFIG->setUserPassword($Password);
my $SN = ServiceNow->new($CONFIG);
###########

sub closeIncident_sub{
	#########
	# Close Ticket
	# Requires Ticket number in the form of INC0052833 and text decription
	# Usage
	#	closeIncident_sub($ticket_Number , $description);
	#
	# Definitions / Example
	#	$ticket_Number = "INC0052833" 				*Required
	#	$description = "Server has restarted and all is ok"	*Required
	#
	#########	

	my ($ticket_Number, $description)=@_;
	my $error_note = $SN->updateIncident($ticket_Number, { "state" => "-15", "close_notes"=>$description,"u_resolution_notes"=>$description,"Close_code"=>"Fixed","u_cause_code"=>"Hardware Repair","u_resolution_action"=>"Automatic system recovery"}); 
	return $error_note;
}


sub createIncident_sub{
	###########
	# Create an Incident
	# Usage
	# 	$sys=createIncident_sub($description,$short_description,$assignment_group,$business_service,$assigned_to,$category,$impact,$urgency,$cmdb);
	#
	# Returnes the ticket sys_id number eg. "d37eb38e6475e10064cbb33d711d42cb"
	#
	# Definitions / Example
	#	$description => "Main Ticket Notes"	eg. "Solarwinds has reported this server V0DPRD001023160 to be down please fix it"   *Required
	#	$short_description => "Ticket Subject"	eg. "Server V0DPRD001023160 is down"	*Required
	#	$assignment_group => "Assignment Aroup"	eq. "IT Windows & Automation" or sys_id	*Required
	#	$business_service => "Service"	eg. "CITRIX (MEDIBANK) PRODUCTION"		
	#	$assigned_to => "Assigned To"	eg. "Dwayne Godden"				
	#	$category => "Assigned To"	eg. "Hardware"					*Required
	#	$impact => "Impact" 1=High, 2= Medium, 3=Low	Default = 0                     *Required
	#	$urgency => "Urgency" 1=High, 2= Medium, 3=Low   Default = 0                    *Required
	#		Urgency and Impact = Priorty
	#		Impact 1 + Urgency 1 = Priorty 1
	#		Impact 1 + Urgency 2 = Priorty 2
	#		Impact 1 + Urgency 3 = Priorty 3
	#		Impact 2 + Urgency 1 = Priorty 2
	#		Impact 2 + Urgency 2 = Priorty 3
	#		Impact 2 + Urgency 3 = Priorty 4
	#		Impact 3 + Urgency 1 = Priorty 3
	#		Impact 3 + Urgency 2 = Priorty 4
	#		Impact 3 + Urgency 3 = Priorty 5
	#	$cmdb => "swnd02dev"                                                            *Required
	#					
	###########

	my ($description,$short_description,$assignment_group,$business_service,$assigned_to,$category,$impact,$urgency,$cmdb) = @_;
	# setting incident values as a hash map in the insert argument
	my $priority;
	$impact = 3;

	if ($impact == 1){
		if ($urgency == 1){
			$priority =1;
		}
		if ($urgency == 2){
			$priority =2;
		}
		if ($urgency == 3){
			$priority =3;
		}
	}
	if ($impact == 2){
		if ($urgency == 1){
			$priority =2;
		}
		if ($urgency == 2){
			$priority =3;
		}
		if ($urgency == 3){
			$priority =4;
		}
	}
	if ($impact == 3){
		if ($urgency == 1){
			$priority =3;
		}
		if ($urgency == 2){
			$priority =4;
		}
		if ($urgency == 3){
			$priority =4;
		}
	}

	my $incident = ServiceNow::ITIL::Incident->new($CONFIG);
	$incident->setValue("short_description", $short_description);
	$incident->setValue("category", $category);
	$incident->setValue("impact", $impact);
	$incident->setValue("urgency", $urgency);
	$incident->setValue("state", "Submitted");
	$incident->setValue("severity", $priority);
	$incident->setValue("priority", $priority);
	$incident->setValue("assignment_group", $assignment_group);
	$incident->setValue("u_affected_user", "Solar Winds");
	$incident->setValue("u_requestor", "Solar Winds");
	$incident->setValue("u_business_service",$business_service);
	$incident->setValue("assigned_to",$assigned_to);
	$incident->setValue("u_new_category", "Function Impaired");
	$incident->setValue("description", $description);
	$incident->setValue("u_system", "1");
	$incident->setValue("cmdb_ci", $cmdb);
	#$incident->setValue("dv_watch_list", "Natalie McIntosh");
	#$incident->setValue("watch_list", "5553d4d2ed7f95008564d5b5a44e89ac");     # <---- Natalie McIntosh sys_id
	my $sys_id = $incident->insert();
	return $sys_id;
	###########
}

sub GetIncidentNo_sub{
	##########
	# Get Incident No. from sys_id
	# Usage
	# 	$INC=GetIncidentNo_sub($sys_id);
	#
	# Definitions / Example
	#	$sys_id = "d37eb38e6475e10064cbb33d711d42cb"		*Required
	#	
	# returns INC number
	##########
	my ($sys_id) = @_;
	my $number = "";
        my $state = '';	
	my @results = $SN->queryIncident({'sys_id' => $sys_id});
	foreach my $task (@results) {
		$number = $task->{'number'};
		$state = $task->{'state'};
	}
	return ($number, $state);
}


sub GetIncidentSys_ID_sub{
	##########
	# Get sys_id from Incident No.
	# Usage
	# 	$sys_id=GetIncidentNo_sub($inc_number);
	#
	# Definitions / Example
	#	$inc_number = "INC0052832"				*Required
	#
	# returns sys_id number eg. "d37eb38e6475e10064cbb33d711d42cb"
	##########
	my ($INCNUM)=@_;
	my $number = "";	
        my $state = '';	
	my @results = $SN->queryIncident({'number' => $INCNUM});
	foreach my $task (@results) {
		$number=$task->{'sys_id'};
		$state = $task->{'state'};
	}
	return ($number, $state);
}

sub GetCMDB_Sysid {
	##########
	# Get SYS_ID for a CMDB item
	# Usage
	#	$cmdb_id=GetCMDB_Sysid($ServerName);
	#
	# Definitions / Example
	#	($cmdb_id,$state,$support_group)=GetCMDB_Sysid('swnd02dev');				*Required
	#
	# returns sys_id number and operational_status eg. "c56cb0f1f41cf50064cb0b988d5c9124",1,Group ID code 	
	#
	##########
	my ($ci_name)=@_;
	my $sys_id;
	print "$ci_name\n";
	sub SOAP::Transport::HTTP::Client::get_basic_credentials {
	 return $Username => $Password;
	}
	$host="https://".$Instance.".service-now.com/cmdb_ci.do?SOAP";

	my $soap = SOAP::Lite
	 -> proxy($host);

	my $method = SOAP::Data->name('getRecords')
	 ->attr({xmlns => 'http://www.service-now.com/'});

	# get incident by sys_id
	my @params = ( SOAP::Data->name(__order_by => 'sys_id') );
	push (@params, SOAP::Data->name(name => $ci_name) );

	#Check only if CMDB state is operational
	#push (@params, SOAP::Data->name(operational_status => '1') );

	my %keyHash = %{ $soap->call($method => @params)->body->{'getRecordsResponse'} };

	my %record = %{$keyHash{'getRecordsResult'}};

	foreach my $kk (keys %record) {

		if ($kk eq "sys_id"){
			$sys_id=$record{$kk};
		}
		if ($kk eq "operational_status"){
			$state=$record{$kk};
		}
		if ($kk eq "support_group"){
			$support_group=$record{$kk}
		}
	}
	return ($sys_id,$state,$support_group);
}
