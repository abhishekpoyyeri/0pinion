const fs = require('fs');
const path = require('path');

const libDir = path.join(__dirname, 'lib');

function processFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    let changed = false;

    // Replace CircularProgressIndicator with VideoLoader
    if (content.includes('CircularProgressIndicator()')) {
        content = content.replace(/CircularProgressIndicator\(\)/g, 'VideoLoader()');
        changed = true;
    }
    
    // Replace CircularProgressIndicator(color: ...) with VideoLoader()
    if (content.includes('CircularProgressIndicator(')) {
        content = content.replace(/CircularProgressIndicator\([^)]*\)/g, 'VideoLoader()');
        changed = true;
    }

    // Replace RefreshIndicator with VideoRefreshIndicator
    if (content.includes('RefreshIndicator(')) {
        content = content.replace(/RefreshIndicator\(/g, 'VideoRefreshIndicator(');
        changed = true;
    }

    if (changed) {
        // Add imports if not present
        if (content.includes('VideoLoader') && !content.includes('video_loader.dart')) {
            content = "import 'package:opinion_app/core/widgets/video_loader.dart';\n" + content;
        }
        if (content.includes('VideoRefreshIndicator') && !content.includes('video_refresh_indicator.dart')) {
            content = "import 'package:opinion_app/core/widgets/video_refresh_indicator.dart';\n" + content;
        }
        fs.writeFileSync(filePath, content, 'utf8');
        console.log('Updated: ' + filePath);
    }
}

function walkDir(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            walkDir(fullPath);
        } else if (fullPath.endsWith('.dart') && !fullPath.includes('video_loader.dart') && !fullPath.includes('video_refresh_indicator.dart')) {
            processFile(fullPath);
        }
    }
}

walkDir(libDir);
console.log('Done refactoring');
