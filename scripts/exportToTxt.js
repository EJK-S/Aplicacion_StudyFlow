const fs = require("fs");

const inputPath = process.argv[2];
const content = fs.readFileSync(inputPath, "utf8");

const outputPath = inputPath.replace(".dart", ".txt");

fs.writeFileSync(outputPath, content);

console.log("Archivo exportado a:", outputPath);
