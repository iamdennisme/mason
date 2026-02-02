const fs = require('fs');
const path = require('path');

async function generateWindowsIcon() {
    // Configuration
    const scriptDir = __dirname;
    const projectRoot = path.dirname(scriptDir);
    const macOSIconsetDir = path.join(projectRoot, 'macos', 'Runner', 'Resources', 'AppIcon.iconset');
    const windowsIconDir = path.join(projectRoot, 'windows', 'runner', 'resources');
    const windowsIcon = path.join(windowsIconDir, 'app_icon.ico');

    console.log('Generating Windows icon from macOS PNG files...');
    console.log('Project Root:', projectRoot);

    // Check if macOS iconset exists
    if (!fs.existsSync(macOSIconsetDir)) {
        console.error(`Error: macOS iconset not found at ${macOSIconsetDir}`);
        console.log('Please run the bash script first to generate macOS icons.');
        process.exit(1);
    }

    try {
        // Ensure output directory exists
        if (!fs.existsSync(windowsIconDir)) {
            fs.mkdirSync(windowsIconDir, { recursive: true });
        }

        // Create ICO file using a simple implementation
        console.log('\nCreating Windows ICO file...');

        // Check if png-to-ico is available, if not, install it
        let pngToIco;
        try {
            pngToIco = require('png-to-ico');
        } catch (error) {
            console.log('Installing png-to-ico package...');
            const { execSync } = require('child_process');
            execSync(`npm install png-to-ico`, { cwd: scriptDir, stdio: 'inherit' });
            pngToIco = require('png-to-ico');
        }

        // Map macOS PNG sizes to Windows ICO sizes
        // Windows needs: 16x16, 32x32, 48x48, 256x256
        const sizeMapping = [
            { windows: 16, macos: 'icon_16x16' },
            { windows: 32, macos: 'icon_32x32' },
            { windows: 48, macos: 'icon_128x128' }, // Use 128 for 48 (will be resized)
            { windows: 256, macos: 'icon_256x256' },
        ];

        // Read PNG files
        const pngBuffers = [];
        for (const mapping of sizeMapping) {
            const pngFile = path.join(macOSIconsetDir, `${mapping.macos}.png`);
            if (fs.existsSync(pngFile)) {
                pngBuffers.push(fs.readFileSync(pngFile));
                console.log(`Using: ${mapping.macos}.png`);
            } else {
                console.warn(`Warning: ${pngFile} not found, skipping...`);
            }
        }

        if (pngBuffers.length === 0) {
            throw new Error('No PNG files found in macOS iconset');
        }

        // Convert to ICO
        // png-to-ico exports an object with 'default' and 'imagesToIco' functions
        const convertFn = pngToIco.default || pngToIco.imagesToIco;
        const icoBuffer = await convertFn(pngBuffers);

        // Write ICO file
        fs.writeFileSync(windowsIcon, icoBuffer);

        console.log(`\n✓ Windows icon created: ${windowsIcon}`);
        console.log('\n✓ Windows icon generation complete!');
    } catch (error) {
        console.error('Error generating Windows icon:', error.message);
        process.exit(1);
    }
}

generateWindowsIcon();
