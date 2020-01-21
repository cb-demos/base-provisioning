import groovy.time.TimeCategory
import java.util.concurrent.ThreadLocalRandom;


if (true) {
    def envName = args.environmentName
    project args.projectName, {
        release args.releaseName

        if (args.plannedEndDate && args.plannedStartDate) {
            release args.releaseName, {
                plannedEndDate = args.plannedEndDate
                plannedStartDate = args.plannedStartDate
            }
        }
        if (args.serviceName) {
            service args.serviceName
            environment envName, {
                cluster args.clusterName
            }
        } else {
            application args.applicationName
            environment envName
        }
    }
}

if (args.build) {
  loadBuildData()
}

if (args.systemTest) {
  loadTestData('system-test', args.systemTest)
}

if (args.unitTest) {
  loadTestData('unit-test', args.unitTest)
}

if (args.deployment) {
  loadDeploymentData()
}

if (args.incident) {
  loadIncidentData()
}

if (args.feature) {
  loadFeatureData(args.feature)
}

if (args.defect) {
  loadDefectData(args.defect)
}

/**
 * Reads following parameter args:
 * build.durationInMinutes
 * build.successCount
 * build.failureCount
 * build.trendUp
 */
def loadBuildData() {

    def successCount = args.build.successCount
    def failureCount = args.build.failureCount

    def previousSuccessCount = args.build.trendUp ? successCount - 1 : successCount + 1
    def previousFailureCount = args.build.trendUp ? failureCount + 1 : failureCount - 1

    loadBuilds(currentTimeWindow(), args.build.durationInMinutes?:10, successCount, failureCount)

    loadBuilds(previousTimeWindow(), args.build.durationInMinutes?:10, previousSuccessCount, previousFailureCount)

}


