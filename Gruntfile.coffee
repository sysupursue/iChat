module.exports = (grunt) ->
  require('load-grunt-tasks')(grunt)
  path = require('path')

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    clean:
      all:
        [
          'bin/*'
          '!bin/views'
          'bin/views/*'
          '!bin/views/vendor'
          'test/*'
        ]

    sass:
      build:
        options:{
            includePaths: require('node-bourbon').with('src/views/stylesheets')
        },
        files: [
          src: ["stylesheets/**/*.sass"]
          dest: "bin/"
          cwd: "src/"
          ext: ".css"
          expand: true
        ]

    livescript:
      options:
        bare: true
      
      controllers:
        cwd:"src/"
        src:["controllers/*.ls"]
        dest:"bin/"
        ext:".js"
        expand:true

      models:
        cwd:"src/"
        src:["models/*.ls"]
        dest:"bin/"
        ext:".js"
        expand:true
        
      client:
        cwd: "src/"
        src: ["views/**/*.ls"]
        dest: "bin/"
        ext: ".js"
        expand: true

      server:
        cwd: "src/"
        src: ["**/*.ls", '!views/**/*.ls']
        dest: "bin/"
        ext: ".js"
        expand: true

      test:
        cwd: "testSrc/"
        src: ["*.ls"]
        dest: "test/"
        ext: ".js"
        expand: true

    copy:
      views:
        files: [
          src: ["views/**/*.*", "!views/**/*.{ls,sass}"]
          dest: "bin/"
          cwd: "src/"
          expand: true
        ]

      router:
        src: 'src/controllers/router.js'
        dest: 'bin/controllers/router.js'

      validation: # validation.js 在前后端都有用到
        src: 'bin/common/validation.js'
        dest: 'bin/views/common/validation.js'

    express:
      build:
        options:
          script: 'bin/app.js'

    watch:
      options:
        livereload: true

      sass:
        files: ['src/stylesheets/**/*.sass']
        tasks: ['sass'] # 因为一个sass文件的改变会对多个sass文件有影响，所以这里不能用newer

      livescriptclient:
        files: ['src/views/**/*.ls']
        tasks: ['newer:livescript:client']

      livescriptserver:
        files: ['src/**/*.ls'
                '!src/views/**/*.ls']
        tasks: ['newer:livescript:server'
                'express:build']
        options:
          spawn: false

      livescripttest:
        files: ['testSrc/*ls']
        tasks: ['newer:livescript:test']

      views:
        files: ["src/views/**/*.*", "!src/views/**/*.{ls,sass}"]
        tasks: ['newer:copy:views']

      validation:
        files: ["src/common/validation.ls"]
        tasks: ['copy: validation']

      router:
        files: ['src/controllers/router.js']
        tasks: ['copy:router'
                'express:build']

    grunt.registerTask 'default', [
      'clean'
      'sass'
      'livescript'
      'copy'
      'express'
      'watch'
      ]
