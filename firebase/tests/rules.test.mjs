import { before, beforeEach, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, collection, getDoc, getDocs, query, limit, where, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, Timestamp } from 'firebase/firestore';

let env;
const A='bear-a',B='bear-b',X='outsider',CID='a'.repeat(64);
const pairPath='privatePair/main';
const moment=(id='m')=>`couples/${CID}/moments/${id}`;
const payload=(id='m')=>`couples/${CID}/payloads/${id}`;
const db=(uid)=>env.authenticatedContext(uid).firestore();
const get=(uid,path)=>getDoc(doc(db(uid),path));
const future=()=>Timestamp.fromMillis(Date.now()+3600_000);
function pair(status='active',id=CID){return {memberUids:[A,B],creatorUid:A,receiverUid:B,creatorBear:'brown',invitationId:id,status,approvedBy:status==='active'?[A,B]:[],createdAt:Timestamp.now()};}
function meta(sender=A,receiver=B){return {senderUid:sender,receiverUid:receiver,createdAt:serverTimestamp(),openedAt:null,playedAt:null,genericLabel:'A little surprise arrived.'};}
function body(sender=A,receiver=B){return {senderUid:sender,receiverUid:receiver,interactionType:'warmHug',animationVariant:'gentle',personalMessage:'I am right here.',senderBear:sender===A?'brown':'white',receiverBear:sender===A?'white':'brown',assetVersion:1};}
async function seed(data){await env.withSecurityRulesDisabled(async(c)=>{for(const [path,value]of Object.entries(data)){await setDoc(doc(c.firestore(),path),value);}});}
async function active(){await seed({[pairPath]:pair(),[`couples/${CID}`]:{memberUids:[A,B],themeId:'cozyRoom',createdAt:Timestamp.now()}});}
async function send(uid=A,id='m',overrides={},metadata={}){const f=db(uid),batch=writeBatch(f);batch.set(doc(f,moment(id)),{...meta(uid,uid===A?B:A),...metadata});batch.set(doc(f,payload(id)),{...body(uid,uid===A?B:A),...overrides});return batch.commit();}
async function existing(){await active();await send();}
async function createInvitation(){const f=db(A),batch=writeBatch(f);batch.set(doc(f,`pairInvitations/${CID}`),{creatorUid:A,intendedReceiverUid:B,createdAt:serverTimestamp(),expiresAt:future(),status:'pending'});batch.set(doc(f,pairPath),{...pair('pending'),createdAt:serverTimestamp()});return batch.commit();}
async function accept(){const f=db(B),batch=writeBatch(f);batch.update(doc(f,`pairInvitations/${CID}`),{status:'accepted'});batch.update(doc(f,pairPath),{status:'confirming'});return batch.commit();}

before(async()=>{
  const rules=(await readFile(new URL('../firestore.rules',import.meta.url),'utf8')).replace(/function memberA\(\) \{ return '[^']*'; \}/,`function memberA() { return '${A}'; }`).replace(/function memberB\(\) \{ return '[^']*'; \}/,`function memberB() { return '${B}'; }`);
  const [host,port]=(process.env.FIRESTORE_EMULATOR_HOST??'127.0.0.1:8080').split(':');
  env=await initializeTestEnvironment({projectId:'demo-bear-with-me',firestore:{host,port:Number(port),rules}});
});
beforeEach(async()=>env.clearFirestore());
after(async()=>{await env?.cleanup();});

