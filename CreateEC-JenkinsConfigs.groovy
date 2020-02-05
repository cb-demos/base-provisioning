/*
    Create EC-Jenkins configurations
*/

def confs=["alpha","bravo"]
def proj="/plugins/EC-Jenkins/project"
def BaseUrl = "https://core.cb-demos.io/"
def uName='admin'
def pwd='changeme'

def ExistingConfigs = []
getProperties(propertySheetId: getProperty("/plugins/EC-Jenkins/project/Jenkins_cfgs").propertySheetId).property.each {
	ExistingConfigs.push(it.name)
}

confs.each { conf ->
	// Create a Transient credential
	def Cred = new RuntimeCredentialImpl()		
	Cred.name = conf	        
	Cred.userName = uName		
	Cred.password = pwd
	def Creds=[Cred]

	// Call the config creation procedure
	// if it does not already exists
	// by checking if the config property (name may be different in different plugin)
	if (! (conf in ExistingConfigs)) {
	  runProcedure(
		projectName : proj,
		procedureName : "CreateConfiguration",
		actualParameter : [
		  config: conf,
		  server: BaseUrl + conf,  // required
		  credential: conf,        // Credential has the same name than the config
		],
		 credential: Creds
	  )
	} else {
	  // overwrite the  credential
	  /*
	  credential(
		projectName: proj,
		userNane: uName
		password: pwd
		credentialName: conf
	  )
	  // overtrite properties
	  setProperty("$proj/ServiceNow_cfgs/$conf/host": value: "http://myNewHost"
	  setProperty("$proj/ServiceNow_cfgs/$conf/http_proxy": value: "http://myProxy"
	  //.....
	  */
	}
} // Each conf
