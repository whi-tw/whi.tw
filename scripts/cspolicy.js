const fs = require("fs");
const crypto = require('crypto');
var hashes = {scripts: [], styles: []};
fs.readFile("build/ell/index.html", function(err, buf) {
    if(err) throw err;
    var cheerio = require('cheerio'),
    $ = cheerio.load(buf.toString());
    var scripts = $('script');
    var styles = $('style');
    scripts.each(function(index) {
        if($(this).html() != '') {
        const hash = crypto.createHash('sha256');
        hash.write($(this).html());
        hashes.scripts.push(hash.digest('base64'))
        }
    });
    styles.each(function(index) {
        if($(this).html() != '') {
        const hash = crypto.createHash('sha256');
        hash.write($(this).html());
        hashes.styles.push(hash.digest('base64'))
        }
    });
    var csp_string = "default-src https:; script-src https: "
    hashes.scripts.forEach(function(hash, index, arr){
        csp_string += "'sha256-" + hash + "'";
        if (index+1 != arr.length ){
            csp_string += " "
        }
    });
    csp_string += "; style-src 'unsafe-inline' https:"
    // hashes.styles.forEach(function(hash, index, arr){
        // csp_string += "'sha256-" + hash + "'";
        // if (index+1 != arr.length ){
            // csp_string += " "
        // }
    // });
    fs.readFile('_headers', function(err, buf) {
        if(err) throw err;
        data = buf.toString();
        data = data.replace(/(?<=Content-Security-Policy:).*$/gm, " " + csp_string);
        fs.writeFile('_headers', data, function(err) {
            err || console.log('Data replaced \n', data);
        });
    });
  });
