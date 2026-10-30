import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root=fileURLToPath(new URL('../',import.meta.url));
const cli=path.join(root,'node_modules/firebase-tools/lib/bin/firebase.js');
const project='bear-with-me-f60a3';
const run=promisify(execFile);
async function firebase(args){
  try{
    const {stdout}=await run(process.execPath,[cli,...args,'--project',project,'--json','--non-interactive'],{cwd:root,timeout:180_000,maxBuffer:4*1024*1024,windowsHide:true,env:{...process.env,DEBUG:'',FIREBASE_CLI_DISABLE_UPDATE_CHECK:'true'}});
    const response=JSON.parse(stdout);
    if(response.status!=='success')throw new Error(response.error??'Firebase command failed.');
    return response.result;
  }catch(error){throw new Error(`Firebase ${args[0]} failed. Sign in using scripts/firebase.ps1 login, verify access to ${project}, and retry. ${error.message}`);}
}
const apps=await firebase(['apps:list']);
const platforms=[
  {name:'ANDROID',label:'Bear With Me Android',identifier:'com.bearwithme.bear_with_me',flag:'--package-name',field:'packageName'},
  {name:'IOS',label:'Bear With Me iOS',identifier:'com.bearwithme.bearWithMe',flag:'--bundle-id',field:'bundleId'},
  {name:'WEB',label:'Bear With Me Web'},
];
const configs={};
for(const platform of platforms){
  let app=apps.find(a=>a.platform===platform.name&&(platform.identifier?a[platform.field]===platform.identifier:a.displayName===platform.label));
  if(!app){
    app=await firebase(['apps:create',platform.name,platform.label,...(platform.flag?[platform.flag,platform.identifier]:[])]);
    apps.push(app);
  }
  const info=await firebase(['apps:sdkconfig',platform.name,app.appId]);
  let config;
  if(platform.name==='ANDROID'){
    const native=JSON.parse(info.fileContents);
    const client=native.client.find(c=>c.client_info.android_client_info.package_name===platform.identifier);
    config={apiKey:client.api_key[0].current_key,appId:client.client_info.mobilesdk_app_id,messagingSenderId:native.project_info.project_number,projectId:native.project_info.project_id};
    await writeFile(path.join(root,'android/app/google-services.json'),info.fileContents);
  }else if(platform.name==='IOS'){
    const value=key=>info.fileContents.match(new RegExp(`<key>${key}</key>\\s*<string>([^<]+)</string>`))?.[1];
    config={apiKey:value('API_KEY'),appId:value('GOOGLE_APP_ID'),messagingSenderId:value('GCM_SENDER_ID'),projectId:value('PROJECT_ID'),iosBundleId:platform.identifier};
    await writeFile(path.join(root,'ios/Runner/GoogleService-Info.plist'),info.fileContents);
  }else{
    const web=JSON.parse(info.fileContents);
    config={apiKey:web.apiKey,appId:web.appId,messagingSenderId:web.messagingSenderId,projectId:web.projectId,authDomain:web.authDomain};
  }
  if(Object.values(config).some(v=>typeof v!=='string'||!v))throw new Error(`Incomplete ${platform.name} client configuration. Nothing was guessed.`);
  configs[platform.name.toLowerCase()]=config;
  await mkdir(path.join(root,'config'),{recursive:true});
  await writeFile(path.join(root,`config/firebase.${platform.name.toLowerCase()}.json`),JSON.stringify(Object.fromEntries(Object.entries(config).map(([k,v])=>[({apiKey:'FIREBASE_API_KEY',appId:'FIREBASE_APP_ID',messagingSenderId:'FIREBASE_MESSAGING_SENDER_ID',projectId:'FIREBASE_PROJECT_ID',authDomain:'FIREBASE_AUTH_DOMAIN',iosBundleId:'IOS_BUNDLE_ID'})[k],v])),null,2)+'\n');
  console.log(`${platform.name} client configured: ${app.appId}`);
}
const dartOptions=(name,c)=>`  static const ${name} = FirebaseOptions(\n${Object.entries(c).map(([k,v])=>`    ${k}: ${JSON.stringify(v)},`).join('\n')}\n  );`;
await writeFile(path.join(root,'lib/firebase_options.dart'),`// Generated from Firebase Management API client configuration. No service credentials.\nimport 'package:firebase_core/firebase_core.dart';\nimport 'package:flutter/foundation.dart';\nabstract final class DefaultFirebaseOptions {\n  static const configured = true;\n  static FirebaseOptions get currentPlatform {\n    if (kIsWeb) return web;\n    return switch (defaultTargetPlatform) {\n      TargetPlatform.android => android,\n      TargetPlatform.iOS || TargetPlatform.macOS => ios,\n      _ => throw UnsupportedError('Use Android, iOS or web.'),\n    };\n  }\n${Object.entries(configs).map(([k,v])=>dartOptions(k,v)).join('\n')}\n}\n`);
console.log('Flutter client configuration written. No billing or paid services were enabled.');
