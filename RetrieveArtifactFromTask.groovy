/*

Flow DSL: Retrieve latest artifact from a task

Instructions
- Run EC-DSLIDE Example "Application" first to create the artifact version
- Run this pipeline

*/

def ProjectName = "BeeZone Demo"
def PipelineName = "BeeZone Release"
def ArtifactName = "BeeZone:HelloWorld"
project ProjectName,{
  pipeline PipelineName,{
    stage "Stage 1",{
      task 'Retrieve Latest Artifact', {
        actualParameter = [
          artifactName: ArtifactName,  // required
          artifactVersionLocationProperty: '/myJob/retrievedArtifactVersions/$[assignedResourceName]',  // required
          filterList: '',
          overwrite: 'update',
          retrieveToDirectory: '',
          versionRange: '',        ]
        subpluginKey = 'EC-Artifact'
        subprocedure = 'Retrieve'
        taskType = 'PLUGIN'
      }
    }
  }
}
