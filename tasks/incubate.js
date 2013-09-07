var path  = require('path'),
    spawn = require('child_process').spawn;

var NPM_BIN = path.join(__dirname, '..', 'node_modules', '.bin');
var PKG_DIR = path.join(__dirname, '..', 'packages');

module.exports = function (grunt) {
    grunt.registerTask('incubate', 'Build Stemcell packages', function () {
        var pkgs = [].slice.call(arguments, 0),
            done = this.async();
        spawn(path.join(NPM_BIN, 'incubate'),
              ['--package-path=' + PKG_DIR].concat(pkgs),
              { stdio: 'inherit' })
            .on('exit', function (code) {
                done(code == 0);
            });
    });
};