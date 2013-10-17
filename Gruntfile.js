module.exports = function (grunt) {
    grunt.initConfig({
        incubator: {
            path: __dirname + '/packages'
        }
    });
    grunt.loadNpmTasks('incubator');
    grunt.registerTask('build-iso', 'incubate:isoimage');
    grunt.registerTask('build-dev', 'incubate:roofs-dev');
    grunt.registerTask('build-all', 'incubate:isoimage:rootfs-dev');
    grunt.registerTask('default', 'build-iso');
};