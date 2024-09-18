import * as fs from 'fs';
import * as path from 'path';
import glob from 'glob';

class LinkedNode {
	#links: LinkedNode[] = [];
	filename = '';

	constructor(filename: string) {
		this.filename = filename;
	}

	addLink(node: LinkedNode) {
		this.#links.push(node);
	}
}

// Finds all files that have the filename in it
const findLinks = (fileName: string): string[] => {
    const pattern = '**/*.{js,jsx,ts,tsx}';
    const files = glob.sync(pattern, { cwd: process.cwd() });
    const matchingFiles: string[] = [];

    // Regular expression to match the filename followed by either a quote or a file extension
    const regex = new RegExp(`${fileName}(?:['"]|\\.js|\\.jsx|\\.ts|\\.tsx)`, 'g');

    for (const file of files) {
        const filePath = path.join(process.cwd(), file);
        const content = fs.readFileSync(filePath, 'utf-8');
        if (regex.test(content)) {
            matchingFiles.push(filePath);
        }
    }

    return matchingFiles;
};

const isAtTopLevel = (fileName: string): boolean => {
	// Implement your logic to check if the file is at the top level
	return true;
};

const findReferences = (rootNode: LinkedNode) => {
	const links = findLinks(rootNode.filename);
	const linksToParse: LinkedNode[] = [];
	for (const link of links) {
		const node = new LinkedNode(link);
		rootNode.addLink(node);
		if (isAtTopLevel(link)) linksToParse.push(node);
	}

	for (const link of linksToParse) {
		findReferences(link);
	}
	return rootNode;
}