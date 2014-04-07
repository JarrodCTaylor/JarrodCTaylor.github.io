module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-contrib-less")
  grunt.initConfig
    less:
      deploy:
        files:
          "css/deploy.css": "less/deploy.less"

  grunt.task.registerTask("deploy", ["less:deploy"])
