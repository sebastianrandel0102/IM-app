import {readFile,writeFile} from 'node:fs/promises';
const [a,b]=process.argv.slice(2);
if(!a||!b||a===b||![a,b].every(v=>/^[A-Za-z0-9_-]{1,128}$/.test(v))){throw new Error('Pass two distinct Firebase Authentication UIDs. This helper supports the standard URL-safe UID format.');}
const root=new URL('../',import.meta.url);
const rulesUrl=new URL('firebase/firestore.rules',root);
const rules=await readFile(rulesUrl,'utf8');
await writeFile(rulesUrl,rules.replace(/function memberA\(\) \{ return '[^']*'; \}/,`function memberA() { return '${a}'; }`).replace(/function memberB\(\) \{ return '[^']*'; \}/,`function memberB() { return '${b}'; }`));
await writeFile(new URL('lib/app/configuration/private_membership.dart',root),`// UI addressing hints only; deployed rules are the membership authority.\nconst privateMemberA = '${a}';\nconst privateMemberB = '${b}';\n`);
console.log('Two-member configuration updated locally. Deploy the rules and rebuild both apps.');