def loadBuilds(def endTime, def durationInMins, def successCount, def failureCount) {

    def startTime
    use( TimeCategory ) {
        startTime = endTime - durationInMins.minutes
    }

    def startTimeStr = startTime.format("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone.getTimeZone('UTC'))
    def endTimeStr = endTime.format("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone.getTimeZone('UTC'))

    def duration = durationInMins * 60000
    if (successCount > 0) {
        println "Loading $successCount success builds"
        successCount.times {
            sendReportingData reportObjectTypeName: 'build', payload: """{
                "source": "Jenkins",
                "sourceUrl": "http://10.200.1.171:8081/job/EC%20Reporting%20Plugins/${it}",
                "buildNumber": "10${it}",
                "pluginName": "EC-Jenkins",
                "pluginConfiguration": "config",
                "releaseName": "$args.releaseName",
                "releaseProjectName": "$args.projectName",
                "duration" : $duration,
                "startTime": "$startTimeStr",
                "endTime": "$endTimeStr",
                "buildStatus": "SUCCESS",
                "timestamp": "$endTimeStr",
                "baseDrilldownUrl": "http://pm-jenkins.ecloud-kdemo.com:8080"
            }"""
        }
    }

    if (failureCount > 0) {
        println "Loading $failureCount failed builds"
        failureCount.times {
            sendReportingData reportObjectTypeName: 'build', payload: """{
                "source": "Jenkins",
                "sourceUrl": "http://10.200.1.171:8081/job/EC%20Reporting%20Plugins/${it}",
                "buildNumber": "10${it}",
                "pluginName": "EC-Jenkins",
                "pluginConfiguration": "config",
                "releaseName": "$args.releaseName",
                "releaseProjectName": "$args.projectName",
                "duration" : $duration,
                "startTime": "$startTimeStr",
                "endTime": "$endTimeStr",
                "buildStatus": "FAILURE",
                "timestamp": "$endTimeStr",
                "baseDrilldownUrl": "http://pm-jenkins.ecloud-kdemo.com:8080/"
            }"""
        }
    }
}

/**
 * Reads following parameter args from the specs arg:
 * specs.lastNumberOfDays
 * specs.successCount
 * specs.trendUp
 */
def loadTestData(def category, def specs) {

    def durationInMillis = specs.durationInMillis?:((specs.durationInMinutes?:1)*60000)
    def trendUp = specs.trendUp

    def successCount = specs.successCount
    def failureCount = specs.failureCount

    def previousSuccessCount = specs.trendUp ? successCount - 1 : successCount + 1
    def previousFailureCount = specs.trendUp ? failureCount + 1 : failureCount - 1

    loadTests(category, currentTimeWindow(), durationInMillis, successCount, failureCount)

    loadTests(category, previousTimeWindow(), durationInMillis, previousSuccessCount, previousFailureCount)

}

def loadTests(def category, def endTime, def durationInMillis, def successCount, def failureCount) {

    def source = (category == 'system-test') ? 'HPALM' : 'Jenkins'
    def sourceUrl = (category == 'system-test') ? 'http://10.200.1.210:8080/qcbin/domain' : 'http://10.200.1.210:8080/job/HelloWorld/1'
    def pluginName = (category == 'system-test') ? 'EC-ALM' : 'EC-Jenkins'

    def startTime
    use( TimeCategory ) {
        startTime = endTime - durationInMillis.milliseconds
    }

    def startTimeStr = startTime.format("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone.getTimeZone('UTC'))
    def endTimeStr = endTime.format("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone.getTimeZone('UTC'))

    // reset to zero if values dropped to negative
    if (successCount < 0) successCount = 0
    if (failureCount < 0) failureCount = 0

    sendReportingData reportObjectTypeName: 'quality', payload: """{
        "source": "$source",
        "sourceUrl": "$sourceUrl",
        "pluginName": "$pluginName",
        "pluginConfiguration": "config",
        "releaseName": "$args.releaseName",
        "releaseProjectName": "$args.projectName",
        "duration" : $durationInMillis,
        "timestamp": "$endTimeStr",
        "category": "$category",
        "failedTests": $failureCount,
        "successfulTests": $successCount,
        "baseDrilldownUrl": "https://pm2.ecloud-kdemo.com/commander/jobSteps/727122dc-c5cb-11e8-84d2-06b49b6cb774/surefire-report.html"
    }"""
}

/**
 * Reads following parameter args:
 * deployment.successCount
 * deployment.failureCount
 * deployment.trendUp
 */
def loadDeploymentData() {

    def durationInMillis = args.deployment.durationInMillis
    def trendUp = args.deployment.trendUp

    def successCount = args.deployment.successCount
    def failureCount = args.deployment.failureCount

    def previousSuccessCount = args.deployment.trendUp ? successCount - 1 : successCount + 1
    def previousFailureCount = args.deployment.trendUp ? failureCount + 1 : failureCount - 1

    loadDeployments(currentTimeWindow(), durationInMillis, successCount, failureCount)

    loadDeployments(previousTimeWindow(), durationInMillis, previousSuccessCount, previousFailureCount)
}

def loadDeployments(def endTime, def durationInMillis, def successCount, def failureCount) {

    def startTime
    use( TimeCategory ) {
        startTime = endTime - durationInMillis.milliseconds
    }

    def startTimeStr = startTime.format("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone.getTimeZone('UTC'))
    def endTimeStr = endTime.format("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone.getTimeZone('UTC'))

    // reset to zero if values dropped to negative
    if (failureCount < 0) failureCount = 0
    if (successCount < 0) successCount = 0

    def statuses = []
    successCount.times {
        statuses << 'success'
    }
    failureCount.times {
        statuses << 'error'
    }

    //loop up in the system for ids since deploy reports currently use ids also
    def envName = args.environmentName
    def environment = getEnvironment projectName: args.projectName, environmentName: envName

    def application = null
    if (args.applicationName) {
        application = getApplication projectName: args.projectName, applicationName: args.applicationName
    }
    def service = null
    def cluster = null
    if (args.serviceName) {
        service = getService projectName: args.projectName, serviceName: args.serviceName
        cluster = getCluster projectName: args.projectName, environmentName: envName, clusterName: args.clusterName
    }

    def release = getRelease projectName: args.projectName, releaseName: args.releaseName

    statuses.each { status ->
        sendReportingData reportObjectTypeName: 'deployment', payload: args.applicationName ? """{
                    "reportEventType": "ef_process_run_completed",
                    "projectName": "$args.projectName",
                    "releaseProjectName": "$args.projectName",
                    "releaseName": "$args.releaseName",
                    "releaseId": "$release.releaseId",
                    "environmentProjectName": "$args.projectName",
                    "environmentName": "$environment.environmentName",
                    "environmentId": "$environment.environmentId",
                    "applicationName" : "$args.applicationName",
                    "applicationId" : "$application.applicationId",
                    "jobStart": "$startTimeStr",
                    "jobFinish": "$endTimeStr",
                    "deploymentOutcome": "$status"
                }""" :
                """{
                    "reportEventType": "ef_process_run_completed",
                    "projectName": "$args.projectName",
                    "releaseProjectName": "$args.projectName",
                    "releaseName": "$args.releaseName",
                    "releaseId": "$release.releaseId",
                    "environmentProjectName": "$args.projectName",
                    "environmentName": "$environment.environmentName",
                    "environmentId": "$environment.environmentId",
                    "clusterName": "$cluster.clusterName",
                    "clusterId": "$cluster.clusterId",
                    "pluginKey": "$cluster.pluginKey",
                    "serviceName" : "$args.serviceName",
                    "serviceId" : "$service.serviceId",
                    "jobStart": "$startTimeStr",
                    "jobFinish": "$endTimeStr",
                    "deploymentOutcome": "$status"
                }"""
    }
}

/**
 * Reads following parameter args:
 * incident.openCount
 * incident.closedCount
 * incident.trendUp
 */
def loadIncidentData() {

    def duration = args.incident.durationInMillis?:60000
    def trendUp = args.incident.trendUp?:false

    def closedCount = args.incident.closedCount?:10
    int openCount = args.incident.openCount?:(closedCount/2)

    def previousClosedCount = args.incident.trendUp ? closedCount - 1 : closedCount + 1
    def previousOpenCount = args.incident.trendUp ? openCount + 1 : openCount - 1

    loadIncidents(currentTimeWindow(), duration, closedCount, openCount)

    loadIncidents(previousTimeWindow(), duration, previousClosedCount, previousOpenCount)

}

def loadIncidents(def endTime, def durationInMillis, def closedCount, def openCount) {

    def startTime
    use( TimeCategory ) {
        startTime = endTime - durationInMillis.milliseconds
    }

    def startTimeStr = startTime.format("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone.getTimeZone('UTC'))
    def endTimeStr = endTime.format("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone.getTimeZone('UTC'))

    // reset to zero if values dropped to negative
    if (openCount < 0) openCount = 0
    if (closedCount < 0) closedCount = 0

    def statuses = []
    closedCount.times {
        statuses << 'Resolved'
    }
    openCount.times {
        statuses << 'Open'
    }

     statuses.eachWithIndex { status, statusIndex ->
         def resolvedOnStr = status == 'Resolved' ? "\"resolvedOn\" : \"${endTimeStr}\"," : ""
         def incidentId = "Incident_${statusIndex}"

         sendReportingData reportObjectTypeName: 'incident', payload: """{
                     "source": "ServiceNow",
                     "sourceUrl": "https://ven077552.service-now.com",
                     "pluginName": "EC-ServiceNow",
                     "pluginConfiguration": "config",
                     "releaseName": "$args.releaseName",
                     "releaseProjectName": "$args.projectName",
                     "incidentId" : "$incidentId",
                     "createdOn": "$startTimeStr",
                     "modifiedOn": "$startTimeStr",
                     $resolvedOnStr
                     "status": "$status",
                     "timestamp": "$startTimeStr",
                     "baseDrilldownUrl": "https://ven01735.service-now.com/incident_list.do",
                     "releaseUri": "?sysparm_query=category%3Dsoftware"
                 }"""
     }
}


/**
 * Reads following parameter args:
 * feature.openCount
 * feature.closedCount
 * feature.trendUp
 * feature.storiesWithStoryPoints
 */
def loadFeatureData(def specs) {

    def trendUp = specs.trendUp
    def openCount = specs.openCount
    def closedCount = specs.closedCount

    def previousOpenCount = specs.trendUp ? openCount + 1 : openCount - 1
    def previousClosedCount = specs.trendUp ? closedCount - 1 : closedCount + 1

    def storiesWithStoryPoints = args.feature.storiesWithStoryPoints?:0
    loadFeatures(currentTimeWindow(), openCount, closedCount, storiesWithStoryPoints)

    loadFeatures(previousTimeWindow(), previousOpenCount, previousClosedCount, /*storiesWithStoryPoints*/ 0)

}

def loadFeatures(def time, def openCount, def closedCount, storiesWithStoryPoints) {

    def timeStr = time.format("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone.getTimeZone('UTC'))

    if (openCount < 0) openCount = 0
    if (closedCount < 0) closedCount = 0

    if (openCount > 0) {
        println "Loading $openCount open stories"
        def resolvedOnStr = ''
        def status = 'Open'

        openCount.times {
            def storyPoints = getStoryPoints(storiesWithStoryPoints, it)
            def storyPointsStr = "\"storyPoints\" : $storyPoints,"
            def featureIndex = it
            def feature = "Feature-${featureIndex}"
            sendReportingData reportObjectTypeName: 'feature', payload: """{
                "source": "JIRA",
                "sourceUrl": "http://kdemo3.atlassian.net/browse/${it}",
                "pluginName": "EC-JIRA",
                "pluginConfiguration": "config",
                "releaseName": "$args.releaseName",
                "releaseProjectName": "$args.projectName",
                "featureName" : "$feature",
                "key" : "$feature",
                "type" : "Story",
                $storyPointsStr
                "createdOn": "$timeStr",
                "modifiedOn": "$timeStr",
                $resolvedOnStr
                "status": "$status",
                "timestamp": "$timeStr",
		 "baseDrilldownUrl": "https://kdemo3.atlassian.net/projects/PM/issues/PM-21?filter=allissues",
                "releaseUri": ""
            }"""
        }
    }

    if (closedCount > 0) {
        println "Loading closedCount closed stories"
        def resolvedOnStr = "\"resolvedOn\" : \"$timeStr\","
        closedCount.times {
            def storyPoints = getStoryPoints(storiesWithStoryPoints, openCount + it)
            def storyPointsStr = "\"storyPoints\" : $storyPoints,"

            def status = it%2 == 0 ? 'Resolved' : 'Closed'
            def featureIndex = openCount + it
            def feature = "Feature-${featureIndex}"

            sendReportingData reportObjectTypeName: 'feature', payload: """{
                "source": "JIRA",
                "sourceUrl": "http://kdemo3.atlassian.net/browse/${it}",
                "pluginName": "EC-JIRA",
                "pluginConfiguration": "config",
                "releaseName": "$args.releaseName",
                "releaseProjectName": "$args.projectName",
                "featureName" : "$feature",
                "key" : "$feature",
                "type" : "Story",
                $storyPointsStr
                "createdOn": "$timeStr",
                "modifiedOn": "$timeStr",
                $resolvedOnStr
                "status": "$status",
                "timestamp": "$timeStr",
		 "baseDrilldownUrl": "https://kdemo3.atlassian.net/projects/PM/issues/PM-21?filter=allissues",
                "releaseUri":""
            }"""
        }
    }

}

def getStoryPoints(def storiesWithStoryPoints, def currentIndex) {
    currentIndex + 1 <= storiesWithStoryPoints ? 10 : 0
}


/**
 * Reads following parameter args:
 * defect.openCount
 * defect.closedCount
 * defect.trendUp
 */
def loadDefectData(def specs) {

    def trendUp = specs.trendUp
    def openCount = specs.openCount
    def closedCount = specs.closedCount

    def previousOpenCount = specs.trendUp ? openCount - 5 : openCount
    def previousClosedCount = closedCount

    loadDefects(currentTimeWindow(), openCount, closedCount)

    loadDefects(previousTimeWindow(), previousOpenCount, previousClosedCount)

}

def loadDefects(def time, def openCount, def closedCount) {

    def timeStr = time.format("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone.getTimeZone('UTC'))

    if (openCount < 0) openCount = 0
    if (closedCount < 0) closedCount = 0

    if (openCount > 0) {
        println "Loading $openCount open defects"
        def resolvedOnStr = ''
        def status = 'Open'

        openCount.times {
            def defectIndex = it
            def defect = "Defect-${defectIndex}"
            sendReportingData reportObjectTypeName: 'defect', payload: """{
                "source": "JIRA",
                "sourceUrl": "http://kdemo3.atlassian.net/browse/${it}",
                "pluginName": "EC-JIRA",
                "pluginConfiguration": "config",
                "releaseName": "$args.releaseName",
                "releaseProjectName": "$args.projectName",
                "defectName" : "$defect",
                "key" : "$defect",
                "createdOn": "$timeStr",
                "modifiedOn": "$timeStr",
                $resolvedOnStr
                "status": "$status",
                "timestamp": "$timeStr",
		 "baseDrilldownUrl": "https://kdemo3.atlassian.net/projects/PM/issues/PM-21?filter=allissues",
                "releaseUri": ""
            }"""
        }
    }

    if (closedCount > 0) {
        println "Loading closedCount closed defects"
        def resolvedOnStr = "\"resolvedOn\" : \"$timeStr\","
        closedCount.times {

            def status = it%2 == 0 ? 'Resolved' : 'Closed'
            def defectIndex = openCount + it
            def defect = "Defect-${defectIndex}"

            sendReportingData reportObjectTypeName: 'defect', payload: """{
                "source": "JIRA",
                "sourceUrl": "http://kdemo3.atlassian.net/browse/${it}",
                "pluginName": "EC-JIRA",
                "pluginConfiguration": "config",
                "releaseName": "$args.releaseName",
                "releaseProjectName": "$args.projectName",
                "defectName" : "$defect",
                "key" : "$defect",
                "createdOn": "$timeStr",
                "modifiedOn": "$timeStr",
                $resolvedOnStr
                "status": "$status",
                "timestamp": "$timeStr",
		 "baseDrilldownUrl": "https://kdemo3.atlassian.net/projects/PM/issues/PM-21?filter=allissues",
                "releaseUri": ""
            }"""
        }
    }

}

def currentTimeWindow() {
    def now = new Date()
    def daysAgo = null
    use( TimeCategory ) {
        daysAgo = now - 1.days
    }
    daysAgo
}

def previousTimeWindow() {
    def now = new Date()
    def daysAgo = null
    use( TimeCategory ) {
        daysAgo = now - 11.days
    }
    daysAgo
}

def toss() {
    int randomDuration = ThreadLocalRandom.current().nextInt(1, 3)
    randomDuration == 2
}