test('anonymous access is denied',async()=>{await active();await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),pairPath)));});
test('outsider cannot read pair, partner profile or moments',async()=>{await existing();await seed({[`users/${A}`]:{displayName:'Bear',accessory:'none',createdAt:Timestamp.now()}});await assertFails(get(X,pairPath));await assertFails(get(X,`users/${A}`));await assertFails(get(X,moment()));});
test('registration can only initialize own safe profile',async()=>{await assertSucceeds(setDoc(doc(db(X),`users/${X}`),{displayName:'New bear',accessory:'none',createdAt:serverTimestamp()}));await assertFails(setDoc(doc(db(X),`users/${A}`),{displayName:'Spoof',accessory:'none',createdAt:serverTimestamp()}));await assertFails(updateDoc(doc(db(X),`users/${X}`),{isMember:true}));});
test('profiles cannot be listed or membership elevated',async()=>{await assertFails(getDocs(collection(db(A),'users')));await assertFails(setDoc(doc(db(X),`users/${X}`),{displayName:'X',accessory:'none',createdAt:serverTimestamp(),memberUids:[A,X]}));});
test('pairing requires atomic invitation and pair creation',async()=>{await assertFails(setDoc(doc(db(A),pairPath),{...pair('pending'),createdAt:serverTimestamp()}));await assertSucceeds(createInvitation());});
test('outsider cannot create an invitation',async()=>{await assertFails(setDoc(doc(db(X),`pairInvitations/${CID}`),{creatorUid:X,intendedReceiverUid:A,createdAt:serverTimestamp(),expiresAt:future(),status:'pending'}));});
test('creator cannot preapprove or accept for recipient',async()=>{await createInvitation();await assertFails(updateDoc(doc(db(A),pairPath),{approvedBy:[B],status:'confirming'}));await assertFails(updateDoc(doc(db(A),`pairInvitations/${CID}`),{status:'accepted'}));});
test('acceptance must update invitation and pair together',async()=>{await createInvitation();await assertFails(updateDoc(doc(db(B),pairPath),{status:'confirming'}));await assertSucceeds(accept());});
test('expired invitations cannot be accepted',async()=>{await createInvitation();await seed({[`pairInvitations/${CID}`]:{creatorUid:A,intendedReceiverUid:B,createdAt:Timestamp.fromMillis(Date.now()-7200_000),expiresAt:Timestamp.fromMillis(Date.now()-1000),status:'pending'}});await assertFails(accept());});
test('each bear must confirm its own approval',async()=>{await createInvitation();await accept();await assertFails(updateDoc(doc(db(A),pairPath),{approvedBy:[B],status:'confirming'}));await assertSucceeds(updateDoc(doc(db(A),pairPath),{approvedBy:[A],status:'confirming'}));await assertFails(updateDoc(doc(db(A),pairPath),{approvedBy:[A,B],status:'active'}));const f=db(B),batch=writeBatch(f);batch.update(doc(f,pairPath),{approvedBy:[A,B],status:'active'});batch.set(doc(f,`couples/${CID}`),{memberUids:[A,B],themeId:'cozyRoom',createdAt:serverTimestamp()});await assertSucceeds(batch.commit());await assertSucceeds(get(A,`couples/${CID}`));});
test('pair approvals cannot be removed or overwritten',async()=>{await createInvitation();await accept();await updateDoc(doc(db(A),pairPath),{approvedBy:[A],status:'confirming'});await assertFails(updateDoc(doc(db(B),pairPath),{approvedBy:[B],status:'confirming'}));});
test('active pair cannot be overwritten by another invitation',async()=>{await active();await assertFails(createInvitation());});
test('valid atomic sending works in both directions',async()=>{await active();await assertSucceeds(send(A,'forward'));await assertSucceeds(send(B,'reverse'));});
test('a standalone metadata write or payload write is denied',async()=>{await active();await assertFails(setDoc(doc(db(A),moment()),meta()));await assertFails(setDoc(doc(db(A),payload()),body()));});
test('outsider cannot send into the private world',async()=>{await active();await assertFails(send(X));});
test('sender and receiver spoofing is denied',async()=>{await active();await assertFails(send(A,'fake',{}, {senderUid:B}));await assertFails(send(A,'self',{}, {receiverUid:A}));});
test('metadata cannot leak a type, message or premature opened state',async()=>{await active();await assertFails(send(A,'leak',{}, {interactionType:'warmHug'}));await assertFails(send(A,'label',{}, {genericLabel:'A warm hug'}));await assertFails(send(A,'open',{}, {openedAt:serverTimestamp()}));});
test('invalid types, variants and oversized notes are denied',async()=>{await active();await assertFails(send(A,'badtype',{interactionType:'arbitrary'}));await assertFails(send(A,'badvariant',{animationVariant:'arbitrary'}));await assertFails(send(A,'large',{personalMessage:'x'.repeat(501)}));await assertFails(send(A,'field',{admin:true}));});
test('incorrect character assignments are denied',async()=>{await active();await assertFails(send(A,'wrongbear',{senderBear:'white',receiverBear:'brown'}));});
test('receiver cannot read sealed payload; sender can read own',async()=>{await existing();await assertFails(get(B,payload()));await assertSucceeds(get(A,payload()));const safe=(await get(B,moment())).data();assert.deepEqual(Object.keys(safe).sort(),['createdAt','genericLabel','openedAt','playedAt','receiverUid','senderUid'].sort());});
test('payload collection listing is denied even after opening',async()=>{await existing();await updateDoc(doc(db(B),moment()),{openedAt:serverTimestamp()});await assertFails(getDocs(query(collection(db(B),`couples/${CID}/payloads`),limit(30))));await assertFails(getDocs(query(collection(db(A),`couples/${CID}/payloads`),limit(30))));});
test('only the receiver can authorize reveal',async()=>{await existing();await assertFails(updateDoc(doc(db(A),moment()),{openedAt:serverTimestamp()}));await assertFails(updateDoc(doc(db(X),moment()),{openedAt:serverTimestamp()}));await assertSucceeds(updateDoc(doc(db(B),moment()),{openedAt:serverTimestamp()}));await assertSucceeds(get(B,payload()));});
test('reveal timestamp must be server time and change no other fields',async()=>{await existing();await assertFails(updateDoc(doc(db(B),moment()),{openedAt:Timestamp.fromMillis(1234)}));await assertFails(updateDoc(doc(db(B),moment()),{openedAt:serverTimestamp(),senderUid:B}));});
test('opened time cannot be rewritten or reset',async()=>{await existing();await updateDoc(doc(db(B),moment()),{openedAt:serverTimestamp()});await assertFails(updateDoc(doc(db(B),moment()),{openedAt:null}));await assertFails(updateDoc(doc(db(B),moment()),{openedAt:serverTimestamp()}));});
test('playback completion requires reveal and only receiver',async()=>{await existing();await assertFails(updateDoc(doc(db(B),moment()),{playedAt:serverTimestamp()}));await updateDoc(doc(db(B),moment()),{openedAt:serverTimestamp()});await assertFails(updateDoc(doc(db(A),moment()),{playedAt:serverTimestamp()}));await assertSucceeds(updateDoc(doc(db(B),moment()),{playedAt:serverTimestamp()}));});
test('payloads are immutable',async()=>{await existing();await assertFails(updateDoc(doc(db(A),payload()),{personalMessage:'changed'}));await assertFails(deleteDoc(doc(db(A),payload())));});
test('inbox queries must have a bounded limit',async()=>{await existing();await assertSucceeds(getDocs(query(collection(db(B),`couples/${CID}/moments`),where('receiverUid','==',B),limit(30))));await assertFails(getDocs(collection(db(B),`couples/${CID}/moments`)));await assertFails(getDocs(query(collection(db(B),`couples/${CID}/moments`),limit(31))));});
test('memories require an eligible opened moment and belong to their saver',async()=>{await existing();const memory={momentId:'m',savedByUid:B,caption:'A hug',favorite:false,createdAt:serverTimestamp()};const path=`couples/${CID}/memories/${B}_m`;await assertFails(setDoc(doc(db(B),path),memory));await updateDoc(doc(db(B),moment()),{openedAt:serverTimestamp()});await assertSucceeds(setDoc(doc(db(B),path),memory));await assertFails(get(A,path));await assertFails(updateDoc(doc(db(A),path),{favorite:true}));await assertSucceeds(updateDoc(doc(db(B),path),{favorite:true}));await assertSucceeds(deleteDoc(doc(db(B),path)));});
test('memory queries cannot list another bear’s private book',async()=>{await existing();await seed({[`couples/${CID}/memories/${B}_m`]:{momentId:'m',savedByUid:B,caption:'Hug',favorite:false,createdAt:Timestamp.now()}});await assertFails(getDocs(query(collection(db(A),`couples/${CID}/memories`),limit(30))));await assertSucceeds(getDocs(query(collection(db(B),`couples/${CID}/memories`),where('savedByUid','==',B),limit(30))));});
test('revocation immediately denies all previous world access',async()=>{await existing();await updateDoc(doc(db(B),moment()),{openedAt:serverTimestamp()});await assertSucceeds(updateDoc(doc(db(A),pairPath),{status:'revoked'}));await assertFails(get(A,moment()));await assertFails(get(B,payload()));await assertFails(send(A,'after'));await assertFails(get(A,`couples/${CID}`));});
test('re-pairing cannot restore previous world access',async()=>{await existing();await seed({[pairPath]:pair('active','b'.repeat(64))});await assertFails(get(A,moment()));await assertFails(get(B,payload()));});
test('one account cannot delete the other account profile',async()=>{await active();await seed({[`users/${B}`]:{displayName:'B',accessory:'none',createdAt:Timestamp.now()}});await assertFails(deleteDoc(doc(db(A),`users/${B}`)));await assertFails(deleteDoc(doc(db(B),`users/${B}`)));await updateDoc(doc(db(B),pairPath),{status:'revoked'});await assertSucceeds(deleteDoc(doc(db(B),`users/${B}`)));});
test('shared themes accept only the bundled theme IDs',async()=>{await active();await assertSucceeds(updateDoc(doc(db(A),`couples/${CID}`),{themeId:'flowerGarden'}));await assertFails(updateDoc(doc(db(A),`couples/${CID}`),{themeId:'remote-url'}));await assertFails(updateDoc(doc(db(A),`couples/${CID}`),{memberUids:[A,X]}));});
test('live sessions require partner acceptance and monotonic sequenced actions',async()=>{await active();const path=`couples/${CID}/liveSessions/live`;await assertSucceeds(setDoc(doc(db(A),path),{initiatorUid:A,status:'invited',currentAction:'wave',eventSequence:0,updatedAt:serverTimestamp()}));await assertFails(updateDoc(doc(db(A),path),{status:'active',updatedAt:serverTimestamp()}));await assertSucceeds(updateDoc(doc(db(B),path),{status:'active',updatedAt:serverTimestamp()}));await seed({[path]:{initiatorUid:A,status:'active',currentAction:'wave',eventSequence:0,updatedAt:Timestamp.fromMillis(Date.now()-2000)}});await assertFails(updateDoc(doc(db(A),path),{currentAction:'warmHug',eventSequence:7,actionSenderUid:A,updatedAt:serverTimestamp()}));await assertSucceeds(updateDoc(doc(db(A),path),{currentAction:'warmHug',eventSequence:1,actionSenderUid:A,updatedAt:serverTimestamp()}));await assertFails(updateDoc(doc(db(B),path),{currentAction:'warmHug',eventSequence:2,actionSenderUid:B,updatedAt:serverTimestamp()}));});

