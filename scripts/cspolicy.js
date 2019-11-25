const fs = require("fs"),
  glob = require("glob"),
  cheerio = require('cheerio'),
  crypto = require('crypto');

function getAllHashes(files) {
  var scripts = [], styles = [];
  for (var i = 0; i < files.length; i++) {
    var fileHashes = getHashesFromFile(files[i]);
    scripts.push(...fileHashes.scripts);
    styles.push(...fileHashes.styles);
  }
  return {
    scripts: [...new Set(scripts)],
    styles: [...new Set(styles)]
  };
}
function getHashesFromFile(file) {
  var content = fs.readFileSync(file);
  var hashes = {
    scripts: [],
    styles: []
  };
  $ = cheerio.load(content.toString());
  var scripts = $('script');
  var styles = $('style');
  for (var i = 0; i < scripts.length; i++) {
    if ($(scripts[i]).html() != '') {
      const hash = crypto.createHash('sha256');
      hash.write($(scripts[i]).html());
      hashes.scripts.push(hash.digest('base64'))
    }
  }
  for (var i = 0; i < styles.length; i++) {
    if ($(styles[i]).html() != '') {
      const hash = crypto.createHash('sha256');
      hash.write($(styles[i]).html());
      hashes.styles.push(hash.digest('base64'))
    }
  }
  return hashes;
}


if (process.argv.length <= 2) {
  process.exit(1);
};

const basedir = process.argv[2];

var files = glob.sync(basedir + "/**/*.html")
var hashes = getAllHashes(files);

var csp_string = "default-src 'self' https:; script-src 'self' https: "
hashes.scripts.forEach(function(hash, index, arr){
    csp_string += "'sha256-" + hash + "'";
    if (index+1 != arr.length ){
        csp_string += " "
    }
});
csp_string += "; style-src 'self' https: "
hashes.styles.forEach(function(hash, index, arr){
    csp_string += "'sha256-" + hash + "'";
    if (index+1 != arr.length ){
        csp_string += " "
    }
});
fs.readFile('_headers', function(err, buf) {
    if(err) throw err;
    data = buf.toString();
    data = data.replace(/(?<=Content-Security-Policy:).*$/gm, " " + csp_string);
    fs.writeFile(basedir + '/_headers', data, function(err) {
        err || console.log(data);
    });
});
