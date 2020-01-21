project 'BeeZone Demo', {
  release 'BeeZone Release', {
    description = ''
    disableMultipleActiveRuns = '0'
    plannedEndDate = '2020-02-07'
    plannedStartDate = '2020-01-10'
    projectName = 'BeeZone Demo'
    timeZone = null

    pipeline 'pipeline_BeeZone Release', {
      disableMultipleActiveRuns = '0'
      disableRestart = '0'
      enabled = '1'
      overrideWorkspace = '0'
      pipelineRunNameTemplate = null
      releaseName = 'BeeZone Release'
      skipStageMode = 'ENABLED'
      templatePipelineName = null
      templatePipelineProjectName = null
      type = null
      workspaceName = null

      formalParameter 'ec_stagesToRun', defaultValue: null, {
        expansionDeferred = '1'
        label = null
        orderIndex = null
        required = '0'
        type = null
      }

      stage 'Stage 1', {
        colorCode = null
        completionType = 'auto'
        condition = null
        duration = null
        parallelToPrevious = null
        pipelineName = 'pipeline_BeeZone Release'
        plannedEndDate = null
        plannedStartDate = null
        precondition = null
        resourceName = null
        waitForPlannedStartDate = '0'

        gate 'PRE', {
          condition = null
          precondition = null
        }

        gate 'POST', {
          condition = null
          precondition = null
        }
      }
    }
  }
  application 'Account Statements', {
    description = ''
    projectName = 'BeeZone Demo'

    applicationTier 'Tier 1', {
      applicationName = 'Account Statements'
    }

    // Custom properties

    property 'ec_deploy', {

      // Custom properties
      ec_notifierStatus = '0'
    }
  }
  environment 'QA', {
    environmentEnabled = '1'
    projectName = 'BeeZone Demo'
    reservationRequired = '0'
    rollingDeployEnabled = null
    rollingDeployType = null

    environmentTier 'Tier 1', {
      batchSize = null
      batchSizeType = null
    }  
  } 
}