test('live action roles cannot impersonate the partner or an outsider',async()=>{
  await active();
  const path=`couples/${CID}/liveSessions/roles`;
  await seed({[path]:{initiatorUid:A,status:'active',currentAction:'wave',eventSequence:0,updatedAt:Timestamp.fromMillis(Date.now()-2000)}});
  const action={currentAction:'warmHug',eventSequence:1,updatedAt:serverTimestamp()};
  await assertFails(updateDoc(doc(db(B),path),action));
  await assertFails(updateDoc(doc(db(X),path),{...action,actionSenderUid:X}));
  await assertFails(updateDoc(doc(db(B),path),{...action,actionSenderUid:A}));
  await assertSucceeds(updateDoc(doc(db(B),path),{...action,actionSenderUid:B}));
});

const touchDefaults={schemaVersion:1,kind:'headPet',zone:'head',style:'gentle',intensity:.3,durationMs:1800,seed:123,direction:1,repetitions:1,animationId:'touch_headPet',animationVersion:1};
async function sendTouch(uid=A,id='touch',touch={},payloadOverrides={},metadata={}){
  const f=db(uid),batch=writeBatch(f),receiver=uid===A?B:A;
  batch.set(doc(f,moment(id)),{...meta(uid,receiver),kind:'touch_echo',...metadata});
  batch.set(doc(f,payload(id)),{...body(uid,receiver),interactionType:'headPat',personalMessage:'',touch:{...touchDefaults,...touch},replyToEventId:null,...payloadOverrides});
  batch.set(doc(f,`couples/${CID}/touchSendLimits/${uid}`),{eventId:id,sentAt:serverTimestamp()});
  return batch.commit();
}
test('Touch Echo head pet is atomic, sealed and reversible; replay preserves opened time',async()=>{
  await active();await assertSucceeds(sendTouch(A));await assertSucceeds(sendTouch(B,'reverse'));
  await assertFails(get(B,payload('touch')));await assertSucceeds(get(A,payload('touch')));
  const envelope=(await get(B,moment('touch'))).data();assert.equal(envelope.kind,'touch_echo');
  assert.equal(envelope.touch,undefined);assert.equal(envelope.interactionType,undefined);
  await assertFails(updateDoc(doc(db(A),moment('touch')),{openedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(doc(db(B),moment('touch')),{openedAt:serverTimestamp()}));
  await assertSucceeds(get(B,payload('touch')));
  const opened=(await get(B,moment('touch'))).data().openedAt;
  await assertFails(updateDoc(doc(db(B),moment('touch')),{openedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(doc(db(B),moment('touch')),{playedAt:serverTimestamp()}));
  assert.ok((await get(B,moment('touch'))).data().openedAt.isEqual(opened));
});
test('Touch Echo rejects anonymous, outsider, forged roles, spoilers and duplicate overwrites',async()=>{
  await active();await assertFails(sendTouch(X,'outsider'));
  await assertFails(sendTouch(A,'spoof',{}, {senderUid:B}));
  await assertFails(sendTouch(A,'wrongReceiver',{}, {receiverUid:A}));
  await assertFails(sendTouch(A,'wrongbear',{}, {senderBear:'white'}));
  await assertFails(sendTouch(A,'spoiler',{}, {},{touch:touchDefaults}));
  await assertSucceeds(sendTouch());
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),payload('touch'))));
  await assertFails(sendTouch(A));
  await assertFails(updateDoc(doc(db(B),payload('touch')),{'touch.intensity':1}));
  await assertFails(updateDoc(doc(db(A),payload('touch')),{'touch.kind':'noseBoop'}));
  await assertFails(updateDoc(doc(db(B),moment('touch')),{kind:'warmHug',openedAt:serverTimestamp()}));
});
test('Touch payload bounds, enums, schema, zone, adapters and trajectory fields are validated',async()=>{
  await active();let n=0;
  for(const bad of [{kind:'talk'},{zone:'nose'},{style:'rough'},{intensity:-1},{intensity:2},
    {durationMs:6001},{durationMs:350.5},{seed:-1},{repetitions:9},{direction:2},
    {animationVersion:99},{schemaVersion:2},{animationId:'unknown'},
    {normalizedTrace:Array(1000).fill({x:0,y:0})}]){
    await assertFails(sendTouch(A,`bad${n++}`,bad));
  }
  await assertFails(sendTouch(A,'adapter',{}, {interactionType:'noseBoop'}));
  await assertFails(sendTouch(A,'note',{}, {personalMessage:'hidden extra text'}));
});
test('Touch Back must reference a completed received Echo in this active pair',async()=>{
  await active();await sendTouch(A,'original');
  await assertFails(sendTouch(B,'unopened',{}, {replyToEventId:'original'}));
  await updateDoc(doc(db(B),moment('original')),{openedAt:serverTimestamp()});
  await assertFails(sendTouch(B,'unfinished',{}, {replyToEventId:'original'}));
  await updateDoc(doc(db(B),moment('original')),{playedAt:serverTimestamp()});
  await assertSucceeds(sendTouch(B,'reply',{}, {replyToEventId:'original'}));
  await assertFails(sendTouch(A,'ownReply',{}, {replyToEventId:'original'}));
  await assertFails(sendTouch(A,'missing',{}, {replyToEventId:'missing'}));
});
test('Touch Echo rate limit and receiver pause are enforced on the server',async()=>{
  await active();await sendTouch();await assertFails(sendTouch(A,'tooFast'));
  await assertSucceeds(setDoc(doc(db(B),`couples/${CID}/touchPreferences/${B}`),{receiveTouches:false}));
  await seed({[`couples/${CID}/touchSendLimits/${A}`]:{eventId:'touch',sentAt:Timestamp.fromMillis(Date.now()-3000)}});
  await assertFails(sendTouch(A,'blocked'));
  await assertFails(setDoc(doc(db(A),`couples/${CID}/touchPreferences/${B}`),{receiveTouches:true}));
  await assertSucceeds(setDoc(doc(db(B),`couples/${CID}/touchPreferences/${B}`),{receiveTouches:true}));
  await assertSucceeds(sendTouch(A,'resumed'));
});
test('revocation denies Touch Echo payload, pending sends and preference writes',async()=>{
  await active();await sendTouch();await updateDoc(doc(db(B),moment('touch')),{openedAt:serverTimestamp()});
  await updateDoc(doc(db(A),pairPath),{status:'revoked'});
  await assertFails(get(A,moment('touch')));await assertFails(get(B,payload('touch')));
  await assertFails(sendTouch(B,'after'));await assertFails(setDoc(doc(db(B),`couples/${CID}/touchPreferences/${B}`),{receiveTouches:true}));
});
