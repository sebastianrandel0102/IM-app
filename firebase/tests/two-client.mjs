// Real Auth + Firestore emulator integration, not a two-physical-device claim.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { randomBytes, createHash } from 'node:crypto';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator, doc, collection, query, where, orderBy, limit, getDoc, getDocs, setDoc, updateDoc, writeBatch, onSnapshot, serverTimestamp, Timestamp, terminate } from 'firebase/firestore';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

if(!process.env.FIRESTORE_EMULATOR_HOST||!process.env.FIREBASE_AUTH_EMULATOR_HOST)throw new Error('This test only runs against the local Auth and Firestore emulators.');
const projectId='demo-bear-with-me';
const [host,port]=process.env.FIRESTORE_EMULATOR_HOST.split(':');
const clients=[];
let environment;
try{
  for(const label of ['caramel','snow']){
    const app=initializeApp({projectId,apiKey:'emulator-only-key',appId:'1:123456789:web:emulator'},`client-${label}-${Date.now()}`);
    const auth=getAuth(app);connectAuthEmulator(auth,`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`,{disableWarnings:true});
    const db=getFirestore(app);connectFirestoreEmulator(db,host,Number(port));
    const email=`${label}-${randomBytes(6).toString('hex')}@example.test`,password=randomBytes(16).toString('hex');
    const result=await createUserWithEmailAndPassword(auth,email,password);
    clients.push({app,auth,db,uid:result.user.uid,email,password});
  }
  const [a,b]=clients;
  const rules=(await readFile(new URL('../firestore.rules',import.meta.url),'utf8'))
    .replace(/function memberA\(\) \{ return '[^']*'; \}/,`function memberA() { return '${a.uid}'; }`)
    .replace(/function memberB\(\) \{ return '[^']*'; \}/,`function memberB() { return '${b.uid}'; }`);
  environment=await initializeTestEnvironment({projectId,firestore:{host,port:Number(port),rules}});
  await environment.clearFirestore();
  for(const c of clients){await setDoc(doc(c.db,`users/${c.uid}`),{displayName:c===a?'Caramel':'Snow',accessory:'none',createdAt:serverTimestamp()});}
  const token=randomBytes(32).toString('base64url'),cid=createHash('sha256').update(token).digest('hex');
  const pairPath='privatePair/main',invitePath=`pairInvitations/${cid}`,world=`couples/${cid}`;
  let batch=writeBatch(a.db);
  batch.set(doc(a.db,invitePath),{creatorUid:a.uid,intendedReceiverUid:b.uid,createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+3600_000),status:'pending'});
  batch.set(doc(a.db,pairPath),{memberUids:[a.uid,b.uid],creatorUid:a.uid,receiverUid:b.uid,creatorBear:'brown',invitationId:cid,status:'pending',approvedBy:[],createdAt:serverTimestamp()});
  await batch.commit();
  assert.equal(createHash('sha256').update(token).digest('hex'),cid);
  batch=writeBatch(b.db);batch.update(doc(b.db,invitePath),{status:'accepted'});batch.update(doc(b.db,pairPath),{status:'confirming'});await batch.commit();
  await updateDoc(doc(a.db,pairPath),{approvedBy:[a.uid],status:'confirming'});
  batch=writeBatch(b.db);batch.update(doc(b.db,pairPath),{approvedBy:[a.uid,b.uid],status:'active'});batch.set(doc(b.db,world),{memberUids:[a.uid,b.uid],themeId:'cozyRoom',createdAt:serverTimestamp()});await batch.commit();
  console.log('PASS: two independent Auth registrations, profiles, invitation, acceptance and attributable approvals');
  for(const [sender,receiver,type,id]of [[a,b,'warmHug','hug'],[b,a,'cheekKiss','kiss']]){
    let stop;
    const arrived=new Promise((resolve,reject)=>{
      const timeout=setTimeout(()=>{stop?.();reject(new Error('Real-time inbox listener timed out.'));},10000);
      stop=onSnapshot(query(collection(receiver.db,`${world}/moments`),where('receiverUid','==',receiver.uid),orderBy('createdAt','desc'),limit(30)),snapshot=>{
        const moment=snapshot.docs.find(d=>d.id===id);if(moment){clearTimeout(timeout);resolve(moment.data());}
      },error=>{clearTimeout(timeout);reject(error);});
    });
    const metadata={senderUid:sender.uid,receiverUid:receiver.uid,createdAt:serverTimestamp(),openedAt:null,playedAt:null,genericLabel:'A little surprise arrived.'};
    batch=writeBatch(sender.db);batch.set(doc(sender.db,`${world}/moments/${id}`),metadata);batch.set(doc(sender.db,`${world}/payloads/${id}`),{senderUid:sender.uid,receiverUid:receiver.uid,interactionType:type,animationVariant:'gentle',personalMessage:'An emulator-only test note.',senderBear:sender===a?'brown':'white',receiverBear:sender===a?'white':'brown',assetVersion:1});await batch.commit();
    const safe=await arrived;stop();assert.equal(safe.openedAt,null);assert.equal('interactionType'in safe,false);assert.equal('personalMessage'in safe,false);
    await assert.rejects(getDoc(doc(receiver.db,`${world}/payloads/${id}`)),e=>e.code==='permission-denied');
    await updateDoc(doc(receiver.db,`${world}/moments/${id}`),{openedAt:serverTimestamp()});
    const revealed=(await getDoc(doc(receiver.db,`${world}/payloads/${id}`))).data();assert.equal(revealed.interactionType,type);
    await updateDoc(doc(receiver.db,`${world}/moments/${id}`),{playedAt:serverTimestamp()});
    await setDoc(doc(receiver.db,`${world}/memories/${receiver.uid}_${id}`),{momentId:id,savedByUid:receiver.uid,caption:type,favorite:false,createdAt:serverTimestamp()});
    await signOut(receiver.auth);await signInWithEmailAndPassword(receiver.auth,receiver.email,receiver.password);
    assert.equal((await getDocs(query(collection(receiver.db,`${world}/memories`),where('savedByUid','==',receiver.uid),limit(30)))).size,1);
    console.log(`PASS: ${type} delivered by a live listener, sealed read denied, reveal authorized, playback recorded, memory survives sign-out/sign-in`);
  }
  // Full semantic-touch exchange through real emulator Auth identities.
  const touch={schemaVersion:1,kind:'headPet',zone:'head',style:'gentle',intensity:.3,durationMs:1800,seed:82317,direction:1,repetitions:1,animationId:'touch_headPet',animationVersion:1};
  async function sendEcho(sender,receiver,id,intent,replyToEventId=null){
    return (await import('firebase/firestore')).runTransaction(sender.db,async tx=>{
      const envelopeRef=doc(sender.db,`${world}/moments/${id}`),payloadRef=doc(sender.db,`${world}/payloads/${id}`);
      const existing=await tx.get(envelopeRef);
      if(existing.exists()){const old=await tx.get(payloadRef);assert.deepEqual(old.data().touch,intent);return;}
      tx.set(envelopeRef,{senderUid:sender.uid,receiverUid:receiver.uid,kind:'touch_echo',createdAt:serverTimestamp(),openedAt:null,playedAt:null,genericLabel:'A little surprise arrived.'});
      tx.set(payloadRef,{senderUid:sender.uid,receiverUid:receiver.uid,interactionType:intent.kind==='headPet'?'headPat':'holdingHands',animationVariant:'gentle',personalMessage:'',senderBear:sender===a?'brown':'white',receiverBear:receiver===a?'brown':'white',assetVersion:1,touch:intent,replyToEventId});
      tx.set(doc(sender.db,`${world}/touchSendLimits/${sender.uid}`),{eventId:id,sentAt:serverTimestamp()});
    });
  }
  let stopEcho;
  const echoed=new Promise((resolve,reject)=>{
    const timeout=setTimeout(()=>{stopEcho?.();reject(new Error('Touch inbox delivery timed out'));},10000);
    stopEcho=onSnapshot(query(collection(b.db,`${world}/moments`),where('receiverUid','==',b.uid),limit(30)),s=>{
      const echo=s.docs.find(d=>d.id==='head-pet');if(echo){clearTimeout(timeout);resolve(echo.data());}
    },reject);
  });
  await sendEcho(a,b,'head-pet',touch);
  const envelope=await echoed;stopEcho();assert.equal(envelope.kind,'touch_echo');assert.equal(envelope.touch,undefined);
  await assert.rejects(getDoc(doc(b.db,`${world}/payloads/head-pet`)),e=>e.code==='permission-denied');
  await updateDoc(doc(b.db,`${world}/moments/head-pet`),{openedAt:serverTimestamp()});
  const openedAt=(await getDoc(doc(b.db,`${world}/moments/head-pet`))).data().openedAt;
  assert.deepEqual((await getDoc(doc(b.db,`${world}/payloads/head-pet`))).data().touch,touch);
  await updateDoc(doc(b.db,`${world}/moments/head-pet`),{playedAt:serverTimestamp()});
  await sendEcho(a,b,'head-pet',touch); // Same ID: acknowledged retry, no new event.
  assert.ok((await getDoc(doc(b.db,`${world}/moments/head-pet`))).data().openedAt.isEqual(openedAt));
  const hold={...touch,kind:'pawHold',zone:'paw',animationId:'touch_pawHold',durationMs:2200};
  await sendEcho(b,a,'touch-back',hold,'head-pet');
  await assert.rejects(getDoc(doc(a.db,`${world}/payloads/touch-back`)),e=>e.code==='permission-denied');
  await updateDoc(doc(a.db,`${world}/moments/touch-back`),{openedAt:serverTimestamp()});
  const reply=(await getDoc(doc(a.db,`${world}/payloads/touch-back`))).data();
  assert.equal(reply.replyToEventId,'head-pet');assert.equal(reply.senderBear,'white');assert.equal(reply.receiverBear,'brown');
  await setDoc(doc(a.db,`${world}/memories/${a.uid}_touch-back`),{momentId:'touch-back',savedByUid:a.uid,caption:'Paw Hold',favorite:false,createdAt:serverTimestamp()});
  console.log('PASS: actual head-pet listener delivery, sealed payload denied, explicit reveal, completion, idempotent retry, reverse-role Touch Back and private memory');
  await updateDoc(doc(a.db,pairPath),{status:'revoked'});
  await assert.rejects(getDoc(doc(b.db,`${world}/payloads/hug`)),e=>e.code==='permission-denied');
  console.log('PASS: revoked pairing denies subsequent server access');
  console.log('Two-client emulator integration passed. Physical Android device testing is still required.');
}finally{
  for(const c of clients){await terminate(c.db).catch(()=>{});await deleteApp(c.app);}
  await environment?.cleanup();
}
